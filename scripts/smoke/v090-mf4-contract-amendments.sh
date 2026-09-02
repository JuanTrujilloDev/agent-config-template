# v0.9.0 MF4 contract amendments (@s21..@s27).
V090_MF4_DIR="$WORK/v090-mf4"
mkdir -p "$V090_MF4_DIR"

cat >"$V090_MF4_DIR/contract.md" <<'EOF'
- **@s1 [FR-001, SC-001]** Given an amendment, When validated, Then it is accepted.
EOF
cat >"$V090_MF4_DIR/features.json" <<'EOF'
{"schema_version":2,"feature":"amendment","mini_features":[
{"id":1,"name":"changed","scenarios":["@s1"],"depends_on":[],"parallel":false,"files_hint":[],"max_files":1,"max_loc":10,"status":"needs-rework","verified_by_human":"skipped"}]}
EOF
python3 "$ROOT/scripts/validate-specs.py" "$V090_MF4_DIR/features.json" >"$V090_MF4_DIR/valid.out" 2>&1
check "v0.9.0 @s26 needs-rework accepted" "0" "$?"
sed 's/needs-rework/changed-again/' "$V090_MF4_DIR/features.json" >"$V090_MF4_DIR/invalid.json"
python3 "$ROOT/scripts/validate-specs.py" "$V090_MF4_DIR/invalid.json" >"$V090_MF4_DIR/invalid.out" 2>&1
check "v0.9.0 @s26 unknown status rejected" "1" "$?"

for f in "$ROOT/core/.claude/agents/pmo.md" "$ROOT/plugin/agents/pmo.md"; do
  grep_case "v0.9.0 @s21 $(basename "$f") exact amendment marker" "$f" '\*\(Amended at <ISO date/time> — <reason>\)\*'
  grep_case "v0.9.0 @s22 $(basename "$f") pending reset" "$f" 'pending.*spec_ready.*pending'
  grep_case "v0.9.0 @s22 $(basename "$f") rework sources" "$f" 'in_progress.*done'
  grep_case "v0.9.0 @s22 $(basename "$f") rework target" "$f" 'needs-rework'
  grep_case "v0.9.0 @s22 $(basename "$f") blocked reassessment" "$f" 'blocked.*remains blocked.*reassess'
  grep_case "v0.9.0 @s23 $(basename "$f") transitive reset" "$f" 'transitive dependents'
  grep_case "v0.9.0 @s23 $(basename "$f") unrelated preserved" "$f" '[Uu]nrelated.*status'
done

for f in "$ROOT/core/.claude/commands/feature.md" "$ROOT/plugin/commands/feature.md" "$ROOT/core/.claude/agents/orchestrator.md" "$ROOT/plugin/agents/orchestrator.md"; do
  grep_case "v0.9.0 @s24 $(basename "$f") gate ledger" "$f" 'progress/gate1\.md'
  grep_case "v0.9.0 @s24 $(basename "$f") stale approval" "$f" '[Ss]tale Gate 1'
  grep_case "v0.9.0 @s24 $(basename "$f") refusal" "$f" '[Rr]efuse.*implementation'
  grep_case "v0.9.0 @s25 $(basename "$f") approval timestamp/text" "$f" 'timestamp.*approver text'
  grep_case "v0.9.0 @s25 $(basename "$f") approval amendment ref" "$f" 'amendment reference'
  grep_case "v0.9.0 @s25 $(basename "$f") resume first" "$f" 'first'
  grep_case "v0.9.0 @s25 $(basename "$f") resume ready" "$f" 'ready (mini-feature|item)'
  grep_case "v0.9.0 @s26 $(basename "$f") rework dependency rules" "$f" 'needs-rework.*dependenc'
done

for f in "$ROOT/docs/sdd-workflow.md" "$ROOT/plugin/skills/sdd-workflow/SKILL.md" "$ROOT/hosts/codex/skills/sdd-workflow/SKILL.md"; do
  grep_case "v0.9.0 @s27 $(basename "$f") amendment marker" "$f" 'Amended at <ISO date/time>'
  grep_case "v0.9.0 @s27 $(basename "$f") transitive reset" "$f" 'transitive dependents'
  grep_case "v0.9.0 @s27 $(basename "$f") gate ledger" "$f" 'progress/gate1\.md'
  grep_case "v0.9.0 @s27 $(basename "$f") reapproval timestamp/text" "$f" 'timestamp.*approver text'
  grep_case "v0.9.0 @s27 $(basename "$f") reapproval amendment ref" "$f" 'amendment reference'
done
