# MF6 companions (@s40..@s47) — item 4 of the frontier round grows three groups (core quality /
# output / UI), `companions` grammar gains `<comma list>`, /setup-companions learns ui-ux-pro-max
# (has_ui only), caveman never appears. Instruction text — asserted by grep, not by rendering.
ST="$ROOT/plugin/commands/setup-template.md"; SC="$ROOT/plugin/commands/setup-companions.md"
X_SC="$ROOT/hosts/codex/skills/setup-companions/SKILL.md"; RD="$ROOT/README.md"; P_RD="$ROOT/plugin/README.md"
ORCH_SRC="$ROOT/core/.claude/agents/orchestrator.md"; P_ORCH="$ROOT/plugin/agents/orchestrator.md"
GRAMMAR='companions=yes\|not_now\|never\|<comma list>'
# item 4 of the frontier round: from "   4. " to the next numbered item
awk '/^   4\. /{on=1} /^   5\. /{exit} on' "$ST" >"$WORK/item4.md"
# @s40 — still item 4, still 5 numbered items, three groups, recommended Not now
check "@s40 frontier round still has exactly 5 numbered items" "5" "$(grep -cE '^   [0-9]+\. ' "$ST" | tr -d ' ')"
grep_case "@s40 item 4 is the companions item" "$WORK/item4.md" '[Cc]ompanion'
grep_case "@s40 item 4 core quality group: graphify + ponytail" "$WORK/item4.md" '[Cc]ore quality.*graphify.*ponytail'
grep_case "@s40 item 4 output group: native concise, nothing to install" "$WORK/item4.md" '[Oo]utput.*`concise`.*(nothing to install|on by default)'
grep_case "@s40 item 4 UI group: ui-ux-pro-max only when has_ui" "$WORK/item4.md" 'UI.*ui-ux-pro-max.*`has_ui`|`has_ui`.*ui-ux-pro-max'
grep_case "@s40 item 4 recommended stays Not now" "$WORK/item4.md" 'Recommended: `Not now`'
# @s41 — grammar documented; key lives only in .claude/answers.local.env
grep_case "@s41 companions grammar in setup-template" "$ST" "$GRAMMAR"
grep_case "@s41 yes = all recommended" "$ST" '`yes` *(=|—|-) *all recommended'
grep_case "@s41 list installs only those, rest skipped by omission" "$ST" 'list.*(only those|only the listed).*(skipped by omission|not re-recommended)'
grep_case "@s41 not_now re-asks next run" "$ST" '`not_now`.*(re-ask|asked again)'
grep_case "@s41 never suppresses all mention" "$ST" '`never`.*(suppress|say nothing|no mention)'
check "@s41 companions key absent from template.config.yaml placeholders" "0" "$(grep -cE '^ *companions:' "$ROOT/template.config.yaml"; true)"
check "@s41 companions never written to answers.env (scope table)" "1" "$(grep -cE '^\| Local prefs .*`companions`' "$ST"; true)"
check "@s41 companions absent from rendered answers.env" "0" "$(grep -rc companions "$WORK/answers.env" "$WORK/.claude/settings.json" 2>/dev/null | awk -F: '{s+=$NF} END{print s+0}')"
# @s42 — /setup-companions: optional list arg, ui-ux-pro-max detect + plan, no caveman, gate
grep_case "@s42 usage shows optional list argument" "$SC" '/setup-companions \[?(graphify|<tool)'
grep_case "@s42 detects ui-ux-pro-max installed" "$SC" '^ *- ui-ux-pro-max:'
grep_case "@s42 plan prints exact install command" "$SC" '(exact )?install command'
grep_case "@s42 literal upstream install command" "$SC" 'npm install -g ui-ux-pro-max-cli'
grep_case "@s42 literal upstream init command" "$SC" 'uipro init --ai claude'
grep_case "@s42 plan names source per tool" "$SC" 'ui-ux-pro-max.*(github\.com|marketplace|upstream)|(github\.com|marketplace|upstream).*ui-ux-pro-max'
grep_case "@s42 plan says what is written" "$SC" 'what (each|it) writes'
check "@s42 caveman absent from setup-companions" "0" "$(grep -ci caveman "$SC"; true)"
grep_case "@s42 nothing installs before explicit yes" "$SC" '[Ii]nstall nothing without an explicit yes|nothing installs (before|without) an explicit yes'
before "@s42 plan gate precedes ui-ux-pro-max install step" "$SC" 'explicit yes' '\*\*Install ui-ux-pro-max\*\*'
# @s43 — codex mirror carries the entry with codex commands; build --check green
grep_case "@s43 codex SKILL detects ui-ux-pro-max" "$X_SC" '^ *- ui-ux-pro-max:'
grep_case "@s43 codex SKILL install step for ui-ux-pro-max" "$X_SC" '\*\*Install ui-ux-pro-max\*\*'
check "@s43 codex SKILL uses codex, not claude, commands" "0" "$(grep -cE '^\s*claude (plugin|mcp)' "$X_SC"; true)"
check "@s43 codex SKILL caveman absent" "0" "$(grep -ci caveman "$X_SC"; true)"
check "@s43 build --check clean" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
# @s44 — orchestrator: one line, ponytail reaches dev subagents via PONYTAIL_SUBAGENT_MATCHER
check "@s44 core orchestrator one PONYTAIL_SUBAGENT_MATCHER line" "1" "$(grep -c 'PONYTAIL_SUBAGENT_MATCHER' "$ORCH_SRC"; true)"
grep_case "@s44 core orchestrator: applies to dev subagents when matcher matches dev" "$ORCH_SRC" 'PONYTAIL_SUBAGENT_MATCHER.*dev|dev.*PONYTAIL_SUBAGENT_MATCHER'
grep_case "@s44 core orchestrator: when installed" "$ORCH_SRC" 'PONYTAIL_SUBAGENT_MATCHER.*(when|if) installed|(when|if) installed.*PONYTAIL_SUBAGENT_MATCHER'
parity "@s44 plugin orchestrator parity" 'PONYTAIL_SUBAGENT_MATCHER' "$ORCH_SRC" "$P_ORCH"
grep_case "@s44 rendered orchestrator carries the line" "$ORCH" 'PONYTAIL_SUBAGENT_MATCHER'
# @s45 — docs name the three tools, ui-ux-pro-max has_ui-only, no caveman, list grammar, no tracker requirement
for f in "$RD" "$P_RD" "$UPG"; do
  b=$(basename "$(dirname "$f")")/$(basename "$f")
  grep_case "@s45 $b names graphify" "$f" 'graphify'
  grep_case "@s45 $b names ponytail" "$f" 'ponytail'
  grep_case "@s45 $b names ui-ux-pro-max" "$f" 'ui-ux-pro-max'
  grep_case "@s45 $b ui-ux-pro-max is has_ui-only" "$f" 'ui-ux-pro-max.*`has_ui`|`has_ui`.*ui-ux-pro-max'
  grep_case "@s45 $b shows list grammar" "$f" 'companions=(yes\|not_now\|never\|<comma list>|graphify,ponytail)'
  check "@s45 $b caveman absent" "0" "$(grep -ci caveman "$f"; true)"
  check "@s45 $b no 'require.*Plane'" "" "$(grep -n 'require.*Plane' "$f"; true)"
