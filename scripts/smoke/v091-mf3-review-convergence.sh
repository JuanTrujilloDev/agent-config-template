# v0.9.1 MF3 bounded review convergence (@s17..@s25).
V091_MF3_DIR="$WORK/v091-mf3"
mkdir -p "$V091_MF3_DIR"

cat >"$V091_MF3_DIR/contract.md" <<'EOF'
- **@s1 [FR-001, SC-001]** Given a review, When validated, Then it converges.
EOF

cycle_case() { # NAME JSON_VALUE|absent EXPECTED_RC
  cycle_extra=
  [ "$2" = absent ] || cycle_extra=",\"review_cycles\":$2"
  printf '{"schema_version":2,"feature":"cycle","mini_features":[{"id":1,"name":"one","scenarios":["@s1"],"depends_on":[],"parallel":false,"files_hint":[],"max_files":1,"max_loc":10,"status":"pending","verified_by_human":"skipped"%s}]}' "$cycle_extra" >"$V091_MF3_DIR/features.json"
  python3 "$ROOT/scripts/validate-specs.py" "$V091_MF3_DIR/features.json" >/dev/null 2>&1
  check "v0.9.1 @s17/@s18 $1" "$3" "$?"
}

cycle_case "missing cycle defaults compatibly" absent 0
cycle_case "cycle zero accepted" 0 0
cycle_case "cycle two accepted" 2 0
cycle_case "negative cycle rejected" -1 1
cycle_case "cycle three rejected" 3 1
cycle_case "boolean cycle rejected" true 1
cycle_case "string cycle rejected" '"1"' 1

for f in "$ROOT/core/.claude/agents/pmo.md" "$ROOT/plugin/agents/pmo.md"; do
  grep_case "v0.9.1 @s17 $(basename "$f") initializes cycles" "$f" '"review_cycles": 0'
  grep_case "v0.9.1 @s17 $(basename "$f") old ledgers default zero" "$f" '[Aa]bsent.*review_cycles.*0|review_cycles.*absent.*0'
done

for f in "$ROOT/core/.claude/agents/orchestrator.md" "$ROOT/plugin/agents/orchestrator.md"; do
  grep_case "v0.9.1 @s19 $(basename "$f") bounded-loop pointer" "$f" '[Bb]ounded review-convergence loop.*sdd-workflow|sdd-workflow.*[Bb]ounded review-convergence loop'
done

for f in "$ROOT/docs/sdd-workflow.md" "$ROOT/plugin/skills/sdd-workflow/SKILL.md" "$ROOT/hosts/codex/skills/sdd-workflow/SKILL.md"; do
  label=$(basename "$f")
  grep_case "v0.9.1 @s17 $label initial cycle zero" "$f" '[Ii]nitial review.*cycle 0'
  grep_case "v0.9.1 @s19 $label increments before re-review" "$f" '[Ii]ncrement.*before.*re-review'
  grep_case "v0.9.1 @s20 $label all required approve" "$f" '[Ee]very required reviewer.*APPROVED'
  grep_case "v0.9.1 @s21 $label maximum two" "$f" '[Mm]aximum.*2.*fix.*re-review|[Aa]t most.*2.*fix.*re-review'
  grep_case "v0.9.1 @s21 $label no third cycle" "$f" '[Nn]ever.*third.*(cycle|re-review)'
  grep_case "v0.9.1 @s22 $label escalation artifact" "$f" 'progress/<mf>\.review-escalation\.md'
  grep_case "v0.9.1 @s22 $label both positions" "$f" '[Rr]eviewer position.*implementer position/evidence'
  grep_case "v0.9.1 @s22 $label human choices" "$f" '[Mm]inimal human choices'
  grep_case "v0.9.1 @s22 $label blocked state" "$f" '(mark|set).*mini-feature.*blocked'
  grep_case "v0.9.1 @s24 $label reset new feature" "$f" '[Rr]eset.*0.*new mini-feature'
  grep_case "v0.9.1 @s24 $label reset amendment" "$f" '[Rr]eset.*0.*reapproved contract amendment'
done

parity "v0.9.1 @s25 pmo cycle parity" 'review_cycles' "$ROOT/core/.claude/agents/pmo.md" "$ROOT/plugin/agents/pmo.md"
parity "v0.9.1 @s25 orchestrator convergence parity" 'bounded review-convergence loop' "$ROOT/core/.claude/agents/orchestrator.md" "$ROOT/plugin/agents/orchestrator.md"
