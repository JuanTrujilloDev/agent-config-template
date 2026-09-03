# v0.10.0 MF2 brand-tokens-code (@s9..@s15).
TOKENS_SRC="$ROOT/core/docs/design-system/tokens.json"
DESIGN_SRC="$ROOT/core/.claude/commands/design.md"
DESIGN_PLUGIN="$ROOT/plugin/commands/design.md"
JUDGE_SRC="$ROOT/core/.claude/agents/judge.md"
JUDGE_PLUGIN="$ROOT/plugin/agents/judge.md"
UI_ANS="$ROOT/examples/node-nextjs/answers.env"
NO_UI_ANS="$ROOT/examples/python-fastapi/answers.env"

# @s9/@s10 — capability-gated valid token source.
UI="$WORK/v010-ui"; NO_UI="$WORK/v010-no-ui"
bash "$ROOT/setup.sh" --target "$UI" --answers "$UI_ANS" >/dev/null 2>&1
bash "$ROOT/setup.sh" --target "$NO_UI" --answers "$NO_UI_ANS" >/dev/null 2>&1
check "v0.10.0 @s9 UI tokens render" "1" "$([ -f "$UI/docs/design-system/tokens.json" ] && echo 1 || echo 0)"
check "v0.10.0 @s9 rendered tokens parse" "0" "$(python3 -m json.tool "$UI/docs/design-system/tokens.json" >/dev/null 2>&1; echo $?)"
for group in colors typography spacing radii shadows motion; do
  grep_case "v0.10.0 @s9 tokens group $group" "$UI/docs/design-system/tokens.json" "\"$group\""
done
grep_case "v0.10.0 @s9 MASTER points at tokens" "$UI/docs/design-system/MASTER.md" 'tokens\.json.*value source|value source.*tokens\.json'
check "v0.10.0 @s10 no-UI tokens absent" "0" "$([ -e "$NO_UI/docs/design-system/tokens.json" ] && echo 1 || echo 0)"
check "v0.10.0 @s10 no-UI MASTER absent" "0" "$([ -e "$NO_UI/docs/design-system/MASTER.md" ] && echo 1 || echo 0)"

# @s11/@s12 — design chooses one native adapter and records portable hashes.
for file in "$DESIGN_SRC" "$DESIGN_PLUGIN"; do
  grep_case "v0.10.0 @s11 $(basename "$file") exactly one target" "$file" '[Ee]xactly one.*(target|adapter)|one relevant.*(target|adapter)'
  for adapter in 'CSS custom properties' 'ThemeExtension|ThemeData' 'ScriptableObject' 'native.*theme' 'JSON-only'; do
    grep_case "v0.10.0 @s11 $(basename "$file") adapter $adapter" "$file" "$adapter"
  done
  grep_case "v0.10.0 @s12 $(basename "$file") lock path" "$file" 'tokens\.lock\.json'
  for field in source_sha256 target_sha256 adapter target; do
    grep_case "v0.10.0 @s12 $(basename "$file") lock field $field" "$file" "$field"
  done
  grep_case "v0.10.0 @s12 $(basename "$file") relative paths" "$file" '[Rr]elative.*path|paths.*relative'
done

# @s13/@s14 — judge blocks drift/raw forks.
for file in "$JUDGE_SRC" "$JUDGE_PLUGIN"; do
  grep_case "v0.10.0 @s13 $(basename "$file") reads token source" "$file" 'tokens\.json'
  grep_case "v0.10.0 @s13 $(basename "$file") checks hashes" "$file" 'source_sha256.*target_sha256|target_sha256.*source_sha256'
  grep_case "v0.10.0 @s13 $(basename "$file") blocks stale" "$file" '[Ss]tale.*hard-violation|hard-violation.*[Ss]tale'
  grep_case "v0.10.0 @s14 $(basename "$file") blocks raw forks" "$file" '[Rr]aw.*brand.*hard-violation|hard-violation.*[Rr]aw.*brand'
done

# @s15 — generated host surfaces and user-owned merge behavior.
check "v0.10.0 @s15 core tokens generated to plugin" "0" "$(diff -q "$TOKENS_SRC" "$ROOT/plugin/template/docs/design-system/tokens.json" >/dev/null 2>&1; echo $?)"
check "v0.10.0 @s15 core tokens generated to cursor" "0" "$(diff -q "$TOKENS_SRC" "$ROOT/cursor/docs/design-system/tokens.json" >/dev/null 2>&1; echo $?)"
grep_case "v0.10.0 @s15 codex design carries adapters" "$ROOT/codex/skills/design/SKILL.md" 'CSS custom properties'
printf '\n"user-edit"\n' >>"$UI/docs/design-system/tokens.json"
bash "$ROOT/setup.sh" --target "$UI" --answers "$UI_ANS" --merge >/dev/null 2>&1
grep_case "v0.10.0 @s15 merge keeps user token file" "$UI/docs/design-system/tokens.json" 'user-edit'
