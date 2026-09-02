#!/bin/bash
# Cursor plugin hook: run targeted autofixers after an edit; never block.

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('file_path',''))" 2>/dev/null)
[ -z "$FILE_PATH" ] && { printf '{"permission":"allow"}\n'; exit 0; }

EXT="${FILE_PATH##*.}"
PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
FRONTEND_DIR="${AGENT_CONFIG_FRONTEND_DIR:-${CLAUDE_CONFIG_FRONTEND_DIR:-}}"

surface() {
    if [ "$3" -ne 0 ]; then
        printf '[format-on-edit] %s reported issues it could not auto-fix:\n%s\n' "$1" "$2" >&2
    fi
}

case "$EXT" in
    py)
        if command -v ruff >/dev/null 2>&1; then
            out=$(ruff check --fix "$FILE_PATH" 2>&1); surface ruff "$out" $?
        fi
        ;;
    ts|tsx|js|jsx|mjs|cjs)
        if [ -x "$PROJECT_DIR/node_modules/.bin/eslint" ]; then
            out=$(cd "$PROJECT_DIR" && ./node_modules/.bin/eslint --fix "$FILE_PATH" 2>&1); surface eslint "$out" $?
        elif [ -n "$FRONTEND_DIR" ] && [ -x "$PROJECT_DIR/$FRONTEND_DIR/node_modules/.bin/eslint" ]; then
            out=$(cd "$PROJECT_DIR/$FRONTEND_DIR" && ./node_modules/.bin/eslint --fix "$FILE_PATH" 2>&1); surface eslint "$out" $?
        fi
        ;;
esac

printf '{"permission":"allow"}\n'
