#!/usr/bin/env bash
# Run the web-mcp skill via `go run`.
# Usage:
#   ./run.sh search <query>
#   ./run.sh get_url <url>
set -euo pipefail

cd "$(dirname "$0")"

exec go run ./cmd/server "$@"
