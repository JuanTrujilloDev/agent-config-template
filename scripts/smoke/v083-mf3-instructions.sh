# v0.8.3 MF3 instruction-text debt (@s15..@s23).
CORE_FIX="$ROOT/core/.claude/commands/fix.md"; PLUGIN_FIX="$ROOT/plugin/commands/fix.md"
CORE_PRINCIPLES="$ROOT/core/.claude/rules/principles.md"; PLUGIN_PRINCIPLES="$ROOT/plugin/skills/principles/SKILL.md"
SETUP_TEMPLATE="$ROOT/plugin/commands/setup-template.md"; MASTER="$ROOT/core/docs/design-system/MASTER.md"

# @s15 (pmo CONVERSE order) retired in v0.11 with the pmo agent.

for f in "$CORE_FIX" "$PLUGIN_FIX"; do
  grep_case "v0.8.3 @s16 $(basename "$f") paragraph ends after cause" "$f" 'before naming the cause\.$'
  grep_case "v0.8.3 @s16 $(basename "$f") next paragraph starts repro fallback" "$f" '^   If you cannot get a reproduction'
done

TDD_ANS="$WORK/v083-mf3-tdd.env"; cp "$ROOT/examples/python-fastapi/answers.env" "$TDD_ANS"
printf '\nworkflow_mode=SDD+TDD\n' >>"$TDD_ANS"
TDD_RENDER="$WORK/v083-mf3-tdd"; SDD_RENDER="$WORK/v083-mf3-sdd"
bash "$ROOT/setup.sh" --target "$TDD_RENDER" --answers "$TDD_ANS" >/dev/null 2>&1
bash "$ROOT/setup.sh" --target "$SDD_RENDER" --answers "$ROOT/examples/python-fastapi/answers.env" >/dev/null 2>&1
# v0.11 chunk 1: CLAUDE.md runs tests-first in every workflow mode
for f in "$TDD_RENDER/CLAUDE.md" "$SDD_RENDER/CLAUDE.md"; do
  grep_case "v0.11 @s17 $(basename "$(dirname "$f")") CLAUDE.md runs tests-first" "$f" '`tests-first`'
done
for f in "$TDD_RENDER/CLAUDE.md"; do
  check "v0.8.3 @s17 TDD render omits optional TDD: $(basename "$f")" "0" "$(grep -ci 'optional TDD' "$f"; true)"
done

# v0.11 chunk 1: core principles keep only the session-scoped "just go"
grep_case "v0.11 @s18 principles.md just-go is session-only" "$CORE_PRINCIPLES" '"just go".*this session only; never write'
grep_case "v0.11 @s18 plugin principles just-go is session-only" "$PLUGIN_PRINCIPLES" '"just go".*this session only; never write'

# v0.11 dropped the workflow_mode question, so the last round item is 4.
grep_case "v0.11 @s19 setup item 4 is explicit" "$SETUP_TEMPLATE" '^   4\. [A-Za-z]'
check "v0.11 @s19 setup item 4 has no ellipsis" "0" "$(grep -c '^   4\. …' "$SETUP_TEMPLATE"; true)"
grep_case "v0.8.3 @s20 hard rule has just-go merge carve-out" "$SETUP_TEMPLATE" '[Jj]ust-go.*--merge|--merge.*[Jj]ust-go'
grep_case "v0.8.3 @s20 carve-out still forbids automatic overwrite" "$SETUP_TEMPLATE" '[Jj]ust-go.*--overwrite.*never|--overwrite.*never.*[Jj]ust-go'
grep_case "v0.8.3 @s21 --auto belongs to this command" "$SETUP_TEMPLATE" 'passes `--auto` to this command'

grep_case "v0.8.3 @s22 mobile device-class TODO" "$MASTER" 'Mobile.*TODO:.*device class|TODO:.*device class.*mobile'
grep_case "v0.8.3 @s22 game canvas-scaler TODO" "$MASTER" 'Game.*TODO:.*[Cc]anvas [Ss]caler|TODO:.*[Cc]anvas [Ss]caler.*game'

parity "v0.8.3 @s23 fix paragraph parity" '^   If you cannot get a reproduction' "$CORE_FIX" "$PLUGIN_FIX"
