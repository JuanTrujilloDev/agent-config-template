# v0.13.0 item 1 — tools/verify_changed.py: deslop checks on added lines only.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v013-1-verifier.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

V13_T="$WORK/tools/verify_changed.py"
check "v0.13 i1 verify_changed.py rendered" "present" "$([ -f "$V13_T" ] && echo present || echo absent)"
check "v0.13 i1 verify_changed.py has no {{placeholder}}" "0" "$(grep -c '{{' "$V13_T")"
grep_case "v0.13 i1 verify_changed.py scans the rendered src_dir" "$V13_T" '^SOURCE_DIRS = \["src"\]$'

V13_R="$WORK/v013-repo"
mkdir -p "$V13_R/src/models" "$V13_R/bin"
(
  cd "$V13_R" && git init -q -b feature/DEMO-core-be && git config user.email smoke@example.com && git config user.name smoke
  printf '# legacy comment stays\ndef old(a):\n    if a:\n        if a > 1:\n            return 2\n    return 1\n' > src/legacy.py
  git add . && git commit -qm base
)
printf '# legacy comment stays\ndef old(a):\n    if a:\n        if a > 1:\n            return 2\n    return 1\n\n\ndef added(a, b):\n    if a:\n        if b:\n            return 1\n    return 0\n' > "$V13_R/src/legacy.py"
cat > "$V13_R/src/app.py" <<'PY'
def load(rows):
    try:
        return rows[0]
    except IndexError:
        return None


def total(rows):
    # add them up
    count = 0
    for row in rows:
        for cell in row:
            while cell:
                cell -= 1
                count += 1
    return count


def pick(a, b):
    return 1 if a else 2 if b else 3


def tidy(rows):  # noqa: D401
    if not rows:
        return []
    return [r for r in rows if r]
PY
V13_OUT=$(cd "$V13_R" && python3 "$V13_T" 2>&1); V13_RC=$?
check "v0.13 i1 verifier fails on slop" "1" "$V13_RC"
for want in 'src/app.py:2: new try in load' 'src/app.py:9: new comment' 'src/app.py:13: block depth 3 > 2' \
            'src/app.py:20: nested ternary' 'src/legacy.py:11: nested if'; do
  check "v0.13 i1 verifier reports '$want'" "1" "$(printf '%s\n' "$V13_OUT" | grep -cF "$want")"
done
check "v0.13 i1 verifier ignores legacy lines" "0" "$(printf '%s\n' "$V13_OUT" | grep -cE 'legacy\.py:(1|4):')"
check "v0.13 i1 verifier keeps tool directives" "0" "$(printf '%s\n' "$V13_OUT" | grep -c 'app.py:23:')"
check "v0.13 i1 verifier notes a missing ruff" "1" "$(printf '%s\n' "$V13_OUT" | grep -c 'ruff not installed')"

mkdir -p "$V13_R/docs/epics/DEMO/slices"
cat > "$V13_R/docs/epics/DEMO/slices/1.md" <<'MD'
# Slice 1 — be: demo
- Branch: `feature/DEMO-core-be`

## Last-resort error handling
| File | Function | Why no handler covers it |
| --- | --- | --- |
| `src/app.py` | `load` | an empty export is a result the user sees, not an error |
MD
V13_OUT=$(cd "$V13_R" && python3 "$V13_T" 2>&1)
check "v0.13 i1 verifier accepts a listed last-resort try" "0" "$(printf '%s\n' "$V13_OUT" | grep -c 'new try')"

mkdir -p "$V13_R/.claude/rules"
cat > "$V13_R/.claude/rules/architecture-map.md" <<'MD'
## Map
| Kind | Lives in | Per module | File name | Check |
| --- | --- | --- | --- | --- |
| Model | `src/models/*.py` | one model | `<model>.py` | max 1 class based on Model |
MD
printf 'class Model:\n    pass\n\n\nclass User(Model):\n    pass\n\n\nclass Label(Model):\n    pass\n' > "$V13_R/src/models/user.py"
V13_OUT=$(cd "$V13_R" && python3 "$V13_T" 2>&1)
check "v0.13 i1 verifier enforces the architecture map" "1" "$(printf '%s\n' "$V13_OUT" | grep -cF 'src/models/user.py:9: 2 classes where the map row "Model" allows 1')"

cat > "$V13_R/bin/ruff" <<'SH'
#!/bin/sh
printf '[{"filename":"%s/src/app.py","location":{"row":16},"code":"C901","message":"too complex"},{"filename":"%s/src/legacy.py","location":{"row":3},"code":"SIM102","message":"nested if"}]' "$PWD" "$PWD"
SH
chmod +x "$V13_R/bin/ruff"
V13_OUT=$(cd "$V13_R" && PATH="$V13_R/bin:$PATH" python3 "$V13_T" 2>&1)
check "v0.13 i1 verifier keeps ruff hits on added lines" "1" "$(printf '%s\n' "$V13_OUT" | grep -c 'src/app.py:16: C901')"
check "v0.13 i1 verifier drops ruff hits on legacy lines" "0" "$(printf '%s\n' "$V13_OUT" | grep -c 'legacy.py:3: SIM102')"

V13_RC=$(cd "$V13_R" && printf '{}' | python3 "$V13_T" --hook >/dev/null 2>&1; echo $?)
check "v0.13 i1 hook mode asks for a fix (exit 2)" "2" "$V13_RC"
V13_RC=$(cd "$V13_R" && printf '{"stop_hook_active":true}' | python3 "$V13_T" --hook >/dev/null 2>&1; echo $?)
check "v0.13 i1 hook mode never loops (stop_hook_active)" "0" "$V13_RC"

(cd "$V13_R" && git add -A && git commit -qm all)
V13_OUT=$(cd "$V13_R" && python3 "$V13_T" 2>&1); V13_RC=$?
check "v0.13 i1 verifier passes a clean tree" "0" "$V13_RC"
V13_RC=$(cd "$V13_R" && python3 "$V13_T" --base HEAD~1 >/dev/null 2>&1; echo $?)
check "v0.13 i1 --base checks the branch since its merge-base" "1" "$V13_RC"
