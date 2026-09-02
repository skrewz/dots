/**
 * Goal extension — keeps the agent working toward a goal until it's met.
 *
 * Inspired by Claude Code's /goal command. After each turn, a separate
 * model call evaluates whether the goal condition has been met. If not,
 * the agent is prompted to continue with the evaluator's reason as
 * guidance for the next turn.
 *
 * Usage:
 *   /goal <condition>   Set a goal (starts working immediately)
 *   /goal               Show goal status
 *   /goal clear         Clear the active goal
 *
 * Configuration (settings.json, global or project):
 *   {
 *     "goal": {
 *       "evaluatorModel": "anthropic/claude-haiku-4-5"
 *     }
 *   }
 *
 * If evaluatorModel is not set, the current session model is used.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { CONFIG_DIR_NAME, getAgentDir } from "@earendil-works/pi-coding-agent";

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

// --- Types ---

interface GoalState {
	condition: string;
	turnCount: number;
	startTime: number;
	lastReason?: string;
	stallCount: number;
}

interface GoalSettings {
	evaluatorModel?: string;
}

interface RetrySettings {
	enabled?: boolean;
	maxRetries?: number;
	baseDelayMs?: number;
}

interface RetryPolicy {
	enabled: boolean;
	maxRetries: number;
	baseDelayMs: number;
}

interface Verdict {
	met: boolean;
	impossible?: boolean;
	reason?: string;
}

// --- Constants ---

const STALL_LIMIT = 8;
const MAX_CONVERSATION_CHARS = 30_000;

// --- Retry (matches settings.retry semantics: exponential backoff) ---

const TRANSIENT_ERROR_PATTERN = /429|rate.?limit|too many requests|503|unavailable|overloaded|try again later/i;

function sleep(ms: number, signal?: AbortSignal): Promise<void> {
	return new Promise((resolve) => {
		const t = setTimeout(resolve, ms);
		signal?.addEventListener("abort", () => { clearTimeout(t); resolve(); }, { once: true });
	});
}

async function completeWithRetry(
	produce: () => Promise<{ stopReason: string; errorMessage?: string; [key: string]: unknown }>,
	policy: RetryPolicy,
	signal: AbortSignal | undefined,
	onRetry?: (attempt: number, max: number, delayMs: number, error: string) => void,
) {
	if (!policy.enabled || policy.maxRetries <= 0) return produce();

	for (let attempt = 0; ; attempt++) {
		if (signal?.aborted) break;
		const result = await produce();

		const isTransient = result.stopReason === "error" &&
			TRANSIENT_ERROR_PATTERN.test(result.errorMessage ?? "");

		if (!isTransient || attempt >= policy.maxRetries) return result;

		const delayMs = policy.baseDelayMs * 2 ** attempt;
		onRetry?.(attempt + 1, policy.maxRetries, delayMs, result.errorMessage ?? "");
		await sleep(delayMs, signal);
	}

	// Aborted during backoff — return a synthetic aborted result
	return { stopReason: "aborted", errorMessage: "Aborted during retry backoff" } as any;
}

// --- Settings ---

function loadJsonFile(path: string): Record<string, unknown> | null {
	try {
		if (!existsSync(path)) return null;
		return JSON.parse(readFileSync(path, "utf-8"));
	} catch {
		return null;
	}
}

function loadMergedSettings(cwd: string): Record<string, unknown> {
	const globalSettings = loadJsonFile(join(getAgentDir(), "settings.json"));
	const projectSettings = loadJsonFile(join(cwd, CONFIG_DIR_NAME, "settings.json"));

	return {
		...globalSettings,
		...projectSettings,
	};
}

function loadGoalSettings(cwd: string): GoalSettings {
	return (loadMergedSettings(cwd).goal as GoalSettings | undefined) ?? {};
}

function loadRetryPolicy(cwd: string): RetryPolicy {
	const settings = loadMergedSettings(cwd);
	const retry = settings.retry as RetrySettings | undefined;
	return {
		enabled: retry?.enabled ?? true,
		maxRetries: retry?.maxRetries ?? 3,
		baseDelayMs: retry?.baseDelayMs ?? 5000,
	};
}

// --- Conversation builder ---

type ContentBlock = {
	type?: string;
	text?: string;
	name?: string;
	arguments?: Record<string, unknown>;
};

type SessionEntry = {
	type: string;
	message?: {
		role?: string;
		content?: unknown;
	};
};

function extractTextParts(content: unknown): string[] {
	if (typeof content === "string") return [content];
	if (!Array.isArray(content)) return [];
	return content
		.filter((p): p is ContentBlock => p != null && typeof p === "object")
		.filter((p) => p.type === "text" && typeof p.text === "string")
		.map((p) => p.text!);
}

function extractToolCallLines(content: unknown): string[] {
	if (!Array.isArray(content)) return [];
	return content
		.filter((p): p is ContentBlock => p != null && typeof p === "object")
		.filter((p) => p.type === "toolCall" && typeof p.name === "string")
		.map((p) => `  → ${p.name}(${JSON.stringify(p.arguments ?? {}).slice(0, 200)})`);
}

function buildConversationText(ctx: ExtensionContext, maxChars: number): string {
	const branch = ctx.sessionManager.getBranch();
	const sections: string[] = [];

	for (const entry of branch) {
		if (entry.type !== "message" || !entry.message?.role) continue;

		const role = entry.message.role;
		if (role !== "user" && role !== "assistant") continue;

		const lines: string[] = [];
		const textParts = extractTextParts(entry.message.content);
		if (textParts.length > 0) {
			const label = role === "user" ? "User" : "Assistant";
			const text = textParts.join("\n").trim();
			if (text) lines.push(`${label}: ${text}`);
		}

		if (role === "assistant") {
			lines.push(...extractToolCallLines(entry.message.content));
		}

		if (lines.length > 0) sections.push(lines.join("\n"));
	}

	let result = sections.join("\n\n");

	// Keep the most recent messages (truncate from the front)
	if (result.length > maxChars) {
		result = "…[earlier conversation truncated]…\n\n" + result.slice(-maxChars);
	}

	return result;
}

// --- Stall detection ---

function lastTurnHadToolUse(ctx: ExtensionContext): boolean {
	const branch = ctx.sessionManager.getBranch();
	for (let i = branch.length - 1; i >= 0; i--) {
		const entry = branch[i];
		if (entry.type !== "message") continue;
		const msg = entry.message;
		if (!msg || msg.role !== "assistant") continue;

		const content = msg.content;
		if (Array.isArray(content)) {
			return content.some(
				(p) => p != null && typeof p === "object" && (p as ContentBlock).type === "toolCall",
			);
		}
		return false;
	}
	return false;
}

// --- Evaluator ---

const EVALUATOR_SYSTEM_PROMPT = [
	"You are an evaluator. Determine whether a goal has been achieved based solely on the conversation provided.",
	"Do not assume anything not visible in the conversation.",
	"",
	"Respond with a single JSON object on one line:",
	'- Goal achieved: {"met":true}',
	'- Not yet achieved: {"met":false,"reason":"<what specifically remains>"}',
	'- Impossible: {"met":false,"impossible":true,"reason":"<why it can never be satisfied>"}',
	'',
	'The "reason" for not-met should be a concise, actionable instruction for the next step.',
].join("\n");

function parseVerdict(text: string): Verdict {
	// Try to parse the whole response as JSON
	try {
		const parsed = JSON.parse(text);
		if (typeof parsed.met === "boolean") {
			return { met: parsed.met, impossible: parsed.impossible ?? false, reason: parsed.reason };
		}
	} catch { /* not pure JSON */ }

	// Look for a JSON object in the response
	const match = text.match(/\{[^{}]*"met"\s*:\s*(?:true|false)[^{}]*\}/);
	if (match) {
		try {
			const parsed = JSON.parse(match[0]);
			return { met: parsed.met, impossible: parsed.impossible ?? false, reason: parsed.reason };
		} catch { /* malformed */ }
	}

	// Fallback: treat as not met
	return { met: false, reason: "Evaluator response could not be parsed. Continue working toward the goal." };
}

