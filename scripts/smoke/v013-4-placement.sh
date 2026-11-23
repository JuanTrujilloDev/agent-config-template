# v0.13.0 item 4 — slices name a file per piece (## Placement) and list last-resort tries; code-review gates both.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v013-4-placement.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

V13_S="$ROOT/core/.claude/skills"
SL="$V13_S/slice/SKILL.md"; CR="$V13_S/code-review/SKILL.md"
grep_case "v0.13 i4 slice template has ## Placement" "$SL" '^## Placement$'
grep_case "v0.13 i4 slice Placement columns" "$SL" '^\| Piece \| File \| New or edit \| Map row \|$'
grep_case "v0.13 i4 slice template has ## Last-resort error handling" "$SL" '^## Last-resort error handling$'
grep_case "v0.13 i4 slice takes Placement from the approved design" "$SL" 'approved design.*architect'
grep_case "v0.13 i4 slice keeps paths out of the card" "$SL" 'no file paths, no file lists and no MR links in the card'
grep_case "v0.13 i4 epic render keeps Placement and Last-resort" "$V13_S/epic/SKILL.md" '`## Placement` and `## Last-resort error handling` sections when re-rendering'
grep_case "v0.13 i4 code-review Placement gate" "$CR" '^3\. \*\*Placement\.\*\*.*\*\*Spec blocker\*\*'
grep_case "v0.13 i4 code-review runs the verifier" "$CR" '^4\. \*\*Changed lines\.\*\* Run `python3 tools/verify_changed\.py --base <fixed-point>`'
grep_case "v0.13 i4 code-review reader-load check" "$CR" 'reader load'
for n in 1 2 3; do
  grep_case "v0.13 i4 EXAMPLE slice $n has Placement" "$ROOT/docs/epics/EXAMPLE/slices/$n.md" '^## Placement$'
done
grep_case "v0.13 i4 EXAMPLE slice 2 shows a last-resort try" "$ROOT/docs/epics/EXAMPLE/slices/2.md" '^\| `apps/accounts/tasks/sso_tasks\.py` \| `sweep_revoked_sso` \|'

V13_E="$WORK/v013-epics/DEMO"; mkdir -p "$V13_E/slices"
printf '%s\n' '<!-- source=local -->' '# DEMO' '## Request' 'x' '## Description' 'x' '## Capability groups' 'x' \
  '## User Stories' '- **S1** As a user, I want x so that y.' '## Acceptance Criteria' '- **S1** x' '## Test Scenarios' '- **TS1** Given x, When y, Then z.' > "$V13_E/epic.md"
printf '%s\n' '<!-- source=local -->' '# Slice 1 — be: demo' '- Layer: be' '- Stories covered: S1' '- Branch: `feature/DEMO-x-be`' \
  '## Placement' '| Piece | File | New or edit | Map row |' '| --- | --- | --- | --- |' '| `run()` | somewhere | new | Business rule |' \
  '## Last-resort error handling' '| File | Function | Why no handler covers it |' '| --- | --- | --- |' '| `src/other.py` | `run` | x |' > "$V13_E/slices/1.md"
V13_OUT=$(python3 "$V13_S/epic/validate-epics.py" "$V13_E" 2>&1); V13_RC=$?
check "v0.13 i4 validator fails a Placement row with no file" "1" "$V13_RC"
check "v0.13 i4 validator names the row" "1" "$(printf '%s\n' "$V13_OUT" | grep -cF 'Placement row `run()` names no file')"
check "v0.13 i4 validator warns on a try outside Placement" "1" "$(printf '%s\n' "$V13_OUT" | grep -c 'WARN .*last-resort try in `src/other.py` is not in `## Placement`')"
check "v0.13 i4 validator passes the repo's epics" "0" "$(python3 "$V13_S/epic/validate-epics.py" "$ROOT/docs/epics" >/dev/null 2>&1; echo $?)"
