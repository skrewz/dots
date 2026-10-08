// Tests for the thinking-token labels in ../extensions/thinking-tokens.ts.
// Run via:  make -C ~/.pi/agent/extensions-tests test
//
// These drive pi's real AssistantMessageComponent, so they fail if pi's internal
// thinking renderer changes shape. That is the trade-off the extension makes:
// pi's public API only offers one global hidden-thinking label.
import { AssistantMessageComponent, initTheme } from "@earendil-works/pi-coding-agent";
import { installThinkingTokenLabels, spinnerFrame, thinkingLabelFor } from "../extensions/thinking-tokens";

// The component themes its label, so the theme module needs a theme to render at all.
initTheme();

let passed = 0;
let failed = 0;

function check(name: string, ok: boolean, detail?: unknown): void {
	if (ok) {
		passed++;
	} else {
		failed++;
		console.error(`FAIL ${name}${detail === undefined ? "" : `: ${JSON.stringify(detail)}`}`);
	}
}

/** Strip ANSI and the spinner glyph so rendered lines can be matched on text. */
function plain(text: string): string {
	return text
		// eslint-disable-next-line no-control-regex
		.replace(/\x1b\[[0-9;]*m|\x1b\]8;;[^\x07\x1b]*(?:\x07|\x1b\\)/g, "")
		.replace(/[\u2800-\u28FF]/g, "");
}

/** True if the rendered text contains a braille spinner glyph. */
function spinning(text: string): boolean {
	return /[\u2800-\u28FF]/.test(text);
}

function rendered(component: InstanceType<typeof AssistantMessageComponent>): string {
	return plain(component.render(80).join("\n"));
}

/** Rendered text with ANSI stripped but the spinner glyph intact. */
function coloured(component: InstanceType<typeof AssistantMessageComponent>): string {
	return component
		.render(80)
		.join("\n")
		// eslint-disable-next-line no-control-regex
		.replace(/\x1b\[[0-9;]*m|\x1b\]8;;[^\x07\x1b]*(?:\x07|\x1b\\)/g, "");
}

function assistantMessage(thinkingChars: number, reasoning?: number) {
	return {
		role: "assistant" as const,
		content: [{ type: "thinking" as const, thinking: "a".repeat(Math.max(thinkingChars, 1)) }],
		stopReason: "stop" as const,
		usage: {
			input: 10,
			output: 20,
			cacheRead: 0,
			cacheWrite: 0,
			totalTokens: 30,
			cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
			...(reasoning === undefined ? {} : { reasoning }),
		},
	};
}

// --- label text (pure) ---

check(
	"uses the provider's reasoning count when reported",
	thinkingLabelFor(assistantMessage(10, 1234)).includes("1234 reasoning tokens"),
	thinkingLabelFor(assistantMessage(10, 1234)),
);

check(
	"estimates from thinking text when no count is reported",
	thinkingLabelFor(assistantMessage(80)).includes("20 reasoning tokens"),
	thinkingLabelFor(assistantMessage(80)),
);

check(
	"says just 'Thought' when there is nothing to count",
	thinkingLabelFor(assistantMessage(0)) === "Thought",
	thinkingLabelFor(assistantMessage(0)),
);

check(
	"keeps a custom base wording",
	thinkingLabelFor(assistantMessage(10, 42), "Pondering...") === "Pondering... (42 reasoning tokens)",
	thinkingLabelFor(assistantMessage(10, 42), "Pondering..."),
);

// Wording follows the block's state: a spinner and the present tense while
// streaming, past tense once the message is over (pi passes isStreaming=false
// at message_end).
check(
	"spins in the present while streaming",
	thinkingLabelFor(assistantMessage(10, 1234), undefined, true, "⠹") === "⠹ Thinking... (1234 reasoning tokens)",
	thinkingLabelFor(assistantMessage(10, 1234), undefined, true, "⠹"),
);
check(
	"reads in the past tense once over",
	thinkingLabelFor(assistantMessage(10, 1234)) === "Thought (1234 reasoning tokens)",
	thinkingLabelFor(assistantMessage(10, 1234)),
);
check(
	"big counts are written out, never abbreviated",
	thinkingLabelFor(assistantMessage(10, 14_000)) === "Thought (14000 reasoning tokens)",
	thinkingLabelFor(assistantMessage(10, 14_000)),
);
check(
	"spins before there is anything to count",
	thinkingLabelFor(assistantMessage(0), undefined, true, "⠹") === "⠹ Thinking...",
	thinkingLabelFor(assistantMessage(0), undefined, true, "⠹"),
);

// The frame comes from the clock, so it advances on pi's own render ticks and
// never needs a timer of its own.
check("the spinner holds for one 80ms tick", spinnerFrame(0) === spinnerFrame(79), { a: spinnerFrame(0), b: spinnerFrame(79) });
check("the spinner turns on the next tick", spinnerFrame(0) !== spinnerFrame(80), spinnerFrame(0));
check("the spinner wraps round", spinnerFrame(0) === spinnerFrame(80 * 10), spinnerFrame(0));

