# v0.8.3 MF3 instruction-text debt (@s15..@s23).
CORE_PMO="$ROOT/core/.claude/agents/pmo.md"; PLUGIN_PMO="$ROOT/plugin/agents/pmo.md"
CORE_FIX="$ROOT/core/.claude/commands/fix.md"; PLUGIN_FIX="$ROOT/plugin/commands/fix.md"
CORE_FEATURE="$ROOT/core/.claude/commands/feature.md"; CORE_CLAUDE="$ROOT/core/CLAUDE.md"
CORE_PRINCIPLES="$ROOT/core/.claude/rules/principles.md"; PLUGIN_PRINCIPLES="$ROOT/plugin/skills/principles/SKILL.md"
SETUP_TEMPLATE="$ROOT/plugin/commands/setup-template.md"; MASTER="$ROOT/core/docs/design-system/MASTER.md"

before "v0.8.3 @s15 core CONVERSE before artifacts" "$CORE_PMO" '^## CONVERSE$' '^## What you produce'
before "v0.8.3 @s15 plugin CONVERSE before artifacts" "$PLUGIN_PMO" '^## CONVERSE$' '^## What you produce'

for f in "$CORE_FIX" "$PLUGIN_FIX"; do
  grep_case "v0.8.3 @s16 $(basename "$f") paragraph ends after cause" "$f" 'before naming the cause\.$'
  grep_case "v0.8.3 @s16 $(basename "$f") next paragraph starts repro fallback" "$f" '^   If you cannot get a reproduction'
done

TDD_ANS="$WORK/v083-mf3-tdd.env"; cp "$ROOT/examples/python-fastapi/answers.env" "$TDD_ANS"
printf '\nworkflow_mode=SDD+TDD\n' >>"$TDD_ANS"
TDD_RENDER="$WORK/v083-mf3-tdd"; SDD_RENDER="$WORK/v083-mf3-sdd"
bash "$ROOT/setup.sh" --target "$TDD_RENDER" --answers "$TDD_ANS" >/dev/null 2>&1
bash "$ROOT/setup.sh" --target "$SDD_RENDER" --answers "$ROOT/examples/python-fastapi/answers.env" >/dev/null 2>&1
for f in "$TDD_RENDER/.claude/commands/feature.md" "$TDD_RENDER/CLAUDE.md"; do
  grep_case "v0.8.3 @s17 TDD render says default: $(basename "$f")" "$f" 'TDD (is on|by) default|TDD by default'
  check "v0.8.3 @s17 TDD render omits optional TDD: $(basename "$f")" "0" "$(grep -ci 'optional TDD' "$f"; true)"
done
for f in "$SDD_RENDER/.claude/commands/feature.md" "$SDD_RENDER/CLAUDE.md"; do
  grep_case "v0.8.3 @s17 SDD render says optional: $(basename "$f")" "$f" 'optional TDD|TDD is off by default.*available on request'
done

for f in "$CORE_PRINCIPLES" "$PLUGIN_PRINCIPLES"; do
  grep_case "v0.8.3 @s18 $(basename "$f") names three just-go meanings" "$f" 'Read Before You Write.*autonomy.*setup|narration.*autonomy.*setup'
  grep_case "v0.8.3 @s18 $(basename "$f") stored autonomy does not trigger setup" "$f" 'autonomy_mode=autonomous.*(does not|doesn.t).*setup'
done

grep_case "v0.8.3 @s19 setup item 5 is explicit" "$SETUP_TEMPLATE" '^   5\. [A-Za-z]'
check "v0.8.3 @s19 setup item 5 has no ellipsis" "0" "$(grep -c '^   5\. …' "$SETUP_TEMPLATE"; true)"
grep_case "v0.8.3 @s20 hard rule has just-go merge carve-out" "$SETUP_TEMPLATE" '[Jj]ust-go.*--merge|--merge.*[Jj]ust-go'
grep_case "v0.8.3 @s20 carve-out still forbids automatic overwrite" "$SETUP_TEMPLATE" '[Jj]ust-go.*--overwrite.*never|--overwrite.*never.*[Jj]ust-go'
grep_case "v0.8.3 @s21 --auto belongs to this command" "$SETUP_TEMPLATE" 'passes `--auto` to this command'

grep_case "v0.8.3 @s22 mobile device-class TODO" "$MASTER" 'Mobile.*TODO:.*device class|TODO:.*device class.*mobile'
grep_case "v0.8.3 @s22 game canvas-scaler TODO" "$MASTER" 'Game.*TODO:.*[Cc]anvas [Ss]caler|TODO:.*[Cc]anvas [Ss]caler.*game'

grep_case "v0.8.3 @s23 core feature source has workflow_tdd conditional" "$CORE_FEATURE" '\{\{#workflow_tdd\}\}.*TDD.*default'
grep_case "v0.8.3 @s23 core CLAUDE source has workflow_tdd conditional" "$CORE_CLAUDE" '\{\{#workflow_tdd\}\}.*TDD.*default'
parity "v0.8.3 @s23 pmo CONVERSE parity" '^## CONVERSE$' "$CORE_PMO" "$PLUGIN_PMO"
parity "v0.8.3 @s23 fix paragraph parity" '^   If you cannot get a reproduction' "$CORE_FIX" "$PLUGIN_FIX"
parity "v0.8.3 @s23 principles just-go parity" 'autonomy_mode=autonomous.*setup' "$CORE_PRINCIPLES" "$PLUGIN_PRINCIPLES"
