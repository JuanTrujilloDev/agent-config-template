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

# ---------------------------------------------------------------------------
# MF2 patterns-rule (@s10..@s17) — rule text, six domain references, plugin skill,
# generated copies (cursor/codex), host renders, packaging, lean always-loaded surface.
DOMAINS="backend frontend mobile game desktop concurrency"
RULE="$WORK/.claude/rules/patterns.md"
SKILL="$ROOT/plugin/skills/patterns/SKILL.md"
ANS="$ROOT/examples/python-fastapi/answers.env"
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

# @s10 — rendered rule: size + restraint rules in order
line_max "@s10 rule <=120 lines" "$RULE" 120
grep_case "@s10 inspect existing first (code-query)" "$RULE" 'code-query\.md'
grep_case "@s10 name the force" "$RULE" '[Nn]ame the (present )?force'
grep_case "@s10 one-line why" "$RULE" '[Oo]ne-line why'
grep_case "@s10 refusal wording" "$RULE" 'no pattern — single call site'
grep_case "@s10 reject Strategy" "$RULE" 'Strategy'
grep_case "@s10 reject Repository" "$RULE" '[Ss]peculative Repository|Repository.*speculative'
grep_case "@s10 reject Factory" "$RULE" 'Factory'
grep_case "@s10 reject Singleton" "$RULE" 'Singleton'
grep_case "@s10 reject Service Locator" "$RULE" 'Service Locator'
grep_case "@s10 ledger columns" "$RULE" 'pattern / force / rejected alternative'
grep_case "@s10 progressive disclosure" "$RULE" 'force.*(points|routes).*(there|reference)|read.*only when'
check "@s10 order inspect<force<why<refusal<reject<ledger" "1" "$(awk '
  /code-query\.md/&&!a{a=NR} /[Nn]ame the (present )?force/&&!b{b=NR} /[Oo]ne-line why/&&!c{c=NR}
  /no pattern — single call site/&&!d{d=NR} /Service Locator/&&!e{e=NR} /pattern \/ force \/ rejected alternative/&&!f{f=NR}
  END{print (a&&a<b&&b<c&&c<d&&d<e&&e<f)?1:0}' "$RULE" 2>/dev/null)"
for d in $DOMAINS; do grep_case "@s10 table links $d" "$RULE" "\.claude/patterns/$d\.md"; done
# @s11 — six references in core and rendered tree
check "@s11 exactly six core refs" "6" "$(ls "$ROOT"/core/.claude/patterns/*.md 2>/dev/null | wc -l | tr -d ' ')"
for d in $DOMAINS; do
  f="$WORK/.claude/patterns/$d.md"
  line_max "@s11 $d <=150 lines" "$f" 150
  grep_case "@s11 $d simplest default first" "$f" 'Simplest default first'
  grep_case "@s11 $d force->pattern table header" "$f" '^\| *[Ff]orce *\|.*[Pp]attern'
  check "@s11 $d no mustache" "0" "$([ -f "$f" ] && { grep -c '{{' "$f"; true; } || echo missing)"
done
# @s12 — plugin skill: strict frontmatter, skill-style refs, points at references
check "@s12 skill frontmatter opens" "---" "$(head -1 "$SKILL" 2>/dev/null)"
grep_case "@s12 skill description" "$SKILL" '^description: "'
grep_case "@s12 skill code-query skill ref" "$SKILL" 'the `code-query` skill'
grep_case "@s12 skill refusal wording" "$SKILL" 'no pattern — single call site'
grep_case "@s12 skill -> template patterns" "$SKILL" 'CLAUDE_PLUGIN_ROOT\}/template/\.claude/patterns/'
grep_case "@s12 skill -> references/" "$SKILL" 'references/'
# @s13 — generated copies byte-equal to core; --check flags hand-edits
check "@s13 cursor patterns == core" "0" "$(diff -r "$ROOT/core/.claude/patterns" "$ROOT/cursor/.claude/patterns" >/dev/null 2>&1; echo $?)"
check "@s13 cursor rules/patterns.md exists" "1" "$([ -f "$ROOT/cursor/.claude/rules/patterns.md" ] && echo 1 || echo 0)"
grep_case "@s13 codex skill name" "$ROOT/codex/skills/patterns/SKILL.md" '^name: patterns$'
check "@s13 codex references == core" "0" "$(diff -r "$ROOT/core/.claude/patterns" "$ROOT/codex/skills/patterns/references" >/dev/null 2>&1; echo $?)"
check "@s13 --check clean" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
seed_check "@s13 --check flags cursor hand-edit" "$ROOT/cursor/.claude/patterns/backend.md"
seed_check "@s13 --check flags codex hand-edit" "$ROOT/codex/skills/patterns/references/backend.md"
# @s14 — host renders
for h in grok cursor; do
  H="$WORK/host-$h"; bash "$ROOT/setup.sh" --target "$H" --host "$h" --answers "$ANS" >/dev/null 2>&1
  check "@s14 $h rule rendered" "1" "$([ -f "$H/.claude/rules/patterns.md" ] && echo 1 || echo 0)"
  check "@s14 $h six refs" "6" "$(ls "$H"/.claude/patterns/*.md 2>/dev/null | wc -l | tr -d ' ')"
done
H="$WORK/host-codex"; bash "$ROOT/setup.sh" --target "$H" --host codex --answers "$ANS" >/dev/null 2>&1
check "@s14 codex skill rendered" "1" "$([ -f "$H/.agents/skills/patterns/SKILL.md" ] && echo 1 || echo 0)"
check "@s14 codex six refs" "6" "$(ls "$H"/.agents/skills/patterns/references/*.md 2>/dev/null | wc -l | tr -d ' ')"
# @s15 — validate-packaging passes; seeded unquoted-invalid description fails
check "@s15 validate-packaging passes" "0" "$(cd "$ROOT" && python3 scripts/validate-packaging.py >/dev/null 2>&1; echo $?)"
if [ -f "$SKILL" ]; then
  cp "$SKILL" "$WORK/skill.bak"
  sed -i.tmp '2s/.*/description: restraint: rules: for patterns/' "$SKILL"; rm -f "$SKILL.tmp"
  rc=$(cd "$ROOT" && python3 scripts/validate-packaging.py >/dev/null 2>&1; echo $?)
  mv "$WORK/skill.bak" "$SKILL"
  check "@s15 seeded invalid YAML fails" "1" "$rc"
else check "@s15 seeded invalid YAML fails" "1" "skill missing"; fi
# @s16 — READMEs count seven skills and name patterns
grep_case "@s16 plugin README seven skills" "$ROOT/plugin/README.md" '\*\*7 skills\*\*|[Ss]even skills'
grep_case "@s16 plugin README names patterns" "$ROOT/plugin/README.md" '`patterns`'
grep_case "@s16 README names patterns" "$ROOT/README.md" '`patterns`'
# lean always-loaded surface: CLAUDE.md + principles.md reference patterns.md at most once each
check "@s10 CLAUDE.md refs patterns.md <=1" "1" "$([ "$(grep -c 'rules/patterns\.md' "$WORK/CLAUDE.md" 2>/dev/null; true)" -le 1 ] && echo 1 || echo 0)"
check "@s10 principles.md refs patterns.md <=1" "1" "$([ "$(grep -c 'rules/patterns\.md' "$PRIN" 2>/dev/null; true)" -le 1 ] && echo 1 || echo 0)"
# MANUAL @s17 — /spec on brief "add a single CSV export endpoint for orders" with the rule loaded: Design notes read `no pattern — single call site`; no pattern name appears.

exit $FAIL