async function evaluateGoal(
	ctx: ExtensionContext,
	condition: string,
	conversationText: string,
): Promise<Verdict> {
	if (!ctx.model) {
		return { met: false, reason: "No model available for evaluation." };
	}

	// Determine evaluator model: settings override, fall back to current model
	let model = ctx.model;
	const settings = loadGoalSettings(ctx.cwd);
	if (settings.evaluatorModel) {
		const slashIdx = settings.evaluatorModel.indexOf("/");
		if (slashIdx > 0) {
			const provider = settings.evaluatorModel.slice(0, slashIdx);
			const modelId = settings.evaluatorModel.slice(slashIdx + 1);
			const found = ctx.modelRegistry.find(provider, modelId);
			if (found && ctx.modelRegistry.hasConfiguredAuth(found)) {
				model = found;
			}
		}
	}

	const userPrompt = [
		`Goal: ${condition}`,
		"",
		"Conversation:",
		conversationText,
		"",
		"Has the goal been achieved?",
	].join("\n");

	const retryPolicy = loadRetryPolicy(ctx.cwd);

	const response = await completeWithRetry(
		() => ctx.modelRegistry.complete(
			model,
			{
				systemPrompt: EVALUATOR_SYSTEM_PROMPT,
				messages: [
					{
						role: "user" as const,
						content: [{ type: "text" as const, text: userPrompt }],
						timestamp: Date.now(),
					},
				],
			},
			{
				cacheRetention: "none",
				sessionId: `goal-eval-${Date.now().toString(36)}`,
			},
		),
		retryPolicy,
		ctx.signal,
		(attempt, max, delayMs, error) => {
			ctx.ui.notify?.(
				`Goal evaluator retry ${attempt}/${max} in ${Math.round(delayMs / 1000)}s (${error.slice(0, 60)})`,
				"warning",
			);
		},
	);

	const text = response.content
		.filter((c): c is { type: "text"; text: string } => c.type === "text")
		.map((c) => c.text)
		.join("\n");

	return parseVerdict(text);
}

