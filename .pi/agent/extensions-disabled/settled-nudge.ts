/**
 * settled-nudge.ts — jerk Pi back to life when a run settles in a transient
 * provider-error state (e.g. a 429 around compaction) instead of letting it
 * sit idle with the task half done.
 *
 * Why this is needed
 * ------------------
 * `agent_settled` fires when a session-level run ends and no automatic
 * continuation (auto-retry, compaction retry, queued follow-up) remains. It
 * does NOT mean "the task succeeded" — a run can settle in an error state,
 * and once settled nothing inside Pi re-triggers it.
 *
 * With a rate-limited endpoint two failure modes drop the ball:
 *
 *   A. Overflow/truncation recovery compacts, but the summarisation call
 *      itself 429s and exhausts the summarisation retry budget →
 *      "Context overflow recovery failed: Summarization failed: 429 ..." →
 *      the interrupted turn is lost and the agent settles. (The 429 never
 *      becomes an assistant message, so it is only visible via
 *      `session_compact_failed`.)
 *
 *   B. The post-compaction continuation 429s and exhausts the built-in
 *      auto-retry budget (default 3 attempts, 2s/4s/8s backoff) → the agent
 *      settles with the last assistant message an error.
 *
 * This extension watches for runs that settle with a transient provider
 * error (or a compaction failure caused by one) and, after a short backoff,
 * sends a "continue" user message to start a new run — unless the agent is
 * already busy, the user has queued input, or the nudge budget is exhausted.
 *
 * Hard quota/billing errors (e.g. "quota exceeded", "insufficient_quota",
 * "Monthly usage limit reached") are deliberately NOT nudged: retrying
 * against a hard cap is pointless.
 *
 * Install: drop into ~/.pi/agent/extensions/ (global) or .pi/extensions/
 * (project-local), then /reload or restart pi.
 *
 * References:
 * - Extension docs: https://pi.dev/docs/latest/extensions
 * - Compaction internals: https://pi.dev/docs/latest/compaction
 * - Upstream issue #1038 (429 misclassified as context overflow, fixed; the
 *   summarisation-429 variant described there is sub-case A above).
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Mirrors pi-ai's error classification (RETRYABLE_PROVIDER_ERROR_PATTERN and
// NON_RETRYABLE_PROVIDER_LIMIT_ERROR_PATTERN in @earendil-works/pi-ai). Keep
// in sync if pi-ai changes these.
const TRANSIENT = new RegExp(
	[
		"overloaded",
		"rate.?limit",
		"too many requests",
		"429",
		"500",
		"502",
		"503",
		"504",
		"524",
		"service.?unavailable",
		"server.?error",
		"internal.?error",
		"provider.?returned.?error",
		"exceeded request buffer limit while retrying upstream",
		"network.?error",
		"connection.?error",
		"connection.?refused",
		"connection.?lost",
		"other side closed",
		"fetch failed",
		"getaddrinfo",
		"ENOTFOUND",
		"EAI_AGAIN",
		"upstream.?connect",
		"reset before headers",
		"socket hang up",
		"socket connection was closed",
		"timed? out",
		"timeout",
		"terminated",
		"websocket.?closed",
		"websocket.?error",
		"ended without",
		"stream ended before message_stop",
		"stream ended before a terminal response event",
		"http2 request did not get a response",
		"retry delay",
		"you can retry your request",
		"try your request again",
		"please retry your request",
		"ResourceExhausted",
	].join("|"),
	"i",
);
const HARD_LIMIT = new RegExp(
	[
		"GoUsageLimitError",
		"FreeUsageLimitError",
		"Monthly usage limit reached",
		"available balance",
		"insufficient_quota",
		"out of budget",
		"quota exceeded",
		"billing",
	].join("|"),
	"i",
);

/** Maximum consecutive nudges per failure streak. */
const MAX_NUDGES = 5;
/** Base delay for nudge backoff; doubles per nudge (15s, 30s, 60s, ...). */
const BASE_DELAY_MS = 15_000;
/** Cap on any single nudge delay (also caps honoured Retry-After values). */
const MAX_DELAY_MS = 5 * 60_000;
const NUDGE_TEXT =
	"The previous attempt ended in a transient provider error (e.g. rate limit). " +
	"Continue from where you left off.";

