# orchestrator-init: render the orchestrator skeleton into a temp dir.
# Plan mode writes nothing, --write never overwrites, no owner-specific data ships.
OI="$ROOT/plugin/skills/orchestrator-init"
OI_OUT="$WORK/oi/orch"
oi_render() { python3 -I "$OI/render.py" --target "$OI_OUT" --approver "Ada Lovelace" --tracker "Linear" "$@"; }
oi_has() { [ -e "$1" ] && echo yes || echo no; }

line_max "orchestrator-init SKILL.md <= 120 lines" "$OI/SKILL.md" 120
grep_case "orchestrator-init command points at the skill" "$ROOT/plugin/commands/orchestrator-init.md" 'orchestrator-init'
check "orchestrator-init no owner data in templates" "" \
  "$(grep -rEil '\bjuan\b|ricardo|pendi-|alternova|exchangifi|/Users/|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-' "$OI" 2>/dev/null)"

oi_render >"$WORK/oi-plan.txt" 2>&1
check "orchestrator-init plan exit 0" "0" "$?"
check "orchestrator-init plan writes nothing" "no" "$(oi_has "$OI_OUT")"
grep_case "orchestrator-init plan lists AGENTS.md" "$WORK/oi-plan.txt" 'create +AGENTS\.md'

# A file where the plan needs a folder is a conflict: exit 2, nothing written.
OI_CF="$WORK/oi-conflict"
mkdir -p "$OI_CF/orch" && : >"$OI_CF/orch/inbox" && : >"$OI_CF/file-target"
for t in orch file-target; do
  for mode in "" --write; do
    python3 -I "$OI/render.py" --target "$OI_CF/$t" --approver "Ada" --tracker "Linear" $mode >"$WORK/oi-cf.txt" 2>&1
    check "orchestrator-init conflict on $t ${mode:-plan} exits 2" "2" "$?"
  done
done
grep_case "orchestrator-init conflict is printed" "$WORK/oi-cf.txt" '^conflict '
check "orchestrator-init conflict writes nothing" "file-target orch orch/inbox" \
  "$(cd "$OI_CF" && find . -mindepth 1 | sed 's|^\./||' | sort | tr '\n' ' ' | sed 's/ $//')"

oi_render --write >"$WORK/oi-write.txt" 2>&1
check "orchestrator-init write exit 0" "0" "$?"
for f in AGENTS.md bin/README.md bin/_common.py bin/state.py bin/render-progress.py bin/resource-check.py \
  bin/tracker-comment.py bin/archive-evidence.py state/SCHEMA.md plans/TEMPLATE.md plans/launch-standing-orders.md inbox/README.md \
  outbox/README.md inbox/done/.gitkeep outbox/done/.gitkeep learnings/.gitkeep flakes/.gitkeep \
  skills/VENDORED.md schedules/progress-check.md schedules/config-review.md state/EXAMPLE.yaml; do
  check "orchestrator-init renders $f" "yes" "$(oi_has "$OI_OUT/$f")"
