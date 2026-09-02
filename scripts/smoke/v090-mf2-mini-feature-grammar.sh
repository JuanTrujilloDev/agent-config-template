# v0.9.0 MF2 mini-feature grammar (@s7..@s13).
V090_MF2_VALIDATOR="$ROOT/scripts/validate-specs.py"
V090_MF2_DIR="$WORK/v090-mf2"
mkdir -p "$V090_MF2_DIR/valid" "$V090_MF2_DIR/legacy" "$V090_MF2_DIR/invalid" "$V090_MF2_DIR/types"

cat >"$V090_MF2_DIR/valid/contract.md" <<'EOF'
- **@s1 [FR-001, SC-001]** Given ready, When checked, Then valid.
- **@s2 [FR-001, SC-001]** Given ready, When checked, Then valid.
EOF
cat >"$V090_MF2_DIR/valid/features.json" <<'EOF'
{"schema_version":2,"feature":"valid","rules":{"one_at_a_time":true},"mini_features":[
{"id":1,"name":"first","scenarios":["@s1"],"depends_on":[],"parallel":false,"files_hint":[],"max_files":1,"max_loc":10,"status":"done","verified_by_human":"skipped"},
{"id":2,"name":"second","scenarios":["@s2"],"depends_on":[1],"parallel":false,"files_hint":["x.py"],"max_files":2,"max_loc":20,"status":"pending","verified_by_human":"no"}]}
EOF
cat >"$V090_MF2_DIR/legacy/features.json" <<'EOF'
{"feature":"legacy","rules":{"one_at_a_time":true},"mini_features":[
{"id":1,"name":"old-shape","scenarios":["@s1"],"max_files":1,"max_loc":10,"status":"done"}]}
EOF
cp "$V090_MF2_DIR/valid/contract.md" "$V090_MF2_DIR/legacy/contract.md"
cat >"$V090_MF2_DIR/invalid/contract.md" <<'EOF'
- **@s1 [FR-001, SC-001]** Given bad input, When checked, Then rejected.
EOF
cat >"$V090_MF2_DIR/invalid/features.json" <<'EOF'
{"schema_version":2,"feature":"invalid","mini_features":[
{"id":1,"name":"bad_name","scenarios":["@s1","@s99"],"depends_on":[1,99],"files_hint":"x.py","max_files":0,"max_loc":-1,"status":"wat","verified_by_human":"maybe"},
{"id":2,"name":"cycle-two","scenarios":["@s1"],"depends_on":[3],"parallel":false,"files_hint":[],"max_files":1,"max_loc":1,"status":"pending","verified_by_human":"skipped"},
{"id":3,"name":"cycle-two","scenarios":["@s1"],"depends_on":[2],"parallel":false,"files_hint":[],"max_files":1,"max_loc":1,"status":"pending","verified_by_human":"skipped"},
{"id":0,"name":"zero-id","scenarios":["@s1"],"depends_on":[],"parallel":false,"files_hint":[],"max_files":1,"max_loc":1,"status":"pending","verified_by_human":"skipped"}]}
EOF
cp "$V090_MF2_DIR/valid/contract.md" "$V090_MF2_DIR/types/contract.md"
cat >"$V090_MF2_DIR/types/features.json" <<'EOF'
{"schema_version":null,"feature":"types","mini_features":[
{"id":true,"name":[],"scenarios":"@s1","depends_on":[[]],"parallel":0,"files_hint":[1],"max_files":true,"max_loc":null,"status":[],"verified_by_human":[]}]}
EOF

python3 "$V090_MF2_VALIDATOR" "$V090_MF2_DIR/valid/features.json" >"$V090_MF2_DIR/valid.out" 2>&1
check "v0.9.0 @s7 strict valid ledger" "0" "$?"
python3 "$V090_MF2_VALIDATOR" "$V090_MF2_DIR/legacy/features.json" >"$V090_MF2_DIR/legacy.out" 2>&1
legacy_rc=$?
if grep -q '^ALLOW_LEGACY = True' "$V090_MF2_VALIDATOR"; then
  check "v0.9.0 @s12 legacy ledger accepted during MF2" "0" "$legacy_rc"
else
  check "v0.9.0 @s12 legacy window closed after migration" "1" "$legacy_rc"
fi
python3 "$V090_MF2_VALIDATOR" "$V090_MF2_DIR/invalid/features.json" >"$V090_MF2_DIR/invalid.out" 2>&1
check "v0.9.0 @s8 invalid ledger rejected" "1" "$?"
for token in parallel bad_name @s99 self-dependency 'unknown dependency' cycle 'duplicate name' 'duplicate scenario' '.id: expected positive integer' files_hint max_files max_loc status verified_by_human; do
  grep_case "v0.9.0 @s8 reports $token" "$V090_MF2_DIR/invalid.out" "$token"
done
python3 "$V090_MF2_VALIDATOR" "$V090_MF2_DIR/types/features.json" >"$V090_MF2_DIR/types.out" 2>&1
check "v0.9.0 @s7 malformed types rejected without traceback" "1" "$?"
check "v0.9.0 @s7 malformed types do not crash" "0" "$(grep -c Traceback "$V090_MF2_DIR/types.out"; true)"
grep_case "v0.9.0 @s7 explicit null schema rejected" "$V090_MF2_DIR/types.out" 'schema_version: unsupported'

for f in "$ROOT/core/.claude/agents/pmo.md" "$ROOT/plugin/agents/pmo.md"; do
  grep_case "v0.9.0 @s11 $(basename "$f") tracer bullet" "$f" '[Tt]racer bullet'
  grep_case "v0.9.0 @s11 $(basename "$f") all layers" "$f" '(every|required|all).*[Ll]ayer'
  grep_case "v0.9.0 @s11 $(basename "$f") independently demoable" "$f" '[Ii]ndependently demoable'
  grep_case "v0.9.0 @s11 $(basename "$f") one context" "$f" 'one context window'
  grep_case "v0.9.0 @s11 $(basename "$f") blockers" "$f" '[Dd]eclare.*blocker'
done
for f in "$ROOT/core/.claude/agents/orchestrator.md" "$ROOT/plugin/agents/orchestrator.md"; do
  grep_case "v0.9.0 @s9 $(basename "$f") depends_on ready" "$f" 'depends_on.*done|done.*depends_on'
  grep_case "v0.9.0 @s10 $(basename "$f") parallel is hint" "$f" 'parallel.*scheduling hint'
  grep_case "v0.9.0 @s10 $(basename "$f") gates still win" "$f" 'parallel.*never overrides.*(gate|one_at_a_time)'
done
grep_case "v0.9.0 @s13 CI runs spec validator" "$ROOT/.github/workflows/ci.yml" 'python3 scripts/validate-specs.py'
python3 "$V090_MF2_VALIDATOR" >"$V090_MF2_DIR/repo.out" 2>&1
check "v0.9.0 @s13 repository ledgers valid" "0" "$?"
