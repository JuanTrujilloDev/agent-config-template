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
