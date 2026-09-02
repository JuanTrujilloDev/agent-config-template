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

# ---------------------------------------------------------------------------
# MF3 pattern-ledger-integration (@s18..@s24) — checklist lines in principles / pmo /
# judge / verify, plugin mirrors carry the same additions, CLAUDE.md untouched.
PMO="$WORK/.claude/agents/pmo.md"; JUDGE="$WORK/.claude/agents/judge.md"; VERIFY="$WORK/.claude/commands/verify.md"
P_PRIN="$ROOT/plugin/skills/principles/SKILL.md"; P_PMO="$ROOT/plugin/agents/pmo.md"
P_JUDGE="$ROOT/plugin/agents/judge.md"; P_VERIFY="$ROOT/plugin/commands/verify.md"
# section FILE START_RE — prints FILE from the heading matching START_RE up to the next heading of the same level.
section() { awk -v re="$2" '$0~re{on=1;lvl=$0;sub(/ .*/,"",lvl);print;next} on&&index($0,lvl" ")==1{exit} on' "$1" 2>/dev/null; }
LEDGER='pattern / force / rejected alternative'
REJECT='Strategy.*Repository.*Factory.*Singleton.*Service Locator'
# parity NAME PATTERN CORE PLUGIN — grep -cE counts equal (and >= 1) in core file and plugin mirror.
parity() {
  c=$(grep -cE -- "$2" "$3" 2>/dev/null || true); p=$(grep -cE -- "$2" "$4" 2>/dev/null || true)
  if [ "${c:-0}" -ge 1 ] && [ "${c:-0}" = "${p:-0}" ]; then echo "PASS $1"; else
    echo "FAIL $1"; echo "  expected: grep -cE '$2' core==plugin>=1"; echo "  actual:   core=${c:-0} plugin=${p:-0}"; FAIL=1; fi
}

