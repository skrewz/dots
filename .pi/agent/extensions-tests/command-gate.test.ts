// Unit tests for the command-gate detection functions (pure logic, no pi).
// Run via:  make -C .pi/agent/extensions-tests test
import {
	collectCommandCandidates,
	findBlockedCommand,
	invokesBlockedCommand,
} from "../extensions/command-gate";

let passed = 0;
let failed = 0;

function expectBlocked(cmd: string, note?: string): void {
	const got = invokesBlockedCommand(cmd);
	if (got) {
		passed++;
	} else {
		failed++;
		console.error(`FAIL (expected BLOCKED, got allowed): ${JSON.stringify(cmd)}${note ? `  [${note}]` : ""}`);
	}
}

function expectAllowed(cmd: string, note?: string): void {
	const got = invokesBlockedCommand(cmd);
	if (!got) {
		passed++;
	} else {
		failed++;
		console.error(`FAIL (expected ALLOWED, got blocked): ${JSON.stringify(cmd)}${note ? `  [${note}]` : ""}`);
	}
}

// --- Direct ssh: must be blocked ---
expectBlocked(`ssh host "podman ps"`);
expectBlocked(`ssh host podman ps`);
expectBlocked(`ssh user@host "ls -la /etc"`);
expectBlocked(`ssh host`);
expectBlocked(`/usr/bin/ssh host "cmd"`);
expectBlocked(`~/.local/bin/ssh host "cmd"`);

// --- The wrapper: must be allowed (ssh is only an argument) ---
expectAllowed(`s-agentic-wrap-command ssh host "ls -la /etc"`);
expectAllowed(`s-agentic-wrap-command --verbose ssh host "podman ps"`);
expectAllowed(`s-agentic-wrap-command --list-examples`);
expectAllowed(`s-agentic-wrap-command --help`);

// --- Compound commands involving ssh: must be blocked ---
expectBlocked(`foo && ssh host "cmd"`);
expectBlocked(`ssh host "cmd" && bar`);
expectBlocked(`a; ssh host "cmd"`);
expectBlocked(`ssh host "cmd"; b`);
expectBlocked(`a | ssh host "cmd"`);
expectBlocked(`ssh host "cmd" | grep x`);
expectBlocked(`a & ssh host "cmd"`);
expectBlocked(`ssh host "cmd" || backup`);
expectBlocked(`cmd1\ncmd2 && ssh host x`);
expectBlocked(`cmd1\nssh host x`);

// --- Loops / conditionals: must be blocked ---
expectBlocked(`for h in a b; do ssh $h "cmd"; done`);
expectBlocked(`for h in a b; do echo $h; ssh $h "cmd"; done`);
expectBlocked(`if true; then ssh host "cmd"; fi`);
expectBlocked(`while read h; do ssh $h "cmd"; done < hosts`);

// --- Subshells: must be blocked ---
expectBlocked(`(ssh host "cmd")`);
expectBlocked(`( cd /tmp && ssh host "cmd" )`);

// --- Command substitutions: must be blocked ---
expectBlocked(`x=$(ssh host "cmd")`);
expectBlocked(`echo $(ssh host "cmd")`);
expectBlocked(`x=\`ssh host "cmd"\``);
expectBlocked(`echo \`ssh host "cmd"\``);
expectBlocked(`a=$(ssh h1 x) && b=$(ssh h2 y)`);

// --- shell -c strings: must be blocked ---
expectBlocked(`bash -c "ssh host 'cmd'"`);
expectBlocked(`sh -c 'ssh host "cmd"'`);
expectBlocked(`zsh -c "ssh host cmd"`);
expectBlocked(`bash -e -c "ssh host cmd"`);
expectBlocked(`env bash -c "ssh host cmd"`);

// --- Prefix / env-assignment wrappers around ssh: must be blocked ---
expectBlocked(`env ssh host "cmd"`);
expectBlocked(`nohup ssh host "cmd"`);
expectBlocked(`time ssh host "cmd"`);
expectBlocked(`sudo ssh host "cmd"`);
expectBlocked(`FOO=bar ssh host "cmd"`);
expectBlocked(`A=1 B=2 ssh host "cmd"`);

// --- False positives: must be ALLOWED ---
expectAllowed(`cat ~/.ssh/config`);
expectAllowed(`ls -la /etc/ssh/sshd_config`);
expectAllowed(`grep ssh file.txt`);
expectAllowed(`echo "ssh"`);
expectAllowed(`echo 'ssh is a tool'`);
expectAllowed(`crush --do-thing`);
expectAllowed(`ssh-keygen -t ed25519`);
expectAllowed(`systemctl status sshd`);
expectAllowed(`git config --global core.sshCommand foo`);
expectAllowed(`rsync -av local/ host:remote/`); // no literal ssh command
expectAllowed(`ls`);
expectAllowed(`echo hello world`);
expectAllowed(`podman container ls --all`);
expectAllowed(`cat /etc/containers/storage.conf`);
expectAllowed(`echo "use s-agentic-wrap-command for ssh"`);

// --- findBlockedCommand returns the matched name ---
const m1 = findBlockedCommand(`foo && /usr/bin/ssh host x`);
if (m1 === "ssh") passed++;
else { failed++; console.error(`FAIL findBlockedCommand basename: got ${JSON.stringify(m1)}`); }

const m2 = findBlockedCommand(`ls -la`);
if (m2 === null) passed++;
else { failed++; console.error(`FAIL findBlockedCommand null: got ${JSON.stringify(m2)}`); }

// --- collectCommandCandidates sanity ---
const cands = collectCommandCandidates(`a && env ssh host x`);
const joined = cands.join(",");
if (cands.includes("a") && cands.includes("ssh")) {
	passed++;
} else {
	failed++;
	console.error(`FAIL collectCommandCandidates: got [${joined}]`);
}

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
