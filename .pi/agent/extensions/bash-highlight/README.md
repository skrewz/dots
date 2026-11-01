# bash-highlight

Syntax-highlights the shell commands pi runs, in the interactive transcript.

```
$ git commit -am 'fix: typo' && make test
```

renders with command names, options, strings, variables, operators, keywords, numbers and comments in
the theme's `syntax*` colours instead of one flat colour.

Rendering only: execution, approvals and the tool contract are untouched.

## How it works

`pi.registerToolRenderer()` wraps the built-in bash renderer, so the tool is not re-registered and
other extensions' wrappers keep working. The command is parsed by the
[tree-sitter-bash](https://github.com/tree-sitter/tree-sitter-bash) grammar — WebAssembly, built by
the grammar's own maintainers — through
[web-tree-sitter](https://github.com/tree-sitter/tree-sitter-bash/blob/main/README.md), and the node
types are mapped onto theme tokens following the grammar's own
[`queries/highlights.scm`](https://github.com/tree-sitter/tree-sitter-bash/blob/main/queries/highlights.scm).
No parsing code is written here; `highlight.ts` only says which theme token each node type gets.

Only `bash` is handled, and nothing else is touched: for every other tool the resolver hands back
`next()` unchanged, so `edit`, `read`, `write`, MCP tools and the rest render exactly as pi renders
them on its own. (Returning `undefined` would not be a pass — to pi that means "this tool has no
renderers", and the call would fall back to unformatted output.) PowerShell is deliberately out of
scope.

## Install

```bash
cp -r bash-highlight ~/.pi/agent/extensions/
cd ~/.pi/agent/extensions/bash-highlight
npm install --omit=peer --ignore-scripts
```

Restart pi. To try it for one run without installing anything:

```bash
pi -e ./extensions/bash-highlight
```

`--omit=peer` keeps pi's own packages out of this directory — pi supplies them to extensions, and a
second copy can create duplicate classes. `--ignore-scripts` skips the grammar's native build, which
is not used; only its `.wasm` is. That leaves 25 MB in `node_modules`, of which 1.5 MB is the two wasm
files; if you want it leaner:

```bash
rm -rf node_modules/tree-sitter-bash/{src,prebuilds} node_modules/{node-gyp-build,node-addon-api}
```

Without `npm install` the extension still loads, every command renders plainly, and you get one
warning in the transcript.

## Behaviour worth knowing

- **Text is never altered** — strip the escape sequences and you get exactly the command the tool runs.
- **Nothing is coloured while the arguments stream in.** A half-received command would parse as
  garbage, so the plain line is shown until the call's arguments are complete.
- **Commands over 8 000 characters are left plain.** Parsing runs on the render path: about 0.2 ms for
  a typical command, 1.6 ms for a 2 KB one, ~3 µs on a memo hit.
- **Multi-line commands are shown as they are**, without re-indenting continuation lines.
- **Hermetic per line.** pi resets styling after every rendered line, so each line opens and closes
  its own colours instead of leaking into the next.
- **Theme changes take effect immediately.** The memo keys on the theme's colours, not on the theme
  object, so `/theme` cannot leave stale colours behind.
- **User `!` shell commands are not covered.** They are drawn by `BashExecutionComponent`, not by a
  tool renderer.