# @s18 — principles.md Design Patterns section: pointer + four hard rules + default-reject list (one line each)
section "$PRIN" '^## Design Patterns' >"$WORK/prin_dp.md"
grep_case "@s18 section exists" "$WORK/prin_dp.md" '^## Design Patterns'
grep_case "@s18 points at rules/patterns.md" "$WORK/prin_dp.md" '\.claude/rules/patterns\.md'
grep_case "@s18 rule: inspect first" "$WORK/prin_dp.md" '[Ii]nspect (existing|first)'
grep_case "@s18 rule: name the force" "$WORK/prin_dp.md" '[Nn]ame the (present )?force'
grep_case "@s18 rule: one-line why" "$WORK/prin_dp.md" '[Oo]ne-line why'
grep_case "@s18 rule: refusal valid" "$WORK/prin_dp.md" '[Rr]efus(al|ing).*valid|no pattern — single call site'
grep_case "@s18 default-reject list on one line" "$WORK/prin_dp.md" "$REJECT"
# @s19 — pmo Design notes: ledger line + literal refusal; Gotchas keep cargo-culting
section "$PMO" '^## Design notes' >"$WORK/pmo_dn.md"
grep_case "@s19 ledger line in Design notes" "$WORK/pmo_dn.md" "$LEDGER"
grep_case "@s19 ledger per named pattern" "$WORK/pmo_dn.md" '(every|each|per) (named )?pattern'
grep_case "@s19 refusal form" "$WORK/pmo_dn.md" 'no pattern — single call site'
grep_case "@s19 Gotchas keep cargo-culting" "$PMO" '\*\*Pattern cargo-culting\.\*\*'
# @s20 — judge: Traceability ledger line, pattern-stuffing Blocker, Minimalist lens names default-reject list
section "$JUDGE" '^### Traceability' >"$WORK/judge_tr.md"
grep_case "@s20 Traceability ledger line" "$WORK/judge_tr.md" '^- \[ \].*ledger'
grep_case "@s20 pattern-stuffing is a Blocker" "$JUDGE" 'pattern-stuffing.*Blocker|Blocker.*pattern-stuffing'
grep_case "@s20 stuffing = pattern without a stated force" "$JUDGE" 'without a (stated )?force'
grep_case "@s20 Minimalist lens names default-reject list" "$JUDGE" "Minimalist.*$REJECT"
# @s21 — /verify step 1: ledger question + simplest default (patterns.md) tried first
section "$VERIFY" '^### 1\.' >"$WORK/verify_1.md"
grep_case "@s21 step 1 asks ledger" "$WORK/verify_1.md" 'ledger'
grep_case "@s21 step 1 asks simplest default tried" "$WORK/verify_1.md" '[Ss]implest default.*\.claude/rules/patterns\.md|\.claude/rules/patterns\.md.*[Ss]implest default'
# @s22 — plugin mirrors: same additions (grep-count parity against core source), skill-style refs
parity "@s22 principles four rules: force" '[Nn]ame the (present )?force' "$ROOT/core/.claude/rules/principles.md" "$P_PRIN"
parity "@s22 principles four rules: one-line why" '[Oo]ne-line why' "$ROOT/core/.claude/rules/principles.md" "$P_PRIN"
parity "@s22 principles default-reject" "$REJECT" "$ROOT/core/.claude/rules/principles.md" "$P_PRIN"
grep_case "@s22 principles skill-style ref" "$(section "$P_PRIN" '^## Design Patterns' >"$WORK/pprin_dp.md"; echo "$WORK/pprin_dp.md")" 'the `patterns` skill'
parity "@s22 pmo ledger" "$LEDGER" "$ROOT/core/.claude/agents/pmo.md" "$P_PMO"
parity "@s22 pmo refusal" 'no pattern — single call site' "$ROOT/core/.claude/agents/pmo.md" "$P_PMO"
parity "@s22 judge ledger" 'ledger' "$ROOT/core/.claude/agents/judge.md" "$P_JUDGE"
parity "@s22 judge pattern-stuffing" 'pattern-stuffing' "$ROOT/core/.claude/agents/judge.md" "$P_JUDGE"
parity "@s22 judge default-reject" "$REJECT" "$ROOT/core/.claude/agents/judge.md" "$P_JUDGE"
parity "@s22 verify ledger" 'ledger' "$ROOT/core/.claude/commands/verify.md" "$P_VERIFY"
parity "@s22 verify simplest default" '[Ss]implest default' "$ROOT/core/.claude/commands/verify.md" "$P_VERIFY"
# lean surface: CLAUDE.md gains nothing beyond MF2's single pointer
check "@s18 CLAUDE.md patterns.md pointer stays 1" "1" "$(grep -c 'rules/patterns\.md' "$WORK/CLAUDE.md" 2>/dev/null; true)"
check "@s18 CLAUDE.md no ledger text" "0" "$(grep -ciE 'ledger|pattern-stuffing' "$WORK/CLAUDE.md" 2>/dev/null; true)"
# MANUAL @s23 — /spec on a brief with three real, present payment providers: Design notes name ONE pattern with a force and a rejected alternative (plain if/dict) — nothing else.
# MANUAL @s24 — judge on a diff wrapping one call site in a `*Strategy` class with a single implementation: verdict lists it under Blockers citing pattern-stuffing.

# MF4 brand-system (@s25..@s32) — templated docs/design-system/MASTER.md gated by has_ui,
# read-before-act lines in UI agents, judge brand check, /design refresh, cursor + plugin parity.
MASTER_SRC="$ROOT/core/docs/design-system/MASTER.md"
PH='\{\{[#^/]?[a-z_]+\}\}'  # placeholder-shaped only; `style={{...}}` in the inline-styles gotcha is legit JSX
SECTIONS='Colors & semantic tokens|Typography|Spacing & layout|Radius, shadows & motion|Component conventions|Icon & image style|Voice & tone|Responsive rules|Accessibility & contrast|Anti-patterns'
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

