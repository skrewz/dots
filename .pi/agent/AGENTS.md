# Instructions for agents

## The environment and setup

- Be podman-centric. Docker is not used here.
- If producing git commits, use gitmoji and conventional commits.
- Prefer British English.

## Mandatory steps at startup and after compaction

- You will likely be working with a git worktree. Please orient yourself.
- Take the skills available to you into account. Load skills that could be
  relevant to the user's prompt proactively.
- Always load any web search skills available to you. They will almost always
  be relevant to your work.
- When working with software libraries, tools etc, never rely on your internal
  memory. Always start off by using web search tools to look up man pages and
  other relevant official documentation. Link to this documentation in
  comments.

## Mandatory steps on every turn

- Consider if you have the right skills loaded relative to the task at hand.

### Before handing back to the user

- Have a look at the git diff you've produced and ask yourself if that reflects
  what you set out to do.
- Check if there are Makefile targets for building and/or linting; use them
  before handing over the task.

## General gotcha's

- Do not add unnessary trailing whitespace (or lines with whitespace only).
- When handling errors, make changes only if they relate to the specific error
- Do not use complete paths in the read tool if a relative path would do.
- Never use internal domain names in examples. Always use example.com-derived
  domain names.
