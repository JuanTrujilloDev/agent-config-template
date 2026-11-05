# v0.11.0 item 6 — update-config skill + migrate.py; this repo's docs/specs/ migrated (Q4);
# workflow_mode, use_gherkin, enforce_layer_split retired with one warning (Q5).
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v011-6-update-config.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0; V011_6_ALONE=1
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

V6_UC="$ROOT/core/.claude/skills/update-config"
V6_MIG="$V6_UC/migrate.py"
V6_VAL="$ROOT/core/.claude/skills/epic/validate-epics.py"
for f in SKILL.md migrate.py; do
  check "v0.11 i6 update-config/$f exists" "present" "$([ -f "$V6_UC/$f" ] && echo present || echo absent)"
done
grep_case "v0.11 i6 update-config is user-invoked" "$V6_UC/SKILL.md" '^disable-model-invocation: true$'
grep_case "v0.11 i6 update-config refuses without lock + answers" "$V6_UC/SKILL.md" 'agent-config\.lock\.json'
grep_case "v0.11 i6 update-config plans with setup.sh" "$V6_UC/SKILL.md" 'STALE-MANAGED'
grep_case "v0.11 i6 update-config never touches CUSTOMIZED" "$V6_UC/SKILL.md" 'CUSTOMIZED-\*'
grep_case "v0.11 i6 update-config runs migrate.py --apply" "$V6_UC/SKILL.md" 'migrate\.py --apply'
grep_case "v0.11 i6 update-config commits on chore/" "$V6_UC/SKILL.md" 'chore\(config\): update agent-config-template'
check "v0.11 i6 update-config has no {{placeholder}}" "0" "$(grep -c '{{' "$V6_UC/SKILL.md")"
check "v0.11 i6 plugin/skills/update-config == core" "same" "$(diff -r "$V6_UC" "$ROOT/plugin/skills/update-config" >/dev/null 2>&1 && echo same || echo differs)"

# This repo dogfooded the migration: docs/specs/ is gone, every slug archived.
check "v0.11 i6 docs/specs/ removed" "absent" "$([ -e "$ROOT/docs/specs" ] && echo present || echo absent)"
check "v0.11 i6 eight specs archived" "8" "$(ls -d "$ROOT"/docs/epics/archive/*/ 2>/dev/null | wc -l | tr -d ' ')"
check "v0.11 i6 dropped validate-specs.py and migrate-specs.py" "absent absent" \
  "$([ -e "$ROOT/scripts/validate-specs.py" ] && printf present || printf absent) $([ -e "$ROOT/scripts/migrate-specs.py" ] && echo present || echo absent)"
grep_case "v0.11 i6 CI validates docs/epics" "$ROOT/.github/workflows/ci.yml" 'validate-epics\.py docs/epics'

# Rebuild the pre-migration tree from the committed archive (CI checkouts are shallow, so not from
# git history): copy each archive back to docs/specs/ and drop the header line migrate.py added.
V6_T="$WORK/v6-repo"; mkdir -p "$V6_T/docs/specs"
V6_SPECS() { # DEST [SLUG] — reconstruct docs/specs/ under DEST
  for d in "$ROOT"/docs/epics/archive/${2:-*}/; do
    s=$(basename "$d"); cp -R "$d" "$1/docs/specs/$s"
    sed -i.bak '1{/^<!-- archived from docs\/specs\//d;}' "$1/docs/specs/$s/spec.md" && rm -f "$1/docs/specs/$s/spec.md.bak"
  done
}
V6_SPECS "$V6_T"
V6_BEFORE=$(find "$V6_T/docs/specs" -type f | wc -l | tr -d ' ')
check "v0.11 i6 fixture has the 8 specs" "8" "$(ls -d "$V6_T"/docs/specs/*/ | wc -l | tr -d ' ')"
python3 "$V6_MIG" --root "$V6_T" >"$WORK/v6-plan.txt" 2>&1
check "v0.11 i6 plan is a dry run" "present" "$([ -d "$V6_T/docs/specs" ] && echo present || echo absent)"
grep_case "v0.11 i6 plan lists 8 done specs" "$WORK/v6-plan.txt" '[[:space:]]done +archive' 8
python3 "$V6_MIG" --root "$V6_T" --apply >"$WORK/v6-apply.txt" 2>&1
check "v0.11 i6 apply exits 0" "0" "$?"
check "v0.11 i6 file count preserved" "$V6_BEFORE" "$(find "$V6_T/docs/epics/archive" -type f | wc -l | tr -d ' ')"
grep_case "v0.11 i6 archived spec.md gets a header" "$V6_T/docs/epics/archive/review-debt/spec.md" '^<!-- archived from docs/specs/review-debt/ .*source=migrated'
check "v0.11 i6 migrating again reproduces the committed archive" "same" \
  "$(diff -r "$ROOT/docs/epics/archive" "$V6_T/docs/epics/archive" >/dev/null && echo same || echo differs)"
