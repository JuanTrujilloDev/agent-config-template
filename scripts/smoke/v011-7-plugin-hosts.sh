# v0.11.0 item 7 — plugin hand-authored side (agents, commands, hooks, manifests, README) and hosts/.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v011-7-plugin-hosts.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0; V011_7_ALONE=1
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

V7_P="$ROOT/plugin"
check "v0.11 i7 plugin agents" "security-reviewer.md ui-designer.md" "$(cd "$V7_P/agents" && echo *.md)"
check "v0.11 i7 plugin commands" "audit.md commit.md design.md fix.md integrate.md orchestrator-init.md pr.md setup-companions.md setup-template.md verify.md" \
  "$(cd "$V7_P/commands" && echo *.md)"
for f in skills/sdd-workflow hooks/coding-reminder.sh; do
  check "v0.11 i7 plugin/$f dropped" "absent" "$([ -e "$V7_P/$f" ] && echo present || echo absent)"
done
check "v0.11 i7 hosts/codex overrides" "port-config setup-companions" "$(cd "$ROOT/hosts/codex/skills" && echo *)"
check "v0.11 i7 hooks.json valid, no UserPromptSubmit" "PostToolUse PreToolUse" \
  "$(python3 -c 'import json,sys; print(" ".join(sorted(json.load(open(sys.argv[1]))["hooks"])))' "$V7_P/hooks/hooks.json" 2>&1)"

# The hand-authored plugin and host files name no dropped role, command or grammar.
V7_FILES=$(ls "$V7_P"/agents/*.md "$V7_P"/commands/*.md "$V7_P"/hooks/* "$V7_P"/README.md "$V7_P"/.claude-plugin/plugin.json \
  "$V7_P"/.cursor-plugin/rules/*.mdc "$V7_P"/skills/{principles,backend-style,frontend-style,port-config,lavish}/SKILL.md \
  "$ROOT"/hosts/cursor/AGENTS.md "$ROOT"/hosts/cursor/principles.mdc "$ROOT"/hosts/codex/note-role-adaptation.md \
  "$ROOT"/hosts/codex/skills/*/SKILL.md "$ROOT"/.cursor-plugin/plugin.json "$ROOT"/codex/.codex-plugin/plugin.json)
n=$(grep -nwE 'pmo|judge|backend-dev|frontend-dev|core-dev|desktop-dev|mobile-dev|game-dev|sdd-workflow|mini-feature|coding-reminder|agent_style|workflow_mode|enforce_layer_split|use_gherkin|primary_dev_agent' $V7_FILES \
  | grep -v 'retired' | tee "$WORK/v7-names.txt" | wc -l | tr -d ' ')
check "v0.11 i7 no dropped names in the plugin and hosts" "0" "$n"
[ "$n" = 0 ] || sed 's/^/    /' "$WORK/v7-names.txt"
n=$(grep -nE '(^|[^[:alnum:]:_-])/(spec|feature)([^[:alnum:]_-]|$)|agent-config-template:(spec|feature)\b|docs/specs/' $V7_FILES | grep -vE 'update-config|migrat' | tee "$WORK/v7-cmds.txt" | wc -l | tr -d ' ')
check "v0.11 i7 no /spec, /feature or docs/specs" "0" "$n"
[ "$n" = 0 ] || sed 's/^/    /' "$WORK/v7-cmds.txt"
check "v0.11 i7 plugin files placeholder-free" "0" "$(grep -lE "$PH" $V7_FILES | grep -v 'hosts/' | wc -l | tr -d ' ')"
line_max "v0.11 i7 plugin principles ≤90 lines" "$V7_P/skills/principles/SKILL.md" 90
grep_case "v0.11 i7 plugin principles locks approved tests" "$V7_P/skills/principles/SKILL.md" 'Approved tests'
grep_case "v0.11 i7 setup-template points to update-config" "$V7_P/commands/setup-template.md" 'update-config'
grep_case "v0.11 i7 README lists the slice loop" "$V7_P/README.md" 'tests-first'
grep_case "v0.11 i7 cursor AGENTS.md runs the slice loop" "$ROOT/hosts/cursor/AGENTS.md" '/epic'

# Plugin hook: branch block and approved-tests lock, same behaviour as core.
V7_H="$V7_P/hooks/agent-enforcement.sh"
check "v0.11 i7 bash -n plugin hook" "0" "$(bash -n "$V7_H" 2>/dev/null; echo $?)"
V7_R="$WORK/v7-repo"; mkdir -p "$V7_R/docs/epics/X/slices" "$V7_R/src" "$V7_R/tests"
git -C "$V7_R" init -q -b main && git -C "$V7_R" -c user.email=s@x -c user.name=s commit -q --allow-empty -m init
printf -- '- Branch: `feature/X-a-be`\n\n## Approved tests\nCommit: `abc1234`\n- `tests/test_a.py`\n' >"$V7_R/docs/epics/X/slices/1.md"
V7_RUN() { printf '{"tool_input":{"file_path":"%s"}}' "$1" | CLAUDE_PROJECT_DIR="$V7_R" AGENT_CONFIG_UNLOCK_TESTS="${2:-}" bash "$V7_H" >/dev/null 2>&1; echo $?; }
check "v0.11 i7 plugin hook blocks src/ on main" "2" "$(V7_RUN "$V7_R/src/app.py")"
git -C "$V7_R" checkout -q -b feature/X-a-be
check "v0.11 i7 plugin hook locks an approved test" "2" "$(V7_RUN "$V7_R/tests/test_a.py")"
check "v0.11 i7 plugin hook unlock override" "0" "$(V7_RUN "$V7_R/tests/test_a.py" 1)"
check "v0.11 i7 plugin hook allows source on the slice branch" "0" "$(V7_RUN "$V7_R/src/app.py")"

# Rendered cursor tree (node-nextjs) carries the new AGENTS.md.
V7_C="$WORK/v7-cursor"
bash "$ROOT/setup.sh" --target "$V7_C" --answers "$ROOT/examples/node-nextjs/answers.env" --host cursor >/dev/null 2>&1
check "v0.11 i7 cursor AGENTS.md has no dropped agent" "0" "$(grep -cwE 'pmo|judge|orchestrator|frontend-dev' "$V7_C/AGENTS.md")"

check "v0.11 i7 check-override-headings.py" "0" "$(cd "$ROOT" && python3 scripts/check-override-headings.py >/dev/null 2>&1; echo $?)"
check "v0.11 i7 validate-packaging.py" "0" "$(cd "$ROOT" && python3 scripts/validate-packaging.py >/dev/null 2>&1; echo $?)"
check "v0.11 i7 build.sh --check" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
[ -n "${V011_7_ALONE:-}" ] && exit $FAIL