// Deriving a label from a label must neither stack counts nor stack spinners:
// that is what happens on every re-render and whenever pi writes its global
// label across the transcript. Small and large counts are both covered.
for (const [name, message] of [
	["plain count", assistantMessage(10, 42)],
	["large count", assistantMessage(10, 1810)],
	["estimate", assistantMessage(400)],
] as const) {
	for (const streaming of [false, true]) {
		const once = thinkingLabelFor(message, undefined, streaming, "⠹");
		const again = thinkingLabelFor(message, once, streaming, "⠹");
		check(`re-deriving a ${name} ${streaming ? "streaming" : "final"} label is stable`, again === once, { once, again });
	}
}

// --- component rendering (patches pi's renderer) ---

const restore = installThinkingTokenLabels();

const streamed = new AssistantMessageComponent(undefined, true);
const historic = new AssistantMessageComponent(undefined, true);

// A partial message: estimate from the thinking text streamed so far.
streamed.updateContent(assistantMessage(400) as never, true);
check("streaming block shows a live estimate", rendered(streamed).includes("Thinking... (100 reasoning tokens)"), rendered(streamed));
check("streaming block shows a spinner", spinning(coloured(streamed)), coloured(streamed));

// A second, older message keeps its own number — the reported bug was that
// writing the global label renumbered every block in the transcript.
historic.updateContent(assistantMessage(120, 42) as never, false);
check("older block shows its own count", rendered(historic).includes("Thought (42 reasoning tokens)"), rendered(historic));
check("older block is not double labelled", !/reasoning tokens.*reasoning tokens/.test(rendered(historic)), rendered(historic));

// Simulate pi's global setHiddenThinkingLabel() fan-out across the transcript.
// The string is deliberately one this extension no longer writes (abbreviated),
// to prove the suffix is recognised either way rather than doubled up.
for (const component of [streamed, historic]) {
	component.setHiddenThinkingLabel("Thinking... 9.9k reasoning tokens");
}
check("global label write leaves the older block at its own count", rendered(historic).includes("Thought (42 reasoning tokens)"), rendered(historic));
check("global label write leaves the current block at its own count", rendered(streamed).includes("Thinking... (100 reasoning tokens)"), rendered(streamed));

// Finalised message: the provider's count wins.
streamed.updateContent(assistantMessage(400, 1810) as never, false);
check("finalised block shows the reported count", rendered(streamed).includes("Thought (1810 reasoning tokens)"), rendered(streamed));
check("older block is still untouched", rendered(historic).includes("Thought (42 reasoning tokens)"), rendered(historic));
check("no block accumulated a second label", !/reasoning tokens.*reasoning tokens/.test(rendered(streamed) + rendered(historic)), rendered(streamed));

// A custom wording set by another extension survives, in either state.
for (const component of [streamed, historic]) {
	component.setHiddenThinkingLabel("Pondering...");
}
check("custom wording is kept", rendered(historic).includes("Pondering... (42 reasoning tokens)"), rendered(historic));

// --- the end of a block is detectable ---
// pi passes isStreaming=false at message_end, and the component remembers it
// for the re-renders that omit the argument: invalidate(), and Ctrl+T's
// setHideThinkingBlock(). Historical messages are constructed not streaming.

const settled = new AssistantMessageComponent(undefined, true);
settled.updateContent(assistantMessage(400, 1810) as never, false);
check("finished block reads in the past tense", rendered(settled).includes("Thought (1810 reasoning tokens)"), rendered(settled));
check("finished block stops spinning", !spinning(coloured(settled)), coloured(settled));
settled.invalidate();
check("a later re-render keeps the past tense", rendered(settled).includes("Thought (1810 reasoning tokens)"), rendered(settled));
settled.setHiddenThinkingLabel("Thinking... 9.9k reasoning tokens");
check("a global label write does not unset the past tense", rendered(settled).includes("Thought (1810 reasoning tokens)"), rendered(settled));

const live = new AssistantMessageComponent(undefined, true);
live.updateContent(assistantMessage(400) as never, true);
live.invalidate();
check("invalidate() while streaming stays in the present tense", rendered(live).includes("Thinking... (100 reasoning tokens)"), rendered(live));
check("invalidate() while streaming keeps spinning", spinning(coloured(live)), coloured(live));

const resumed = new AssistantMessageComponent(assistantMessage(400, 1810) as never, true);
check("a resumed session's block reads in the past tense", rendered(resumed).includes("Thought (1810 reasoning tokens)"), rendered(resumed));

// --- install() is idempotent, so reloading the extension cannot stack ---

const undoSecondInstall = installThinkingTokenLabels();
const reloaded = new AssistantMessageComponent(undefined, true);
reloaded.updateContent(assistantMessage(400, 1810) as never, false);
check("installing twice still renders one count", rendered(reloaded).includes("Thought (1810 reasoning tokens)"), rendered(reloaded));
check("no block accumulated a second label after reinstall", !/reasoning tokens.*reasoning tokens/.test(rendered(reloaded)), rendered(reloaded));
undoSecondInstall();

// --- restore() puts pi back the way it was ---

restore();
const after = new AssistantMessageComponent(assistantMessage(400, 1810) as never, true);
check("restore() removes the counts", !rendered(after).includes("reasoning tokens"), rendered(after));

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
