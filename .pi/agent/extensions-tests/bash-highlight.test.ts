// Tests for the tool-renderer resolver in ../extensions/bash-highlight/index.ts.
// Run via:  make -C ~/.pi/agent/extensions-tests test
//
// The extension registers one *global* renderer resolver. pi composes resolvers so that whatever a
// resolver returns is the final answer for that tool — a resolver that returns `undefined` has not
// passed, it has said "this tool has no renderers", and the call falls back to pi's generic,
// unformatted rendering. Only `next()` continues the chain (see `resolveToolRenderers` in
// pi's dist/core/extensions/runner.js and "Tool rendering" in docs/extensions.md).
//
// So the property these tests guard is narrow but expensive to lose: bash-highlight stays out of the
// way of every tool it does not own. Getting it wrong is silent — the transcript just renders `edit`,
// `read`, `write` and friends plainly.
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { createEventBus, initTheme } from "@earendil-works/pi-coding-agent";
import type { Theme, ToolRenderers } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { createShellRendererResolver } from "../extensions/bash-highlight/index.ts";

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

/** A theme that paints nothing, so assertions match on text rather than escape sequences. */
const plainTheme = {
	fg: (_token: string, text: string) => text,
	bold: (text: string) => text,
} as unknown as Theme;

/** Stand-in for pi's built-in renderers. Identity is what most assertions turn on. */
function makeBase(options: { renderCall?: boolean } = {}): ToolRenderers & { calls: number } {
	const base: ToolRenderers & { calls: number } = {
		calls: 0,
		renderCall: () => {
			base.calls++;
			return new Text("built-in call line", 0, 0);
		},
		renderResult: () => new Text("built-in result line", 0, 0),
	};
	if (options.renderCall === false) delete (base as ToolRenderers).renderCall;
	return base;
}

const renderCall = (renderers: ToolRenderers | undefined, args: unknown, argsComplete = true): string => {
	const component = renderers?.renderCall?.(args as never, plainTheme, { argsComplete, invalidate: () => {} } as never);
	return (component as InstanceType<typeof Text> | undefined)?.render(200).join("\n") ?? "";
};

// --- every tool that is not bash goes back out of next(), untouched ------------------------------

const TOOLS_WE_DO_NOT_OWN = ["edit", "read", "write", "find", "grep", "ls", "powershell", "mcp__jira__search"];

for (const toolName of TOOLS_WE_DO_NOT_OWN) {
	const base = makeBase();
	let nextCalls = 0;
	const result = createShellRendererResolver()(toolName, () => {
		nextCalls++;
		return base;
	});
	check(`${toolName}: keeps the renderers it was handed`, result === base, result);
	check(`${toolName}: asks next() for them rather than opting out`, nextCalls === 1, nextCalls);
}

// Opting out is what the bug looked like. If a resolver returns undefined for a tool it does not
// own, pi has nothing left to draw the call with.
const absent = createShellRendererResolver()("edit", () => undefined);
check("edit with nothing behind it stays unresolved, not fabricated", absent === undefined, absent);

// A base without renderCall (another extension already owns the call) is returned as it stands:
// dropping it would take its renderResult with it.
const resultOnly = makeBase({ renderCall: false });
check("a base with only renderResult is returned unchanged", createShellRendererResolver()("edit", () => resultOnly) === resultOnly);
check("bash with only renderResult is returned unchanged too", createShellRendererResolver()("bash", () => resultOnly) === resultOnly);

// --- bash is still wrapped ----------------------------------------------------------------------

const highlight = (command: string) => `HL:${command}`;
const bashBase = makeBase();
const wrapped = createShellRendererResolver(highlight)("bash", () => bashBase);
check("bash: gets its own renderers", wrapped !== undefined && wrapped !== bashBase, wrapped);
check("bash: keeps the built-in renderResult", wrapped?.renderResult === bashBase.renderResult);
check("bash: renders through the built-in call renderer", (() => { void renderCall(wrapped, { command: "ls -la" }); return bashBase.calls === 1; })());
check(
	"bash: colours the command once the arguments are complete",
	renderCall(wrapped, { command: "ls -la" }).includes("HL:ls -la"),
	renderCall(wrapped, { command: "ls -la" }),
);
check(
	"bash: stays plain while the arguments stream in",
	!renderCall(wrapped, { command: "ls -l", timeout: 5 }, false).includes("HL:"),
	renderCall(wrapped, { command: "ls -l", timeout: 5 }, false),
);
check("bash: still shows the timeout note", renderCall(wrapped, { command: "sleep 1", timeout: 30 }).includes("(timeout 30s)"));

// --- through pi's own composition ---------------------------------------------------------------

// The unit checks above encode the contract by hand. This one asks pi's real resolver chain what
// `edit` would render with, which is the thing that actually regressed.
const entryPath = fileURLToPath(import.meta.resolve("@earendil-works/pi-coding-agent"));
const packageDir = dirname(dirname(entryPath));
const loaderPath = join(packageDir, "dist", "core", "extensions", "loader.js");
const runnerPath = join(packageDir, "dist", "core", "extensions", "runner.js");
const renderersPath = join(packageDir, "dist", "core", "tools", "renderers", "index.js");

if (!existsSync(loaderPath) || !existsSync(runnerPath)) {
	console.log("pi internals not installed the expected way; skipping composition checks");
} else {
	const { createExtensionRuntime, loadExtensionFromFactory } = (await import(pathToFileURL(loaderPath).href)) as {
		createExtensionRuntime: () => never;
		loadExtensionFromFactory: (factory: (pi: { registerToolRenderer: (r: unknown) => void }) => void, cwd: string, eventBus: unknown, runtime: unknown) => Promise<object>;
	};
	const { ExtensionRunner } = (await import(pathToFileURL(runnerPath).href)) as {
		ExtensionRunner: new (extensions: unknown[], runtime: unknown, cwd: string) => {
			resolveToolRenderers: (toolName: string, base: () => ToolRenderers | undefined) => ToolRenderers | undefined;
		};
	};

	const resolver = createShellRendererResolver(highlight);
	const extension = await loadExtensionFromFactory(
		(pi) => pi.registerToolRenderer(resolver),
		process.cwd(),
		createEventBus(),
		createExtensionRuntime(),
	);
	const runner = new ExtensionRunner([extension], createExtensionRuntime(), process.cwd());

	const builtIn = makeBase();
	const editRenderers = runner.resolveToolRenderers("edit", () => builtIn);
	check("pi resolves edit to the built-in renderers, not to nothing", editRenderers === builtIn, editRenderers);
	check(
		"pi renders an edit call through the built-in renderer",
		renderCall(editRenderers, { path: "a.ts" }).trim() === "built-in call line",
		renderCall(editRenderers, { path: "a.ts" }),
	);

	const bashRenderers = runner.resolveToolRenderers("bash", () => makeBase());
	check("pi resolves bash through the highlighter", renderCall(bashRenderers, { command: "ls -la" }).includes("HL:ls -la"), renderCall(bashRenderers, { command: "ls -la" }));

	// With pi's actual built-in renderers at the end of the chain, rather than a stand-in: the
	// renderer pi would have used for `edit` is still the one it gets.
	if (existsSync(renderersPath)) {
		const { editRenderers } = (await import(pathToFileURL(renderersPath).href)) as { editRenderers: ToolRenderers };
		check(
			"pi's own edit renderer survives the chain",
			runner.resolveToolRenderers("edit", () => editRenderers)?.renderCall === editRenderers.renderCall,
		);
	}
}

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
