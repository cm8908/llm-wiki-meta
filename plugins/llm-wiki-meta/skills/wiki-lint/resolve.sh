#!/usr/bin/env bash
# wiki-lint/resolve.sh [ROOT] — print ROOT/WIKI/SKILL for the attached wiki's local lint.
exec "$(cd "$(dirname "$0")" && pwd)/../../lib/dispatch.sh" lint "$@"
