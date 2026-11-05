# v0.11.0 item 5 — style, code-query and patterns are skills; rules/ keeps principles only;
# build.sh mirrors placeholder-free core skills into plugin/skills, codex and cursor.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v011-5-skills-mirror.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0; V011_5_ALONE=1
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

V5_S="$ROOT/core/.claude/skills"
check "v0.11 i5 core rules/ holds principles only" "principles.md" "$(cd "$ROOT/core/.claude/rules" && echo *.md)"
check "v0.11 i5 core .claude/patterns/ gone" "absent" "$([ -e "$ROOT/core/.claude/patterns" ] && echo present || echo absent)"
for s in backend-style frontend-style code-query patterns; do
  check "v0.11 i5 core skill $s" "present" "$([ -f "$V5_S/$s/SKILL.md" ] && echo present || echo absent)"
done
check "v0.11 i5 patterns references" "backend.md concurrency.md desktop.md frontend.md game.md mobile.md" \
  "$(cd "$V5_S/patterns/references" 2>/dev/null && echo *.md)"
check "v0.11 i5 code-query speaks slices" "0" "$(grep -c 'mini-feature' "$V5_S/code-query/SKILL.md")"
check "v0.11 i5 patterns has no ledger wording" "0" "$(grep -ciE 'ledger|mini-feature|Design notes' "$V5_S/patterns/SKILL.md")"
n=$(grep -rnE '\.claude/rules/(backend-style|frontend-style|code-query|patterns)|\.claude/patterns/' "$ROOT/core" "$ROOT/hosts" | tee "$WORK/v5-refs.txt" | wc -l | tr -d ' ')
check "v0.11 i5 no reference to the old rule paths in core/ or hosts/" "0" "$n"
[ "$n" = 0 ] || sed 's/^/    /' "$WORK/v5-refs.txt"
line_max "v0.11 i5 principles still ≤80 lines" "$ROOT/core/.claude/rules/principles.md" 80

# build.sh: placeholder-free core skills are copied verbatim into plugin/skills; style skills stay hand-authored.
for s in epic slice tests-first implement code-review council code-query patterns; do
  check "v0.11 i5 plugin/skills/$s == core" "same" "$(diff -r "$V5_S/$s" "$ROOT/plugin/skills/$s" >/dev/null 2>&1 && echo same || echo differs)"
done
check "v0.11 i5 plugin backend-style stays generic" "0" "$(grep -c '{{' "$ROOT/plugin/skills/backend-style/SKILL.md")"
for s in epic slice implement code-review tests-first; do
  check "v0.11 i5 codex skill $s" "present" "$([ -f "$ROOT/codex/skills/$s/SKILL.md" ] && echo present || echo absent)"
  check "v0.11 i5 codex $s has one name: line" "1" "$(grep -c '^name: ' "$ROOT/codex/skills/$s/SKILL.md" 2>/dev/null)"
done
check "v0.11 i5 codex patterns references ride along" "present" "$([ -f "$ROOT/codex/skills/patterns/references/backend.md" ] && echo present || echo absent)"

# Cursor: one .mdc rule (principles), every core skill under .claude/skills/.
check "v0.11 i5 cursor .cursor/rules holds principles.mdc only" "principles.mdc" "$(cd "$ROOT/cursor/.cursor/rules" && echo *.mdc)"
for s in epic slice tests-first implement code-review council backend-style frontend-style code-query patterns; do
  check "v0.11 i5 cursor .claude/skills/$s" "present" "$([ -f "$ROOT/cursor/.claude/skills/$s/SKILL.md" ] && echo present || echo absent)"
done
V5_C="$WORK/v5-cursor"
bash "$ROOT/setup.sh" --target "$V5_C" --answers "$ROOT/examples/node-nextjs/answers.env" --host cursor >/dev/null 2>&1
check "v0.11 i5 cursor render" "0" "$?"
check "v0.11 i5 cursor render one .mdc" "principles.mdc" "$(cd "$V5_C/.cursor/rules" && echo *.mdc)"
check "v0.11 i5 cursor render no placeholder" "0" "$(grep -rlE "$PH" "$V5_C" | wc -l | tr -d ' ')"

# Claude render: style skills render, frontend-style only with a frontend.
V5_D="$WORK/v5-django"
bash "$ROOT/setup.sh" --target "$V5_D" --answers "$ROOT/examples/python-django/answers.env" >/dev/null 2>&1
check "v0.11 i5 django rules/" "principles.md" "$(cd "$V5_D/.claude/rules" && echo *.md)"
grep_case "v0.11 i5 django backend-style skill rendered" "$V5_D/.claude/skills/backend-style/SKILL.md" '^name: backend-style$'
check "v0.11 i5 django skills placeholder-free" "0" "$(grep -rlE "$PH" "$V5_D/.claude/skills" | wc -l | tr -d ' ')"
V5_F="$WORK/v5-fastapi"
bash "$ROOT/setup.sh" --target "$V5_F" --answers "$ROOT/examples/python-fastapi/answers.env" >/dev/null 2>&1
check "v0.11 i5 no frontend → no frontend-style skill" "absent" "$([ -e "$V5_F/.claude/skills/frontend-style/SKILL.md" ] && echo present || echo absent)"

check "v0.11 i5 check-override-headings.py" "0" "$(cd "$ROOT" && python3 scripts/check-override-headings.py >/dev/null 2>&1; echo $?)"
check "v0.11 i5 build.sh --check" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
seed_check "v0.11 i5 --check flags drift in a mirrored skill" "$ROOT/plugin/skills/epic/SKILL.md"
check "v0.11 i5 validate-packaging.py" "0" "$(cd "$ROOT" && python3 scripts/validate-packaging.py >/dev/null 2>&1; echo $?)"
[ -n "${V011_5_ALONE:-}" ] && exit $FAIL
