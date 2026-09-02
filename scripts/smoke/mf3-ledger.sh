# MF3 pattern-ledger-integration (@s18..@s24) — checklist lines in principles / pmo /
# judge / verify, plugin mirrors carry the same additions, CLAUDE.md untouched.
P_JUDGE="$ROOT/plugin/agents/judge.md"; P_VERIFY="$ROOT/plugin/commands/verify.md"
LEDGER='pattern / force / rejected alternative'
REJECT='Strategy.*Repository.*Factory.*Singleton.*Service Locator'

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
# @s20 — judge: Traceability ledger line, pattern-stuffing hard violation, Minimalist lens names default-reject list
section "$JUDGE" '^### Traceability' >"$WORK/judge_tr.md"
grep_case "@s20 Traceability ledger line" "$WORK/judge_tr.md" '^- \[ \].*ledger'
grep_case "@s20 pattern-stuffing is a hard violation" "$JUDGE" 'pattern-stuffing.*hard-violation|hard-violation.*pattern-stuffing'
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
