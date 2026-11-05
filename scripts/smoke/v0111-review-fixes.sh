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

# 2. setup.sh --merge --prune drops settings hooks that point at pruned files (v0.10 coding-reminder).
F_T="$WORK/f-prune"; F_ANS="$ROOT/examples/python-fastapi/answers.env"
bash "$ROOT/setup.sh" --target "$F_T" --answers "$F_ANS" >/dev/null 2>&1
printf '#!/bin/bash\necho reminder\n' >"$F_T/.claude/hooks/coding-reminder.sh"
python3 - "$F_T" <<'PY'
import hashlib, json, pathlib, sys
t = pathlib.Path(sys.argv[1]); rel = ".claude/hooks/coding-reminder.sh"
lock = json.loads((t / "agent-config.lock.json").read_text())
lock["files"][rel] = {"template_version": "0.10.0", "sha256": hashlib.sha256((t / rel).read_bytes()).hexdigest()}
(t / "agent-config.lock.json").write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n")
s = json.loads((t / ".claude/settings.json").read_text())
s.setdefault("hooks", {})["UserPromptSubmit"] = [{"hooks": [{"type": "command", "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/coding-reminder.sh\""}]}]
(t / ".claude/settings.json").write_text(json.dumps(s, indent=2) + "\n")
PY
bash "$ROOT/setup.sh" --target "$F_T" --answers "$F_ANS" --merge >/dev/null 2>&1
grep_case "v0.11.1 F2 merge without --prune keeps the hook of a kept file" "$F_T/.claude/settings.json" 'coding-reminder'
F_OUT=$(bash "$ROOT/setup.sh" --target "$F_T" --answers "$F_ANS" --merge --prune 2>&1)
check "v0.11.1 F2 merge --prune exits 0" "0" "$?"
check "v0.11.1 F2 coding-reminder.sh pruned" "absent" "$([ -e "$F_T/.claude/hooks/coding-reminder.sh" ] && echo present || echo absent)"
check "v0.11.1 F2 settings.json names no pruned hook" "0" "$(grep -c 'coding-reminder' "$F_T/.claude/settings.json")"
check "v0.11.1 F2 empty UserPromptSubmit event removed" "0" "$(grep -c 'UserPromptSubmit' "$F_T/.claude/settings.json")"
grep_case "v0.11.1 F2 other hooks kept" "$F_T/.claude/settings.json" 'agent-enforcement\.sh'
grep_case "v0.11.1 F2 merge reports the dropped hook" <(printf '%s\n' "$F_OUT") 'dropped 1 hook command'
check "v0.11.1 F2 settings.json still valid JSON" "0" "$(python3 -m json.tool "$F_T/.claude/settings.json" >/dev/null 2>&1; echo $?)"

# 3. code-review treats ## Approved tests and - Branch: as append-only; tests-first locks the whole tests commit.
F_CR="$ROOT/core/.claude/skills/code-review/SKILL.md"; F_TF="$ROOT/core/.claude/skills/tests-first/SKILL.md"
grep_case "v0.11.1 F4 code-review diffs the slice file against the fixed point" "$F_CR" 'git diff \$\(git merge-base <fixed-point> HEAD\) -- docs/epics/<ID>/slices/<n>\.md'
grep_case "v0.11.1 F4 code-review: slice file is append-only" "$F_CR" 'append-only.*Approved tests.*- Branch:'
grep_case "v0.11.1 F4 code-review reads the last Commit line" "$F_CR" 'the last `Commit: <sha>` line'
grep_case "v0.11.1 F5 tests-first locks every file in the tests commit" "$F_TF" 'git show --name-only --format= <sha>'
grep_case "v0.11.1 F5 tests-first example lists a fixture" "$F_TF" '^- `tests/sso/conftest\.py`$'
grep_case "v0.11.1 F4 tests-first: re-approval appends" "$F_TF" 'append a new `Commit:` line'

# 4. migrate.py: old `- @sN **(tag)**` grammar on the open path; render errors are ERROR rows in plan and apply.
F_MIG="$ROOT/core/.claude/skills/update-config/migrate.py"
F_M="$WORK/f-mig"; mkdir -p "$F_M/docs/specs"
for s in adaptive-skills review-debt; do
  cp -R "$ROOT/docs/epics/archive/$s" "$F_M/docs/specs/$s"
  sed -i.bak '1{/^<!-- archived from docs\/specs\//d;}' "$F_M/docs/specs/$s/spec.md" && rm -f "$F_M/docs/specs/$s/spec.md.bak"
done
python3 - "$F_M/docs/specs" <<'PY'
import json, sys
for slug, change in (("adaptive-skills", "open"), ("review-debt", "bad-id")):
    p = f"{sys.argv[1]}/{slug}/features.json"; d = json.load(open(p))
    d["mini_features"][-1]["status"] = "in_progress"
    if change == "bad-id":
        d["mini_features"][0]["id"] = "MF1"
    json.dump(d, open(p, "w"), indent=2)
