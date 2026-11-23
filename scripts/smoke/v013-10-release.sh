# v0.13.0 item 10 — release: notes in the README and the upgrade guide, update-config manual steps.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v013-10-release.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

grep_case "v0.13 i10 README keeps the v0.13.0 section" "$ROOT/README.md" '^## v0\.13\.0 — plan, design, deslop$'
for t in 'scope-page' 'architect' 'Complexity' 'verify_changed\.py' 'architecture-map\.md' 'Placement' 'lang-python' 'plan-design-build\.md'; do
  grep_case "v0.13 i10 README notes name $t" <(section "$ROOT/README.md" '^## v0\.13\.0') "$t"
done
V13_UG=$(section "$ROOT/docs/upgrade-guide.md" '^## Upgrading from v0\.12\.1 to v0\.13\.0')
for t in 'architecture-map\.md' 'step 9' '`Stop` hook' 'keeps one of the two' '≤90 lines' 'old slices without them still validate' 'Playwright'; do
  grep_case "v0.13 i10 upgrade guide names $t" <(printf '%s\n' "$V13_UG") "$t"
done
grep_case "v0.13 i10 update-config offers the map survey" "$ROOT/core/.claude/skills/update-config/SKILL.md" 'Architecture map \(v0\.13\)'
grep_case "v0.13 i10 update-config keeps one changed-lines hook" "$ROOT/core/.claude/skills/update-config/SKILL.md" 'One changed-lines hook \(v0\.13\)'
grep_case "v0.13 i10 code-review skips Placement on pre-v0.13 slices" "$ROOT/core/.claude/skills/code-review/SKILL.md" 'a slice without `## Placement` \(written before v0\.13\): skip'
for f in verify_changed.py; do
  grep_case "v0.13 i10 what-each-file-does names $f" "$ROOT/docs/what-each-file-does.md" "$f"
done
