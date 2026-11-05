# MF8 agent-style (@s58..@s66) — grep/structure checks on rendered + source files.
# @s58 — terse user style is opt-in; concise stays default (the rest of @s58..@s61 went with agent_style in v0.11 chunk 1)
grep_case "@s58 terse opt-in" "$PRIN" 'output_style=.*\|terse'
grep_case "@s58 technical tokens verbatim" "$PRIN" 'path, command, identifier and number verbatim'
grep_case "@s58 concise remains default" "$PRIN" 'absent or unknown = `concise`'
# @s63 — hooks never mention agent_style (banner cases above unchanged)
check "@s63 core hooks no agent_style" "0" "$(cat "$WORK"/.claude/hooks/*.sh | grep -c agent_style)"
check "@s63 plugin hook no agent_style" "0" "$(grep -c agent_style "$PLUGIN_HOOK")"
# @s64 — local-prefs docs list agent_style beside output_style
grep_case "@s64 template.config.yaml" "$ROOT/template.config.yaml" 'output_style.*agent_style|agent_style.*output_style'
grep_case "@s64 setup-template scopes table" "$ROOT/plugin/commands/setup-template.md" 'Local prefs.*output_style.*agent_style'
grep_case "@s64 setup-template not asked" "$ROOT/plugin/commands/setup-template.md" 'agent_style.*(not asked|never rendered)|(not asked|never rendered).*agent_style'
# @s65 — plugin mirrors carry the same additions (grep parity with core)
# principles parity dropped in v0.11 chunk 1; feature.md/orchestrator.md parity dropped with those files in chunk 2.
grep_case "@s65 plugin/skills/principles/SKILL.md has agent_style" "$ROOT/plugin/skills/principles/SKILL.md" 'agent_style'
grep_case "@s65 principles mirror Report format" "$ROOT/plugin/skills/principles/SKILL.md" '^### Report format'
