/**
 * Anti-loop extension — prevents the model from getting stuck in a tool-call
 * loop by tracking recent tool calls and blocking repeated ones.
 *
 * Rules:
 *   - If the exact same tool call (tool name + serialised arguments) appears
 *     more than 2 times in the last 10 tool calls, the 3rd+ occurrence is
 *     blocked with a warning.
 *   - If the same tool call appears more than 5 times in the last 10 tool
 *     calls, the occurrence is blocked with a stern "loop detected" message
 *     that tells the model repeating tool calls is disallowed.
 *
 * The sliding window is kept in a simple array of { toolName, argsHash }
 * entries.  Every new tool_call event pushes to the window (max 10) and
 * counts duplicates before the tool executes.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const WINDOW_SIZE = 10;
const WARNING_THRESHOLD = 3;  // block on 3rd+ occurrence in window
const LOOP_THRESHOLD = 6;     // block on 6th+ occurrence in window

function hashArgs(input: Record<string, unknown>): string {
	// Deterministic serialisation of arguments for comparison.
	// Only stringify known fields — ignore internal tool metadata.
	const keys = Object.keys(input).sort();
	return keys.map(k => `${k}:${JSON.stringify(input[k])}`).join("|");
}

export default function (pi: ExtensionAPI) {
	/** Sliding window of { toolName, argsHash } for the current turn. */
	const window: Array<{ toolName: string; argsHash: string }> = [];

	pi.on("tool_call", async (event) => {
		// Only track built-in tools — custom tools may have their own guards.
		const toolName = event.toolName;

		const argsHash = hashArgs(event.input);
		const entry = { toolName, argsHash };

		// Always add to the sliding window so blocked retries are also tracked.
		window.push(entry);
		while (window.length > WINDOW_SIZE) {
			window.shift();
		}

		// Re-count after adding (now includes this attempt).
		const totalCount = window.filter(
			(w) => w.toolName === entry.toolName && w.argsHash === entry.argsHash,
		).length;

		if (totalCount >= LOOP_THRESHOLD) {
			// Stern warning — model is clearly in a loop.
			return {
				block: true,
				reason: `Loop detected: the same tool call (${toolName}) has been made ${totalCount} times in the last ${WINDOW_SIZE} tool calls. Repeating tool calls is strictly disallowed — but do not give up. Change your approach, try a different tool, or provide a text response instead.`,
			};
		}

		if (totalCount >= WARNING_THRESHOLD) {
			// Gentle warning — model may be stuck.
			return {
				block: true,
				reason: `Warning: the same tool call (${toolName}) has been made ${totalCount} times recently. Repeating the same tool call is unlikely to produce a different result — but do not give up. Try a different approach, modify your arguments, or respond with text instead.`,
			};
		}

		return undefined;
	});
}
