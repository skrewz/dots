// End-to-end smoke test for the renderer patch in
// ../extensions/thinking-tokens.ts, under the runtime pi actually ships.
// Run via:  make -C ~/.pi/agent/extensions-tests test
//
// The unit test proves the patch does the right thing to a component. This one
// proves it reaches the components pi renders: pi runs from dist/bundle, and
// extensions there resolve `@earendil-works/pi-coding-agent` through the
// bundle's own module graph (dist/core/extensions/virtual-modules.ts), so the
// class the extension patches must be the class interactive mode instantiates.
// If those ever diverge — a source checkout, a bundler change — the extension
// would silently do nothing, which is what this catches.
import { existsSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

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

// The package only exposes ESM entry points, so resolve it as a module specifier.
const entryPath = fileURLToPath(import.meta.resolve("@earendil-works/pi-coding-agent"));
const packageDir = dirname(dirname(entryPath));
const bundleIndex = join(packageDir, "dist", "bundle", "index.js");
const chunksDir = join(packageDir, "dist", "bundle", "chunks");

if (!existsSync(bundleIndex) || !existsSync(chunksDir)) {
	console.log("Bundled runtime not installed (source checkout?); skipping smoke test");
	process.exit(0);
}

// Sanity: the bundle must be able to hand extensions its own modules.
const virtualModulesFile = readdirSync(chunksDir).find((file) => file.startsWith("virtual-modules-"));
check("bundle exposes its virtual modules", virtualModulesFile !== undefined, chunksDir);
if (!virtualModulesFile) {
	console.log(`\n${passed} passed, ${failed} failed`);
	process.exit(1);
}
const { VIRTUAL_MODULES } = (await import(pathToFileURL(join(chunksDir, virtualModulesFile)).href)) as {
	VIRTUAL_MODULES: Record<string, unknown>;
};
check(
	"pi-coding-agent resolves to the bundle the extension will import",
	Object.keys(VIRTUAL_MODULES).includes("@earendil-works/pi-coding-agent"),
);

// Load the extension the way bundled pi does: jiti with pi's own virtual modules.
const { createJiti } = await import(pathToFileURL(join(packageDir, "dist", "core", "extensions", "jiti-loader.js")).href);
const jiti = createJiti(pathToFileURL(bundleIndex).href, {
	moduleCache: false,
	virtualModules: VIRTUAL_MODULES,
	tryNative: false,
});
const extensionPath = join(dirname(dirname(fileURLToPath(import.meta.url))), "extensions", "thinking-tokens.ts");
const factory = await jiti.import(extensionPath, { default: true });
check("extension loads under the bundled resolver", typeof factory === "function", typeof factory);

// Running the factory is what installs the patch (it is a load-time patch).
factory({ on: () => () => {}, registerCommand() {}, registerFlag() {}, registerShortcut() {}, registerTool() {} });

// Now look at the component graph pi itself uses: the bundle's own exports.
const pi = (await import(pathToFileURL(bundleIndex).href)) as {
	initTheme(): void;
	AssistantMessageComponent: new (message: unknown, hideThinkingBlock?: boolean) => {
		render(width: number): string[];
	};
};
pi.initTheme();

const message = {
	role: "assistant",
	content: [{ type: "thinking", thinking: "a".repeat(400) }],
	stopReason: "stop",
	usage: { reasoning: 1810 },
};
const rendered = new pi.AssistantMessageComponent(message, true)
	.render(80)
	.join("\n")
	// eslint-disable-next-line no-control-regex
	.replace(/\x1b\[[0-9;]*m/g, "");
check("pi's own assistant component renders the count in the past tense", rendered.includes("Thought (1810 reasoning tokens)"), rendered);

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
