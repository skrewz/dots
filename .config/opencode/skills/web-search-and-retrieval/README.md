# Web search and retrieval skill

A CLI skill with two commands:
- **`search`** — Web search, results as markdown
- **`get_url`** — Fetch a URL and convert HTML to markdown

## Usage

```bash
# Search the web
./run.sh search "golang concurrency patterns"

# Fetch a URL and convert to markdown
./run.sh get_url "https://example.com"
```

## Environment Variables

- `DEBUG` — Enable debug logging (any non-empty value)

## Development

```bash
make build    # Build the binary
make test     # Run all tests
make clean    # Remove built binary
```

## Files

| File | Purpose |
|------|---------|
| `cmd/server/main.go` | CLI entrypoint |
| `internal/search/search.go` | Web search logic |
| `internal/scraper/scraper.go` | HTML-to-markdown URL fetching |
| `Makefile` | Build targets |
| `go.mod` / `go.sum` | Go module dependencies |
