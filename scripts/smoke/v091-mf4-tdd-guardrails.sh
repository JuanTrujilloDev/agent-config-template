# v0.9.1 MF4 TDD quality guardrails (@s26..@s33).
for f in "$ROOT/docs/sdd-workflow.md" "$ROOT/plugin/skills/sdd-workflow/SKILL.md" "$ROOT/hosts/codex/skills/sdd-workflow/SKILL.md"; do
  label=$(basename "$f")
  grep_case "v0.9.1 @s26 $label guardrail heading" "$f" '^## TDD quality guardrails$'
  grep_case "v0.9.1 @s26 $label names seams first" "$f" '[Nn]ame.*public behavior seams.*before.*test'
  grep_case "v0.9.1 @s27 $label Gate 2 evidence" "$f" 'Gate 2.*public seams.*first failing test'
  grep_case "v0.9.1 @s28 $label rejects unconfirmed seam" "$f" '[Dd]o not.*test.*unconfirmed seam'
  grep_case "v0.9.1 @s29 $label independent sources" "$f" '[Ee]xpected value.*contract.*literal.*worked example.*independent oracle'
  grep_case "v0.9.1 @s29 $label rejects same algorithm" "$f" '[Nn]ever.*same algorithm.*production'
  grep_case "v0.9.1 @s30 $label external mocks only" "$f" '[Mm]ock only external boundaries'
  grep_case "v0.9.1 @s30 $label own modules real" "$f" '[Pp]roject-owned.*modules.*real'
  grep_case "v0.9.1 @s31 $label vertical loop" "$f" '[Oo]ne test.*failing evidence.*minimal green.*next test'
  grep_case "v0.9.1 @s31 $label no batching" "$f" '[Dd]o not batch.*tests.*code'
done

# v0.11 chunk 2: core feature.md/orchestrator.md (and their renders) are gone; plugin and codex copies stay until chunk 7.
for f in "$ROOT/plugin/commands/feature.md" "$ROOT/hosts/codex/skills/feature/SKILL.md" "$ROOT/plugin/agents/orchestrator.md"; do
  label=$(basename "$f")
  grep_case "v0.9.1 @s32 $label passes guardrails" "$f" '[Ii]mplementer (prompt|handoff).*TDD quality guardrails|TDD quality guardrails.*implementer (prompt|handoff)'
  grep_case "v0.9.1 @s32 $label keeps agent style" "$f" 'agent_style:'
done

dev_copies=$(grep -Rl 'TDD quality guardrails' "$ROOT/core/.claude/agents"/*-dev.md "$ROOT/plugin/agents"/*-dev.md 2>/dev/null | wc -l | tr -d ' ')
check "v0.9.1 @s32 no duplicated dev-agent policy" "0" "$dev_copies"

