#!/bin/bash
# Cursor beforeShellExecution hook — branch-guard adapter.
#
# Adapter over the protected-branch hard block in
# core/.claude/hooks/agent-enforcement.sh: same guard, Cursor payload schema
# (JSON with a `command` field on stdin; JSON verdict on stdout).
#
# Cursor has no native pre-edit gate (spec D5), so the block lands on the
# mutating git commands instead: `git commit` / `git push` on a protected
# branch are denied with the typed-branch guidance. Everything else — including
# an unparseable payload with no command — is allowed.
#
# Protected = $AGENT_CONFIG_PROTECTED_BRANCHES (or the legacy
# $CLAUDE_CONFIG_PROTECTED_BRANCHES), default "{{default_branch}},master".

set -uo pipefail

INPUT=$(cat)
export HOOK_INPUT="$INPUT"

allow() { printf '{"permission":"allow"}\n'; exit 0; }

CMD=$(python3 -c '
import json, os
try:
    data = json.loads(os.environ.get("HOOK_INPUT", ""))
    print(data.get("command") or "")
except Exception:
    pass
' 2>/dev/null) || CMD=""

[ -z "$CMD" ] && allow

# ponytail: word-scan, not a shell parser — "git ... commit|push" anywhere in
# the command line counts as a mutation. Newlines are flattened and quote/path
# boundaries count so `sh -c "git push"` and `/usr/bin/git push` still match.
# A false hit on a protected branch is a safe over-block; upgrade to real
# tokenizing if it ever bites.
if ! printf '%s' "$CMD" | tr '\n' ' ' | grep -Eq '(^|[[:space:];&|("'\''/=])git([[:space:]]+[^;&|]*)?[[:space:]](commit|push)([[:space:]"'\'']|$)'; then
    allow
fi

# Membership test for a comma/space-separated list (bash 3.2 safe) — same
# logic as core/.claude/hooks/agent-enforcement.sh.
branch_in_list() {
    _b="$1"; _list=$(printf '%s' "$2" | tr ',' ' '); _i=""
    for _i in $_list; do
        [ "$_b" = "$_i" ] && return 0
    done
    return 1
}

PROTECTED="${AGENT_CONFIG_PROTECTED_BRANCHES:-${CLAUDE_CONFIG_PROTECTED_BRANCHES:-{{default_branch}},master}}"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [ -z "$CURRENT_BRANCH" ] || ! branch_in_list "$CURRENT_BRANCH" "$PROTECTED"; then
    allow
fi

MSG="[branch-guard] BLOCKED: '$CURRENT_BRANCH' is a protected branch — no direct commits or pushes.
Check out a typed branch first:
  git checkout -b feature/{{#branch_prefix}}{{branch_prefix}}-<#>-{{/branch_prefix}}<slug>
  git checkout -b fix/<slug>
  git checkout -b hotfix/<slug>
  git checkout -b refactor/<slug>
  git checkout -b chore/<slug>
Protected branches: $PROTECTED  (override with AGENT_CONFIG_PROTECTED_BRANCHES)"

HOOK_MSG="$MSG" python3 -c '
import json, os
msg = os.environ["HOOK_MSG"]
print(json.dumps({"permission": "deny", "userMessage": msg, "agentMessage": msg}))
'
exit 0
