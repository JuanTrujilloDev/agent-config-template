# v0.9.0 MF1 contract grammar (@s1..@s6).
V090_PMO_SRC="$ROOT/core/.claude/agents/pmo.md"
V090_PMO_PLUGIN="$ROOT/plugin/agents/pmo.md"
V090_ORCH_SRC="$ROOT/core/.claude/agents/orchestrator.md"
V090_ORCH_PLUGIN="$ROOT/plugin/agents/orchestrator.md"
V090_FEATURE_SRC="$ROOT/core/.claude/commands/feature.md"
V090_FEATURE_PLUGIN="$ROOT/plugin/commands/feature.md"
V090_HELP="$ROOT/core/.claude/HELP.md"
V090_SDD="$ROOT/docs/sdd-workflow.md"
V090_SDD_PLUGIN="$ROOT/plugin/skills/sdd-workflow/SKILL.md"
V090_SDD_CODEX="$ROOT/hosts/codex/skills/sdd-workflow/SKILL.md"
V090_TRACE='@s[0-9]+.*\[FR-[0-9]+.*SC-[0-9]+'

for f in "$V090_PMO_SRC" "$V090_PMO_PLUGIN"; do
  grep_case "v0.9.0 @s1 $(basename "$f") separates FR" "$f" '## Functional requirements.*FR-###|FR-###.*functional requirements'
  grep_case "v0.9.0 @s1 $(basename "$f") separates SC" "$f" '## Success criteria.*SC-###|SC-###.*success criteria'
  grep_case "v0.9.0 @s2 $(basename "$f") traces scenarios" "$f" 'scenario.*FR-###.*SC-###|FR-###.*SC-###.*scenario'
  grep_case "v0.9.0 @s3 $(basename "$f") exact marker" "$f" 'NEEDS CLARIFICATION: <question>'
  grep_case "v0.9.0 @s3 $(basename "$f") lists markers" "$f" '[Ll]ist.*clarification.*before.*Gate 1|before.*Gate 1.*[Ll]ist.*clarification'
done

for f in "$V090_ORCH_SRC" "$V090_ORCH_PLUGIN" "$V090_FEATURE_SRC" "$V090_FEATURE_PLUGIN"; do
  grep_case "v0.9.0 @s4 $(basename "$f") scans clarification markers" "$f" 'NEEDS CLARIFICATION:'
  grep_case "v0.9.0 @s4 $(basename "$f") refuses implementation" "$f" '(refuse|block|do not proceed|STOP).*implementation|implementation.*(refuse|block|do not proceed|STOP)'
  grep_case "v0.9.0 @s4 $(basename "$f") prints questions" "$f" '(print|list|show).*unresolved|unresolved.*(print|list|show)'
done

grep_case "v0.9.0 @s5 HELP has FR template" "$V090_HELP" '^## Functional requirements|FR-001'
grep_case "v0.9.0 @s5 HELP has SC template" "$V090_HELP" '^## Success criteria|SC-001'
grep_case "v0.9.0 @s5 HELP has traced scenario" "$V090_HELP" "$V090_TRACE"

for f in "$V090_SDD" "$V090_SDD_PLUGIN" "$V090_SDD_CODEX"; do
  grep_case "v0.9.0 @s6 $(basename "$f") FR/SC traceability" "$f" 'FR-###.*SC-###|functional requirements.*success criteria'
  grep_case "v0.9.0 @s6 $(basename "$f") clarification gate" "$f" 'NEEDS CLARIFICATION: <question>'
done

parity "v0.9.0 @s6 pmo FR parity" 'FR-###' "$V090_PMO_SRC" "$V090_PMO_PLUGIN"
parity "v0.9.0 @s6 pmo marker parity" 'NEEDS CLARIFICATION:' "$V090_PMO_SRC" "$V090_PMO_PLUGIN"
parity "v0.9.0 @s6 orchestrator marker parity" 'NEEDS CLARIFICATION:' "$V090_ORCH_SRC" "$V090_ORCH_PLUGIN"
parity "v0.9.0 @s6 feature marker parity" 'NEEDS CLARIFICATION:' "$V090_FEATURE_SRC" "$V090_FEATURE_PLUGIN"
check "v0.9.0 @s6 build --check clean" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
