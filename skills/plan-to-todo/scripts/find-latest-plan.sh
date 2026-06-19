#!/usr/bin/env bash
# find-latest-plan.sh
#
# Finds the most recently modified .md file under docs/research/
# relative to the current working directory.
#
# Usage: ./scripts/find-latest-plan.sh
# Output: prints the relative path (e.g. docs/research/demo-data-plan.md)
# Exit code: 0 if found, 1 if none found.

set -euo pipefail

DIR="docs/research"

if [ ! -d "$DIR" ]; then
	echo "Error: '$DIR' directory not found in $(pwd)." >&2
	echo "Create a plan file under $DIR/ and re-run." >&2
	exit 1
fi

# Find all .md files directly in docs/research (non-recursive, alphabetical)
# shellcheck disable=SC2012
LATEST=$(ls -1t "$DIR"/*.md 2>/dev/null | head -1)

if [ -z "$LATEST" ]; then
	echo "Error: No .md files found in '$DIR/'." >&2
	exit 1
fi

echo "$LATEST"
