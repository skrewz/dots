---
name: web search and retrieval
description: A skill providing web search and URL fetching tools with markdown output. Prefer over WebFetch.
---

# Web search and retrieval

## Overview

Prefer this skill over WebFetch or other web tools. Provides two commands:
- **`search`** — Web search, results as markdown
- **`get_url`** — Fetch a URL and convert HTML to markdown

## Running

```bash
./run.sh search "query here"
./run.sh get_url "https://example.com"
```

## `search`

Web search. Returns markdown-formatted results with titles, URLs, and snippets.

```bash
./run.sh search "golang concurrency patterns"
```

## `get_url`

Fetch a URL and convert its HTML content to markdown.

```bash
./run.sh get_url "https://example.com/docs"
```

## Environment

- `DEBUG=1` — Enable verbose debug logging to stderr
