#!/bin/bash
# PostToolUse hook for Claude Code — runs after Edit/Write.
#
# Policy: only *targeted* lint autofixers run inline (ruff --fix, eslint --fix).
# Whole-file formatters (black, prettier, gofmt, rustfmt) are NOT run per-edit —
# they reformat untouched code and bloat diffs (violates Surgical Changes). Run
# them once, on the changed set, in the Definition of Done instead.
# Tool errors are surfaced to stderr, not silently swallowed.
# Uses project-local tools when available (node_modules/.bin).

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('tool_input',{}).get('file_path',''))" 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

EXT="${FILE_PATH##*.}"
FRONTEND_DIR="${CLAUDE_CONFIG_FRONTEND_DIR:-}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"

# surface <tool> <captured-output> <exit-status> — report unfixable issues, never block.
surface() {
    if [ "$3" -ne 0 ]; then
        printf '[auto-format] %s reported issues it could not auto-fix:\n%s\n' "$1" "$2" >&2
    fi
    return 0
}

case "$EXT" in
    py)
        if command -v ruff >/dev/null 2>&1; then
            out=$(ruff check --fix "$FILE_PATH" 2>&1); surface ruff "$out" $?
        fi
        # black (whole-file) runs in the Definition of Done, not here.
        ;;
    ts|tsx|js|jsx|mjs|cjs)
        for dir in "$PROJECT_DIR" "$PROJECT_DIR/$FRONTEND_DIR"; do
            [ -z "$dir" ] && continue
            if [ -f "$dir/node_modules/.bin/eslint" ]; then
                out=$(cd "$dir" && ./node_modules/.bin/eslint --fix "$FILE_PATH" 2>&1); surface eslint "$out" $?
                break
            fi
        done
        # prettier (whole-file) runs in the Definition of Done, not here.
        ;;
    go|rs|html|htm)
        # Whole-file formatters / template-unsafe — handled by the DoD format step.
        ;;
esac
exit 0