# @s25 — source: requires guard on line 1, exactly the ten H2s in order, page-overrides note
check "@s25 line 1 requires has_ui" "<!-- requires: has_ui -->" "$(head -1 "$MASTER_SRC" 2>/dev/null)"
check "@s25 ten H2 sections in order" "$SECTIONS" "$(h2_list "$MASTER_SRC")"
grep_case "@s25 page overrides note" "$MASTER_SRC" 'docs/design-system/pages/<page>\.md'
grep_case "@s25 overrides only when a page must deviate" "$MASTER_SRC" '[Oo]nly when.*deviat'
# @s26 — rendered: present + placeholder-free + TODO markers for has_ui examples; absent for API-only
for ex in node-nextjs flutter-mobile unity-game; do
  H="$WORK/brand-$ex"; bash "$ROOT/setup.sh" --target "$H" --answers "$ROOT/examples/$ex/answers.env" >/dev/null 2>&1
  M="$H/docs/design-system/MASTER.md"
  check "@s26 $ex MASTER.md rendered" "1" "$([ -f "$M" ] && echo 1 || echo 0)"
  check "@s26 $ex ten H2 in order" "$SECTIONS" "$(h2_list "$M")"
  check "@s26 $ex zero {{ leftovers" "0" "$(grep -cE "$PH" "$M" 2>/dev/null; true)"
  check "@s26 $ex requires guard stripped" "0" "$(grep -c 'requires: has_ui' "$M" 2>/dev/null; true)"
  grep_case "@s26 $ex TODO markers" "$M" 'TODO:'
  grep_case "@s26 $ex page overrides note" "$M" 'docs/design-system/pages/<page>\.md'
done
check "@s26 python-fastapi (has_frontend=no) MASTER.md absent" "0" "$([ -e "$WORK/docs/design-system/MASTER.md" ] && echo 1 || echo 0)"
# @s27 — cursor host render carries the file (build copies core/docs into cursor/)
H="$WORK/brand-cursor"; bash "$ROOT/setup.sh" --target "$H" --host cursor --answers "$ROOT/examples/node-nextjs/answers.env" >/dev/null 2>&1
check "@s27 cursor MASTER.md rendered" "1" "$([ -f "$H/docs/design-system/MASTER.md" ] && echo 1 || echo 0)"
check "@s27 cursor zero {{ leftovers" "0" "$(grep -cE "$PH" "$H/docs/design-system/MASTER.md" 2>/dev/null; true)"
# @s28 — UI agents read MASTER.md (+ pages/<page>.md) and cite tokens BEFORE their design/implementation step
NEXT="$WORK/brand-node-nextjs"
for a in ui-designer frontend-dev mobile-dev; do
  A="$ROOT/core/.claude/agents/$a.md"
  grep_case "@s28 $a reads MASTER.md" "$A" 'docs/design-system/MASTER\.md'
  grep_case "@s28 $a pages override" "$A" 'pages/<page>\.md'
  grep_case "@s28 $a cites tokens" "$A" '[Cc]ite.*tokens'
