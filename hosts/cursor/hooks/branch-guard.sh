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

# Tokenize known shell forms so literal mentions do not look executable.
MUTATION=$(HOOK_COMMAND="$CMD" python3 - <<'PY'
import os
import posixpath
import re
import shlex

CONTROL = ";&|()\n"
SHELLS = {"bash", "dash", "ksh", "sh", "zsh"}
GIT_VALUE_OPTIONS = {
    "-C", "-c", "--config-env", "--exec-path", "--git-dir", "--namespace",
    "--super-prefix", "--work-tree",
}
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")


def tokens(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=CONTROL)
    lexer.whitespace = " \t\r"
    lexer.whitespace_split = True
    lexer.commenters = "#"
    return list(lexer)


def segments(command):
    current = []
    for token in tokens(command):
        if token and all(char in CONTROL for char in token):
            if current:
                yield current
                current = []
        else:
            current.append(token)
    if current:
        yield current


def git_mutates(words):
    index = 1
    while index < len(words):
        value = words[index]
        if value == "--":
            index += 1
            break
        if not value.startswith("-"):
            break
        if value in GIT_VALUE_OPTIONS and index + 1 < len(words):
            index += 2
        else:
            index += 1
    return index < len(words) and words[index] in {"commit", "push"}


def argv_mutates(words, depth):
    index = 0
    while index < len(words) and ASSIGNMENT.match(words[index]):
        index += 1
    if index >= len(words):
        return False
    command = posixpath.basename(words[index])
    args = words[index:]
    if command in {"command", "exec"}:
        next_index = 1
        while next_index < len(args) and args[next_index].startswith("-"):
            next_index += 1
        return argv_mutates(args[next_index:], depth)
    if command == "env":
        next_index = 1
        while next_index < len(args) and (args[next_index].startswith("-") or ASSIGNMENT.match(args[next_index])):
            next_index += 1
        return argv_mutates(args[next_index:], depth)
    if command in SHELLS and depth < 4:
        for option_index, option in enumerate(args[1:], 1):
            if option.startswith("-") and "c" in option[1:] and option_index + 1 < len(args):
                return command_mutates(args[option_index + 1], depth + 1)
        return False
    return command == "git" and git_mutates(args)


def command_mutates(command, depth=0):
    try:
        return any(argv_mutates(part, depth) for part in segments(command))
    except (TypeError, ValueError):
        return False


print("yes" if command_mutates(os.environ.get("HOOK_COMMAND", "")) else "no")
PY
) || MUTATION="no"

[ "$MUTATION" = "yes" ] || allow

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
