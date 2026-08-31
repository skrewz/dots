/**
 * command-gate — gate bash commands that invoke blocked commands.
 *
 * Mirrors the OpenCode bash permission policy
 *
 *   "ssh *": "deny",
 *   "s-agentic-wrap-command *": "allow",
 *
 * but is stricter: it blocks `ssh` wherever it is invoked *as a command*,
 * including inside compound commands, subshells, command substitutions and
 * `sh -c "..."` strings — not just a naive `ssh ...` prefix match.
 *
 * The sanctioned path for any remote command is the root-owned,
 * self-ownership-checking `s-agentic-wrap-command` wrapper, which carries its
 * own allowlist of safe remote commands. That wrapper is *not* blocked, because
 * in `s-agentic-wrap-command ssh host "..."` the word `ssh` is an *argument*,
 * not a command.
 *
 * Only the built-in `bash` tool is inspected. The detection logic is a set of
 * pure functions (`collectCommandCandidates`, `findBlockedCommand`) exported
 * for unit-testing in isolation.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

/**
 * Command names that must not be invoked directly from the bash tool. They
 * must go through the `s-agentic-wrap-command` wrapper instead. Extend this
 * list to gate additional commands (e.g. `scp`, `sftp`).
 */
const BLOCKED_COMMANDS: ReadonlySet<string> = new Set(["ssh"]);

/** Shell interpreters whose `-c` argument is itself a command line. */
const SHELLS: ReadonlySet<string> = new Set([
	"bash", "sh", "zsh", "ksh", "dash", "busybox",
]);

/**
 * Transparent prefix commands: the *real* command follows the prefix (and its
 * flags), so command position is preserved across the prefix word itself.
 */
const PREFIX_COMMANDS: ReadonlySet<string> = new Set([
	"env", "nohup", "time", "nice", "command", "builtin", "exec",
	"stdbuf", "ionice", "unbuffer", "timeout", "xargs", "sudo",
]);

/** Shell keywords after which the next word is a command. */
const COMMAND_KEYWORDS: ReadonlySet<string> = new Set([
	"then", "do", "else", "elif", "fi", "done",
]);

/** Operators / separators after which the next word is a command. */
const OPERATORS: ReadonlySet<string> = new Set([
	";", "&", "&&", "||", "|", "(", ")", "{", "}",
]);

const isEnvAssignment = (v: string): boolean =>
	/^[A-Za-z_][A-Za-z0-9_]*=/.test(v);

/**
 * Collect every word that sits at a *command position* in `line`, recursing
 * into command substitutions (`$(...)`, backticks) and `shell -c "..."`
 * strings. Words that are merely arguments (or substrings of arguments/paths)
 * are not collected.
 */
export function collectCommandCandidates(line: string): string[] {
	const out: string[] = [];
	scanLine(line, out);
	return out;
}

/**
 * Return the name of a blocked command that `command` invokes (matched by
 * basename, so `/usr/bin/ssh` also matches `ssh`), or `null` if it invokes
 * none of them.
 */
export function findBlockedCommand(
	command: string,
	blocked: ReadonlySet<string> = BLOCKED_COMMANDS,
): string | null {
	for (const candidate of collectCommandCandidates(command)) {
		const base = candidate.split("/").pop() ?? candidate;
		if (blocked.has(base)) return base;
	}
	return null;
}

/** Convenience boolean wrapper around {@link findBlockedCommand}. */
export function invokesBlockedCommand(
	command: string,
	blocked: ReadonlySet<string> = BLOCKED_COMMANDS,
): boolean {
	return findBlockedCommand(command, blocked) !== null;
}

/**
 * Quote-aware single-pass scanner. Walks `line`, tracking command position,
 * and pushes every command-position word onto `out`. Recurses into command
 * substitutions and `shell -c` strings so nested invocations are caught.
 */
