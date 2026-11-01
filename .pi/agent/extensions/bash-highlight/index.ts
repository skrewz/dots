/**
 * bash-highlight — syntax-highlight the shell commands pi runs.
 *
 * Rendering only: execution, approvals and the tool contract are untouched. The command is parsed by
 * tree-sitter-bash and coloured by the rules in highlight.ts.
 *
 * Install once, then it just works:
 *   cd ~/.pi/agent/extensions/bash-highlight && npm install --omit=peer --ignore-scripts
 *
 * Try it without installing anything:
 *   pi -e ./extensions/bash-highlight
 *
 * Integration point: `pi.registerToolRenderer()` (docs/extensions.md, "Tool rendering"), which chooses
 * how calls to a tool are drawn — including tools that are not registered yet. `next()` yields the
 * renderers the rest of the stack would have used, so this wraps the built-in renderer rather than
 * re-registering the tool and stepping on other extensions' wrappers (ssh.ts, permission gates).
 */

import type { ExtensionAPI, ToolRenderContext, ToolRendererResolver } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { formatShellCall, type HighlightCommand } from "./format.ts";
import { highlightCommand, loadParser, parserReady } from "./parser.ts";

interface ShellArgs {
	command?: unknown;
	timeout?: unknown;
}

/**
 * Exported for the checks in ../../extensions-tests/bash-highlight.test.ts, which inject their own
 * parser so the renderer can be exercised without waiting on a grammar to load. Production passes
 * nothing and uses the parser module.
 */
export function createShellRendererResolver(highlight: HighlightCommand | null = null): ToolRendererResolver {
	const resolveHighlight = highlight ?? highlightCommand;
	return (toolName, next) => {
		// Handing back `undefined` from a resolver means "this tool has no renderers", not "I pass" —
		// only `next()` continues the chain. Everything that is not bash (edit, read, write, PowerShell,
		// MCP tools, …) must therefore go straight back out of `next()` with pi's own rendering intact.
		if (toolName !== "bash") return next();
		const base = next();
		if (!base?.renderCall) return base; // Nothing to wrap: another renderer owns this call.
		const baseRenderCall = base.renderCall;
		return {
			...base,
			renderCall: (args, theme, context) => {
				// The base renderer first: it starts the timer the built-in renderResult reads for the
				// duration note, and reuses this component while the arguments stream in.
				const component = baseRenderCall(args, theme, context as ToolRenderContext<any, any>);
				const command = (args as ShellArgs | undefined)?.command;
				const text = component as Partial<Text>;
				if (typeof command !== "string" || typeof text.setText !== "function") {
					return component; // The argument is not a string, or the base draws something else.
				}
				if (!parserReady()) {
					// Warm the grammar up and redraw this call when it lands. A partial command would
					// highlight as garbage, so nothing is coloured until the arguments are complete.
					loadParser(() => context.invalidate());
				}
				text.setText!(
					formatShellCall(args as ShellArgs, theme, {
						highlight: context.argsComplete ? resolveHighlight : null,
					}),
				);
				return component;
			},
		};
	};
}

export default function (pi: ExtensionAPI): void {
	pi.on("session_start", async (_event, ctx) => {
		loadParser((error) => {
			if (error && ctx.hasUI) ctx.ui.notify(error, "warning");
		});
	});
	pi.registerToolRenderer(createShellRendererResolver());
}