done
for f in "$OI_OUT"/bin/*.py; do
  check "orchestrator-init ${f#$OI_OUT/} executable" "yes" "$([ -x "$f" ] && echo yes || echo no)"
done
check "orchestrator-init bin scripts parse" "0" \
  "$(python3 -I -c 'import ast,sys; [ast.parse(open(p).read(), p) for p in sys.argv[1:]]' "$OI_OUT"/bin/*.py >/dev/null 2>&1; echo $?)"
check "orchestrator-init no render tokens left" "" "$(grep -rl '{{' "$OI_OUT" 2>/dev/null)"
grep_case "orchestrator-init approver filled" "$OI_OUT/AGENTS.md" 'Ada Lovelace'
grep_case "orchestrator-init tracker filled" "$OI_OUT/AGENTS.md" 'Linear'
grep_case "orchestrator-init AGENTS keeps placeholders" "$OI_OUT/AGENTS.md" '<[a-z][a-z ]+>' 3
for tier in Trivial Simple Medium Complex; do
  grep_case "orchestrator-init routing tier $tier" "$OI_OUT/AGENTS.md" "^\| $tier"
done
grep_case "orchestrator-init AGENTS fresh thread per round" "$OI_OUT/AGENTS.md" 'Fresh thread per round.*re-reads the whole thread'
grep_case "orchestrator-init AGENTS owner rounds are runs" "$OI_OUT/AGENTS.md" 'Owner-driven rounds.*no parallel thread'
grep_case "orchestrator-init AGENTS epic story slice section" "$OI_OUT/AGENTS.md" '^## Epic → story → slice$'
grep_case "orchestrator-init AGENTS threads cite standing orders" "$OI_OUT/AGENTS.md" 'plans/launch-standing-orders\.md'
OI_SO="$OI_OUT/plans/launch-standing-orders.md"
for pat in '/slice.*step 1' 'approved_by' 'commit done, push pending approval' 'Continue' 'rebase' 'default branch' 'red'; do
  grep_case "orchestrator-init standing orders name $pat" "$OI_SO" "$pat"
done
grep_case "orchestrator-init prints progress check prompt" "$WORK/oi-write.txt" 'Orchestrator progress check'
grep_case "orchestrator-init prints config review prompt" "$WORK/oi-write.txt" 'Config review \(bi-weekly\)'
grep_case "orchestrator-init progress check every 45 min" "$WORK/oi-write.txt" '45 min'

printf 'mine\n' >"$OI_OUT/AGENTS.md"
oi_render --write >"$WORK/oi-rerun.txt" 2>&1
check "orchestrator-init never overwrites" "mine" "$(cat "$OI_OUT/AGENTS.md")"
grep_case "orchestrator-init rerun reports skip" "$WORK/oi-rerun.txt" 'skip +AGENTS\.md'

# The rendered scripts resolve paths from their own folder, whatever it is named (needs PyYAML).
if python3 -c 'import yaml' 2>/dev/null; then
  python3 "$OI_OUT/bin/render-progress.py" --quiet >/dev/null 2>&1
  check "orchestrator-init render-progress writes into the folder" "yes" "$(oi_has "$OI_OUT/PROGRESS.md")"
  # Task ids: any path-safe tracker key (GitHub `123`, Jira `QA2-15`), never a path.
  check "orchestrator-init task ids accepted" "ok" "$(python3 -c '
import sys; sys.path.insert(0, sys.argv[1]); from pathlib import Path; import _common as c
for t in ("123", "QA2-15", "ABC-123"): c.state_path(Path("."), t)
for t in ("a/b", "..", "", "-1"):
    try: c.state_path(Path("."), t); sys.exit("accepted " + repr(t))
    except c.StateError: pass
print("ok")' "$OI_OUT/bin" 2>&1)"
  mkdir -p "$WORK/oi-ev"
  python3 "$OI_OUT/bin/archive-evidence.py" --task ../x --run r1 --store "$WORK/oi-store" "$WORK/oi-ev" >/dev/null 2>&1
  check "orchestrator-init archive-evidence rejects bad --task before moving" "yes" "$(oi_has "$WORK/oi-ev")"
  python3 "$OI_OUT/bin/archive-evidence.py" --task ABC-1 --run a/b --store "$WORK/oi-store" "$WORK/oi-ev" >/dev/null 2>&1
  check "orchestrator-init archive-evidence rejects bad --run before moving" "yes" "$(oi_has "$WORK/oi-ev")"
  # No sysctl / vm_stat / ps on PATH: exit 2 (could not measure) or 0 via /proc, never a traceback (1).
  mkdir -p "$WORK/oi-nobin"
  PATH="$WORK/oi-nobin" "$(python3 -c 'import sys; print(sys.executable)')" \
    "$OI_OUT/bin/resource-check.py" --kind remote --root "$WORK/oi" >"$WORK/oi-rc.txt" 2>&1
  rc=$?
  check "orchestrator-init resource-check without sysctl exits 0 or 2" "yes" "$([ $rc = 0 ] || [ $rc = 2 ] && echo yes || echo no)"
  check "orchestrator-init resource-check without sysctl no traceback" "" "$(grep -l Traceback "$WORK/oi-rc.txt")"
  # The first state file is a copy of EXAMPLE.yaml, and it must validate.
  cp "$OI_OUT/state/EXAMPLE.yaml" "$OI_OUT/state/ABC-123.yaml" 2>/dev/null
  python3 "$OI_OUT/bin/state.py" validate --task ABC-123 >"$WORK/oi-val.txt" 2>&1
  check "orchestrator-init EXAMPLE.yaml validates as a state file" "0" "$?"
  # ADHOC-22 S1: the features the bin/ scripts must carry (see also validate-packaging.py).
  OI_ST="$OI_OUT/bin/state.py"
  oi_tracker() { python3 -c 'import sys,yaml; d=yaml.safe_load(open(sys.argv[1])); print(d["tracker"].get("state"), "plane" in d)' "$OI_OUT/state/ABC-123.yaml" 2>&1; }
  python3 "$OI_ST" run-add --task ABC-123 --id abc-123-tests-r1 --kind tests --no-render >/dev/null 2>&1
  check "orchestrator-init state.py accepts the tests run kind" "0" "$?"
  python3 "$OI_ST" set --task ABC-123 plane.state=Done --no-render >/dev/null 2>&1
  check "orchestrator-init state.py set plane.x writes tracker.x" "0 Done False" "$? $(oi_tracker)"
  python3 "$OI_ST" set --task ABC-123 tracker.state=Nope --no-render >/dev/null 2>&1
  check "orchestrator-init state.py rejects an unknown tracker.state" "1 Done False" "$? $(oi_tracker)"
  python3 "$OI_ST" set --task ABC-123 "tracker.state=In Progress" --no-render >/dev/null 2>&1
  check "orchestrator-init state.py tracker.state ignores case" "0 In Progress False" "$? $(oi_tracker)"
else
  echo "SKIP orchestrator-init render-progress (PyYAML missing)"
fi
check "orchestrator-init codex mirror carries templates" "yes" \
  "$(oi_has "$ROOT/codex/skills/orchestrator-init/templates/bin/state.py")"
