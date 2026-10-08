/**
 * Collapsed thinking blocks that keep their own reasoning-token count.
 *
 * Pi can hide thinking blocks (`settings.json` `hideThinkingBlock: true`, or
 * Ctrl+T), and renders each collapsed block as one italic label, defaulting to
 * "Thinking...". The only public knob for that label is
 * `ctx.ui.setHiddenThinkingLabel(label)`, which is *global*: Pi stores one
 * string and writes it to every assistant message component in the transcript
 * (`setHiddenThinkingLabel` in `dist/modes/interactive/interactive-mode.js`).
 * Driving it from `message_update` therefore renumbered every collapsed block
 * in the history with the streaming message's count. See
 * `docs/extensions.md` and `examples/extensions/hidden-thinking-label.ts` in
 * the installed package.
 *
 * There is no per-message API, so this extension does what
 * `pi-compact-thinking` (pi.dev/packages/pi-compact-thinking) does and reaches
 * into the renderer. `AssistantMessageComponent` is exported from
 * `@earendil-works/pi-coding-agent`, and in the bundled runtime extensions get
 * that module from Pi's own module graph
 * (`dist/core/extensions/virtual-modules.js`), so patching its prototype
 * affects the components Pi actually renders.
 *
 * `updateContent(message)` is the one place that reads
 * `this.hiddenThinkingLabel` while drawing a hidden thinking block, and Pi
 * calls it for every render: on construction, on each streamed chunk, at
 * `message_end`, and from `invalidate()`. Wrapping it lets each block derive
 * its label from its own message, so:
 *
 *   - the streaming block counts up while the model reasons;
 *   - the number freezes at that message's final count;
 *   - older blocks are never touched again.
 *
 * Wording follows the block's state. `updateContent(message, isStreaming)` is
 * Pi's own end-of-block signal: it passes `true` on `message_start` and every
 * `message_update`, and `false` on `message_end` (`interactive-mode.js`). The
 * component also stores that flag, so re-renders that omit the argument —
 * `invalidate()`, the Ctrl+T `setHideThinkingBlock()` toggle — keep the state
 * of the block they belong to. Hence "⠋ Thinking... (78 reasoning tokens)" while
 * reasoning, "Thought (78 reasoning tokens)" once over. Historical messages,
 * including resumed ones, are constructed not streaming, so they read
 * "Thought (...)" straight away. Counts are written out in full, never as
 * "1.4k".
 *
 * The spinner is derived from the clock rather than from a timer of our own.
 * Pi already re-renders the whole interface every 80 ms while a turn is in
 * flight, because its working indicator is a `Loader` (pi-tui
 * `components/loader.js`) ticking `ui.requestRender()`, and `updateContent` runs
 * on every one of those frames — so the braille glyph spins in step with Pi's
 * own indicator at no extra cost, and stops dead when the turn ends. Nothing
 * here starts a process, socket or timer. If another extension hides the
 * working row (`ctx.ui.setWorkingVisible(false)`), the glyph still advances,
 * just once per streamed chunk rather than every 80 ms.
 *
 * Counts come from `usage.reasoning` when the provider reports it (this also
 * covers resumed sessions, which store usage per message), otherwise they are
 * estimated from the thinking text at four characters per token. Providers that
 * hide their reasoning (encrypted reasoning) report neither, and those blocks
 * keep the plain label, spinner aside. The count is per assistant message, so a
 * message with several thinking runs after some tool calls shows that total on
 * each line.
 *
 * Caveat: this leans on Pi internals, so it may need updating after a Pi
 * upgrade. The tests in `~/.pi/agent/extensions-tests` render real components
 * and will fail loudly if the renderer changes shape.
 *
 * Try it:
 *   pi --extension ~/.pi/agent/extensions/thinking-tokens.ts
 */

