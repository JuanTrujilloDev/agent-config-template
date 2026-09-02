#!/bin/bash
# Cursor plugin guard: block commit/push from protected branches.

set -uo pipefail

INPUT=$(cat)
export HOOK_INPUT="$INPUT"

allow() { printf '{"permission":"allow"}\n'; exit 0; }

CMD=$(python3 -c '
import json, os
try:
    print(json.loads(os.environ.get("HOOK_INPUT", "")).get("command") or "")
except Exception:
    pass
' 2>/dev/null) || CMD=""

[ -z "$CMD" ] && allow

if ! printf '%s' "$CMD" | tr '\n' ' ' | grep -Eq '(^|[^[:alnum:]_])git([[:space:]]+[^;&|]*)?[[:space:]]+(commit|push)([^[:alnum:]_]|$)'; then
    allow
fi

branch_in_list() {
    _branch="$1"; _list=$(printf '%s' "$2" | tr ',' ' '); _item=""
    for _item in $_list; do
        [ "$_branch" = "$_item" ] && return 0
    done
    return 1
}

PROTECTED="${AGENT_CONFIG_PROTECTED_BRANCHES:-main,master}"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

if [ -z "$CURRENT_BRANCH" ] || ! branch_in_list "$CURRENT_BRANCH" "$PROTECTED"; then
    allow
fi

MSG="[branch-guard] BLOCKED: '$CURRENT_BRANCH' is protected. Check out feature/<slug>, fix/<slug>, hotfix/<slug>, refactor/<slug>, chore/<slug>, or docs/<slug> first. Protected branches: $PROTECTED"
HOOK_MSG="$MSG" python3 -c '
import json, os
msg = os.environ["HOOK_MSG"]
print(json.dumps({"permission": "deny", "userMessage": msg, "agentMessage": msg}))
'
