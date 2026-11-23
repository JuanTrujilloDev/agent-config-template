# v0.13.0 item 6 — architect: three full designs, one consolidation, interrogation, Complexity, user approval.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v013-6-architect.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

AR="$ROOT/core/.claude/skills/architect"; AS="$AR/SKILL.md"; AT="$AR/design-template.md"
for f in SKILL.md design-template.md LICENSE-pstack.txt; do
  check "v0.13 i6 architect/$f exists" "present" "$([ -f "$AR/$f" ] && echo present || echo absent)"
done
grep_case "v0.13 i6 architect frontmatter name" "$AS" '^name: architect$'
check "v0.13 i6 architect has no {{placeholder}}" "0" "$(grep -c '{{' "$AS" "$AT" | awk -F: '{s+=$2} END {print s}')"
check "v0.13 i6 architect steps" "1. Brief three models: same inputs, a full design each|2. Consolidate: this thread, once|3. Interrogate before the user sees it|4. Hand back" "$(h2_list "$AS")"
grep_case "v0.13 i6 each model writes the whole design" "$AS" 'Each model writes the whole design'
grep_case "v0.13 i6 lead areas: Claude frontend" "$AS" '^\| Claude .*\| Frontend and design \|'
grep_case "v0.13 i6 lead areas: Codex backend" "$AS" '^\| Codex .*\| Backend \|'
grep_case "v0.13 i6 lead areas: Cursor security" "$AS" '^\| Cursor .*\| Security \|'
grep_case "v0.13 i6 delegates through T3 Code" "$AS" '`orchestrator_capabilities` once.*`delegate_task` per model'
grep_case "v0.13 i6 never substitutes a provider" "$AS" '\*\*never substitute\*\*'
grep_case "v0.13 i6 lead model wins by default" "$AS" 'lead model wins by default'
grep_case "v0.13 i6 a finding counts only when a run proves it" "$AS" 'A finding counts only when a run proves it'
grep_case "v0.13 i6 approval stays the user's" "$AS" 'Never write an approval the user did not give'
check "v0.13 i6 design template sections" "Interrogation|Consolidation|Disagreements|Screens|Backend|Security|Complexity|Last-resort error handling|Slices|Open questions" "$(h2_list "$AT")"
grep_case "v0.13 i6 Complexity columns" "$AT" '^\| Piece \| n is \| Time \| DB queries \| Memory \| Outside calls \| Checked by \|$'
grep_case "v0.13 i6 Complexity names n" "$AT" 'without "n of what" is a finding'
grep_case "v0.13 i6 epic takes the design's slices" "$ROOT/core/.claude/skills/epic/SKILL.md" 'Technical tasks are its slices'
grep_case "v0.13 i6 HELP routes UI features through architect" "$WORK/.claude/HELP.md" 'architect <design folder>'
grep_case "v0.13 i6 rendered architect skill" "$WORK/.claude/skills/architect/SKILL.md" '^name: architect$'
grep_case "v0.13 i6 codex architect gets the role note" "$ROOT/codex/skills/architect/SKILL.md" 'Codex'
check "v0.13 i6 plugin architect mirrors core" "0" "$(diff -r "$AR" "$ROOT/plugin/skills/architect" >/dev/null 2>&1; echo $?)"
