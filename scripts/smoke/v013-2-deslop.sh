# v0.13.0 item 2 — the Deslop rule in the principles, the verifier in the DoD and as a Stop hook.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v013-2-deslop.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

V13_CP="$ROOT/core/.claude/rules/principles.md"
for f in "$V13_CP" "$P_PRIN" "$PRIN"; do
  n=${f#$ROOT/}; n=${n#$WORK/}
  grep_case "v0.13 i2 $n has a Deslop section" "$f" '^## Deslop$'
  grep_case "v0.13 i2 $n bans comments with a keep list" "$f" '^- No comments\..*tool directives.*license.*outside'
  grep_case "v0.13 i2 $n allows a try only as a listed last resort" "$f" 'Last-resort error handling'
  grep_case "v0.13 i2 $n caps depth and complexity" "$f" 'block depth ≤2, complexity ≤8'
  grep_case "v0.13 i2 $n DoD runs the verifier" "$f" '^3\. Changed lines: `python3 tools/verify_changed\.py'
  before "v0.13 i2 $n Deslop sits before Commits" "$f" '^## Deslop$' '^## Commits$'
done
parity "v0.13 i2 Deslop bullets core == plugin" '^- (No comments|No try/except|Few ifs|Plain code)' "$V13_CP" "$P_PRIN"
grep_case "v0.13 i2 rendered settings registers the Stop hook" "$WORK/.claude/settings.json" 'tools/verify_changed\.py\\" --hook'
check "v0.13 i2 rendered settings is valid JSON" "0" "$(python3 -m json.tool "$WORK/.claude/settings.json" >/dev/null 2>&1; echo $?)"
V13_RC=$(cd "$WORK" && CLAUDE_PROJECT_DIR="$WORK/nowhere" sh -c "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["hooks"]["Stop"][0]["hooks"][0]["command"])' "$WORK/.claude/settings.json")"; echo $?)
check "v0.13 i2 Stop hook is a no-op without the verifier" "0" "$V13_RC"
grep_case "v0.13 i2 cursor principles point to Deslop" "$ROOT/hosts/cursor/principles.mdc" '\*\*Deslop\*\*.*verify_changed\.py'
