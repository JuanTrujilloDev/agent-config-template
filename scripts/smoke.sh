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

# ---------------------------------------------------------------------------
# MF8 agent-style (@s58..@s66) — grep/structure checks on rendered + source files.
PRIN="$WORK/.claude/rules/principles.md"
FEAT="$WORK/.claude/commands/feature.md"
ORCH="$WORK/.claude/agents/orchestrator.md"

# grep_case NAME FILE PATTERN MIN — asserts `grep -cE PATTERN FILE` >= MIN (default 1).
grep_case() {
  n=$(grep -cE -- "$3" "$2" 2>/dev/null || true)
  if [ "${n:-0}" -ge "${4:-1}" ]; then echo "PASS $1"; else
    echo "FAIL $1"; echo "  expected: grep -cE '$3' $2 >= ${4:-1}"; echo "  actual:   ${n:-0}"; FAIL=1; fi
}

# @s58 — terse user style defined (opt-in, telegraphic, keep tokens, no invented abbrevs, no arrow chains, caveat); concise stays default
grep_case "@s58 terse opt-in" "$PRIN" '\*\*terse\*\*.*opt-in|terse.*\(opt-in\)'
grep_case "@s58 telegraphic" "$PRIN" '[Tt]elegraphic'
grep_case "@s58 keep negations" "$PRIN" '[Kk]eep negations'
grep_case "@s58 technical tokens verbatim" "$PRIN" 'paths, commands, identifiers, versions, numbers.*verbatim'
grep_case "@s58 never invent abbreviations" "$PRIN" '[Nn]ever invent abbreviations'
grep_case "@s58 no arrow chains" "$PRIN" '[Nn]o arrow chains'
grep_case "@s58 net-negative caveat" "$PRIN" 'net-negative'
grep_case "@s58 concise remains default" "$PRIN" '\*\*concise\*\* \(default\)'
# @s59 — Report format subsection
grep_case "@s59 heading" "$PRIN" '^### Report format'
grep_case "@s59 key + values" "$PRIN" 'agent_style=terse\|descriptive'
grep_case "@s59 read from local env" "$PRIN" 'agent_style.*answers\.local\.env|answers\.local\.env.*agent_style'
grep_case "@s59 absent/empty/unrecognized -> terse" "$PRIN" '[Aa]bsent, empty, or unrecognized = `?terse'
grep_case "@s59 return message only" "$PRIN" 'return message.*subagent|subagent.*return message'
grep_case "@s59 never human-facing / never disk" "$PRIN" 'never human-facing.*never.*(disk|writes)'
# @s60 — schema fields, order, budget, descriptive
check "@s60 field order" "RESULT FILES CHECKS FINDINGS DECISIONS NEXT" \
  "$(grep -oE '\b(RESULT|FILES|CHECKS|FINDINGS|DECISIONS|NEXT):' "$PRIN" 2>/dev/null | tr -d ':' | awk '!s[$0]++' | paste -sd' ' -)"
grep_case "@s60 RESULT values" "$PRIN" 'pass\|fail\|approved\|changes-requested\|blocked'
grep_case "@s60 FILES shape" "$PRIN" 'path:\+n/-m'
grep_case "@s60 CHECKS shape" "$PRIN" 'name=pass\|fail'
grep_case "@s60 <=25 lines" "$PRIN" '≤ ?~?25 lines|<= ?~?25 lines'
grep_case "@s60 descriptive = prose report" "$PRIN" '\*\*descriptive\*\*.*prose'
grep_case "@s60 descriptive for debugging/onboarding" "$PRIN" 'debugging the workflow.*onboarding'
# @s61 — boundary rule
grep_case "@s61 progress dir always prose" "$PRIN" 'docs/specs/\*/progress'
grep_case "@s61 spec/contract/commits/PR/docs" "$PRIN" 'spec\.md.*contract\.md.*commit messages.*PR bodies.*docs'
grep_case "@s61 human output follows output_style not agent_style" "$PRIN" 'follows `?output_style`?, never `?agent_style'
# @s62 — prompt-passing line in feature.md and orchestrator.md
S62_LINE='agent_style: <terse\|descriptive> — return per "Report format" in \.claude/rules/principles\.md'
for f in "$FEAT" "$ORCH"; do
  b=$(basename "$f")
  grep_case "@s62 $b read once (absent = terse)" "$f" 'agent_style.*answers\.local\.env.*(absent|missing).*terse'
  grep_case "@s62 $b prompt line" "$f" "$S62_LINE"
  grep_case "@s62 $b names subagents" "$f" 'pmo.*judge.*security-reviewer.*mutation-tester'
done
# @s63 — hooks never mention agent_style (banner cases above unchanged)
check "@s63 core hook no agent_style" "0" "$(grep -c agent_style "$CORE_HOOK")"
check "@s63 plugin hook no agent_style" "0" "$(grep -c agent_style "$PLUGIN_HOOK")"
# @s64 — local-prefs docs list agent_style beside output_style
grep_case "@s64 template.config.yaml" "$ROOT/template.config.yaml" 'output_style.*agent_style|agent_style.*output_style'
grep_case "@s64 setup-template scopes table" "$ROOT/plugin/commands/setup-template.md" 'Local prefs.*output_style.*agent_style'
grep_case "@s64 setup-template not asked" "$ROOT/plugin/commands/setup-template.md" 'agent_style.*(not asked|never rendered)|(not asked|never rendered).*agent_style'
# @s65 — plugin mirrors carry the same additions (grep parity with core)
for pair in "core/.claude/rules/principles.md:plugin/skills/principles/SKILL.md" \
            "core/.claude/commands/feature.md:plugin/commands/feature.md" \
            "core/.claude/agents/orchestrator.md:plugin/agents/orchestrator.md"; do
  c=${pair%%:*}; m=${pair##*:}
  grep_case "@s65 $m has agent_style" "$ROOT/$m" 'agent_style'
  check "@s65 $m parity" "$(grep -c agent_style "$ROOT/$c")" "$(grep -c agent_style "$ROOT/$m")"
done
grep_case "@s65 principles mirror Report format" "$ROOT/plugin/skills/principles/SKILL.md" '^### Report format'
# MANUAL @s66 — judge via /feature with agent_style=terse: return ≤25 lines per @s60 schema, all paths + severities kept; verdict file under docs/specs/<slug>/progress/ has grep -c '^RESULT:' = 0.

exit $FAIL