// --- Main extension ---

export default function (pi: ExtensionAPI) {
	let goal: GoalState | null = null;

	// --- /goal command ---
	pi.registerCommand("goal", {
		description: "Set a goal for the agent to work toward until achieved",
		handler: async (args, ctx) => {
			const arg = args?.trim() ?? "";

			// /goal clear
			if (["clear", "stop", "off", "reset", "none", "cancel"].includes(arg.toLowerCase())) {
				if (goal) {
					ctx.ui.notify(`Goal cleared: ${goal.condition}`, "info");
				} else {
					ctx.ui.notify("No goal set", "info");
				}
				goal = null;
				pi.appendEntry("goal-state", { cleared: true });
				ctx.ui.setStatus("goal", undefined);
				ctx.ui.setWidget("goal", undefined);
				return;
			}

			// /goal (no args) — show status
			if (!arg) {
				if (!goal) {
					ctx.ui.notify("No goal set. Usage: /goal <condition>", "info");
					return;
				}
				const elapsed = Math.floor((Date.now() - goal.startTime) / 1000);
				const mins = Math.floor(elapsed / 60);
				const secs = elapsed % 60;
				const lines = [
					`Goal: ${goal.condition}`,
					`Running: ${mins}m ${secs}s`,
					`Turns evaluated: ${goal.turnCount}`,
				];
				if (goal.lastReason) lines.push(`Last: ${goal.lastReason}`);
				ctx.ui.notify(lines.join("\n"), "info");
				return;
			}

			// /goal <condition> — set goal (replaces any existing goal)
			goal = {
				condition: arg,
				turnCount: 0,
				startTime: Date.now(),
				stallCount: 0,
			};
			pi.appendEntry("goal-state", { ...goal });
			ctx.ui.notify(`Goal set: ${arg}`, "info");
			ctx.ui.setStatus("goal", "◎ /goal active");
			ctx.ui.setWidget("goal", [`◎ ${arg}`]);

			// Start working immediately — the condition is the directive
			pi.sendUserMessage(arg);
		},
	});

	// --- Evaluate on agent_settled ---
	pi.on("agent_settled", async (_event, ctx) => {
		if (!goal) return;

		// If another extension started a new run, skip evaluation
		if (!ctx.isIdle()) return;

		// Stall detection
		const hadToolUse = lastTurnHadToolUse(ctx);
		goal.stallCount = hadToolUse ? 0 : goal.stallCount + 1;

		if (goal.stallCount >= STALL_LIMIT) {
			ctx.ui.notify(
				`Goal stalled: no tool use for ${STALL_LIMIT} consecutive turns. ` +
				`Goal remains set — send a prompt to resume.`,
				"warning",
			);
			ctx.ui.setStatus("goal", `◎ /goal stalled`);
			return;
		}

		// Evaluate
		try {
			const conversationText = buildConversationText(ctx, MAX_CONVERSATION_CHARS);
			const verdict = await evaluateGoal(ctx, goal.condition, conversationText);
			goal.turnCount++;

			if (verdict.met) {
				ctx.ui.notify(`Goal achieved: ${goal.condition}`, "info");
				pi.appendEntry("goal-state", { ...goal, achieved: true });
				goal = null;
				ctx.ui.setStatus("goal", undefined);
				ctx.ui.setWidget("goal", undefined);
				return;
			}

			if (verdict.impossible) {
				ctx.ui.notify(`Goal impossible: ${verdict.reason ?? "no reason given"}`, "warning");
				pi.appendEntry("goal-state", { ...goal, failed: true });
				goal = null;
				ctx.ui.setStatus("goal", undefined);
				ctx.ui.setWidget("goal", undefined);
				return;
			}

			// Not met — continue
			goal.lastReason = verdict.reason;
			const reason = verdict.reason ?? "Continue working toward the goal.";

			const shortReason = reason.length > 60 ? reason.slice(0, 57) + "…" : reason;
			ctx.ui.setStatus("goal", `◎ /goal turn ${goal.turnCount} — ${shortReason}`);
			ctx.ui.setWidget("goal", [
				`◎ ${goal.condition}`,
				`Turn ${goal.turnCount}: ${shortReason}`,
			]);

			// Send follow-up to continue the agent
			if (ctx.isIdle()) {
				pi.sendUserMessage(reason);
			} else {
				pi.sendUserMessage(reason, { deliverAs: "followUp" });
			}
		} catch (err) {
			const msg = err instanceof Error ? err.message : String(err);
			ctx.ui.notify(`Goal evaluation failed: ${msg}`, "warning");
		}
	});

	// --- Restore state on session_start ---
	pi.on("session_start", async (_event, ctx) => {
		goal = null;
		for (const entry of ctx.sessionManager.getEntries()) {
			if (entry.type !== "custom" || entry.customType !== "goal-state") continue;
			const data = entry.data as
				| (GoalState & { achieved?: boolean; failed?: boolean; cleared?: boolean })
				| null
				| undefined;
			if (!data) continue;
			if (data.cleared || data.achieved || data.failed) continue;
			// Restore active goal, reset per-session counters
			goal = {
				condition: data.condition,
				turnCount: 0,
				startTime: Date.now(),
				stallCount: 0,
			};
			ctx.ui.setStatus("goal", "◎ /goal active (resumed)");
			ctx.ui.setWidget("goal", [`◎ ${data.condition} (resumed)`]);
		}
	});
}
