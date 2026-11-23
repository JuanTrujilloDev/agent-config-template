# v0.13.0 item 5 — implement runs a deslop pass; tests-first rejects empty-return tests and checks complexity claims.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v013-5-implement-deslop.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

V13_S="$ROOT/core/.claude/skills"; IM="$V13_S/implement/SKILL.md"; TF="$V13_S/tests-first/SKILL.md"
grep_case "v0.13 i5 implement has a Deslop pass" "$IM" '^5\. \*\*Deslop pass\.\*\*'
before "v0.13 i5 deslop pass comes before the DoD" "$IM" '^5\. \*\*Deslop pass' '^7\. \*\*Definition of Done'
grep_case "v0.13 i5 deslop pass reruns the verifier" "$IM" 'Deslop pass.*verify_changed\.py --base'
grep_case "v0.13 i5 deslop pass checks Placement" "$IM" 'Deslop pass.*`## Placement` row'
grep_case "v0.13 i5 a hiding guard is not a fix (implement)" "$IM" 'guard that only hides a crash is not a fix'
grep_case "v0.13 i5 a hiding guard is not a fix (/fix)" "$ROOT/core/.claude/commands/fix.md" 'guard that only hides the crash is not a fix'
grep_case "v0.13 i5 DoD in implement includes the verifier" "$IM" 'format, lint, the changed-lines verifier'
grep_case "v0.13 i5 tests-first rejects empty-return tests" "$TF" '\*\*Empty-return\*\*: the test would still pass if every function under it returned nothing'
grep_case "v0.13 i5 tests-first turns Complexity rows into tests" "$TF" '`## Complexity` row.*`→ Complexity`'
check "v0.13 i5 plugin implement mirrors core" "0" "$(diff -q "$IM" "$ROOT/plugin/skills/implement/SKILL.md" >/dev/null 2>&1; echo $?)"
