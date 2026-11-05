#!/bin/bash
# PreToolUse hook for Claude Code (Edit | Write | MultiEdit | NotebookEdit), plugin variant of
# core/.claude/hooks/agent-enforcement.sh. Two hard blocks (exit 2):
#  - Branch discipline: no edits to code under $CLAUDE_CONFIG_SRC_DIR (default src) or
#    $CLAUDE_CONFIG_FRONTEND_DIR while on a protected branch. Protected =
#    $AGENT_CONFIG_PROTECTED_BRANCHES (or legacy $CLAUDE_CONFIG_PROTECTED_BRANCHES), default "main,master".
#  - Approved-tests lock: no edits to the paths listed under `## Approved tests` in the slice
#    file (docs/epics/<ID>/slices/<n>.md) whose `- Branch:` line names the current branch.
#    Override: AGENT_CONFIG_UNLOCK_TESTS=1 in the environment Claude Code runs in.
# Anything it cannot parse passes: a guardrail, not a security boundary.

set -uo pipefail

HOOK_INPUT=$(cat)
export HOOK_INPUT

FILE_PATH=$(python3 -c '
import json, os
try:
    ti = json.loads(os.environ.get("HOOK_INPUT", "")).get("tool_input") or {}
    print(ti.get("file_path") or ti.get("notebook_path") or "")
except Exception:
    pass
' 2>/dev/null)
[ -n "$FILE_PATH" ] || exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
CURRENT_BRANCH=""
if [ -n "$PROJECT_DIR" ] && { [ -d "$PROJECT_DIR/.git" ] || [ -f "$PROJECT_DIR/.git" ]; }; then
    CURRENT_BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi
[ -n "$CURRENT_BRANCH" ] || exit 0

# Membership test for a comma/space-separated list (bash 3.2 safe).
branch_in_list() {
    _b="$1"; _list=$(printf '%s' "$2" | tr ',' ' '); _i=""
    for _i in $_list; do
        [ "$_b" = "$_i" ] && return 0
    done
    return 1
}

# --- Branch Discipline ---
SRC_DIR="${CLAUDE_CONFIG_SRC_DIR:-src}"
FRONTEND_DIR="${CLAUDE_CONFIG_FRONTEND_DIR:-}"
PROTECTED="${AGENT_CONFIG_PROTECTED_BRANCHES:-${CLAUDE_CONFIG_PROTECTED_BRANCHES:-main,master}}"
if branch_in_list "$CURRENT_BRANCH" "$PROTECTED"; then
    IN_SCOPE=0
    case "$FILE_PATH" in
        *"/$SRC_DIR/"*|*"/$SRC_DIR"|"$SRC_DIR/"*) IN_SCOPE=1 ;;
    esac
    if [ -n "$FRONTEND_DIR" ]; then
        case "$FILE_PATH" in *"$FRONTEND_DIR"*) IN_SCOPE=1 ;; esac
    fi
    if [ "$IN_SCOPE" = "1" ]; then
        cat >&2 <<MSG
[agent-enforcement] BLOCKED: '$CURRENT_BRANCH' is a protected branch — no direct edits.
Check out a typed branch first:
  git checkout -b feature/<ID>-<group>-<layer>
  git checkout -b fix/<slug>
  git checkout -b hotfix/<slug>
  git checkout -b refactor/<slug>
  git checkout -b chore/<slug>
Protected branches: $PROTECTED  (override with AGENT_CONFIG_PROTECTED_BRANCHES; legacy: CLAUDE_CONFIG_PROTECTED_BRANCHES)
MSG
        exit 2
    fi
fi

# --- Approved-tests lock ---
[ "${AGENT_CONFIG_UNLOCK_TESTS:-}" = 1 ] && exit 0
LOCKED_BY=$(python3 -c '
import glob, os, re, sys
root, branch, target = sys.argv[1:]
def key(p):  # one spelling per file: symlinks resolved; case folded where the filesystem ignores it
    p = os.path.normcase(os.path.realpath(os.path.join(root, p)))
    return p.casefold() if sys.platform == "darwin" else p
target = key(target)
for slice_file in sorted(glob.glob(os.path.join(root, "docs/epics/*/slices/*.md"))):
    if not re.fullmatch(r"\d+\.md", os.path.basename(slice_file)):
        continue  # <n>.security.md, <n>.mutation.md are reports, not slices
    text = open(slice_file, encoding="utf-8", errors="replace").read()
    if not re.search(r"^- Branch: `" + re.escape(branch) + "`", text, re.M):
        continue
    section = re.search(r"^## Approved tests\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    for path in re.findall(r"^- `([^`]+)`", section.group(1) if section else "", re.M):
        if key(path) == target:
            print(os.path.relpath(slice_file, root))
            sys.exit(0)
' "$PROJECT_DIR" "$CURRENT_BRANCH" "$FILE_PATH" 2>/dev/null)
if [ -n "$LOCKED_BY" ]; then
    cat >&2 <<MSG
[agent-enforcement] BLOCKED: $FILE_PATH is an approved test ($LOCKED_BY, branch '$CURRENT_BRANCH').
Make the code pass the test; do not change the test. If the test itself is wrong, stop and ask
the user. Once they agree, they restart with AGENT_CONFIG_UNLOCK_TESTS=1 and re-approve the tests.
MSG
    exit 2
fi
exit 0
