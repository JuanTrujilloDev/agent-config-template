# v0.9.1 MF2 two-axis verdicts (@s8..@s16).
V091_JUDGE_SRC="$ROOT/core/.claude/agents/judge.md"
V091_JUDGE_PLUGIN="$ROOT/plugin/agents/judge.md"
V091_JUDGE_RENDERED="$WORK/.claude/agents/judge.md"
V091_SECURITY_SRC="$ROOT/core/.claude/agents/security-reviewer.md"
V091_SECURITY_PLUGIN="$ROOT/plugin/agents/security-reviewer.md"
V091_SECURITY_RENDERED="$WORK/.claude/agents/security-reviewer.md"

for f in "$V091_JUDGE_SRC" "$V091_JUDGE_PLUGIN" "$V091_JUDGE_RENDERED"; do
  label=$(basename "$f")
  grep_case "v0.9.1 @s8 $label spec axis" "$f" '^## Spec fidelity$'
  grep_case "v0.9.1 @s8 $label standards axis" "$f" '^## Standards & health$'
  grep_case "v0.9.1 @s8 $label axis result values" "$f" 'Result: (pass|fail|not-applicable)' 2
  grep_case "v0.9.1 @s9 $label finding classes" "$f" 'hard-violation.*judgment-call|judgment-call.*hard-violation'
  grep_case "v0.9.1 @s9 $label never cross-ranks" "$f" '[Nn]ever (merge|move|cross-rank).*axes|[Nn]ever.*axes.*(merge|move|cross-rank)'
  grep_case "v0.9.1 @s10 $label judgment calls approve" "$f" '[Jj]udgment-call.*alone.*(cannot|never).*block'
  grep_case "v0.9.1 @s11 $label hard violations block" "$f" 'CHANGES REQUESTED.*hard-violation|hard-violation.*CHANGES REQUESTED'
  grep_case "v0.9.1 @s16 $label exact verdict heading" "$f" '^## Verdict$'
  check "v0.9.1 @s16 $label removes checkbox verdict" "0" "$(grep -c '\[.\] APPROVED' "$f" 2>/dev/null || true)"
done

for f in "$V091_SECURITY_SRC" "$V091_SECURITY_PLUGIN" "$V091_SECURITY_RENDERED"; do
  label=$(basename "$f")
  grep_case "v0.9.1 @s12 $label keeps severity" "$f" '^### Critical$'
  grep_case "v0.9.1 @s12 $label finding classes" "$f" 'hard-violation.*judgment-call|judgment-call.*hard-violation'
  grep_case "v0.9.1 @s10 $label judgment calls approve" "$f" '[Jj]udgment-call.*alone.*(cannot|never).*block'
  grep_case "v0.9.1 @s11 $label hard violations block" "$f" 'CHANGES REQUESTED.*hard-violation|hard-violation.*CHANGES REQUESTED'
  grep_case "v0.9.1 @s12 $label exact verdict heading" "$f" '^## Verdict$'
  grep_case "v0.9.1 @s12 $label exact verdict values" "$f" '^APPROVED \| CHANGES REQUESTED$'
done

for f in "$V091_JUDGE_SRC" "$V091_JUDGE_PLUGIN" "$V091_JUDGE_RENDERED"; do
  label=$(basename "$f")
  grep_case "v0.9.1 @s13 $label 200-line trigger" "$f" '(over|>) (approximately |~)?200 (changed )?lines'
  grep_case "v0.9.1 @s14 $label risk triggers" "$f" 'auth.*persistent data.*concurrency.*architecture|security.*persistent data.*concurrency.*architecture'
  check "v0.9.1 @s15 $label spec origin is not trigger" "0" "$(grep -ciE 'any change coming out of a planning/spec session|spec-originated change' "$f" 2>/dev/null || true)"
  grep_case "v0.9.1 @s13 $label adversarial stays in axes" "$f" '[Aa]dversarial.*(existing|appropriate).*axis|axis.*adversarial'
done

for f in "$ROOT/docs/sdd-workflow.md" "$ROOT/plugin/skills/sdd-workflow/SKILL.md" "$ROOT/hosts/codex/skills/sdd-workflow/SKILL.md"; do
  label=$(basename "$f")
  grep_case "v0.9.1 @s16 $label verdict contract" "$f" '^## Review verdict contract$'
  grep_case "v0.9.1 @s16 $label names both axes" "$f" 'Spec fidelity.*Standards & health'
  grep_case "v0.9.1 @s16 $label names both classes" "$f" 'hard-violation.*judgment-call'
done

parity "v0.9.1 @s16 judge axes parity" '^## (Spec fidelity|Standards & health)$' "$V091_JUDGE_SRC" "$V091_JUDGE_PLUGIN"
parity "v0.9.1 @s16 security verdict parity" '^APPROVED \| CHANGES REQUESTED$' "$V091_SECURITY_SRC" "$V091_SECURITY_PLUGIN"
