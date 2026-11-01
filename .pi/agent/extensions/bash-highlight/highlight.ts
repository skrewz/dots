/**
 * Colours a bash parse tree with the active pi theme.
 *
 * Nothing in here parses bash: tree-sitter-bash has already recognised the structure, and this module
 * only maps its node types onto pi's theme tokens. The mapping follows tree-sitter-bash's own
 * `queries/highlights.scm` (MIT, shipped in the `tree-sitter-bash` package) — @function for
 * `command_name`, @string for strings and heredocs, @property for `variable_name`, @keyword for the
 * shell keywords, @operator for `$ && | < >`, @number for numbers and file descriptors, @constant for
 * option words beginning with "-", @comment for comments. Two deliberate deviations, both cosmetic:
 * upstream's @embedded (expansions, command and process substitution) shares the variable colour, and
 * the operator set is completed with `||`, `;`, `&`, `>&`, `<&` and `=`, which the query leaves out
 * but which read the same way as the ones it names.
 */

import type { Node } from "web-tree-sitter";
import type { Theme, ThemeToken } from "@earendil-works/pi-coding-agent";

export type Token =
	| "default"
	| "function"
	| "string"
	| "variable"
	| "keyword"
	| "comment"
	| "number"
	| "operator"
	| "type";

/** Theme token per highlight token. `type` carries option words, the colour upstream calls @constant. */
export const TOKEN_THEME: Record<Token, ThemeToken> = {
	default: "toolTitle",
	function: "syntaxFunction",
	string: "syntaxString",
	variable: "syntaxVariable",
	keyword: "syntaxKeyword",
	comment: "syntaxComment",
	number: "syntaxNumber",
	operator: "syntaxOperator",
	type: "syntaxType",
};

/** Named nodes, per highlights.scm. */
const NAMED_NODES: Record<string, Token> = {
	command_name: "function",
	string: "string",
	raw_string: "string",
	string_content: "string",
	heredoc_start: "string",
	heredoc_body: "string",
	variable_name: "variable",
	simple_expansion: "variable",
	expansion: "variable",
	brace_expansion: "variable",
	command_substitution: "variable",
	process_substitution: "variable",
	comment: "comment",
	number: "number",
	file_descriptor: "number",
	test_operator: "type",
};

/** Literal (anonymous) nodes: keywords and operators named by the grammar. */
const LITERAL_NODES: Record<string, Token> = {
	for: "keyword",
	in: "keyword",
	do: "keyword",
	done: "keyword",
	while: "keyword",
	until: "keyword",
	if: "keyword",
	then: "keyword",
	else: "keyword",
	elif: "keyword",
	fi: "keyword",
	case: "keyword",
	esac: "keyword",
	select: "keyword",
	function: "keyword",
	export: "keyword",
	unset: "keyword",
	time: "keyword",
	$: "operator",
	"&&": "operator",
	"||": "operator",
	"|": "operator",
	"|&": "operator",
	";": "operator",
	";&": "operator",
	"&": "operator",
	">": "operator",
	">>": "operator",
	"<": "operator",
	"<<": "operator",
	"<<<": "operator",
	">&": "operator",
	"<&": "operator",
	"<>": "operator",
	"=": "operator",
};

interface Span {
	start: number;
	end: number;
	token: Token;
}

function tokenFor(node: Node): Token | undefined {
	const named = NAMED_NODES[node.type];
	if (named) return named;
	const literal = LITERAL_NODES[node.type];
	if (literal) return literal;
	// highlights.scm: (command (_) @constant) (#match? @constant "^-") — an option word.
	if (node.type === "word" && node.parent?.type === "command" && node.text?.startsWith("-")) return "type";
	return undefined;
}

/**
 * One span per contiguous run of source, each with the token of the deepest node that claims it.
 * Gaps between children (whitespace, and any node the tables do not name) inherit the parent's token,
 * so the spans tile the source exactly and nothing is dropped or reordered.
 */
function collect(node: Node, inherited: Token, spans: Span[]): void {
	const token = tokenFor(node) ?? inherited;
	if (node.childCount === 0) {
		spans.push({ start: node.startIndex, end: node.endIndex, token });
		return;
	}
	let cursor = node.startIndex;
	for (const child of node.children) {
		if (child.startIndex > cursor) spans.push({ start: cursor, end: child.startIndex, token });
		collect(child, token, spans);
		cursor = Math.max(cursor, child.endIndex);
	}
	if (node.endIndex > cursor) spans.push({ start: cursor, end: node.endIndex, token });
}

/**
 * Style one run of text. pi resets styling after every rendered line, so a span that crosses a line
 * boundary is closed and reopened instead of leaking across it; empty fragments stay bare newlines.
 */
function paint(text: string, token: Token, theme: Theme): string {
	if (!text) return "";
	const colour = theme.fg.bind(theme, TOKEN_THEME[token]);
	return text.includes("\n") ? text.split("\n").map((line) => (line ? colour(line) : line)).join("\n") : colour(text);
}

/** Build the coloured command. The result is the source with escapes added and nothing else changed. */
export function highlightTree(root: Node, theme: Theme): string {
	const source = root.text ?? "";
	const spans: Span[] = [];
	collect(root, "default", spans);
	spans.sort((a, b) => a.start - b.start);

	let out = "";
	let cursor = 0;
	for (const span of spans) {
		if (span.start > cursor) out += paint(source.slice(cursor, span.start), "default", theme);
		out += paint(source.slice(span.start, span.end), span.token, theme);
		cursor = Math.max(cursor, span.end);
	}
	if (cursor < source.length) out += paint(source.slice(cursor), "default", theme);
	return out;
}