PY
grep_case "v0.11.1 F6 fixture uses the old - @sN **(tag)** grammar" "$F_M/docs/specs/adaptive-skills/contract.md" '^- @s[0-9]+ \*\*\('
python3 "$F_MIG" --root "$F_M" >"$WORK/f-mig-plan.txt" 2>&1
grep_case "v0.11.1 F7 plan shows a render error as an ERROR row" "$WORK/f-mig-plan.txt" '^review-debt +open +ERROR +ValueError'
check "v0.11.1 F7 plan has no traceback" "0" "$(grep -c Traceback "$WORK/f-mig-plan.txt")"
python3 "$F_MIG" --root "$F_M" --apply >"$WORK/f-mig-apply.txt" 2>&1
check "v0.11.1 F7 apply exits 1 on an ERROR row" "1" "$?"
check "v0.11.1 F7 apply has no traceback" "0" "$(grep -c Traceback "$WORK/f-mig-apply.txt")"
check "v0.11.1 F7 errored slug left in docs/specs, nothing under docs/epics" "present absent" \
  "$([ -d "$F_M/docs/specs/review-debt" ] && printf present || printf absent) $([ -e "$F_M/docs/epics/review-debt" ] && echo present || echo absent)"
check "v0.11.1 F7 no temp dir left behind" "0" "$(ls -a "$F_M/docs/epics" | grep -c '^\.[a-z]')"
F_ME="$F_M/docs/epics/adaptive-skills/epic.md"
check "v0.11.1 F6 old-grammar open epic keeps every scenario" "66" "$(grep -c '^- \*\*TS[0-9]' "$F_ME")"
grep_case "v0.11.1 F6 old-grammar TS literal kept, tag dropped" "$F_ME" '^- \*\*TS[0-9]+\*\* Given '
check "v0.11.1 F6 old-grammar epic has no tags left" "0" "$(grep -cE '\*\*\(|\[FR-|@s[0-9]' "$F_ME")"
check "v0.11.1 F6 old-grammar slices cover stories" "0" "$(grep -c '^- Stories covered: —$' "$F_M"/docs/epics/adaptive-skills/slices/*.md | grep -vc ':0$')"
grep_case "v0.11.1 F7 rerun skips the migrated slug" <(python3 "$F_MIG" --root "$F_M" adaptive-skills 2>&1) '^adaptive-skills +- +skip \(migrated\)'

# 5. Hook: lock compares realpath (+ casefold on macOS); PreToolUse also routes MultiEdit and NotebookEdit.
for f in "$ROOT/core/.claude/settings.json" "$ROOT/plugin/hooks/hooks.json"; do
  grep_case "v0.11.1 F9 PreToolUse matcher covers MultiEdit and NotebookEdit in ${f#$ROOT/}" "$f" '"matcher": "Edit\|Write\|MultiEdit\|NotebookEdit"'
done
F_R="$WORK/f-hook"; mkdir -p "$F_R/docs/epics/X/slices" "$F_R/tests"; : >"$F_R/tests/test_a.py"; : >"$F_R/tests/nb.ipynb"
git -C "$F_R" init -q -b feature/X-a-be && git -C "$F_R" -c user.email=s@x -c user.name=s commit -q --allow-empty -m init
printf -- '- Branch: `feature/X-a-be`\n\n## Approved tests\nCommit: `abc1234`\n- `tests/test_a.py`\n- `tests/nb.ipynb`\n' >"$F_R/docs/epics/X/slices/1.md"
printf -- '- Branch: `feature/X-a-be`\n\n## Approved tests\n- `src/app.py`\n' >"$F_R/docs/epics/X/slices/1.security.md"
ln -s "$F_R" "$WORK/f-hook-alias"
F_HR() { printf '{"tool_name":"%s","tool_input":{"%s":"%s"}}' "$2" "$3" "$4" | CLAUDE_PROJECT_DIR="$F_R" bash "$1" >/dev/null 2>&1; echo $?; }
for h in "$WORK/.claude/hooks/agent-enforcement.sh" "$ROOT/plugin/hooks/agent-enforcement.sh"; do
  n=${h#$WORK/}; n=${n#$ROOT/}
  check "v0.11.1 F8 $n locks a symlinked spelling" "2" "$(F_HR "$h" Edit file_path "$WORK/f-hook-alias/tests/test_a.py")"
  check "v0.11.1 F9 $n locks a notebook via NotebookEdit" "2" "$(F_HR "$h" NotebookEdit notebook_path "$F_R/tests/nb.ipynb")"
  check "v0.11.1 F1 $n ignores paths in slice reports" "0" "$(F_HR "$h" Edit file_path "$F_R/src/app.py")"
  if [ "$(uname)" = Darwin ]; then
    check "v0.11.1 F8 $n locks a case-variant spelling on macOS" "2" "$(F_HR "$h" Edit file_path "$F_R/TESTS/test_a.py")"
  fi
done

# 6. /epic asks before creating tracker cards; no is the default (design decision 16).
F_EP="$ROOT/core/.claude/skills/epic/SKILL.md"
grep_case "v0.11.1 F10 epic asks about tracker cards, default no" "$F_EP" 'cards on a tracker\? \(default: no\)'
grep_case "v0.11.1 F10 epic creates cards only on an explicit yes" "$F_EP" 'only on an explicit yes'
grep_case "v0.11.1 F10 epic No branch is the default" "$F_EP" '^- \*\*No\*\* \(the default\): create no cards'

[ -n "${V0111_ALONE:-}" ] && exit $FAIL