(cd "$V6_T" && find docs -type f -exec shasum {} + | sort) >"$WORK/v6-sum1.txt"
python3 "$V6_MIG" --root "$V6_T" --apply >"$WORK/v6-again.txt" 2>&1
check "v0.11 i6 second run exits 0" "0" "$?"
(cd "$V6_T" && find docs -type f -exec shasum {} + | sort) >"$WORK/v6-sum2.txt"
check "v0.11 i6 second run is a no-op" "same" "$(cmp -s "$WORK/v6-sum1.txt" "$WORK/v6-sum2.txt" && echo same || echo differs)"
check "v0.11 i6 validator clean on the result" "0" "$(python3 "$V6_VAL" "$V6_T/docs/epics" >/dev/null 2>&1; echo $?)"

# An open spec (one mini-feature not done) also gets docs/epics/<slug>/ with stories, TS and slices.
V6_O="$WORK/v6-open"; mkdir -p "$V6_O/docs/specs"
V6_SPECS "$V6_O" review-debt
python3 - "$V6_O/docs/specs/review-debt/features.json" <<'PY'
import json, sys
p = sys.argv[1]; d = json.load(open(p)); d["mini_features"][-1]["status"] = "in_progress"; json.dump(d, open(p, "w"), indent=2)
PY
V6_OB=$(find "$V6_O/docs/specs" -type f | wc -l | tr -d ' ')
python3 "$V6_MIG" --root "$V6_O" --apply >"$WORK/v6-open.txt" 2>&1
check "v0.11 i6 open spec apply exits 0" "0" "$?"
check "v0.11 i6 open spec originals archived" "$V6_OB" "$(find "$V6_O/docs/epics/archive" -type f | wc -l | tr -d ' ')"
V6_E="$V6_O/docs/epics/review-debt/epic.md"
grep_case "v0.11 i6 open epic header source=migrated" "$V6_E" '^<!-- .*source=migrated'
grep_case "v0.11 i6 open epic capability group per mini-feature" "$V6_E" '^### hook-and-setup-bugs$'
grep_case "v0.11 i6 open epic TODO story" "$V6_E" '^- \*\*S1\*\* TODO: write the story for TS1$'
grep_case "v0.11 i6 open epic TS literal kept, tag dropped" "$V6_E" '^- \*\*TS1\*\* Given preference values with CRLF'
check "v0.11 i6 open epic has no @s or FR/SC tags" "0" "$(grep -cE '@s[0-9]|FR-[0-9]|SC-[0-9]' "$V6_E")"
check "v0.11 i6 one slice per mini-feature" "5" "$(ls "$V6_O"/docs/epics/review-debt/slices/*.md | wc -l | tr -d ' ')"
grep_case "v0.11 i6 slice layer mixed" "$V6_O/docs/epics/review-debt/slices/5.md" '^- Layer: mixed$'
grep_case "v0.11 i6 slice keeps status" "$V6_O/docs/epics/review-debt/slices/5.md" '^- Status: in_progress$'
check "v0.11 i6 validator: no errors on the migrated open epic" "0" "$(python3 "$V6_VAL" "$V6_O/docs/epics" >/dev/null 2>&1; echo $?)"

# Q5: retired answers keys warn once and are ignored.
check "v0.11 i6 template.config.yaml drops the retired keys" "0" \
  "$(grep -cE 'name: (workflow_mode|use_gherkin|enforce_layer_split)$' "$ROOT/template.config.yaml")"
check "v0.11 i6 examples drop the retired keys" "0" \
  "$(cat "$ROOT"/examples/*/answers.env | grep -cE '^(workflow_mode|use_gherkin|enforce_layer_split)=')"
V6_A="$WORK/v6-old.env"
{ cat "$ROOT/examples/python-fastapi/answers.env"; printf 'workflow_mode=SDD+TDD\nuse_gherkin=yes\nenforce_layer_split=yes\n'; } >"$V6_A"
V6_OUT=$(bash "$ROOT/setup.sh" --target "$WORK/v6-old" --answers "$V6_A" 2>&1)
check "v0.11 i6 old answers still render" "0" "$?"
check "v0.11 i6 retired keys warn exactly once" "1" "$(printf '%s\n' "$V6_OUT" | grep -c 'retired')"
grep_case "v0.11 i6 warning names all three keys" <(printf '%s\n' "$V6_OUT") 'workflow_mode.*use_gherkin.*enforce_layer_split'
check "v0.11 i6 old answers render identical to clean ones" "same" \
  "$(bash "$ROOT/setup.sh" --target "$WORK/v6-new" --answers "$ROOT/examples/python-fastapi/answers.env" >/dev/null 2>&1; diff -r -x agent-config.lock.json "$WORK/v6-old" "$WORK/v6-new" >/dev/null && echo same || echo differs)"

[ -n "${V011_6_ALONE:-}" ] && exit $FAIL