type Failure = { source: "turn" | "compaction"; message: string };

function shorten(text: string, max = 80): string {
	const flat = text.replace(/\s+/g, " ").trim();
	return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
}

export default function (pi: ExtensionAPI) {
	let nudges = 0;
	let failure: Failure | undefined;
	let retryAfterMs: number | undefined;
	let timer: ReturnType<typeof setTimeout> | undefined;

	const clearTimer = () => {
		if (timer) {
			clearTimeout(timer);
			timer = undefined;
		}
	};

	// Best-effort: capture Retry-After from rate-limit responses where the
	// provider/transport exposes headers.
	pi.on("after_provider_response", (event) => {
		if (event.status !== 429) return;
		const value = event.headers["retry-after"];
		if (!value) return;
		const seconds = Number(value);
		if (Number.isFinite(seconds) && seconds > 0) {
			retryAfterMs = Math.min(seconds * 1000, MAX_DELAY_MS);
		}
	});

	// Sub-case B: the run's final assistant message is a transient error.
	pi.on("message_end", (event) => {
		const msg = event.message;
		if (msg.role !== "assistant") return;
		if (msg.stopReason === "stop") {
			// Genuinely completed turn: clear failure state and reset budget.
			failure = undefined;
			nudges = 0;
		} else if (msg.stopReason === "aborted") {
			// User cancelled: do not resurrect.
			failure = undefined;
		} else if (msg.stopReason === "error" && msg.errorMessage) {
			if (HARD_LIMIT.test(msg.errorMessage)) {
				failure = undefined; // hard quota/billing: nudging is pointless
			} else if (TRANSIENT.test(msg.errorMessage)) {
				failure = { source: "turn", message: msg.errorMessage };
			}
		}
	});

	// Sub-case A: the summarisation call failed, so the 429 never becomes an
	// assistant message. Only non-abort failures with a transient error count.
	pi.on("session_compact_failed", (event) => {
		if (event.aborted) {
			failure = undefined;
			return;
		}
		if (
			event.errorMessage &&
			!HARD_LIMIT.test(event.errorMessage) &&
			TRANSIENT.test(event.errorMessage)
		) {
			failure = { source: "compaction", message: event.errorMessage };
		}
	});

	// Terminal state: the run is over and Pi will not continue automatically.
	// If it settled in a transient-error state, schedule a nudge.
	pi.on("agent_settled", (_event, ctx) => {
		clearTimer();
		if (!failure) return;
		if (nudges >= MAX_NUDGES) {
			if (ctx.hasUI) {
				ctx.ui.notify(`settled-nudge: giving up after ${MAX_NUDGES} nudges`, "error");
			}
			failure = undefined;
			nudges = 0;
			return;
		}
		if (ctx.hasPendingMessages()) return; // user already queued input
		nudges += 1;
		const delay = Math.min(retryAfterMs ?? BASE_DELAY_MS * 2 ** (nudges - 1), MAX_DELAY_MS);
		retryAfterMs = undefined;
		if (ctx.hasUI) {
			ctx.ui.notify(
				`settled-nudge: ${failure.source} failed (${shorten(failure.message)}); ` +
					`nudge ${nudges}/${MAX_NUDGES} in ${Math.round(delay / 1000)}s`,
				"warning",
			);
		}
		timer = setTimeout(() => {
			timer = undefined;
			try {
				// State may have moved on (user typed a prompt, another
				// extension started a run, session was replaced/reloaded).
				if (!ctx.isIdle() || ctx.hasPendingMessages()) return;
				pi.sendUserMessage(NUDGE_TEXT);
			} catch {
				// Stale ctx after session replacement/reload: nothing to do.
			}
		}, delay);
	});

	pi.on("session_shutdown", () => {
		clearTimer();
		failure = undefined;
		nudges = 0;
		retryAfterMs = undefined;
	});

	// Manual escape hatch.
	pi.registerCommand("nudge", {
		description: "Send a continue-nudge to the agent (settled-nudge extension)",
		handler: async (_args, ctx) => {
			if (!ctx.isIdle()) {
				ctx.ui.notify("Agent is busy", "warning");
				return;
			}
			pi.sendUserMessage(NUDGE_TEXT);
		},
	});
}
