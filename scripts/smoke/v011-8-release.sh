# v0.11.0 item 8 — release: version 0.11.0, docs (README, upgrade guide breaking section, file map,
# epic-story-slice.md), evals rewritten, and every rendered example tree free of the old flow.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v011-8-release.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0; V011_8_ALONE=1
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

for m in plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json .cursor-plugin/plugin.json codex/.codex-plugin/plugin.json; do
  grep_case "v0.11 i8 $m at 0.12.1" "$ROOT/$m" '"version": *"0\.12\.1"'
done
grep_case "v0.11 i8 setup.sh TEMPLATE_VERSION 0.12.1" "$ROOT/setup.sh" '^TEMPLATE_VERSION="0\.12\.1"$'
grep_case "v0.11 i8 packaging reports 0.12.1" <(cd "$ROOT" && python3 scripts/validate-packaging.py 2>&1) 'packaging valid @ v0\.12\.1'

# Docs.
V8_UG="$ROOT/docs/upgrade-guide.md"
check "v0.11 i8 upgrade guide: 0.12.1 is the first release section" "## Upgrading from v0.12.0 to v0.12.1" "$(grep -m1 '^## Upgrading' "$V8_UG")"
grep_case "v0.11 i8 upgrade guide keeps the breaking section" "$V8_UG" '^## Upgrading from v0\.10\.0 to v0\.11\.0 — breaking$'
for t in '`/spec`' '`/feature`' 'update-config' 'migrate\.py' 'workflow_mode' 'AGENT_CONFIG_UNLOCK_TESTS=1' '--prune'; do
  grep_case "v0.11 i8 breaking section names $t" <(section "$V8_UG" '^## Upgrading from v0\.10\.0 to v0\.11\.0') "$t"
done
check "v0.11 i8 sdd-workflow.md replaced" "absent present" \
  "$([ -e "$ROOT/docs/sdd-workflow.md" ] && printf present || printf absent) $([ -f "$ROOT/docs/epic-story-slice.md" ] && echo present || echo absent)"
grep_case "v0.11 i8 README links epic-story-slice.md" "$ROOT/README.md" 'docs/epic-story-slice\.md'
grep_case "v0.11 i8 README breaking notes" "$ROOT/README.md" '^## v0\.11\.0 — breaking$'
grep_case "v0.11 i8 README credits the MIT sources" "$ROOT/README.md" 'mattpocock/skills.*tstack'
for f in tests-first/LICENSE-mattpocock-skills.txt code-review/LICENSE-mattpocock-skills.txt council/LICENSE-tstack.txt; do
  grep_case "v0.11 i8 MIT notice $f" "$ROOT/core/.claude/skills/$f" '^MIT License$'
done
V8_DOCS="$ROOT/README.md $ROOT/docs/what-each-file-does.md $ROOT/docs/epic-story-slice.md $ROOT/docs/install/claude.md $ROOT/docs/install/codex.md $ROOT/docs/install/cursor.md $ROOT/docs/install/host-capability-matrix.md $ROOT/docs/guides/existing-projects.md $ROOT/examples/flutter-mobile/README.md $ROOT/examples/unity-game/README.md"
n=$(grep -nwE 'pmo|judge|backend-dev|frontend-dev|mobile-dev|game-dev|core-dev|desktop-dev|coding-reminder|mini-feature|sdd-workflow|agent_style|features\.json' $V8_DOCS | grep -v 'are gone' | tee "$WORK/v8-docs.txt" | wc -l | tr -d ' ')
check "v0.11 i8 user docs name no dropped piece" "0" "$n"
[ "$n" = 0 ] || sed 's/^/    /' "$WORK/v8-docs.txt"

# Evals: no case drives /spec or /feature; the catalog still validates.
check "v0.11 i8 eval cases speak the new flow" "0" "$(grep -cE '/spec|/feature|docs/specs|judge|agent_style' "$ROOT/scripts/evals/cases.jsonl")"
check "v0.11 i8 evals validate" "0" "$(cd "$ROOT" && python3 scripts/evals/run.py validate >/dev/null 2>&1; echo $?)"

# The slice loop still reads the glossary and /fix escapes to /epic.
grep_case "v0.11 i8 epic reads docs/CONTEXT.md" "$ROOT/core/.claude/skills/epic/SKILL.md" 'docs/CONTEXT\.md'
grep_case "v0.11 i8 tests-first reads docs/CONTEXT.md" "$ROOT/core/.claude/skills/tests-first/SKILL.md" 'docs/CONTEXT\.md'
grep_case "v0.11 i8 /fix escapes to /epic without a repro" "$ROOT/core/.claude/commands/fix.md" 'reproduction in one step, stop and switch to `/epic`'

# Every example, rendered for claude (and node-nextjs for cursor and codex), carries no old flow.
V8_LEFT='(^|[^[:alnum:]_-])(pmo|judge|orchestrator|coding-reminder|mini-features?|features\.json|Gherkin|sdd-workflow|primary_dev_agent)([^[:alnum:]_-]|$)|FR-[0-9]|SC-[0-9]|@s[0-9]|/spec([^[:alnum:]_-]|$)|/feature([^[:alnum:]_/-]|$)'
for ans in "$ROOT"/examples/*/answers.env; do
  ex=$(basename "$(dirname "$ans")")
  for host in claude cursor codex; do
    [ "$host" != claude ] && [ "$ex" != node-nextjs ] && continue
    t="$WORK/v8-$ex-$host"
    bash "$ROOT/setup.sh" --target "$t" --answers "$ans" --host "$host" >/dev/null 2>&1
    check "v0.11 i8 render $ex/$host" "0" "$?"
    # update-config migrates the old names and orchestrator-init (opt-in, unrelated to the dropped agent) keeps its own.
    n=$(grep -rnE "$V8_LEFT" "$t" | grep -v -e '/skills/update-config/' -e '/skills/orchestrator-init/' | tee "$WORK/v8-left-$ex-$host.txt" | wc -l | tr -d ' ')
    check "v0.11 i8 $ex/$host has no old-flow leftovers" "0" "$n"
    [ "$n" = 0 ] || head -5 "$WORK/v8-left-$ex-$host.txt" | sed 's/^/    /'
    check "v0.11 i8 $ex/$host no placeholder" "0" "$(grep -rlE "$PH" "$t" | wc -l | tr -d ' ')"
  done
done
find "$WORK/v8-python-django-claude" -type f | sed "s#$WORK/v8-python-django-claude/##" | sort >"$WORK/v8-tree.txt"
check "v0.11 i8 django tree has the slice skills" "6" "$(grep -cE '^\.claude/skills/(epic|slice|tests-first|implement|code-review|update-config)/SKILL\.md$' "$WORK/v8-tree.txt")"
[ -n "${V011_8_TREE_OUT:-}" ] && cp "$WORK/v8-tree.txt" "$V011_8_TREE_OUT"

[ -n "${V011_8_ALONE:-}" ] && exit $FAIL
