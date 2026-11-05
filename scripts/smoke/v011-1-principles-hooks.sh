# v0.11.0 chunk 1 — principles ≤80 lines, CLAUDE.md/HELP.md/settings.json, coding-reminder dropped,
# agent-enforcement keeps the branch block and gains the approved-tests lock (Q2).
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v011-1-principles-hooks.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0; V011_1_ALONE=1
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

DJ="$WORK/v011-django"
bash "$ROOT/setup.sh" --target "$DJ" --answers "$ROOT/examples/python-django/answers.env" >/dev/null 2>&1
check "v0.11 c1 render python-django" "0" "$?"

# Files chunk 1 owns, as rendered. The rest of the tree (agents, commands, other rules) is chunk 2+.
C1_FILES="$DJ/CLAUDE.md $DJ/.claude/HELP.md $DJ/.claude/settings.json $DJ/.claude/rules/principles.md $DJ/.claude/hooks/agent-enforcement.sh $DJ/.claude/hooks/auto-format.sh"
for f in $C1_FILES; do
  n=$(grep -cwE 'pmo|judge|orchestrator|coding-reminder' "$f" 2>/dev/null || true)
  check "v0.11 c1 no pmo/judge/orchestrator/coding-reminder in ${f#$DJ/}" "0" "${n:-0}"
  n=$(grep -cE "$PH" "$f" 2>/dev/null || true)
  check "v0.11 c1 no unrendered placeholder in ${f#$DJ/}" "0" "${n:-0}"
done
check "v0.11 c1 coding-reminder.sh not rendered" "absent" "$([ -e "$DJ/.claude/hooks/coding-reminder.sh" ] && echo present || echo absent)"
check "v0.11 c1 coding-reminder.sh dropped from core" "absent" "$([ -e "$ROOT/core/.claude/hooks/coding-reminder.sh" ] && echo present || echo absent)"
check "v0.11 c1 settings has no UserPromptSubmit" "0" "$(grep -c UserPromptSubmit "$DJ/.claude/settings.json")"
check "v0.11 c1 settings is valid JSON" "0" "$(python3 -m json.tool "$DJ/.claude/settings.json" >/dev/null 2>&1; echo $?)"
grep_case "v0.11 c1 settings allows Read(docs/epics/**)" "$DJ/.claude/settings.json" '"Read\(docs/epics/\*\*\)"'
grep_case "v0.11 c1 settings allows Write(docs/epics/**)" "$DJ/.claude/settings.json" '"Write\(docs/epics/\*\*\)"'

for h in "$ROOT"/core/.claude/hooks/*.sh "$DJ"/.claude/hooks/*.sh; do
  check "v0.11 c1 bash -n ${h#$ROOT/}" "0" "$(bash -n "$h" 2>/dev/null; echo $?)"
done
line_max "v0.11 c1 principles ≤80 lines (core)" "$ROOT/core/.claude/rules/principles.md" 80
line_max "v0.11 c1 principles ≤80 lines (rendered)" "$DJ/.claude/rules/principles.md" 80
line_max "v0.11 c1 CLAUDE.md ≤120 lines (rendered)" "$DJ/CLAUDE.md" 120
line_max "v0.11 c1 HELP.md ≤80 lines (rendered)" "$DJ/.claude/HELP.md" 80
for w in '/epic' '/slice' 'tests-first' 'implement' 'code-review'; do
  grep_case "v0.11 c1 CLAUDE.md names $w" "$DJ/CLAUDE.md" "$w"
  grep_case "v0.11 c1 HELP.md names $w" "$DJ/.claude/HELP.md" "$w"
done
check "v0.11 c1 build.sh --check" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"

# Hook behaviour on the rendered tree: branch block + approved-tests lock.
HOOK="$DJ/.claude/hooks/agent-enforcement.sh"
git -C "$DJ" init -q -b main
git -C "$DJ" -c user.name=Smoke -c user.email=smoke@example.invalid commit --allow-empty -qm init
edit_rc() { # path [env assignments...] — exit code of the hook for an Edit on path
  p="$1"; shift
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","new_string":"x"}}' "$p" \
    | env CLAUDE_PROJECT_DIR="$DJ" "$@" bash "$HOOK" >/dev/null 2>&1; echo $?
}
check "v0.11 c1 branch block on main for apps/" "2" "$(edit_rc "$DJ/apps/core/views.py")"
check "v0.11 c1 docs edit on main passes" "0" "$(edit_rc "$DJ/docs/notes.md")"
git -C "$DJ" checkout -q -b feature/PROJ-55-login-be
mkdir -p "$DJ/docs/epics/PROJ-55/slices"
cat >"$DJ/docs/epics/PROJ-55/slices/2.md" <<'SLICE'
# Slice 2 — be: OIDC callback
- Branch: `feature/PROJ-55-login-be`

## Approved tests
- `apps/auth/tests/test_sso.py`
SLICE
LOCKED="$DJ/apps/auth/tests/test_sso.py"
check "v0.11 c1 approved test locked" "2" "$(edit_rc "$LOCKED")"
check "v0.11 c1 relative path locked" "2" "$(cd "$DJ" && edit_rc apps/auth/tests/test_sso.py)"
check "v0.11 c1 AGENT_CONFIG_UNLOCK_TESTS=1 overrides" "0" "$(edit_rc "$LOCKED" AGENT_CONFIG_UNLOCK_TESTS=1)"
check "v0.11 c1 unlisted test editable" "0" "$(edit_rc "$DJ/apps/auth/tests/test_other.py")"
check "v0.11 c1 source file editable on slice branch" "0" "$(edit_rc "$DJ/apps/auth/views.py")"
git -C "$DJ" checkout -q -b feature/PROJ-55-login-fe
check "v0.11 c1 lock scoped to the slice branch" "0" "$(edit_rc "$LOCKED")"
check "v0.11 c1 malformed payload passes" "0" "$(printf 'not-json' | CLAUDE_PROJECT_DIR="$DJ" bash "$HOOK" >/dev/null 2>&1; echo $?)"

[ -n "${V011_1_ALONE:-}" ] && exit $FAIL
