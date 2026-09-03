# v0.10.0 MF4 branch-guard-tokenizer (@s23..@s28).
SOURCE_GUARD="$ROOT/hosts/cursor/hooks/branch-guard.sh"
PLUGIN_GUARD="$ROOT/plugin/.cursor-plugin/hooks/branch-guard.sh"
GUARD_REPO="$WORK/v010-guard-repo"
mkdir -p "$GUARD_REPO"
git -C "$GUARD_REPO" init -q -b main
git -C "$GUARD_REPO" -c user.name=Smoke -c user.email=smoke@example.invalid commit --allow-empty -qm init

guard_permission() { # hook command
  payload=$(HOOK_COMMAND="$2" python3 -c 'import json,os; print(json.dumps({"command":os.environ["HOOK_COMMAND"]}))')
  (cd "$GUARD_REPO" && printf '%s' "$payload" | AGENT_CONFIG_PROTECTED_BRANCHES=main bash "$1") \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["permission"])'
}
guard_case() { # name command expected
  for hook in "$SOURCE_GUARD" "$PLUGIN_GUARD"; do
    check "$1 $(basename "$(dirname "$hook")")" "$3" "$(guard_permission "$hook" "$2")"
  done
}

# @s23 — direct/path-qualified/options.
guard_case "v0.10.0 @s23 direct commit" 'git commit -m test' deny
guard_case "v0.10.0 @s23 path push" '/usr/bin/git push origin main' deny
guard_case "v0.10.0 @s23 git option commit" 'git -C . commit --amend' deny
guard_case "v0.10.0 @s23 assignment push" 'TRACE=1 git push' deny

# @s24/@s25 — shell -c, command chains, newlines; quoted separators stay literal.
guard_case "v0.10.0 @s24 sh wrapper" 'sh -c "git push"' deny
guard_case "v0.10.0 @s24 bash lc wrapper" "/bin/bash -lc 'git commit -m nested'" deny
guard_case "v0.10.0 @s25 chained push" 'echo ready && git push' deny
NL_CMD=$(printf 'echo ready\ngit commit -m test')
guard_case "v0.10.0 @s25 newline commit" "$NL_CMD" deny
guard_case "v0.10.0 @s25 quoted separator" 'echo "ok; git push"' allow

# @s26/@s27 — literal/search/read/malformed forms fail open.
guard_case "v0.10.0 @s26 echo literal" 'echo "git push"' allow
guard_case "v0.10.0 @s26 printf literal" "printf '%s' 'git commit'" allow
guard_case "v0.10.0 @s26 git log grep" 'git log --grep=push' allow
guard_case "v0.10.0 @s26 git diff path" 'git diff HEAD -- push' allow
guard_case "v0.10.0 @s26 code search" 'rg "git push" .' allow
guard_case "v0.10.0 @s27 read-only git" 'git status --short' allow
guard_case "v0.10.0 @s27 malformed quote" "echo 'git push" allow
BAD=$(cd "$GUARD_REPO" && printf 'not-json' | AGENT_CONFIG_PROTECTED_BRANCHES=main bash "$SOURCE_GUARD")
check "v0.10.0 @s27 malformed payload allows" "allow" "$(printf '%s' "$BAD" | python3 -c 'import json,sys; print(json.load(sys.stdin)["permission"])')"
git -C "$GUARD_REPO" checkout -q -b feature/eval
check "v0.10.0 @s27 feature branch push allowed" "allow" "$(guard_permission "$SOURCE_GUARD" 'git push')"

# @s28 — syntax, generated copy, and honest docs.
check "v0.10.0 @s28 source hook syntax" "0" "$(bash -n "$SOURCE_GUARD" 2>/dev/null; echo $?)"
check "v0.10.0 @s28 plugin hook syntax" "0" "$(bash -n "$PLUGIN_GUARD" 2>/dev/null; echo $?)"
check "v0.10.0 @s28 rendered hook exact" "0" "$(diff -q "$SOURCE_GUARD" "$ROOT/cursor/.cursor/hooks/branch-guard.sh" >/dev/null 2>&1; echo $?)"
grep_case "v0.10.0 @s28 Cursor docs tokenized" "$ROOT/docs/install/cursor.md" '[Tt]okeniz'
grep_case "v0.10.0 @s28 matrix tokenized" "$ROOT/docs/install/host-capability-matrix.md" '[Tt]okeniz'
for file in "$ROOT/docs/install/cursor.md" "$ROOT/docs/install/host-capability-matrix.md"; do
  grep_case "v0.10.0 @s28 $(basename "$file") still guardrail" "$file" 'guardrail'
  grep_case "v0.10.0 @s28 $(basename "$file") not security boundary" "$file" 'not a security boundary'
done
