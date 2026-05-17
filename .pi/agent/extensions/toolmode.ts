/**
 * Tool Mode Extension
 *
 * Simple toggle between tools-allowed and tools-disallowed (read-only) modes.
 *
 * Features:
 * - /toolmode command or Ctrl+Alt+P to toggle
 * - Read-only mode restricts bash to an allowlist of safe commands
 * - Status indicator in footer
 * - Widget showing active tools
 * - Stern system prompt reminder when in read-only mode
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Key } from "@mariozechner/pi-tui";

// Tool sets
const TOOLS_ALLOWED = ["read", "bash", "edit", "write", "grep", "find", "ls"];
const TOOLS_DISALLOWED = ["read", "grep", "find", "ls"];

// Read-only bash allowlist
const SAFE_COMMANDS = [
	/^\s*cat\b/,
	/^\s*head\b/,
	/^\s*tail\b/,
	/^\s*less\b/,
	/^\s*more\b/,
	/^\s*grep\b/,
	/^\s*find\b/,
	/^\s*ls\b/,
	/^\s*pwd\b/,
	/^\s*echo\b/,
	/^\s*printf\b/,
	/^\s*wc\b/,
	/^\s*sort\b/,
	/^\s*uniq\b/,
	/^\s*diff\b/,
	/^\s*file\b/,
	/^\s*stat\b/,
	/^\s*du\b/,
	/^\s*df\b/,
	/^\s*tree\b/,
	/^\s*which\b/,
	/^\s*whereis\b/,
	/^\s*type\b/,
	/^\s*env\b/,
	/^\s*printenv\b/,
	/^\s*uname\b/,
	/^\s*whoami\b/,
	/^\s*id\b/,
	/^\s*date\b/,
	/^\s*cal\b/,
	/^\s*uptime\b/,
	/^\s*ps\b/,
	/^\s*top\b/,
	/^\s*htop\b/,
	/^\s*free\b/,
	/^\s*git\s+(status|log|diff|show|branch|remote|config\s+--get)/i,
	/^\s*git\s+ls-/i,
	/^\s*npm\s+(list|ls|view|info|search|outdated|audit)/i,
	/^\s*yarn\s+(list|info|why|audit)/i,
	/^\s*node\s+--version/i,
	/^\s*python\s+--version/i,
	/^\s*curl\s/i,
	/^\s*wget\s+-O\s*-/i,
	/^\s*jq\b/,
	/^\s*sed\s+-n/i,
	/^\s*awk\b/,
	/^\s*rg\b/,
	/^\s*fd\b/,
	/^\s*bat\b/,
	/^\s*eza\b/,
];

function isSafeCommand(command: string): boolean {
	return SAFE_COMMANDS.some((p) => p.test(command));
}

function getToolListText(ctx: ExtensionContext, tools: string[]): string {
	return tools.map((t) => ctx.ui.theme.fg("text", t)).join(", ");
}

export default function (pi: ExtensionAPI): void {
	let toolsAllowed = false;

	function updateUI(ctx: ExtensionContext): void {
		// Footer status
		if (toolsAllowed) {
			ctx.ui.setStatus("toolmode", ctx.ui.theme.fg("success", "🔓 tools on"));
		} else {
			ctx.ui.setStatus("toolmode", ctx.ui.theme.fg("warning", "🔒 read-only"));
		}

		// Widget showing active tools
		const tools = toolsAllowed ? TOOLS_ALLOWED : TOOLS_DISALLOWED;
		const label = toolsAllowed
			? ctx.ui.theme.fg("success", "Tools: ON")
			: ctx.ui.theme.fg("warning", "Tools: OFF (read-only)");
		ctx.ui.setWidget("toolmode", [
			label,
			getToolListText(ctx, tools),
		]);
	}

	function toggle(): void {
		toolsAllowed = !toolsAllowed;
		pi.setActiveTools(toolsAllowed ? TOOLS_ALLOWED : TOOLS_DISALLOWED);
	}

	// Register command
	pi.registerCommand("toolmode", {
		description: "Toggle tools-allowed vs tools-disallowed (read-only) mode",
		handler: async (_args, ctx) => {
			toggle();
			updateUI(ctx);
			const status = toolsAllowed ? "tools allowed" : "tools disallowed (read-only)";
			ctx.ui.notify(`Switched to ${status}`, status === "tools allowed" ? "success" : "warning");
		},
	});

	// Register shortcut
	pi.registerShortcut(Key.ctrlAlt("p"), {
		description: "Toggle tool mode",
		handler: async (ctx) => {
			toggle();
			updateUI(ctx);
			const status = toolsAllowed ? "tools allowed" : "tools disallowed (read-only)";
			ctx.ui.notify(`Switched to ${status}`, status === "tools allowed" ? "success" : "warning");
		},
	});

	// Block non-allowlisted bash commands in read-only mode
	pi.on("tool_call", async (event, ctx) => {
		if (toolsAllowed || event.toolName !== "bash") return;

		const command = event.input.command as string;
		if (!isSafeCommand(command)) {
			return {
				block: true,
				reason: `Read-only mode: command blocked. Only read-only/inspection commands are allowed.\n\nAllowed: ${SAFE_COMMANDS.length} safe commands (cat, grep, find, ls, git status, etc.)\nBlocked: ${command}`,
			};
		}
	});

	// Inject mode reminder in system prompt so the model always knows which mode is active
	pi.on("before_agent_start", async () => {
		if (!toolsAllowed) {
			return {
				message: {
					customType: "toolmode-reminder",
					content: `⛔ READ-ONLY MODE ACTIVE ⛔

You are in read-only mode. File modification tools (edit, write) are disabled.
Bash is restricted to inspection commands only (cat, grep, find, ls, git status, etc.).

DO NOT attempt to modify files, run destructive commands, or bypass these restrictions.
If you need to make changes, ask the user to disable read-only mode first.`,
					display: false,
				},
			};
		}
		return {
			message: {
				customType: "toolmode-reminder",
				content: `✅ TOOLS MODE ACTIVE

All tools are enabled (read, write, edit, bash, grep, find, ls). Use them freely to complete tasks.`,
				display: false,
			},
		};
	});

	// Restore state on session start/resume
	pi.on("session_start", async (_event, ctx) => {
		updateUI(ctx);
	});
}
