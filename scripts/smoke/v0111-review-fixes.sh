# v0.11.1 — fixes from the v0.11.0 post-merge review (F1–F11).
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v0111-review-fixes.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0; V0111_ALONE=1
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

# 1. validate-epics.py: only slices/<n>.md are slices; zero-story epic warns; bad explicit path exits 2.
F_VAL="$ROOT/core/.claude/skills/epic/validate-epics.py"
F_V() { python3 "$F_VAL" "$@" >"$WORK/f-val.txt" 2>&1; echo $?; }
F_E="$WORK/f-epics"; mkdir -p "$F_E"; cp -R "$ROOT/docs/epics/EXAMPLE" "$F_E/REP"
printf '# Security review — slice 1\n\nNo findings.\n' >"$F_E/REP/slices/1.security.md"
printf '# Mutation report — slice 1\n' >"$F_E/REP/slices/1.mutation.md"
check "v0.11.1 F1 slice reports beside slices validate clean" "0" "$(F_V "$F_E/REP")"
check "v0.11.1 F1 reports are not checked as slices" "0" "$(grep -cE 'security\.md|mutation\.md' "$WORK/f-val.txt")"
cp -R "$ROOT/docs/epics/EXAMPLE" "$F_E/EMPTY"
python3 - "$F_E/EMPTY/epic.md" <<'PY'
import re, sys
p = sys.argv[1]; t = open(p).read()
open(p, "w").write(re.sub(r"(## (?:User Stories|Acceptance Criteria|Test Scenarios)\n).*?(?=^## )", r"\1\n", t, flags=re.M | re.S))
PY
rm -f "$F_E/EMPTY"/slices/*.md
check "v0.11.1 F6 zero-story epic exits 0" "0" "$(F_V "$F_E/EMPTY")"
grep_case "v0.11.1 F6 zero-story epic warns" "$WORK/f-val.txt" '^WARN .*epic\.md: no .*stories'
check "v0.11.1 F11 missing explicit path exits 2" "2" "$(F_V "$WORK/no-such-epics")"
check "v0.11.1 F11 default path still exits 0 when absent" "0" "$(cd "$WORK" && python3 "$F_VAL" >/dev/null 2>&1; echo $?)"

[ -n "${V0111_ALONE:-}" ] && exit $FAIL
