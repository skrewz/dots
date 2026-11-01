/**
 * The command line of a bash tool call: prompt, command, timeout note.
 *
 * Highlighting is injected, so this module has no opinion about how the command was parsed and can be
 * exercised with no parser at all. Text is never rewritten — with the escape sequences stripped the
 * result is exactly the command the tool will run.
 */

import type { Theme } from "@earendil-works/pi-coding-agent";
import { TOKEN_THEME } from "./highlight.ts";

/** Matches the built-in bash renderer's prompt. */
export const PROMPT = "$";

/** Highlighting runs on the render path. Beyond this, draw the command plainly. */
export const MAX_HIGHLIGHT_CHARS = 8000;

/** Colour a command for this theme, or return null when that is not possible. */
export type HighlightCommand = (command: string, theme: Theme) => string | null;

export interface FormatOptions {
	highlight: HighlightCommand | null;
}

interface ShellArgs {
	command?: unknown;
	timeout?: unknown;
}

const CACHE_LIMIT = 256;
const cache = new Map<string, string>();

/**
 * The escape sequences the theme produces, as part of a cache key. The Theme object's identity is
 * stable across `/theme`, so a memo keyed on the command alone would outlive the palette it was built
 * with.
 */
function themeFingerprint(theme: Theme): string {
	let fingerprint = "";
	for (const token of Object.values(TOKEN_THEME)) fingerprint += theme.fg(token, "");
	return fingerprint;
}

function body(command: string, theme: Theme, options: FormatOptions): string {
	const plain = theme.fg("toolTitle", theme.bold(command));
	const highlighted = command.length > MAX_HIGHLIGHT_CHARS ? null : (options.highlight?.(command, theme) ?? null);
	// No re-indenting: the built-in renderer shows the command as it will run, and so do we.
	return highlighted ?? plain;
}

export function formatShellCall(args: ShellArgs, theme: Theme, options: FormatOptions): string {
	const suffix = typeof args.timeout === "number" ? theme.fg("muted", ` (timeout ${args.timeout}s)`) : "";
	const command = typeof args.command === "string" ? args.command : undefined;
	if (command === undefined) return theme.fg("muted", `${PROMPT} ...`) + suffix;

	const prefix = theme.fg("toolTitle", theme.bold(`${PROMPT} `));
	// The streaming pass and the final pass share one command string, so record which of them this is.
	const key = `${themeFingerprint(theme)}\u0000${options.highlight ? "highlighted" : "plain"}\u0000${command}`;
	let rendered = cache.get(key);
	if (rendered === undefined) {
		rendered = body(command, theme, options);
		if (cache.size >= CACHE_LIMIT) cache.delete(cache.keys().next().value as string);
		cache.set(key, rendered);
	}
	return prefix + rendered + suffix;
}
