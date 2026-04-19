# Skill: karpathy-guidelines

# Karpathy-Inspired Coding Guidelines

Behavioral guidelines to reduce common LLM coding mistakes. Derived from Andrej Karpathy's observations on LLM coding pitfalls.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## Core Principles

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- **State your assumptions explicitly.** If uncertain, ask.
- **If multiple interpretations exist, present them** - don't pick silently.
- **If a simpler approach exists, say so.** Push back when warranted.
- **If something is unclear, stop.** Name what's confusing. Ask.

**HARD REQUIREMENT:** Do NOT proceed with implementation until ambiguity is resolved. The user would rather answer a question now than debug a wrong assumption later.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

**The test:** "Would a senior engineer say this is overcomplicated?" If yes, simplify.

**ANTI-PATTERN:** Over-engineering a "simple" task. Even a one-liner config change can hide assumptions. When in doubt: ask, don't assume.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

**The test:** Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

| Instead of... | Transform to... |
|--------------|-----------------|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure tests pass before and after" |
| "Update the UI" | "Identify what changes, verify visually, check responsive" |

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## Red Flags - STOP and Clarify

These thoughts indicate you should pause and ask:

| Thought | Action |
|---------|--------|
| "I'll just assume..." | Stop. State assumption and ask. |
| "There are multiple ways to interpret this..." | Present options, don't pick. |
| "This seems more complicated than it should be..." | Suggest simpler approach. |
| "I'm not sure what this code does..." | Ask for explanation. |
| "I'll fix this while I'm here..." | Don't. Scope creep kills PRs. |
| "This could be more flexible if..." | YAGNI. Implement what was asked. |

## Success Indicators

These guidelines are working if you see:

- **Fewer unnecessary changes in diffs** - Only requested changes appear
- **Fewer rewrites due to overcomplication** - Code is simple the first time
- **Clarifying questions come before implementation** - Not after mistakes
- **Clean, minimal edits** - No drive-by refactoring or "improvements"

## When to Apply

**ALWAYS apply these principles**, even for simple tasks. A single config change can hide wrong assumptions. Questions now prevent bugs later.

**Exception:** For truly trivial tasks (obvious typo fixes, single-character changes where intent is 100% clear), use judgment.

## Integration with Other Skills

This skill is **complementary** to other skills like `brainstorming`, `systematic-debugging`, or `writing-plans`. Apply these principles within those workflows:

- Use **Think Before Coding** before invoking any implementation skill
- Use **Simplicity First** when designing approaches in brainstorming
- Use **Surgical Changes** when executing plans
- Use **Goal-Driven Execution** when defining verification steps

## Reference

Based on Andrej Karpathy's observations: https://x.com/karpathy/status/2015883857489522876

Original repository: https://github.com/forrestchang/andrej-karpathy-skills
