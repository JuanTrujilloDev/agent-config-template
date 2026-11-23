# v0.13.0 item 7 — scope-page: flows first; after design approval, slices per flow and a Plan checklist from progress files.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v013-7-scope-page.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

SP="$ROOT/core/.claude/skills/scope-page"
for f in SKILL.md build.mjs page.js verify.mjs build.test.mjs tokens.css example/content.mjs example/capture.svg example/progress/1.json; do
  check "v0.13 i7 scope-page/$f exists" "present" "$([ -f "$SP/$f" ] && echo present || echo absent)"
done
grep_case "v0.13 i7 frontmatter name" "$SP/SKILL.md" '^name: scope-page$'
check "v0.13 i7 no {{ in the skill (stays generic)" "0" "$(grep -rl '{{' "$SP" | wc -l | tr -d ' ')"
check "v0.13 i7 no ExchangiFi leftovers" "0" "$(grep -rli 'exchangi\|static_src\|docs/scope-page' "$SP" | wc -l | tr -d ' ')"
grep_case "v0.13 i7 plan comes after design approval" "$SP/SKILL.md" 'Only now add `plan`'
grep_case "v0.13 i7 one progress file per slice thread" "$SP/SKILL.md" 'One writer per file'
grep_case "v0.13 i7 implement writes progress" "$ROOT/core/.claude/skills/implement/SKILL.md" '^10\. \*\*Progress\.\*\*.*_build/progress/<n>\.json'
grep_case "v0.13 i7 tests-first writes tests approved" "$ROOT/core/.claude/skills/tests-first/SKILL.md" 'status `tests approved`'
check "v0.13 i7 plugin scope-page mirrors core" "0" "$(diff -r "$SP" "$ROOT/plugin/skills/scope-page" >/dev/null 2>&1; echo $?)"
check "v0.13 i7 rendered scope-page" "present" "$([ -f "$WORK/.claude/skills/scope-page/build.mjs" ] && echo present || echo absent)"

if command -v node >/dev/null 2>&1; then
  V13_O="$WORK/v013-scope"
  V13_OUT=$(node "$SP/build.mjs" "$SP/example/content.mjs" "$V13_O" 2>&1); V13_RC=$?
  check "v0.13 i7 builds the example" "0" "$V13_RC"
  grep_case "v0.13 i7 checklist reads the progress file" "$V13_O/plan-checklist.md" '^- \[ \] \*\*1 · be\*\* Export job and endpoint · review · !12$'
  grep_case "v0.13 i7 checklist lists an untouched slice as todo" "$V13_O/plan-checklist.md" '^- \[ \] \*\*2 · fe\*\* Button and notification · todo$'
  grep_case "v0.13 i7 page embeds the plan" "$V13_O/index.html" '"plan":\{"slices"'
  check "v0.13 i7 builder's own tests pass" "0" "$(node --test "$SP/build.test.mjs" >/dev/null 2>&1; echo $?)"
else
  echo "SKIP v0.13 i7 node not installed; builder not exercised"
fi
