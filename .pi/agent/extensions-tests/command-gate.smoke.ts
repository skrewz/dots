// End-to-end smoke test: simulate pi loading the extension and firing
// tool_call events, verifying the block/pass-through wiring.
// Run via:  make -C .pi/agent/extensions-tests test
import extFactory from "../extensions/command-gate";

let passed = 0;
let failed = 0;

// Capture registered handlers from a mock ExtensionAPI.
const handlers: Record<string, Function> = {};
const mockPi = {
	on(event: string, handler: Function) {
		handlers[event] = handler;
	},
	registerTool() {},
	registerCommand() {},
};

extFactory(mockPi);

if (typeof handlers["tool_call"] !== "function") {
	console.error("FAIL: no tool_call handler registered");
	process.exit(1);
}
const onToolCall = handlers["tool_call"];

function bashEvent(command: string) {
	return { type: "tool_call", toolCallId: "t1", toolName: "bash", input: { command } };
}

async function check(command: string, expectBlock: boolean): Promise<void> {
	const res = await onToolCall(bashEvent(command), {});
	const blocked = res !== undefined && res.block === true;
	if (blocked === expectBlock) {
		passed++;
		if (expectBlock) {
			// sanity: reason mentions the wrapper
			const okReason = typeof res.reason === "string" && res.reason.includes("s-agentic-wrap-command");
			if (!okReason) {
				failed++;
				console.error(`FAIL reason missing wrapper hint: ${JSON.stringify(command)}`);
				return;
			}
		}
	} else {
		failed++;
		console.error(`FAIL wiring: ${JSON.stringify(command)} -> ${JSON.stringify(res)} (expected block=${expectBlock})`);
	}
}

// Non-bash tool passes through untouched.
const nonBash = await onToolCall({ type: "tool_call", toolCallId: "t2", toolName: "read", input: { path: "/x" } }, {});
if (nonBash === undefined) passed++;
else { failed++; console.error(`FAIL non-bash should pass through, got ${JSON.stringify(nonBash)}`); }

// Empty command passes through.
const empty = await onToolCall(bashEvent(""), {});
if (empty === undefined) passed++;
else { failed++; console.error(`FAIL empty command should pass through, got ${JSON.stringify(empty)}`); }

await check(`ssh host "podman ps"`, true);
await check(`s-agentic-wrap-command ssh host "ls -la /etc"`, false);
await check(`foo && ssh host "cmd"`, true);
await check(`cat ~/.ssh/config`, false);
await check(`bash -c "ssh host 'cmd'"`, true);
await check(`x=$(ssh host "cmd")`, true);
await check(`podman container ls --all`, false);

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
