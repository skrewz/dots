/**
 * Anti-loop extension — prevents the model from getting stuck in either a
 * tool-call loop or an "endless thinking" loop where it repeats the same
 * analysis paragraphs without taking any action.
 *
 * Tool-call loop detection:
 *   - If the exact same tool call (tool name + serialised arguments) appears
 *     3 or more times in the last 10 tool calls, the tool is blocked and
 *     a warning message is shown explaining the repetition.
 *   - If the same tool call appears 6 or more times in the last 10 tool
 *     calls, the tool is blocked with a stern "loop detected" message.
 *
 * Text loop detection (endless thinking):
 *   - Tracks paragraph hashes in a sliding window during streaming.
 *   - If the same paragraph hash appears 3+ times in the last 20 paragraphs,
 *     a steering message is injected to redirect the model.
 *   - If 6+ occurrences are detected, a stern "loop detected" message is used.
 *   - Detection resets at each turn boundary to avoid cross-turn false positives.
 *
 * In both cases the intervention is communicated to the model so it understands
 * why and can try a different approach.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// --- Tool-call loop detection ---
const TOOL_WINDOW_SIZE = 10;
const TOOL_WARNING_THRESHOLD = 3;  // warn on 3rd+ occurrence in window
const TOOL_LOOP_THRESHOLD = 6;     // stern warning on 6th+ occurrence in window

// --- Text loop detection ---
const TEXT_WINDOW_SIZE = 20;
const TEXT_WARNING_THRESHOLD = 3;  // warn on 3rd+ occurrence in window
const TEXT_LOOP_THRESHOLD = 6;     // stern warning on 6th+ occurrence in window

function hashArgs(input: Record<string, unknown>): string {
	// Deterministic serialisation of arguments for comparison.
	// Only stringify known fields — ignore internal tool metadata.
	const keys = Object.keys(input).sort();
	return keys.map(k => `${k}:${JSON.stringify(input[k])}`).join("|");
}

function hashText(text: string): string {
	// Simple hash for paragraph comparison.
	// Uses a basic djb2 variant for speed and determinism.
	let h = 5381;
	for (let i = 0; i < text.length; i++) {
		h = ((h << 5) + h + text.charCodeAt(i)) | 0;
	}
	return h.toString(16);
}

export default function (pi: ExtensionAPI) {
	/** Sliding window of { toolName, argsHash } for the current turn. */
	const toolWindow: Array<{ toolName: string; argsHash: string }> = [];

	/** Sliding window of paragraph hashes for the current turn. */
	const textWindow: string[] = [];

	/** Whether a steering message has already been sent this turn. */
	let textInterventionSent = false;

	/** Reset text window on new turn to avoid cross-turn false positives. */
	pi.on("turn_start", async () => {
		textWindow.length = 0;
		textInterventionSent = false;
	});

	/** Track tool calls for repetition. */
	pi.on("tool_call", async (event) => {
		// Only track built-in tools — custom tools may have their own guards.
		const toolName = event.toolName;

		const argsHash = hashArgs(event.input);
		const entry = { toolName, argsHash };

		// Always add to the sliding window so blocked retries are also tracked.
		toolWindow.push(entry);
		while (toolWindow.length > TOOL_WINDOW_SIZE) {
			toolWindow.shift();
		}

		// Re-count after adding (now includes this attempt).
		const totalCount = toolWindow.filter(
			(w) => w.toolName === entry.toolName && w.argsHash === entry.argsHash,
		).length;

		if (totalCount >= TOOL_LOOP_THRESHOLD) {
			// Block — model is clearly in a loop.
			const reason = `Loop detected: the same tool call (${toolName}) has been made ${totalCount} times in the last ${TOOL_WINDOW_SIZE} tool calls. Repeating tool calls is strictly disallowed — but do not give up. Change your approach, try a different tool, or provide a text response instead.`;
			return { block: true, reason };
		}

		if (totalCount >= TOOL_WARNING_THRESHOLD) {
			// Block — repeated attempts are unlikely to succeed.
			const reason = `Warning: the same tool call (${toolName}) has been made ${totalCount} times recently. Repeating the same tool call is unlikely to produce a different result — but do not give up. Try a different approach, modify your arguments, or respond with text instead.`;
			return { block: true, reason };
		}

		return undefined;
	});

	/** Track text output for repetition (endless thinking detection). */
	pi.on("message_update", async (event) => {
		// Only track assistant messages.
		if (event.message.role !== "assistant") return;

		// Extract text content from the message.
		const content = event.message.content;
		if (!Array.isArray(content)) return;

		let accumulatedText = "";
		for (const part of content) {
			if (part.type === "text") {
				accumulatedText += part.text;
			}
		}

		// Split into paragraphs by double-newline.
		const paragraphs = accumulatedText.split("\n\n").map(p => p.trim()).filter(p => p.length > 0);

		// Hash each paragraph.
		const hashes = paragraphs.map(hashText);

		// Update the sliding window with new hashes.
		// Only add hashes that aren't already in the window (new paragraphs).
		const newHashes = hashes.slice(textWindow.length);
		textWindow.push(...newHashes);

		// Trim window to maximum size.
		while (textWindow.length > TEXT_WINDOW_SIZE) {
			textWindow.shift();
		}

		// Count occurrences of each hash in the window.
		const hashCounts = new Map<string, number>();
		for (const hash of textWindow) {
			hashCounts.set(hash, (hashCounts.get(hash) ?? 0) + 1);
		}

		// Find the most-repeated hash.
		let maxCount = 0;
		for (const count of hashCounts.values()) {
			if (count > maxCount) maxCount = count;
		}

		// Only intervene once per turn to avoid spam.
		if (textInterventionSent) return;

		if (maxCount >= TEXT_LOOP_THRESHOLD) {
			// Stern intervention — model is clearly in a loop.
			textInterventionSent = true;
			const ts = Date.now().toString(36);
			pi.sendMessage({
				customType: "anti-loop",
				content: `⚠️ Endless thinking detected (cycle ${ts}). You appear to be repeating the same analysis paragraphs without taking action. Please either:
1. Call a tool to investigate further
2. Provide a concrete solution or answer
3. Take a different approach entirely

Repeating the same reasoning is not productive — take action or give a definitive answer.`,
				display: false,
			}, { triggerTurn: false, deliverAs: "steer" });
		} else if (maxCount >= TEXT_WARNING_THRESHOLD) {
			// Gentle warning — might be early signs of looping.
			textInterventionSent = true;
			const ts = Date.now().toString(36);
			pi.sendMessage({
				customType: "anti-loop",
				content: `⚠️ You appear to be repeating similar analysis (cycle ${ts}). Consider taking a different approach or calling a tool to investigate further rather than re-analysing the same points.`,
				display: false,
			}, { triggerTurn: false, deliverAs: "steer" });
		}
	});
}
