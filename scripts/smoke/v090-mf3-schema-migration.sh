# v0.9.0 MF3 schema version and migration (@s14..@s20).
V090_MF3_MIGRATOR="$ROOT/scripts/migrate-specs.py"
V090_MF3_FIXTURES="$ROOT/scripts/smoke/fixtures/spec-ledgers"
V090_MF3_WORK="$WORK/v090-mf3"
mkdir -p "$V090_MF3_WORK"

for fixture in "$V090_MF3_FIXTURES"/*.json; do
  name=$(basename "$fixture" .json)
  case_dir="$V090_MF3_WORK/$name"
  mkdir -p "$case_dir"
  cp "$fixture" "$case_dir/features.json"
  cp "$fixture" "$case_dir/before.json"
  cp "$ROOT/docs/specs/$name/contract.md" "$case_dir/contract.md"
  before_mode=$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$case_dir/features.json")

  python3 "$V090_MF3_MIGRATOR" "$case_dir/features.json" >"$case_dir/migrate.out" 2>&1
  check "v0.9.0 @s14 migrate $name" "0" "$?"
  python3 "$ROOT/scripts/validate-specs.py" "$case_dir/features.json" >"$case_dir/validate.out" 2>&1
  check "v0.9.0 @s14 validate $name" "0" "$?"
  python3 -c 'import json,sys; b=json.load(open(sys.argv[1])); a=json.load(open(sys.argv[2])); fields=("id","scenarios","max_files","max_loc","status"); assert b["feature"] == a["feature"]; assert [[x.get(k) for k in fields] for x in b["mini_features"]] == [[x.get(k) for k in fields] for x in a["mini_features"]]' "$case_dir/before.json" "$case_dir/features.json"
  check "v0.9.0 @s14 preserve $name ids/order/scenarios/limits/status" "0" "$?"
  check "v0.9.0 @s14 preserve $name mode" "$before_mode" "$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$case_dir/features.json")"
  check "v0.9.0 @s16 trailing newline $name" "10" "$(tail -c 1 "$case_dir/features.json" | od -An -t u1 | tr -d ' ')"
  cp "$case_dir/features.json" "$case_dir/once.json"
  python3 "$V090_MF3_MIGRATOR" "$case_dir/features.json" >/dev/null 2>&1
  check "v0.9.0 @s17 idempotent $name" "0" "$(cmp -s "$case_dir/once.json" "$case_dir/features.json"; echo $?)"
done

python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["schema_version"] == 2; m={x["id"]:x for x in d["mini_features"]}; assert m[8]["depends_on"] == [1]; assert "after" not in m[8]; assert m[1]["files_hint"] and "files" not in m[1]' "$V090_MF3_WORK/adaptive-skills/features.json"
check "v0.9.0 @s15 after/files migrated" "0" "$?"
python3 -c 'import json,sys; b=json.load(open(sys.argv[1])); a=json.load(open(sys.argv[2])); assert [x.get("verified_by_human") for x in b["mini_features"]] == [x["verified_by_human"] for x in a["mini_features"]]' "$V090_MF3_WORK/review-debt/before.json" "$V090_MF3_WORK/review-debt/features.json"
check "v0.9.0 @s16 existing verification preserved" "0" "$?"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); m=d["mini_features"]; assert m[0]["depends_on"] == []; assert m[1]["depends_on"] == [m[0]["id"]]; assert all(x["parallel"] is False for x in m); assert all("verified_by_human" in x for x in m)' "$V090_MF3_WORK/setup-evolution/features.json"
check "v0.9.0 @s16 defaults deterministic" "0" "$?"

cp "$V090_MF3_FIXTURES/setup-evolution.json" "$V090_MF3_WORK/legacy.json"
python3 "$ROOT/scripts/validate-specs.py" "$V090_MF3_WORK/legacy.json" >"$V090_MF3_WORK/legacy.out" 2>&1
check "v0.9.0 @s18 unversioned ledger rejected" "1" "$?"
grep_case "v0.9.0 @s19 validator names migration command" "$V090_MF3_WORK/legacy.out" 'python3 scripts/migrate-specs.py'
cat >"$V090_MF3_WORK/unknown.json" <<'EOF'
{"schema_version":3,"feature":"future","mini_features":[]}
EOF
cp "$V090_MF3_WORK/unknown.json" "$V090_MF3_WORK/unknown.before"
python3 "$V090_MF3_MIGRATOR" "$V090_MF3_WORK/unknown.json" >"$V090_MF3_WORK/unknown.out" 2>&1
check "v0.9.0 @s19 unknown migration rejected" "1" "$?"
check "v0.9.0 @s19 unknown migration untouched" "0" "$(cmp -s "$V090_MF3_WORK/unknown.before" "$V090_MF3_WORK/unknown.json"; echo $?)"

for f in "$ROOT/core/.claude/commands/feature.md" "$ROOT/plugin/commands/feature.md" "$ROOT/core/.claude/agents/orchestrator.md" "$ROOT/plugin/agents/orchestrator.md"; do
  grep_case "v0.9.0 @s19 $(basename "$f") rejects unsupported schema" "$f" '(unversioned|unknown|unsupported).*schema|schema.*(unversioned|unknown|unsupported)'
  grep_case "v0.9.0 @s19 $(basename "$f") migration recovery" "$f" 'python3 scripts/migrate-specs.py'
done
python3 "$ROOT/scripts/validate-specs.py" >"$V090_MF3_WORK/repo.out" 2>&1
check "v0.9.0 @s18 all live ledgers v2" "0" "$?"
check "v0.9.0 @s18 validator reports zero legacy" "0" "$(grep -c '[1-9][0-9]* legacy' "$V090_MF3_WORK/repo.out"; true)"
