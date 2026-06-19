#!/usr/bin/env bash
# find-source-docs.sh
#
# Discovers the appropriate source documents for plan generation.
# Priority:
#   1. Most recently modified .md file in docs/research/ (feature plan for existing project)
#   2. docs/ARCHITECTURE.md (greenfield project specification)
#
# Output: MODE and SOURCE variables that can be sourced or parsed.
#
# Exit code: 0 if source found, 1 if none found.

set -euo pipefail

# Priority 1: feature plan in docs/research/
if [ -d "docs/research" ]; then
	LATEST=$(ls -1t "docs/research"/*.md 2>/dev/null | head -1)
	if [ -n "$LATEST" ]; then
		echo "MODE=feature"
		echo "SOURCE=$LATEST"
		exit 0
	fi
fi

# Priority 2: greenfield project specification
if [ -f "docs/ARCHITECTURE.md" ]; then
	echo "MODE=greenfield"
	echo "SOURCE=docs/ARCHITECTURE.md"
	exit 0
fi

echo "Error: No source documents found." >&2
echo "Create either:" >&2
echo "  - A plan file in docs/research/ (for a new feature on an existing project)" >&2
echo "  - docs/ARCHITECTURE.md (for a new greenfield project)" >&2
exit 1
