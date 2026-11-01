/**
 * The tree-sitter parser: load it once, parse a command, hand the tree to the highlighter.
 *
 * `web-tree-sitter` and the `tree-sitter-bash` grammar are ordinary dependencies of this extension
 * (see package.json), imported dynamically so that a missing install degrades to the plain command
 * line instead of failing to load the extension. Nothing here is a parser of our own: the grammar is
 * upstream's, compiled to WebAssembly by its own maintainers.
 */

import { createRequire } from "node:module";
import type { Language, Node, Parser as WebTreeSitterParser } from "web-tree-sitter";
import type { Theme } from "@earendil-works/pi-coding-agent";
import { highlightTree } from "./highlight.ts";

const requireFromHere = createRequire(import.meta.url);

type TreeSitterModule = typeof import("web-tree-sitter");

let parser: WebTreeSitterParser | null = null;
let loading: Promise<void> | null = null;
let failure: string | undefined;
const listeners = new Set<(error?: string) => void>();

/** True when both packages can be resolved from this directory. */
export function treeSitterAvailable(): boolean {
	try {
		requireFromHere.resolve("web-tree-sitter");
		requireFromHere.resolve("tree-sitter-bash/tree-sitter-bash.wasm");
		return true;
	} catch {
		return false;
	}
}

export function parserReady(): boolean {
	return parser !== null;
}

/** Why loading failed, if it did — worth showing once rather than swallowing. */
export function parserFailure(): string | undefined {
	return failure;
}

/**
 * Load the grammar. Idempotent; every caller is told once it settles, so a tool call that rendered
 * before the grammar was ready can redraw itself afterwards.
 */
export function loadParser(onSettled?: (error?: string) => void): void {
	if (onSettled) listeners.add(onSettled);
	if (parser) {
		onSettled?.();
		return;
	}
	if (failure) {
		onSettled?.(failure);
		return;
	}
	loading ??= start().then(
		() => {
			const ready = parser !== null;
			if (!ready) failure = "tree-sitter loaded without a bash grammar";
			settle();
		},
		(error: unknown) => {
			failure = `bash highlighting is off: ${error instanceof Error ? error.message : String(error)}`;
			settle();
		},
	);
}

function settle(): void {
	const callbacks = [...listeners];
	listeners.clear();
	for (const callback of callbacks) callback(failure);
}

async function start(): Promise<void> {
	const treeSitter = (await import("web-tree-sitter")) as TreeSitterModule;
	await treeSitter.Parser.init(locateCore());
	const language: Language = await treeSitter.Language.load(
		resolve("tree-sitter-bash/tree-sitter-bash.wasm"),
	);
	const instance = new treeSitter.Parser();
	instance.setLanguage(language);
	parser = instance;
}

function locateCore(): { locateFile: () => string } | undefined {
	try {
		const wasm = resolve("web-tree-sitter/web-tree-sitter.wasm");
		return { locateFile: () => wasm };
	} catch {
		return undefined; // Let the module find its own runtime.
	}
}

function resolve(specifier: string): string {
	return requireFromHere.resolve(specifier);
}

/** Colour one command, or return null when the parser is not ready or the grammar chokes. */
export function highlightCommand(command: string, theme: Theme): string | null {
	const active = parser;
	if (!active) return null;
	const tree = active.parse(command);
	if (!tree) return null;
	try {
		return highlightTree(tree.rootNode as Node, theme);
	} catch {
		return null;
	} finally {
		tree.delete();
	}
}
