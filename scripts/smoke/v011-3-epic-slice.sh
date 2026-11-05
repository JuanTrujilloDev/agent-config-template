# v0.11.0 item 3 — `epic` skill + validate-epics.py, `slice` skill, docs/epics/EXAMPLE/ fixture.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v011-3-epic-slice.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0; V011_3_ALONE=1
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

V3_EPIC="$ROOT/core/.claude/skills/epic/SKILL.md"
V3_SLICE="$ROOT/core/.claude/skills/slice/SKILL.md"
V3_VAL="$ROOT/core/.claude/skills/epic/validate-epics.py"
for f in "$V3_EPIC" "$V3_SLICE" "$V3_VAL" "$ROOT/docs/epics/EXAMPLE/epic.md"; do
  check "v0.11 i3 exists ${f#$ROOT/}" "present" "$([ -f "$f" ] && echo present || echo absent)"
done

# Skill shape: user-invoked, placeholder-free (so build.sh can copy it to the plugin), new grammar only.
for f in "$V3_EPIC" "$V3_SLICE"; do
  n=${f#$ROOT/core/.claude/skills/}
  grep_case "v0.11 i3 $n is user-invoked" "$f" '^disable-model-invocation: true$'
  check "v0.11 i3 $n has no {{placeholder}}" "0" "$(grep -c '{{' "$f")"
  check "v0.11 i3 $n names no dropped agent or old grammar" "0" \
    "$(grep -cwE 'pmo|judge|orchestrator|mini-feature|features\.json|contract\.md|Gherkin|FR-[0-9]|SC-[0-9]' "$f")"
done
grep_case "v0.11 i3 epic asks whether to use a tracker" "$V3_EPIC" 'tracker\?'
grep_case "v0.11 i3 epic local source of truth" "$V3_EPIC" 'source=local'
grep_case "v0.11 i3 epic renders from cards" "$V3_EPIC" '/epic render <ID>'
grep_case "v0.11 i3 epic runs the validator" "$V3_EPIC" 'validate-epics\.py'
grep_case "v0.11 i3 epic one-case stories" "$V3_EPIC" 'one When'
grep_case "v0.11 i3 slice layer order" "$V3_SLICE" 'db → be → fe'
grep_case "v0.11 i3 slice keeps the Branch line" "$V3_SLICE" '^- Branch: `feature/<ID>-<group>-<layer>`'
grep_case "v0.11 i3 slice no file lists in the card" "$V3_SLICE" 'no file (paths|lists)'

# Validator behaviour.
V3_V() { python3 "$V3_VAL" "$@" >"$WORK/v3-out.txt" 2>&1; echo $?; }
check "v0.11 i3 validator clean on EXAMPLE (exit)" "0" "$(V3_V "$ROOT/docs/epics/EXAMPLE")"
check "v0.11 i3 validator clean on EXAMPLE (no WARN)" "0" "$(grep -c '^WARN' "$WORK/v3-out.txt")"
check "v0.11 i3 validator clean on docs/epics" "0" "$(V3_V "$ROOT/docs/epics")"

V3_T="$WORK/v3-epics"; mkdir -p "$V3_T"; cp -R "$ROOT/docs/epics/EXAMPLE" "$V3_T/LONG"
python3 - "$V3_T/LONG/epic.md" <<'PY'
import sys; p = sys.argv[1]; t = open(p).read()
open(p, "w").write(t.replace("## Capability groups", "\n".join(f"Filler line {i}." for i in range(100)) + "\n\n## Capability groups"))
PY
check "v0.11 i3 130-line epic exits 0" "0" "$(V3_V "$V3_T/LONG")"
grep_case "v0.11 i3 130-line epic warns" "$WORK/v3-out.txt" '^WARN .*epic\.md.*lines'

cp -R "$ROOT/docs/epics/EXAMPLE" "$V3_T/WIDE"
python3 - "$V3_T/WIDE" <<'PY'
import pathlib, re, sys
d = pathlib.Path(sys.argv[1]); e = d / "epic.md"; t = e.read_text()
extra = range(4, 8)
t = t.replace("## Acceptance Criteria", "".join(f"- **S{i}** As a user, I want case {i} so that it works.\n" for i in extra) + "\n## Acceptance Criteria")
t = t.replace("## Test Scenarios", "".join(f"- **S{i}** Case {i} returns 200.\n" for i in extra) + "\n## Test Scenarios")
t = t.replace("## Technical tasks", "".join(f"- **TS{i}** Given case {i}, When it runs, Then it returns 200.\n" for i in extra) + "\n## Technical tasks")
e.write_text(t)
s = d / "slices" / "2.md"
s.write_text(re.sub(r"^- Stories covered: .*$", "- Stories covered: S1, S2, S3, S4, S5, S6, S7", s.read_text(), flags=re.M))
PY
check "v0.11 i3 7-story slice exits 0" "0" "$(V3_V "$V3_T/WIDE")"
grep_case "v0.11 i3 7-story slice warns" "$WORK/v3-out.txt" '^WARN .*slices/2\.md.*7 stories'

cp -R "$ROOT/docs/epics/EXAMPLE" "$V3_T/BAD"
sed -i.bak 's/^- Stories covered: .*/- Stories covered: S1, S9/' "$V3_T/BAD/slices/2.md" && rm -f "$V3_T/BAD/slices/2.md.bak"
check "v0.11 i3 unknown story exits 1" "1" "$(V3_V "$V3_T/BAD")"
grep_case "v0.11 i3 unknown story names S9" "$WORK/v3-out.txt" '^ERROR .*slices/2\.md.*S9'

# Rendered: skills land in .claude/skills/ and render clean.
V3_R="$WORK/v3-django"
bash "$ROOT/setup.sh" --target "$V3_R" --answers "$ROOT/examples/python-django/answers.env" >/dev/null 2>&1
for f in epic/SKILL.md epic/validate-epics.py slice/SKILL.md; do
  check "v0.11 i3 rendered .claude/skills/$f" "present" "$([ -f "$V3_R/.claude/skills/$f" ] && echo present || echo absent)"
done
check "v0.11 i3 rendered validator == core" "same" "$(cmp -s "$V3_VAL" "$V3_R/.claude/skills/epic/validate-epics.py" && echo same || echo differs)"

[ -n "${V011_3_ALONE:-}" ] && exit $FAIL
