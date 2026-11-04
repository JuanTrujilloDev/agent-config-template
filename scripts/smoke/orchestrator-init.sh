# orchestrator-init: render the orchestrator skeleton into a temp dir.
# Plan mode writes nothing, --write never overwrites, no owner-specific data ships.
OI="$ROOT/plugin/skills/orchestrator-init"
OI_OUT="$WORK/oi/orch"
oi_render() { python3 -I "$OI/render.py" --target "$OI_OUT" --approver "Ada Lovelace" --tracker "Linear" "$@"; }
oi_has() { [ -e "$1" ] && echo yes || echo no; }

line_max "orchestrator-init SKILL.md <= 120 lines" "$OI/SKILL.md" 120
grep_case "orchestrator-init command points at the skill" "$ROOT/plugin/commands/orchestrator-init.md" 'orchestrator-init'
check "orchestrator-init no owner data in templates" "" \
  "$(grep -rEil '\bjuan\b|ricardo|pendi-|alternova|exchangifi|/Users/|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-' "$OI" 2>/dev/null)"

oi_render >"$WORK/oi-plan.txt" 2>&1
check "orchestrator-init plan exit 0" "0" "$?"
check "orchestrator-init plan writes nothing" "no" "$(oi_has "$OI_OUT")"
grep_case "orchestrator-init plan lists AGENTS.md" "$WORK/oi-plan.txt" 'create +AGENTS\.md'

oi_render --write >"$WORK/oi-write.txt" 2>&1
check "orchestrator-init write exit 0" "0" "$?"
for f in AGENTS.md bin/README.md bin/_common.py bin/state.py bin/render-progress.py bin/resource-check.py \
  bin/tracker-comment.py bin/archive-evidence.py state/SCHEMA.md plans/TEMPLATE.md inbox/README.md \
  outbox/README.md inbox/done/.gitkeep outbox/done/.gitkeep learnings/.gitkeep flakes/.gitkeep \
  skills/VENDORED.md schedules/progress-check.md schedules/config-review.md; do
  check "orchestrator-init renders $f" "yes" "$(oi_has "$OI_OUT/$f")"
done
check "orchestrator-init bin scripts executable" "yes" "$([ -x "$OI_OUT/bin/state.py" ] && echo yes || echo no)"
check "orchestrator-init bin scripts parse" "0" \
  "$(python3 -I -c 'import ast,sys; [ast.parse(open(p).read(), p) for p in sys.argv[1:]]' "$OI_OUT"/bin/*.py >/dev/null 2>&1; echo $?)"
check "orchestrator-init no render tokens left" "" "$(grep -rl '{{' "$OI_OUT" 2>/dev/null)"
grep_case "orchestrator-init approver filled" "$OI_OUT/AGENTS.md" 'Ada Lovelace'
grep_case "orchestrator-init tracker filled" "$OI_OUT/AGENTS.md" 'Linear'
grep_case "orchestrator-init AGENTS keeps placeholders" "$OI_OUT/AGENTS.md" '<[a-z][a-z ]+>' 3
for tier in Trivial Simple Medium Complex; do
  grep_case "orchestrator-init routing tier $tier" "$OI_OUT/AGENTS.md" "^\| $tier"
done
grep_case "orchestrator-init prints progress check prompt" "$WORK/oi-write.txt" 'Orchestrator progress check'
grep_case "orchestrator-init prints config review prompt" "$WORK/oi-write.txt" 'Config review \(bi-weekly\)'
grep_case "orchestrator-init progress check every 45 min" "$WORK/oi-write.txt" '45 min'

printf 'mine\n' >"$OI_OUT/AGENTS.md"
oi_render --write >"$WORK/oi-rerun.txt" 2>&1
check "orchestrator-init never overwrites" "mine" "$(cat "$OI_OUT/AGENTS.md")"
grep_case "orchestrator-init rerun reports skip" "$WORK/oi-rerun.txt" 'skip +AGENTS\.md'

# The rendered scripts resolve paths from their own folder, whatever it is named (needs PyYAML).
if python3 -c 'import yaml' 2>/dev/null; then
  python3 "$OI_OUT/bin/render-progress.py" --quiet >/dev/null 2>&1
  check "orchestrator-init render-progress writes into the folder" "yes" "$(oi_has "$OI_OUT/PROGRESS.md")"
else
  echo "SKIP orchestrator-init render-progress (PyYAML missing)"
fi
check "orchestrator-init codex mirror carries templates" "yes" \
  "$(oi_has "$ROOT/codex/skills/orchestrator-init/templates/bin/state.py")"