import { AssistantMessageComponent, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** Characters per token, matching the rough estimate Pi uses elsewhere. */
const CHARS_PER_TOKEN = 4;

/** Suffix this extension appends; `baseWording()` reverses it. Also tolerates
 * the unparenthesised, abbreviated form older versions of this extension wrote,
 * so a stale or foreign label of that shape never ends up with two counts on
 * one line. */
const COUNT_SUFFIX =
	/(?: \(\d+(?:\.\d+)?k? reasoning tokens\)| \d+(?:\.\d+)?k? reasoning tokens)$/;

/** Leading spinner glyph this extension may have added; `baseWording()` strips it. */
const SPINNER_PREFIX = /^[\u2800-\u28FF]\s+/;

/** Pi's own label, used while the model is reasoning. */
const STREAMING_LABEL = "Thinking...";

/**
 * Wording once the message is over. Reads as "Thought (78 reasoning tokens)";
 * change these two constants to reword the extension.
 */
const COMPLETE_LABEL = "Thought";

/** Labels this extension owns, so a wording set by someone else wins. */
const OWNED_LABELS = new Set([STREAMING_LABEL, COMPLETE_LABEL]);

/** Braille frames and cadence, same as pi-tui's Loader, so they spin in step. */
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const SPINNER_INTERVAL_MS = 80;

/** A braille glyph, from the clock: no timer needed, Pi renders us anyway. */
export function spinnerFrame(now: number = Date.now()): string {
	return SPINNER_FRAMES[Math.floor(now / SPINNER_INTERVAL_MS) % SPINNER_FRAMES.length] ?? SPINNER_FRAMES[0];
}

/** Marks a prototype we have already wrapped, surviving extension reloads. */
const PATCHED = Symbol.for("pi.thinkingTokens.patched");

/** The slice of an assistant message this extension can count. */
interface CountableMessage {
	content?: readonly { type: string; thinking?: string }[];
	usage?: { reasoning?: number };
}

/** The bits of Pi's component prototype this extension wraps. */
interface AssistantComponentPrototype {
	hiddenThinkingLabel?: unknown;
	isStreaming?: boolean;
	updateContent(message: CountableMessage, isStreaming?: boolean): void;
}

/** Reasoning tokens for a message: reported first, estimated otherwise. */
function reasoningTokens(message: CountableMessage | undefined): number {
	if (!message) return 0;
	// Prefer the provider's own count when it reports one. `usage.reasoning` is
	// a subset of `output`, and undefined for providers with no breakdown.
	const reported = message.usage?.reasoning ?? 0;
	if (reported > 0) return reported;
	let chars = 0;
	for (const block of message.content ?? []) {
		if (block.type === "thinking") chars += block.thinking?.length ?? 0;
	}
	return Math.floor(chars / CHARS_PER_TOKEN);
}

/** Recover the wording from a label this extension produced. */
function baseWording(label: unknown): string {
	if (typeof label !== "string" || !label) return STREAMING_LABEL;
	return label.replace(SPINNER_PREFIX, "").replace(COUNT_SUFFIX, "");
}

/**
 * The label for one message: wording for its state, plus its own count in
 * full — no `1.4k` abbreviation. `streaming` is Pi's own flag, true until
 * `message_end`; `frame` is a seam for tests. Exported for tests.
 */
export function thinkingLabelFor(
	message: CountableMessage | undefined,
	base?: string,
	streaming = false,
	frame: string = spinnerFrame(),
): string {
	const tokens = reasoningTokens(message);
	const count = tokens > 0 ? ` (${tokens} reasoning tokens)` : "";
	const spinner = streaming ? `${frame} ` : "";
	// Wording someone else chose (settings, another extension) wins; ours does not.
	const wording = base ? baseWording(base) : undefined;
	const borrowed = wording && !OWNED_LABELS.has(wording) ? wording : undefined;
	if (borrowed) return `${spinner}${borrowed}${count}`;
	if (streaming) return `${spinner}${STREAMING_LABEL}${count}`;
	// A finished block with nothing to report just reads "Thought".
	return `${COMPLETE_LABEL}${count}`;
}

/**
 * Make every assistant message component derive its hidden thinking label from
 * its own message. Idempotent, even across extension reloads (Pi keeps the
 * class, and therefore the prototype, alive). Returns an undo function.
 * Exported for tests.
 */
export function installThinkingTokenLabels(): () => void {
	const proto = AssistantMessageComponent.prototype as unknown as AssistantComponentPrototype & {
		[PATCHED]?: { updateContent: AssistantComponentPrototype["updateContent"] };
	};
	const state = (proto[PATCHED] ??= { updateContent: proto.updateContent });
	const original = state.updateContent;
	proto.updateContent = function (this: AssistantComponentPrototype, message, isStreaming) {
		// Read the label Pi wants, then re-decorate it with this message's count.
		// Because the count suffix is recognisable, Pi's own label survives both
		// its global `setHiddenThinkingLabel()` fan-out and repeated re-renders.
		// Re-renders that omit `isStreaming` inherit the component's own flag,
		// which is how Pi tells a finished block from one still being streamed.
		this.hiddenThinkingLabel = thinkingLabelFor(message, this.hiddenThinkingLabel, isStreaming ?? this.isStreaming ?? false);
		return original.call(this, message, isStreaming);
	};
	return () => {
		proto.updateContent = original;
		delete proto[PATCHED];
	};
}

// Patch as early as possible: the transcript of a resumed session is rendered
// once extensions have loaded, and nothing should render unlabelled first.
// The undo function is discarded here; `installThinkingTokenLabels()` is
// idempotent, so reloading this extension replaces the wrapper rather than
// stacking another one.
installThinkingTokenLabels();

export default function (_pi: ExtensionAPI) {
	// Nothing to drive: each block derives its label from its own message via
	// the patch above, so there are no events to follow and no global label to
	// set. Keeping the factory is what makes this a loadable extension.
}
