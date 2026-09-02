#!/bin/bash
# Shared helpers for scripts/smoke.sh — sourced by the runner, then by each scripts/smoke/mf*.sh.
# Expects ROOT, WORK, FAIL set by the runner. Bash 3.2 + python3 stdlib only.

bash "$ROOT/setup.sh" --target "$WORK" --answers "$ROOT/examples/python-fastapi/answers.env" >/dev/null 2>&1 \
  || { echo "FAIL render examples/python-fastapi"; exit 1; }

CORE_HOOK="$WORK/.claude/hooks/coding-reminder.sh"
PLUGIN_HOOK="$ROOT/plugin/hooks/coding-reminder.sh"
PREFS="$WORK/.claude/answers.local.env"
CODING='{"prompt":"fix the login redirect"}'
NONCODING='{"prompt":"what is a closure?"}'

PRIN="$WORK/.claude/rules/principles.md"
FEAT="$WORK/.claude/commands/feature.md"
ORCH="$WORK/.claude/agents/orchestrator.md"
PMO="$WORK/.claude/agents/pmo.md"; JUDGE="$WORK/.claude/agents/judge.md"; VERIFY="$WORK/.claude/commands/verify.md"

check() { # name expected actual
  if [ "$2" = "$3" ]; then echo "PASS $1"; else
    echo "FAIL $1"; echo "  expected: $2"; echo "  actual:   $3"; FAIL=1; fi
}

# run_hook HOOK PROMPT_JSON — sets OUT (stdout), ERR (stderr), RC, LINE1.
run_hook() {
  OUT=$(printf '%s' "$2" | CLAUDE_PROJECT_DIR="$WORK" bash "$1" 2>"$WORK/err"); RC=$?
  ERR=$(cat "$WORK/err"); LINE1=$(printf '%s\n' "$OUT" | head -1)
}

# hook_case NAME PROMPT_JSON EXPECTED_LINE1 [PREFS_CONTENT] — "-" = no prefs file.
# Asserts core hook line 1 + exit 0 + silent stderr, then @s9 parity with plugin hook.
hook_case() {
  rm -f "$PREFS"; [ "${4:--}" != "-" ] && printf '%s\n' "$4" >"$PREFS"
  run_hook "$CORE_HOOK" "$2"
  check "$1 line1" "$3" "$LINE1"
  check "$1 exit0+quiet" "0|" "$RC|$ERR"
  core_line1=$LINE1; CORE_OUT=$OUT
  run_hook "$PLUGIN_HOOK" "$2"
  check "$1 @s9 plugin parity" "$core_line1" "$LINE1"
}
# grep_case NAME FILE PATTERN MIN — asserts `grep -cE PATTERN FILE` >= MIN (default 1).
grep_case() {
  n=$(grep -cE -- "$3" "$2" 2>/dev/null || true)
  if [ "${n:-0}" -ge "${4:-1}" ]; then echo "PASS $1"; else
    echo "FAIL $1"; echo "  expected: grep -cE '$3' $2 >= ${4:-1}"; echo "  actual:   ${n:-0}"; FAIL=1; fi
}
# line_max NAME FILE MAX — asserts file exists and wc -l <= MAX.
line_max() {
  n=$(wc -l <"$2" 2>/dev/null | tr -d ' '); [ -n "$n" ] || n=missing
  if [ "$n" != missing ] && [ "$n" -le "$3" ]; then echo "PASS $1"; else
    echo "FAIL $1"; echo "  expected: $2 exists, <= $3 lines"; echo "  actual:   $n"; FAIL=1; fi
}
# seed_check NAME FILE — appends a byte to FILE, expects build.sh --check to flag drift, restores.
seed_check() {
  if [ -f "$2" ]; then cp "$2" "$WORK/seed.bak"; else rm -f "$WORK/seed.bak"; fi
  printf 'x' >>"$2"; (cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1); rc=$?
  if [ -f "$WORK/seed.bak" ]; then mv "$WORK/seed.bak" "$2"; else rm -f "$2"; fi
  check "$1" "1" "$rc"
}
# section FILE START_RE — prints FILE from the heading matching START_RE up to the next heading of the same level.
section() { awk -v re="$2" '$0~re{on=1;lvl=$0;sub(/ .*/,"",lvl);print;next} on&&index($0,lvl" ")==1{exit} on' "$1" 2>/dev/null; }
# parity NAME PATTERN CORE PLUGIN — grep -cE counts equal (and >= 1) in core file and plugin mirror.
parity() {
  c=$(grep -cE -- "$2" "$3" 2>/dev/null || true); p=$(grep -cE -- "$2" "$4" 2>/dev/null || true)
  if [ "${c:-0}" -ge 1 ] && [ "${c:-0}" = "${p:-0}" ]; then echo "PASS $1"; else
    echo "FAIL $1"; echo "  expected: grep -cE '$2' core==plugin>=1"; echo "  actual:   core=${c:-0} plugin=${p:-0}"; FAIL=1; fi
}
# h2_list FILE — H2 headings joined by "|", order-preserving, for exact comparison against SECTIONS.
h2_list() { grep '^## ' "$1" 2>/dev/null | sed 's/^## //' | paste -sd'|' -; }
# first_line FILE RE — 1-based line of the first match (0 = none).
first_line() { grep -nE -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | sed 's/^$/0/'; }
# before NAME FILE RE_A RE_B — asserts RE_A first matches on an earlier line than RE_B (both present).
before() {
  a=$(first_line "$2" "$3"); b=$(first_line "$2" "$4")
  if [ "${a:-0}" -gt 0 ] && [ "${b:-0}" -gt 0 ] && [ "$a" -lt "$b" ]; then echo "PASS $1"; else
    echo "FAIL $1"; echo "  expected: '$3' (line $a) before '$4' (line $b) in $2"; FAIL=1; fi
}

# Shared across mini-feature files (hoisted per mf5 judge)
PH='\{\{[#^/]?[a-z_]+\}\}'  # placeholder-shaped only; `style={{...}}` in the inline-styles gotcha is legit JSX
P_PRIN="$ROOT/plugin/skills/principles/SKILL.md"; P_PMO="$ROOT/plugin/agents/pmo.md"
