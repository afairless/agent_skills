#!/usr/bin/env bash
# discover.sh
#
# Reads TODO.md and the project root to discover what to implement.
#
# Output:
#   PLAN_MODE    — "feature" or "greenfield"
#   SOURCE       — path to the source document TODO.md references
#   LANGUAGE     — detected programming language (rust|python|typescript|go|lua|r)
#   HAS_TODO_MD  — "true" if TODO.md exists
#
# Exits with error if TODO.md is missing.

set -euo pipefail

if [ ! -f "TODO.md" ]; then
	echo "Error: TODO.md not found in project root." >&2
	echo "Create a TODO.md first (e.g. using the write-todo-from-plan skill)." >&2
	exit 1
fi

# Parse Source from TODO.md header: line like "Source: docs/research/foo.md"
SOURCE=$(grep -i '^Source:' TODO.md | head -1 | sed 's/^[Ss]ource:\s*//' | xargs || true)

# Determine MODE
if echo "$SOURCE" | grep -qE '^docs/research/'; then
	PLAN_MODE="feature"
elif echo "$SOURCE" | grep -qE '^docs/ARCHITECTURE\.md'; then
	PLAN_MODE="greenfield"
else
	# Fallback: check what files exist
	if [ -f "docs/ARCHITECTURE.md" ]; then
		PLAN_MODE="greenfield"
		SOURCE="docs/ARCHITECTURE.md"
	elif [ -d "docs/research" ]; then
		LATEST=$(ls -1t docs/research/*.md 2>/dev/null | head -1)
		if [ -n "$LATEST" ]; then
			PLAN_MODE="feature"
			SOURCE="$LATEST"
		else
			echo "Error: Could not determine source document from TODO.md." >&2
			echo "TODO.md should contain a line like: Source: docs/research/my-plan.md" >&2
			exit 1
		fi
	else
		echo "Error: Could not determine source document from TODO.md." >&2
		exit 1
	fi
fi

# Detect language from project config files
detect_language_from_config() {
	# Priority order
	if [ -f "Cargo.toml" ]; then
		echo "rust"
		return 0
	fi
	if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
		echo "python"
		return 0
	fi
	if [ -f "package.json" ]; then
		echo "typescript"
		return 0
	fi
	if [ -f "go.mod" ]; then
		echo "go"
		return 0
	fi
	if [ -f "pixi.toml" ]; then
		echo "python"
		return 0
	fi
	if [ -f "renv.lock" ] || [ -f "DESCRIPTION" ]; then
		echo "r"
		return 0
	fi
	# Check source files as fallback (only works for existing codebases)
	if ls *.rs 2>/dev/null | head -1 | grep -q .; then
		echo "rust"
		return 0
	fi
	if ls *.py 2>/dev/null | head -1 | grep -q .; then
		echo "python"
		return 0
	fi
	if ls *.ts 2>/dev/null | head -1 | grep -q .; then
		echo "typescript"
		return 0
	fi
	if ls *.tsx 2>/dev/null | head -1 | grep -q .; then
		echo "typescript"
		return 0
	fi
	if ls *.go 2>/dev/null | head -1 | grep -q .; then
		echo "go"
		return 0
	fi
	if ls *.lua 2>/dev/null | head -1 | grep -q .; then
		echo "lua"
		return 0
	fi
	if ls *.R 2>/dev/null | head -1 | grep -q .; then
		echo "r"
		return 0
	fi
	echo "unknown"
}

# Read the source doc to infer language when no project files exist
# (handles greenfield projects and docs/research/ plans that specify a language)
detect_language_from_source() {
	local doc="$1"
	[ -f "$doc" ] || {
		echo "unknown"
		return 0
	}

	# Check frontmatter for a language/repository-language field
	if grep -qiE '^language:\s*rust' "$doc"; then
		echo "rust"
		return 0
	fi
	if grep -qiE '^language:\s*python' "$doc"; then
		echo "python"
		return 0
	fi
	if grep -qiE '^language:\s*typescript|language:\s*node|language:\s*ts' "$doc"; then
		echo "typescript"
		return 0
	fi
	if grep -qiE '^language:\s*go|^language:\s*golang' "$doc"; then
		echo "go"
		return 0
	fi
	if grep -qiE '^language:\s*lua' "$doc"; then
		echo "lua"
		return 0
	fi
	if grep -qiE '^language:\s*r\b|^language:\s*R\b' "$doc"; then
		echo "r"
		return 0
	fi

	# Check code-fence language tags in the body
	if grep -qE '```rust\b' "$doc"; then
		echo "rust"
		return 0
	fi
	if grep -qE '```python\b' "$doc"; then
		echo "python"
		return 0
	fi
	if grep -qE '```typescript\b' "$doc"; then
		echo "typescript"
		return 0
	fi
	if grep -qE '```go\b' "$doc"; then
		echo "go"
		return 0
	fi
	if grep -qE '```lua\b' "$doc"; then
		echo "lua"
		return 0
	fi
	if grep -qE '```r\b' "$doc"; then
		echo "r"
		return 0
	fi

	# Broad text heuristics — only if the doc mentions one language prominently
	# Count occurrences of each language name (case-insensitive, word-boundaried)
	local rust_count python_count ts_count go_count lua_count r_count
	rust_count=$(grep -ioE '\b[Rr]ust\b' "$doc" | wc -l)
	python_count=$(grep -ioE '\b[Pp]ython\b' "$doc" | wc -l)
	ts_count=$(grep -ioE '\b[Tt]ype[Ss]cript\b' "$doc" | wc -l)
	go_count=$(grep -ioE '\b[Gg]o\b' "$doc" | wc -l)
	lua_count=$(grep -ioE '\b[Ll]ua\b' "$doc" | wc -l)
	r_count=$(grep -ioE '\bR\b' "$doc" | grep -v '^[[:space:]]*$' | wc -l)

	# Whichever is mentioned most, if it dominates (at least 3 and >2x runner-up)
	local max_count=0 max_lang="unknown"
	for pair in "$rust_count:rust" "$python_count:python" "$ts_count:typescript" "$go_count:go" "$lua_count:lua" "$r_count:r"; do
		local cnt="${pair%%:*}" lang="${pair##*:}"
		if [ "$cnt" -gt "$max_count" ]; then
			max_count=$cnt
			max_lang=$lang
		elif [ "$cnt" -eq "$max_count" ] && [ "$max_count" -gt 0 ]; then
			max_lang="ambiguous"
		fi
	done

	if [ "$max_count" -ge 3 ] && [ "$max_lang" != "ambiguous" ]; then
		echo "$max_lang"
		return 0
	fi

	echo "unknown"
}

LANGUAGE=$(detect_language_from_config)

# Fallback: read the source document for language hints
if [ "$LANGUAGE" = "unknown" ] && [ -n "$SOURCE" ]; then
	SOURCE_LANG=$(detect_language_from_source "$SOURCE")
	if [ "$SOURCE_LANG" != "unknown" ]; then
		LANGUAGE="$SOURCE_LANG"
	fi
fi

echo "PLAN_MODE=$PLAN_MODE"
echo "SOURCE=$SOURCE"
echo "LANGUAGE=$LANGUAGE"
echo "HAS_TODO_MD=true"
