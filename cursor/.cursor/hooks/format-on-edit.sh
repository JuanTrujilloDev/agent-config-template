#!/bin/bash
# Cursor afterFileEdit hook — format adapter.
#
# Adapter over core/.claude/hooks/auto-format.sh: same targeted-autofix policy
# (ruff --fix / eslint --fix on the edited file only; whole-file formatters
# like black/prettier stay in the Definition of Done, not per-edit), Cursor
# payload schema (JSON with a `file_path` field on stdin).
#
# NEVER blocks: every path — including unparseable payloads and tool
# failures — exits 0 with an allow verdict. Tool findings go to stderr.

INPUT=$(cat)

allow() { printf '{"permission":"allow"}\n'; exit 0; }

FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('file_path',''))" 2>/dev/null)

[ -z "$FILE_PATH" ] && allow

EXT="${FILE_PATH##*.}"
PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# surface <tool> <captured-output> <exit-status> — report unfixable issues, never block.
surface() {
    if [ "$3" -ne 0 ]; then
        printf '[format-on-edit] %s reported issues it could not auto-fix:\n%s\n' "$1" "$2" >&2
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
        for dir in "$PROJECT_DIR" "$PROJECT_DIR/{{frontend_dir}}"; do
            if [ -f "$dir/node_modules/.bin/eslint" ]; then
                out=$(cd "$dir" && ./node_modules/.bin/eslint --fix "$FILE_PATH" 2>&1); surface eslint "$out" $?
                break
            fi
        done
        # prettier (whole-file) runs in the Definition of Done, not here.
        ;;
esac

allow
