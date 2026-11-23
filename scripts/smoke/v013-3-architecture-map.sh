# v0.13.0 item 3 — .claude/rules/architecture-map.md: always loaded, user-owned, drafted by /setup-template.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v013-3-architecture-map.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

V13_M="$WORK/.claude/rules/architecture-map.md"
check "v0.13 i3 map rendered" "present" "$([ -f "$V13_M" ] && echo present || echo absent)"
check "v0.13 i3 map has no {{placeholder}}" "0" "$(grep -cE "$PH" "$V13_M")"
check "v0.13 i3 map sections" "Map|Columns" "$(h2_list "$V13_M")"
grep_case "v0.13 i3 map starter row uses the rendered tests glob" "$V13_M" '^\| Test \| `tests/` \| one module under test \|'
grep_case "v0.13 i3 map documents the Check vocabulary" "$V13_M" '`max <N> classes based on <Base>`.*`no classes`'
grep_case "v0.13 i3 principles point to the map" "$PRIN" 'New code goes where `\.claude/rules/architecture-map\.md` says'
grep_case "v0.13 i3 CLAUDE.md names the map" "$WORK/CLAUDE.md" 'architecture-map\.md'
grep_case "v0.13 i3 AGENTS.md points Cursor and Codex to the map" "$ROOT/hosts/cursor/AGENTS.md" '\*\*Architecture map\*\*.*architecture-map\.md'
grep_case "v0.13 i3 setup-template drafts the map with measurements" "$ROOT/plugin/commands/setup-template.md" '^9\. \*\*Architecture map\.\*\*'
grep_case "v0.13 i3 setup-template proposes a check only at 90%" "$ROOT/plugin/commands/setup-template.md" 'at least 90% of modules'

V13_U="$WORK/v013-map-merge"
bash "$ROOT/setup.sh" --target "$V13_U" --answers "$ROOT/examples/python-fastapi/answers.env" >/dev/null 2>&1
printf '| Model | `src/models/*.py` | one model | `<model>.py` | max 1 class |\n' >> "$V13_U/.claude/rules/architecture-map.md"
V13_PLAN=$(bash "$ROOT/setup.sh" --target "$V13_U" --answers "$ROOT/examples/python-fastapi/answers.env" 2>&1)
check "v0.13 i3 an edited map is CUSTOMIZED, not stale" "1" "$(printf '%s\n' "$V13_PLAN" | grep -cE 'CUSTOMIZED +\.claude/rules/architecture-map\.md')"
bash "$ROOT/setup.sh" --target "$V13_U" --answers "$ROOT/examples/python-fastapi/answers.env" --merge >/dev/null 2>&1
grep_case "v0.13 i3 --merge keeps the edited map" "$V13_U/.claude/rules/architecture-map.md" '^\| Model \| `src/models/\*\.py`'
before "v0.13 i3 step 9 sits in the numbered steps" "$ROOT/plugin/commands/setup-template.md" '^9\. \*\*Architecture map\.\*\*' '^## Config scopes$'