done
# @s46 — has_ui falsy → ui-ux-pro-max absent from item 4 (conditional wording in the instruction text)
grep_case "@s46 item 4 conditional: shown only when has_ui" "$WORK/item4.md" '(only|omit|drop|skip).*`has_ui`|`has_ui`.*(only|omit|drop|skip|falsy|not set)'
grep_case "@s46 item 4 has_ui falsy drops the UI group" "$ST" '`has_ui`.*(falsy|no|absent|unset).*(omit|drop|skip|not (shown|listed|mentioned))|(omit|drop|skip).*(UI group|ui-ux-pro-max).*`has_ui`'
# @s47 — recorded comma list → item 4 not re-asked, ui-ux-pro-max not mentioned
grep_case "@s47 recorded list is not re-asked (tagged recorded)" "$ST" '`companions=[a-z,]+`.*(not re-asked|recorded|skips? (question|item) 4)|(comma )?list.*(not re-asked|skips? (question|item) 4)'
grep_case "@s47 omitted tools not re-recommended / not mentioned" "$ST" '(not re-recommended|not mentioned again|skipped by omission)'
grep_case "@s47 step 8 routes a list to /setup-companions with that list" "$ST" '^   - `<comma list>`|^   - (`graphify,ponytail`|a list).*`/setup-companions'
