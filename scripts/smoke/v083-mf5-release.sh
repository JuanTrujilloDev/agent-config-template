# v0.8.3 MF5 companion pin + release (@s32..@s36).
CLAUDE_COMPANIONS="$ROOT/plugin/commands/setup-companions.md"
CODEX_COMPANIONS="$ROOT/hosts/codex/skills/setup-companions/SKILL.md"
PIN='npm install -g ui-ux-pro-max-cli@2\.15\.0'

check "v0.8.3 @s32 Claude exact pin once" "1" "$(grep -cE "^ *$PIN" "$CLAUDE_COMPANIONS"; true)"
before "v0.8.3 @s32 Claude plan gate precedes pinned install" "$CLAUDE_COMPANIONS" '^2\. \*\*Show the plan and STOP' "$PIN"
grep_case "v0.8.3 @s32 Claude plan names source" "$CLAUDE_COMPANIONS" 'nextlevelbuilder/ui-ux-pro-max-skill'
grep_case "v0.8.3 @s32 Claude names written location" "$CLAUDE_COMPANIONS" '\.claude/skills/ui-ux-pro-max'
grep_case "v0.8.3 @s33 Claude explains unpinned latest" "$CLAUDE_COMPANIONS" 'unpinned|latest'
grep_case "v0.8.3 @s33 Claude companion stays optional" "$CLAUDE_COMPANIONS" '\*\*optional\*\*'
grep_case "v0.8.3 @s33 Claude companion stays UI-only" "$CLAUDE_COMPANIONS" 'UI projects only|only when requested or `has_ui`'

check "v0.8.3 @s34 Codex exact pin once" "1" "$(grep -cE "^ *$PIN" "$CODEX_COMPANIONS"; true)"
before "v0.8.3 @s34 Codex plan gate precedes pinned install" "$CODEX_COMPANIONS" '^2\. \*\*Show the plan and STOP' "$PIN"
grep_case "v0.8.3 @s34 Codex detects existing install" "$CODEX_COMPANIONS" '\.agents/skills/ui-ux-pro-max'
grep_case "v0.8.3 @s34 Codex explains unpinned latest" "$CODEX_COMPANIONS" 'unpinned|latest'
grep_case "v0.8.3 @s34 Codex keeps confirmation gate" "$CODEX_COMPANIONS" 'Install nothing without an explicit yes'

for manifest in plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json codex/.codex-plugin/plugin.json; do
  grep_case "v0.8.3 @s35 $manifest version" "$ROOT/$manifest" '"version": *"0\.8\.3"'
done
for manifest in plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  grep_case "v0.8.3 @s35 $manifest advertises seven skills" "$ROOT/$manifest" '7 skills'
done
check "v0.8.3 @s35 validator reports v0.8.3" "1" "$(cd "$ROOT" && python3 scripts/validate-packaging.py 2>&1 | grep -c 'packaging valid @ v0\.8\.3'; true)"

UPGRADE="$WORK/v083-upgrade.md"
section "$ROOT/docs/upgrade-guide.md" '^## Upgrading to v0\.8\.3' >"$UPGRADE"
grep_case "v0.8.3 @s36 upgrade section exists" "$UPGRADE" '^## Upgrading to v0\.8\.3'
grep_case "v0.8.3 @s36 upgrade names CRLF preference fix" "$UPGRADE" 'CRLF|carriage return'
grep_case "v0.8.3 @s36 upgrade names stdin replay fix" "$UPGRADE" 'stdin|--answers -'
grep_case "v0.8.3 @s36 upgrade names unique skip count" "$UPGRADE" '[Uu]nique.*skip|skip.*[Uu]nique|double-count'
grep_case "v0.8.3 @s36 upgrade names bundle recovery fix" "$UPGRADE" '[Bb]undle.*reinstall|reinstall.*[Bb]undle'
grep_case "v0.8.3 @s36 upgrade names host-neutral branch key" "$UPGRADE" 'AGENT_CONFIG_PROTECTED_BRANCHES'
grep_case "v0.8.3 @s36 upgrade names legacy fallback" "$UPGRADE" 'CLAUDE_CONFIG_PROTECTED_BRANCHES.*fallback|fallback.*CLAUDE_CONFIG_PROTECTED_BRANCHES'
grep_case "v0.8.3 @s36 upgrade names companion pin" "$UPGRADE" 'ui-ux-pro-max-cli@2\.15\.0'
grep_case "v0.8.3 @s36 upgrade refresh command" "$UPGRADE" 'claude plugin marketplace update juantrujillodev'
grep_case "v0.8.3 @s36 upgrade plugin command" "$UPGRADE" 'claude plugin update agent-config-template@juantrujillodev'

for answers in "$ROOT"/examples/*/answers.env; do
  example=$(basename "$(dirname "$answers")")
  for host in claude cursor grok codex; do
    target="$WORK/v083-$example-$host"
    bash "$ROOT/setup.sh" --target "$target" --answers "$answers" --host "$host" >/dev/null 2>&1; render_rc=$?
    check "v0.8.3 @s36 render $example/$host" "0" "$render_rc"
    check "v0.8.3 @s36 placeholders $example/$host" "0" "$(grep -rEl "$PH" "$target" 2>/dev/null | wc -l | tr -d ' ')"
    shell_rc=0
    while IFS= read -r shell_file; do bash -n "$shell_file" >/dev/null 2>&1 || shell_rc=1; done < <(find "$target" -type f -name '*.sh')
    check "v0.8.3 @s36 shell syntax $example/$host" "0" "$shell_rc"
    json_rc=0
    while IFS= read -r json_file; do python3 -m json.tool "$json_file" >/dev/null 2>&1 || json_rc=1; done < <(find "$target" -type f -name '*.json')
    check "v0.8.3 @s36 JSON parse $example/$host" "0" "$json_rc"
  done
done
