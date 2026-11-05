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

[ -n "${V0111_ALONE:-}" ] && exit $FAIL