function scanLine(line: string, out: string[]): void {
	let i = 0;
	let atCommandPosition = true;
	let inSingle = false;
	let inDouble = false;
	let token = "";
	let pendingShell = false;
	let pendingDashC = false;

	const flush = (): void => {
		const value = token;
		token = "";
		if (value === "") return;

		if (OPERATORS.has(value) || COMMAND_KEYWORDS.has(value)) {
			atCommandPosition = true;
			pendingShell = false;
			pendingDashC = false;
			return;
		}
		if (value === "in") {
			// Word list follows (e.g. `for x in a b`), not a command.
			atCommandPosition = false;
			pendingShell = false;
			pendingDashC = false;
			return;
		}
		if (pendingDashC) {
			// The `-c` string is itself a command line.
			pendingDashC = false;
			pendingShell = false;
			scanLine(value, out);
			atCommandPosition = false;
			return;
		}
		if (atCommandPosition) {
			if (isEnvAssignment(value)) return; // not the command; command follows
			if (PREFIX_COMMANDS.has(value)) return; // real command follows
			if (SHELLS.has(value)) {
				out.push(value);
				pendingShell = true;
				atCommandPosition = false;
				return;
			}
			out.push(value);
			atCommandPosition = false;
			pendingShell = false;
			return;
		}
		// Argument position.
		if (pendingShell) {
			if (value === "-c" || /^-[A-Za-z]*c$/.test(value)) {
				pendingDashC = true;
				return;
			}
			if (value.startsWith("-")) {
				return; // another flag; keep looking for -c
			}
			pendingShell = false;
		}
	};

	// Read a balanced "(...)" starting at the opening paren (index `start`).
	// Returns the inner body and the index just past the closing paren.
	const readBalancedParens = (start: number): { body: string; end: number } => {
		let depth = 0;
		let j = start;
		let s = false;
		let d = false;
		for (; j < line.length; j++) {
			const c = line[j];
			if (s) {
				if (c === "'") s = false;
				continue;
			}
			if (d) {
				if (c === "\\") {
					j++;
					continue;
				}
				if (c === '"') d = false;
				continue;
			}
			if (c === "'") {
				s = true;
				continue;
			}
			if (c === '"') {
				d = true;
				continue;
			}
			if (c === "(") depth++;
			else if (c === ")") {
				depth--;
				if (depth === 0) break;
			}
		}
		return { body: line.slice(start + 1, j), end: j + 1 };
	};

	while (i < line.length) {
		const c = line[i];

		if (inSingle) {
			if (c === "'") {
				inSingle = false;
				i++;
				continue;
			}
			token += c;
			i++;
			continue;
		}

		if (inDouble) {
			if (c === "\\") {
				token += i + 1 < line.length ? line[i + 1] : "";
				i += 2;
				continue;
			}
			if (c === '"') {
				inDouble = false;
				i++;
				continue;
			}
			if (c === "$" && line[i + 1] === "(") {
				const { body, end } = readBalancedParens(i + 1);
				scanLine(body, out);
				token += "$"; // keep the token non-empty
				i = end;
				continue;
			}
			if (c === "`") {
				const close = line.indexOf("`", i + 1);
				const end = close === -1 ? line.length : close;
				scanLine(line.slice(i + 1, end), out);
				token += "`";
				i = end + 1;
				continue;
			}
			token += c;
			i++;
			continue;
		}

		// Unquoted.
		if (c === "'") {
			inSingle = true;
			i++;
			continue;
		}
		if (c === '"') {
			inDouble = true;
			i++;
			continue;
		}
		if (c === "\\") {
			token += i + 1 < line.length ? line[i + 1] : "";
			i += 2;
			continue;
		}
		if (c === "$" && line[i + 1] === "(") {
			const { body, end } = readBalancedParens(i + 1);
			scanLine(body, out);
			flush();
			i = end;
			continue;
		}
		if (c === "`") {
			const close = line.indexOf("`", i + 1);
			const end = close === -1 ? line.length : close;
			scanLine(line.slice(i + 1, end), out);
			flush();
			i = end + 1;
			continue;
		}
		if (
			c === ";" || c === "|" || c === "&" ||
			c === "(" || c === ")" || c === "{" || c === "}"
		) {
			flush();
			if ((c === "|" || c === "&") && line[i + 1] === c) {
				token = c + c;
				i += 2;
			} else {
				token = c;
				i += 1;
			}
			flush();
			continue;
		}
		if (c === " " || c === "\t") {
			flush();
			i++;
			continue;
		}
		if (c === "\n") {
			flush();
			atCommandPosition = true; // newline separates commands
			i++;
			continue;
		}
		token += c;
		i++;
	}
	flush();
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event) => {
		if (!isToolCallEventType("bash", event)) return undefined;

		const command = event.input.command;
		if (typeof command !== "string" || command === "") return undefined;

		const blocked = findBlockedCommand(command);
		if (blocked === null) return undefined;

		const reason =
			`Blocked: this command invokes "${blocked}" directly. Direct ${blocked} is ` +
			`not permitted from the bash tool — it must go through the ` +
			`s-agentic-wrap-command wrapper, which carries the allowlist of permitted ` +
			`remote commands. Re-run it as:\n` +
			`    s-agentic-wrap-command ${blocked} <host> "<remote command>"\n` +
			`Use "s-agentic-wrap-command --list-examples" to see what is allowed, or ` +
			`"s-agentic-wrap-command --help" for usage. If the remote command is not on ` +
			`the allowlist, do not attempt it.`;

		return { block: true, reason };
	});
}
