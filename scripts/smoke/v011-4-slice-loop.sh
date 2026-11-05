# v0.11.0 item 4 — tests-first, implement, code-review, council skills; fix, verify, audit, pr adapted.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v011-4-slice-loop.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0; V011_4_ALONE=1
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

V4_S="$ROOT/core/.claude/skills"; V4_C="$ROOT/core/.claude/commands"
for f in tests-first/SKILL.md tests-first/tests.md tests-first/mocking.md implement/SKILL.md code-review/SKILL.md council/SKILL.md; do
  check "v0.11 i4 exists skills/$f" "present" "$([ -f "$V4_S/$f" ] && echo present || echo absent)"
done
for s in tests-first implement code-review council; do
  f="$V4_S/$s/SKILL.md"
  grep_case "v0.11 i4 $s frontmatter name" "$f" "^name: $s\$"
  check "v0.11 i4 $s has no {{placeholder}}" "0" "$(grep -c '{{' "$f")"
done
# Every skill and adapted command speaks slices: no scenario tags, ledgers or dropped roles.
for f in "$V4_S"/tests-first/SKILL.md "$V4_S"/implement/SKILL.md "$V4_S"/code-review/SKILL.md "$V4_S"/council/SKILL.md \
         "$V4_C"/fix.md "$V4_C"/verify.md "$V4_C"/audit.md "$V4_C"/pr.md "$V4_C"/design.md; do
  n=${f#$ROOT/core/.claude/}
  check "v0.11 i4 $n has no @s/FR/SC/ledger/features.json/docs/specs/agent_style" "0" \
    "$(grep -cE '@s[0-9]|FR-[0-9]|SC-[0-9]|features\.json|docs/specs|agent_style|mini-feature|[Ll]edger|(^|[^[:alnum:]])(pmo|judge)([^[:alnum:]]|$)' "$f")"
done

# tests-first: all tests for the slice, red run, user gate, approved paths recorded.
TF="$V4_S/tests-first/SKILL.md"
grep_case "v0.11 i4 tests-first names tests test_S<n>_<case>" "$TF" 'test_S<n>_<case>'
grep_case "v0.11 i4 tests-first pastes the red run" "$TF" 'red'
grep_case "v0.11 i4 tests-first stops for the user" "$TF" '[Ss]top'
grep_case "v0.11 i4 tests-first writes ## Approved tests" "$TF" '^## Approved tests$'
grep_case "v0.11 i4 tests-first records the approval commit" "$TF" '^Commit: `<sha>`'
check "v0.11 i4 tests-first dropped the horizontal-slicing ban" "0" "$(grep -c 'Horizontal slicing' "$TF")"
grep_case "v0.11 i4 tests.md kept" "$V4_S/tests-first/tests.md" '^# Good and Bad Tests'
grep_case "v0.11 i4 mocking.md kept" "$V4_S/tests-first/mocking.md" '^# When to Mock'

# implement: layer style, locked tests, DoD outputs, then code-review.
IM="$V4_S/implement/SKILL.md"
grep_case "v0.11 i4 implement loads backend-style" "$IM" 'backend-style'
grep_case "v0.11 i4 implement loads frontend-style" "$IM" 'frontend-style'
grep_case "v0.11 i4 implement never edits approved tests" "$IM" '[Nn]ever edit'
grep_case "v0.11 i4 implement ends with code-review" "$IM" 'code-review'
grep_case "v0.11 i4 implement push stays gated" "$IM" '[Pp]ush'

# code-review: pinned fixed point, two axes, test-diff gate, no tracker setup, one fix round.
CR="$V4_S/code-review/SKILL.md"
grep_case "v0.11 i4 code-review pins the fixed point" "$CR" 'git rev-parse'
grep_case "v0.11 i4 code-review three-dot diff" "$CR" '\.\.\.HEAD'
grep_case "v0.11 i4 code-review Standards axis" "$CR" '^## Standards|Standards'
grep_case "v0.11 i4 code-review Spec axis" "$CR" '\*\*Spec\*\*'
grep_case "v0.11 i4 code-review spec source is the slice file" "$CR" 'docs/epics/<ID>/slices/<n>\.md'
grep_case "v0.11 i4 code-review fails on approved-test diff" "$CR" 'Approved tests'
grep_case "v0.11 i4 code-review keeps the smell baseline" "$CR" 'Speculative Generality'
grep_case "v0.11 i4 code-review no rerank" "$CR" 'rerank'
grep_case "v0.11 i4 code-review one fix round" "$CR" 'one fix round'
check "v0.11 i4 code-review has no tracker-setup dependency" "0" "$(grep -ciE 'setup-matt-pocock|issue tracker should' "$CR")"

# council: opt-in, single round, named providers, never substitute.
CO="$V4_S/council/SKILL.md"
grep_case "v0.11 i4 council single round" "$CO" '[Ss]ingle round'
grep_case "v0.11 i4 council opt-in" "$CO" '[Oo]pt-in'
grep_case "v0.11 i4 council never substitutes" "$CO" '[Nn]ever substitute'
grep_case "v0.11 i4 council delegate_task" "$CO" 'delegate_task'

# Adapted commands.
grep_case "v0.11 i4 pr.md stacked base" "$V4_C/pr.md" 'stacked'
grep_case "v0.11 i4 pr.md 200–400 target" "$V4_C/pr.md" '200–400'
grep_case "v0.11 i4 pr.md links the slice" "$V4_C/pr.md" 'docs/epics/<ID>/slices/<n>\.md'
grep_case "v0.11 i4 verify.md looks up the slice file" "$V4_C/verify.md" 'docs/epics/\*/slices/\*\.md'
grep_case "v0.11 i4 fix.md runs code-review" "$V4_C/fix.md" 'code-review'
grep_case "v0.11 i4 audit.md Standards axis" "$V4_C/audit.md" 'Standards axis'

check "v0.11 i4 build.sh --check" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
[ -n "${V011_4_ALONE:-}" ] && exit $FAIL
