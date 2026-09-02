#!/bin/bash
# Smoke harness for docs/specs/adaptive-skills/contract.md **(smoke)** scenarios.
# Renders examples/python-fastapi into mktemp -d and pipes prompt JSON through
# the rendered coding-reminder.sh (and the plugin mirror, @s9). Bash 3.2 +
# python3 stdlib only. Extend by adding `hook_case` / `check` lines below.
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
FAIL=0

bash "$ROOT/setup.sh" --target "$WORK" --answers "$ROOT/examples/python-fastapi/answers.env" >/dev/null 2>&1 \
  || { echo "FAIL render examples/python-fastapi"; exit 1; }

CORE_HOOK="$WORK/.claude/hooks/coding-reminder.sh"
PLUGIN_HOOK="$ROOT/plugin/hooks/coding-reminder.sh"
PREFS="$WORK/.claude/answers.local.env"
CODING='{"prompt":"fix the login redirect"}'
NONCODING='{"prompt":"what is a closure?"}'

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

GATED_CONCISE='mode: gated | output: concise — say "just go" or "explain more" to override this session'
V081_GATED="mode: gated — say 'just go' for autonomous"

# @s1
hook_case "@s1 no prefs" "$CODING" "$GATED_CONCISE"
# @s2
hook_case "@s2 autonomous+detailed" "$CODING" \
  'mode: autonomous | output: detailed — say "gate me" or "be brief" to override this session' \
  "$(printf 'autonomy_mode=autonomous\noutput_style=detailed')"
hook_case "@s2 gated+balanced" "$CODING" \
  'mode: gated | output: balanced — say "just go" or "explain more" to override this session' \
  "output_style=balanced"
hook_case "@s2 gated+terse" "$CODING" \
  'mode: gated | output: terse — say "just go" or "explain more" to override this session' \
  "output_style=terse"
hook_case "@s2 autonomous+terse" "$CODING" \
  'mode: autonomous | output: terse — say "gate me" or "be brief" to override this session' \
  "$(printf 'autonomy_mode=autonomous\noutput_style=terse')"
# @s3 — unrecognized value → v0.8.1 banner, value never echoed
hook_case "@s3 unrecognized" "$CODING" "$V081_GATED" "output_style=verbose"
check "@s3 value not leaked" "0" "$(printf '%s%s' "$CORE_OUT" "$OUT" | grep -c verbose)"
# injection payloads in prefs → fixed strings only
hook_case "inject unrecognized" "$CODING" "$V081_GATED" \
  "$(printf 'autonomy_mode=gated\noutput_style=concise; echo PWNED')"
check "inject not leaked" "0" "$(printf '%s%s' "$CORE_OUT" "$OUT" | grep -c PWNED)"
# garbled/unreadable prefs → fallback banner, exit 0, silent
hook_case "garbled prefs" "$CODING" "$GATED_CONCISE" "$(printf '\x00\xff\xfe\n\x01garbage')"
# @s4 — non-coding prompt → no output
hook_case "@s4 non-coding" "$NONCODING" ""
check "@s4 empty output" "" "$OUT"

exit $FAIL
