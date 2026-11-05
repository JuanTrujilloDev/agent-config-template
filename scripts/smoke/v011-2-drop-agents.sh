# v0.11.0 chunk 2 — drop the 9 SDD agents and the /spec, /feature commands; security-reviewer and
# mutation-tester no longer name dropped agents or the FR/SC / mini-feature contract.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v011-2-drop-agents.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0; V011_2_ALONE=1
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

V011_2_AGENTS="pmo orchestrator judge backend-dev frontend-dev core-dev desktop-dev mobile-dev game-dev"
V011_2_NAMES='pmo|orchestrator|judge|backend-dev|frontend-dev|core-dev|desktop-dev|mobile-dev|game-dev|primary_dev_agent'

for a in $V011_2_AGENTS; do
  check "v0.11 c2 core agent $a dropped" "absent" "$([ -e "$ROOT/core/.claude/agents/$a.md" ] && echo present || echo absent)"
done
for c in spec feature; do
  check "v0.11 c2 core command $c dropped" "absent" "$([ -e "$ROOT/core/.claude/commands/$c.md" ] && echo present || echo absent)"
done
check "v0.11 c2 core agents are the three kept" "mutation-tester.md security-reviewer.md ui-designer.md" \
  "$(cd "$ROOT/core/.claude/agents" && echo *.md)"

# Zero references to dropped agents or commands anywhere in core/.
n=$(grep -rnwE "$V011_2_NAMES" "$ROOT/core" | tee "$WORK/v011-2-names.txt" | wc -l | tr -d ' ')
check "v0.11 c2 core/ names no dropped agent" "0" "$n"
[ "$n" = 0 ] || sed 's/^/    /' "$WORK/v011-2-names.txt"
n=$(grep -rnE '(^|[^[:alnum:]_.-])/(spec|feature)([^[:alnum:]_-]|$)|commands/(spec|feature)\.md' "$ROOT/core" | tee "$WORK/v011-2-cmds.txt" | wc -l | tr -d ' ')
check "v0.11 c2 core/ names no /spec or /feature" "0" "$n"
[ "$n" = 0 ] || sed 's/^/    /' "$WORK/v011-2-cmds.txt"

# The two adapted agents speak slices, not the FR/SC mini-feature contract.
for a in security-reviewer mutation-tester; do
  f="$ROOT/core/.claude/agents/$a.md"
  check "v0.11 c2 $a has no mini-feature/contract/FR-SC/docs/specs" "0" \
    "$(grep -ciE 'mini-feature|contract|\bFR-?[0-9]|\bSC-?[0-9]|docs/specs' "$f" || true)"
  grep_case "v0.11 c2 $a writes under docs/epics/<ID>/slices/" "$f" 'docs/epics/<ID>/slices/<n>\.'
done
grep_case "v0.11 c2 mutation-tester targets the slice's approved tests" "$ROOT/core/.claude/agents/mutation-tester.md" 'Approved tests'
grep_case "v0.11 c2 security-reviewer runs after code-review" "$ROOT/core/.claude/agents/security-reviewer.md" 'code-review'

# Rendered trees: dropped files are gone and the lock does not record them.
V011_2_T="$WORK/v011-2-django"
bash "$ROOT/setup.sh" --target "$V011_2_T" --answers "$ROOT/examples/python-django/answers.env" >/dev/null 2>&1
check "v0.11 c2 render python-django" "0" "$?"
check "v0.11 c2 rendered agents" "security-reviewer.md ui-designer.md" "$(cd "$V011_2_T/.claude/agents" && echo *.md)"
for c in spec feature; do
  check "v0.11 c2 rendered command $c absent" "absent" "$([ -e "$V011_2_T/.claude/commands/$c.md" ] && echo present || echo absent)"
done
check "v0.11 c2 fresh lock records no dropped file" "0" \
  "$(grep -cE "\"\\.claude/(agents/($(echo "$V011_2_AGENTS" | tr ' ' '|'))|commands/(spec|feature))\\.md\"" "$V011_2_T/agent-config.lock.json")"
check "v0.11 c2 rendered agents/commands have no unrendered placeholder" "0" \
  "$(cat "$V011_2_T"/.claude/agents/*.md "$V011_2_T"/.claude/commands/*.md | grep -cE "$PH")"

# An old v0.10 render upgrades cleanly: unchanged dropped files are OBSOLETE, --prune removes them
# and their lock entries, an edited one is kept.
python3 - "$V011_2_T" <<'PY'
import hashlib, json, pathlib, sys
t = pathlib.Path(sys.argv[1]); lock_path = t / "agent-config.lock.json"; lock = json.loads(lock_path.read_text())
for rel in (".claude/agents/pmo.md", ".claude/agents/judge.md", ".claude/agents/backend-dev.md", ".claude/commands/spec.md", ".claude/commands/feature.md"):
    p = t / rel; p.write_text(f"v0.10 {rel}\n")
    lock["files"][rel] = {"template_version": "0.10.0", "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
lock_path.write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n")
PY
printf 'local edit\n' >>"$V011_2_T/.claude/agents/backend-dev.md"
V011_2_PLAN=$(bash "$ROOT/setup.sh" --target "$V011_2_T" --answers "$ROOT/examples/python-django/answers.env" 2>&1)
for rel in agents/pmo agents/judge commands/spec commands/feature; do
  grep_case "v0.11 c2 plan marks .claude/$rel.md OBSOLETE" <(printf '%s\n' "$V011_2_PLAN") "^ *OBSOLETE +\\.claude/$rel\\.md"
done
grep_case "v0.11 c2 plan marks edited backend-dev CUSTOMIZED-OBSOLETE" <(printf '%s\n' "$V011_2_PLAN") 'CUSTOMIZED-OBSOLETE +\.claude/agents/backend-dev\.md'
bash "$ROOT/setup.sh" --target "$V011_2_T" --answers "$ROOT/examples/python-django/answers.env" --merge --prune >/dev/null 2>&1
check "v0.11 c2 merge --prune exits 0" "0" "$?"
check "v0.11 c2 prune removed unchanged dropped files" "absent absent absent absent" \
  "$(for r in agents/pmo agents/judge commands/spec commands/feature; do [ -e "$V011_2_T/.claude/$r.md" ] && printf 'present ' || printf 'absent '; done | sed 's/ $//')"
check "v0.11 c2 prune kept the edited dropped agent" "present" "$([ -e "$V011_2_T/.claude/agents/backend-dev.md" ] && echo present || echo absent)"
check "v0.11 c2 lock lost the pruned entries" "0" \
  "$(grep -cE '"\.claude/(agents/(pmo|judge)|commands/(spec|feature))\.md"' "$V011_2_T/agent-config.lock.json")"

check "v0.11 c2 validate-packaging.py" "0" "$(cd "$ROOT" && python3 scripts/validate-packaging.py >/dev/null 2>&1; echo $?)"
check "v0.11 c2 build.sh --check" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"

[ -n "${V011_2_ALONE:-}" ] && exit $FAIL
