# v0.13.0 item 9 — worked example: EXAMPLE epic with an approved design, a plan and progress files; the guide.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v013-9-example.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

EX="$ROOT/docs/epics/EXAMPLE"; DM="$EX/design/design.md"
V13_TPL=$(h2_list "$ROOT/core/.claude/skills/architect/design-template.md")
check "v0.13 i9 example design follows the template" "Round 1 decisions (the reviewer, 2026-10-30)|$V13_TPL" "$(h2_list "$DM")"
grep_case "v0.13 i9 example design says it is invented" "$DM" 'Worked example with invented code'
grep_case "v0.13 i9 example Complexity names n" "$DM" '^\| `sweep_revoked_sso` \| linked identities \| O\(n\)'
grep_case "v0.13 i9 epic cites the design" "$EX/epic.md" '^Design: `docs/epics/EXAMPLE/design/design\.md`, approved'
grep_case "v0.13 i9 slice 2 lists the Complexity tests" "$EX/slices/2.md" '→ Complexity$' 2
check "v0.13 i9 design last-resort row == slice 2 row" \
  "$(grep -F '| `apps/accounts/tasks/sso_tasks.py` | `sweep_revoked_sso` |' "$DM")" \
  "$(grep -F '| `apps/accounts/tasks/sso_tasks.py` | `sweep_revoked_sso` |' "$EX/slices/2.md")"
check "v0.13 i9 plan slice ids == slice files" "1 2 3" \
  "$(grep -oE "\{ id: '[0-9]+'" "$EX/design/_build/content.mjs" | grep -oE '[0-9]+' | paste -sd' ' -)"
check "v0.13 i9 slice files" "1.md 2.md 3.md" "$(cd "$EX/slices" && echo *.md)"
grep_case "v0.13 i9 guide walks the seven steps" "$ROOT/docs/guides/plan-design-build.md" '^\| 7 \| Code \|'
grep_case "v0.13 i9 built example page is gitignored" "$ROOT/.gitignore" '^/docs/epics/\*/design/scope/$'
if command -v node >/dev/null 2>&1; then
  node "$ROOT/core/.claude/skills/scope-page/build.mjs" "$EX/design/_build/content.mjs" "$WORK/v013-example" >/dev/null 2>&1
  check "v0.13 i9 example page builds" "0" "$?"
  grep_case "v0.13 i9 checklist: slice 1 done" "$WORK/v013-example/plan-checklist.md" '^- \[x\] \*\*1 · db\*\*'
  grep_case "v0.13 i9 checklist: slice 2 in review" "$WORK/v013-example/plan-checklist.md" '^- \[ \] \*\*2 · be\*\* .* · review · #43$'
else
  echo "SKIP v0.13 i9 node not installed; example page not built"
fi
