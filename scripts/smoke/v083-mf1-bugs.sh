# v0.8.3 MF1 hook + setup bugs (@s4..@s8).
SETUP="$ROOT/setup.sh"
ANS="$ROOT/examples/python-fastapi/answers.env"

# @s4 — selected hosts may revisit sources, but skip counts describe unique targets.
SINGLE="$WORK/v083-mf1-single"; MULTI="$WORK/v083-mf1-multi"
SINGLE_OUT=$(bash "$SETUP" --target "$SINGLE" --answers "$ANS" --host claude 2>&1)
MULTI_OUT=$(bash "$SETUP" --target "$MULTI" --answers "$ANS" --host claude,grok 2>&1)
SINGLE_SKIPPED=$(printf '%s\n' "$SINGLE_OUT" | sed -n 's/.*skipped \([0-9][0-9]*\) files.*/\1/p')
MULTI_SKIPPED=$(printf '%s\n' "$MULTI_OUT" | sed -n 's/.*skipped \([0-9][0-9]*\) files.*/\1/p')
check "v0.8.3 @s4 single-host skip count present" "1" "$([ -n "$SINGLE_SKIPPED" ] && echo 1 || echo 0)"
check "v0.8.3 @s4 multi-host skip count is unique" "$SINGLE_SKIPPED" "$MULTI_SKIPPED"

# @s5/@s6 — recovery text follows repo vs installed-bundle layout.
BUNDLE="$WORK/v083-mf1-bundle"; REPO_COPY="$WORK/v083-mf1-repo"
mkdir -p "$BUNDLE/template" "$REPO_COPY/core" "$REPO_COPY/scripts"
cp "$ROOT/plugin/setup.sh" "$BUNDLE/setup.sh"
cp "$ROOT/setup.sh" "$REPO_COPY/setup.sh"
cp "$ROOT/scripts/build.sh" "$REPO_COPY/scripts/build.sh"
BUNDLE_OUT=$(bash "$BUNDLE/setup.sh" --target "$WORK/v083-mf1-bundle-target" --answers "$ANS" --host cursor 2>&1); BUNDLE_RC=$?
REPO_OUT=$(bash "$REPO_COPY/setup.sh" --target "$WORK/v083-mf1-repo-target" --answers "$ANS" --host cursor 2>&1); REPO_RC=$?
check "v0.8.3 @s5 bundle missing tree exits 1" "1" "$BUNDLE_RC"
grep_case "v0.8.3 @s5 bundle says reinstall" <(printf '%s\n' "$BUNDLE_OUT") '[Rr]einstall|plugin update'
check "v0.8.3 @s5 bundle omits repo build hint" "0" "$(printf '%s\n' "$BUNDLE_OUT" | grep -c 'scripts/build\.sh'; true)"
check "v0.8.3 @s6 repo missing tree exits 1" "1" "$REPO_RC"
grep_case "v0.8.3 @s6 repo keeps build hint" <(printf '%s\n' "$REPO_OUT") 'scripts/build\.sh'

# @s7/@s8 — host-neutral protected list wins; legacy and defaults still work.
GUARD_REPO="$WORK/v083-mf1-guard-repo"
mkdir -p "$GUARD_REPO/src"
git -C "$GUARD_REPO" init -q
git -C "$GUARD_REPO" symbolic-ref HEAD refs/heads/main
printf 'x = 0\n' >"$GUARD_REPO/src/app.py"
git -C "$GUARD_REPO" add src/app.py
git -C "$GUARD_REPO" -c user.name=Smoke -c user.email=smoke@example.invalid commit -qm init
EDIT=$(printf '{"tool_input":{"file_path":"%s/src/app.py","new_string":"x = 1\\n"}}' "$GUARD_REPO")
CORE_GUARD="$WORK/.claude/hooks/agent-enforcement.sh"
PLUGIN_GUARD="$ROOT/plugin/hooks/agent-enforcement.sh"
run_guard() { # HOOK [ENV assignments via env command]
  hook=$1; shift
  GUARD_OUT=$(printf '%s' "$EDIT" | env "$@" CLAUDE_PROJECT_DIR="$GUARD_REPO" bash "$hook" 2>&1); GUARD_RC=$?
}
run_guard "$CORE_GUARD" AGENT_CONFIG_PROTECTED_BRANCHES=main CLAUDE_CONFIG_PROTECTED_BRANCHES=other
check "v0.8.3 @s7 core host-neutral key wins" "2" "$GUARD_RC"
grep_case "v0.8.3 @s7 core diagnostic names host-neutral key" <(printf '%s\n' "$GUARD_OUT") 'AGENT_CONFIG_PROTECTED_BRANCHES'
run_guard "$CORE_GUARD" AGENT_CONFIG_PROTECTED_BRANCHES=other CLAUDE_CONFIG_PROTECTED_BRANCHES=main
check "v0.8.3 @s7 core host-neutral key overrides legacy" "0" "$GUARD_RC"
run_guard "$PLUGIN_GUARD" AGENT_CONFIG_PROTECTED_BRANCHES=other CLAUDE_CONFIG_PROTECTED_BRANCHES=main
check "v0.8.3 @s7 plugin host-neutral key overrides legacy" "0" "$GUARD_RC"
run_guard "$CORE_GUARD" CLAUDE_CONFIG_PROTECTED_BRANCHES=main
check "v0.8.3 @s8 core legacy fallback" "2" "$GUARD_RC"
run_guard "$CORE_GUARD"
check "v0.8.3 @s8 core rendered default protects main" "2" "$GUARD_RC"
run_guard "$PLUGIN_GUARD" CLAUDE_CONFIG_PROTECTED_BRANCHES=main
check "v0.8.3 @s8 plugin legacy fallback" "2" "$GUARD_RC"
run_guard "$PLUGIN_GUARD"
check "v0.8.3 @s8 plugin default protects main" "2" "$GUARD_RC"