done
before "@s28 ui-designer reads before wireframes" "$ROOT/core/.claude/agents/ui-designer.md" 'docs/design-system/MASTER\.md' 'Create wireframes'
before "@s28 frontend-dev reads before Design notes & TDD" "$ROOT/core/.claude/agents/frontend-dev.md" 'docs/design-system/MASTER\.md' '^## Design notes & TDD'
before "@s28 mobile-dev reads before Design notes & TDD" "$ROOT/core/.claude/agents/mobile-dev.md" 'docs/design-system/MASTER\.md' '^## Design notes & TDD'
grep_case "@s28 frontend-dev inline-styles gotcha refs MASTER.md" "$ROOT/core/.claude/agents/frontend-dev.md" '\*\*Using inline styles.*MASTER\.md'
grep_case "@s28 rendered frontend-dev placeholder-free ref" "$NEXT/.claude/agents/frontend-dev.md" 'docs/design-system/MASTER\.md'
# @s29 — judge checklist: UI-diff brand line (no hardcoded color/spacing/radius/font outside MASTER.md; file:line)
J="$ROOT/core/.claude/agents/judge.md"
grep_case "@s29 judge UI checklist line" "$J" '^- \[ \].*\{\{frontend_dir\}\}.*docs/design-system/MASTER\.md'
grep_case "@s29 judge names color/spacing/radius/font" "$J" '^- \[ \].*hardcoded.*colou?r.*spacing.*radius.*font'
grep_case "@s29 judge reports file:line" "$J" '^- \[ \].*MASTER\.md.*file:line'
grep_case "@s29 rendered judge frontend_dir resolved" "$NEXT/.claude/agents/judge.md" 'docs/design-system/MASTER\.md'
check "@s29 rendered judge zero {{ leftovers" "0" "$(grep -cE "$PH" "$NEXT/.claude/agents/judge.md" 2>/dev/null; true)"
# @s30 — /design step 2: read MASTER.md, create from the @s25 list when missing, optional ui-ux-pro-max delegate then normalize
D="$ROOT/core/.claude/commands/design.md"
awk '/^2\. /{on=1} /^3\. /{exit} on' "$D" >"$WORK/design_2.md"
grep_case "@s30 step 2 reads MASTER.md" "$WORK/design_2.md" 'docs/design-system/MASTER\.md'
grep_case "@s30 step 2 creates when missing" "$WORK/design_2.md" '([Cc]reate|[Ww]rite).*(missing|absent)|(missing|absent).*([Cc]reate|[Ww]rite)'
grep_case "@s30 step 2 lists the ten sections" "$WORK/design_2.md" 'Colors & semantic tokens.*Anti-patterns'
grep_case "@s30 step 2 may delegate to ui-ux-pro-max" "$WORK/design_2.md" 'ui-ux-pro-max.*(delegate|installed)|(delegate|installed).*ui-ux-pro-max'
grep_case "@s30 step 2 normalizes after delegation" "$WORK/design_2.md" '[Nn]ormali[sz]e'
grep_case "@s30 ui-ux-pro-max optional, never vendored" "$D" 'ui-ux-pro-max.*optional.*never vendored|optional.*never vendored.*ui-ux-pro-max'
# @s31 — plugin mirrors carry the same additions, placeholder-free
for a in ui-designer frontend-dev mobile-dev judge; do
  parity "@s31 plugin $a MASTER.md refs" 'docs/design-system/MASTER\.md' "$ROOT/core/.claude/agents/$a.md" "$ROOT/plugin/agents/$a.md"
  check "@s31 plugin $a zero {{" "0" "$(grep -cE "$PH" "$ROOT/plugin/agents/$a.md" 2>/dev/null; true)"
done
parity "@s31 plugin judge brand check" 'hardcoded.*colou?r.*spacing.*radius.*font' "$J" "$ROOT/plugin/agents/judge.md"
parity "@s31 plugin design MASTER.md refs" 'docs/design-system/MASTER\.md' "$D" "$ROOT/plugin/commands/design.md"
parity "@s31 plugin design ui-ux-pro-max" 'ui-ux-pro-max' "$D" "$ROOT/plugin/commands/design.md"
check "@s31 plugin design zero {{" "0" "$(grep -cE "$PH" "$ROOT/plugin/commands/design.md" 2>/dev/null; true)"
# @s32 — build --check clean; cursor copy is byte-identical to core source
check "@s32 build --check clean" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
check "@s32 cursor MASTER.md == core" "0" "$(cmp -s "$MASTER_SRC" "$ROOT/cursor/docs/design-system/MASTER.md"; echo $?)"
# (no MANUAL scenarios in MF4 — @s25..@s32 are all executable)

exit $FAIL
