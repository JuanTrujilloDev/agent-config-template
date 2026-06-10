#!/bin/bash
# PreToolUse hook for Claude Code (Edit | Write).
#
# Two checks, deliberately with different teeth:
#  - Branch discipline (HARD BLOCK): never edit code under {{src_dir}} while on a
#    protected branch. Protected = $CLAUDE_CONFIG_PROTECTED_BRANCHES, default
#    "{{default_branch}},master".
#  - Agent guidance (ADVISORY): non-trivial edits to {{src_dir}} print a reminder
#    to prefer the right agent, but do NOT block. Discipline is on you, not the hook.
#
# Override the protected-branch list per-project (e.g. to guard env branches):
#   export CLAUDE_CONFIG_PROTECTED_BRANCHES="{{default_branch}},qa,prod"
#
# Trivial edits (≤50 lines AND ≤1 new def/class) pass silently.

set -uo pipefail

INPUT=$(cat)
export HOOK_INPUT="$INPUT"

SUMMARY=$(python3 -c '
import json, os, sys
try:
    data = json.loads(os.environ.get("HOOK_INPUT", ""))
except Exception:
    sys.exit(0)
ti = data.get("tool_input", {}) or {}
fp = (ti.get("file_path") or "").replace("\t", " ")
ns = ti.get("new_string") or ti.get("content") or ""
line_count = ns.count("\n") + (1 if ns and not ns.endswith("\n") else 0)
def_count = 0
for line in ns.splitlines():
    s = line.lstrip()
    if (
        s.startswith("def ")
        or s.startswith("class ")
        or s.startswith("export class ")
        or s.startswith("export function ")
        or s.startswith("function ")
    ):
        def_count += 1
print(f"{fp}\t{line_count}\t{def_count}")
')

if [ -z "$SUMMARY" ]; then
    exit 0
fi

FILE_PATH=$(printf '%s' "$SUMMARY" | awk -F'\t' '{print $1}')
LINE_COUNT=$(printf '%s' "$SUMMARY" | awk -F'\t' '{print $2}')
DEF_COUNT=$(printf '%s' "$SUMMARY" | awk -F'\t' '{print $3}')

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Membership test for a comma/space-separated list (bash 3.2 safe).
branch_in_list() {
    _b="$1"; _list=$(printf '%s' "$2" | tr ',' ' '); _i=""
    for _i in $_list; do
        [ "$_b" = "$_i" ] && return 0
    done
    return 1
}

# --- Branch Discipline (HARD BLOCK) ---
PROTECTED="${CLAUDE_CONFIG_PROTECTED_BRANCHES:-{{default_branch}},master}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -n "$PROJECT_DIR" ] && { [ -d "$PROJECT_DIR/.git" ] || [ -f "$PROJECT_DIR/.git" ]; }; then
    CURRENT_BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [ -n "$CURRENT_BRANCH" ] && branch_in_list "$CURRENT_BRANCH" "$PROTECTED"; then
        case "$FILE_PATH" in
            *{{src_dir}}/*{{#has_frontend}}|*{{frontend_dir}}*{{/has_frontend}})
                cat >&2 <<MSG
[agent-enforcement] BLOCKED: '$CURRENT_BRANCH' is a protected branch — no direct edits.
Check out a typed branch first:
  git checkout -b feature/{{#branch_prefix}}{{branch_prefix}}-<#>-{{/branch_prefix}}<slug>
  git checkout -b fix/<slug>
  git checkout -b hotfix/<slug>
  git checkout -b refactor/<slug>
  git checkout -b chore/<slug>
Protected branches: $PROTECTED  (override with CLAUDE_CONFIG_PROTECTED_BRANCHES)
See .claude/HELP.md for the branch cheat sheet.
MSG
                exit 2
                ;;
        esac
    fi
fi

# --- Agent Guidance (ADVISORY — never blocks) ---
case "$FILE_PATH" in
{{#has_frontend}}
    *{{frontend_dir}}*)
        SCOPE="frontend"
        ;;
{{/has_frontend}}
    *{{src_dir}}/*)
        SCOPE="backend"
        ;;
    *)
        exit 0
        ;;
esac

# Trivial edit (≤50 lines AND ≤1 new def/class)? Pass silently.
if [ "${LINE_COUNT:-0}" -le 50 ] && [ "${DEF_COUNT:-0}" -le 1 ]; then
    exit 0
fi

case "$SCOPE" in
    backend)
        AGENT="{{primary_dev_agent}}"
        SCOPE_DESC="{{src_dir}} (backend code)"
        ;;
    frontend)
        AGENT="frontend-dev"
        SCOPE_DESC="{{frontend_dir}} (frontend code)"
        ;;
esac

cat >&2 <<MSG
[agent-enforcement] ADVISORY: sizable edit to ${SCOPE_DESC}.
  file:          ${FILE_PATH}
  added lines:   ${LINE_COUNT}  (advisory threshold: 50)
  new def/class: ${DEF_COUNT}   (advisory threshold: 1)

For non-trivial work, prefer the \`${AGENT}\` agent (Design First → implement on
a typed branch). This is guidance, not a block — proceed if you've already
scoped the change. See .claude/HELP.md for the decision tree.
MSG

exit 0
