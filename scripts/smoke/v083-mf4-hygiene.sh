# v0.8.3 MF4 build/test hygiene (@s24..@s31).
BUILD="$ROOT/scripts/build.sh"; VALIDATOR="$ROOT/scripts/validate-packaging.py"
LIB="$ROOT/scripts/smoke/lib.sh"; MERGE_SMOKE="$ROOT/scripts/smoke/mf7-merge.sh"
FIXTURE="$ROOT/scripts/smoke/fixtures/stale-render"

for fn in build_codex_skills build_cursor_tree; do
  awk -v fn="$fn" '$0 ~ "^" fn "\\(\\)" { on=1 } on { print } on && /^}/ { exit }' "$BUILD" >"$WORK/$fn.txt"
  grep_case "v0.8.3 @s24 $fn local out" "$WORK/$fn.txt" '^  local out='
  grep_case "v0.8.3 @s24 $fn local name/desc" "$WORK/$fn.txt" '^  local .*name.*desc|^  local .*desc.*name'
done
check "v0.8.3 @s24 build remains Bash 3.2 syntax" "0" "$(bash -n "$BUILD" 2>/dev/null; echo $?)"

check "v0.8.3 @s25 valid frontmatter passes with PyYAML" "0" "$(cd "$ROOT" && python3 "$VALIDATOR" >/dev/null 2>&1; echo $?)"
check "v0.8.3 @s26 valid frontmatter passes without PyYAML" "0" "$(cd "$ROOT" && python3 -S "$VALIDATOR" >/dev/null 2>&1; echo $?)"
(
  target="$ROOT/plugin/commands/audit.md"; backup="$WORK/audit.md.bak"
  cp "$target" "$backup"
  trap 'cp "$backup" "$target"; rm -f "$target.tmp"' EXIT HUP INT TERM
  sed -i.tmp 's/^description:.*/description: "Code "quality" audit."/' "$target"
  (cd "$ROOT" && python3 "$VALIDATOR") >"$WORK/validator-yaml.out" 2>&1; echo $? >"$WORK/validator-yaml.rc"
  (cd "$ROOT" && python3 -S "$VALIDATOR") >"$WORK/validator-stdlib.out" 2>&1; echo $? >"$WORK/validator-stdlib.rc"
)
check "v0.8.3 @s25 inner quote fails with PyYAML" "1" "$([ "$(cat "$WORK/validator-yaml.rc")" -ne 0 ] && echo 1 || echo 0)"
grep_case "v0.8.3 @s25 PyYAML error identifies description" "$WORK/validator-yaml.out" 'description'
check "v0.8.3 @s26 inner quote fails without PyYAML" "1" "$([ "$(cat "$WORK/validator-stdlib.rc")" -ne 0 ] && echo 1 || echo 0)"
grep_case "v0.8.3 @s26 stdlib error identifies description" "$WORK/validator-stdlib.out" 'description'

check "v0.8.3 @s27 first_line drops dead sed" "0" "$(grep -c "sed 's/\^\\\$/0/'" "$LIB"; true)"
printf 'alpha\nbeta\n' >"$WORK/order.txt"
check "v0.8.3 @s27 first_line match unchanged" "2" "$(first_line "$WORK/order.txt" beta)"
check "v0.8.3 @s27 first_line missing stays empty" "" "$(first_line "$WORK/order.txt" missing)"
check "v0.8.3 @s27 before accepts ordered matches" "0" "$(FAIL=0; before test "$WORK/order.txt" alpha beta >/dev/null; echo "$FAIL")"
check "v0.8.3 @s27 before rejects missing matches" "1" "$(FAIL=0; before test "$WORK/order.txt" missing beta >/dev/null; echo "$FAIL")"

EXPECTED='.claude/CLAUDE.md
.claude/agents/backend-dev.md
.claude/agents/frontend-dev.md
.claude/rules/backend-style.md'
ACTUAL="$(cd "$FIXTURE" 2>/dev/null && find . -type f | sed 's#^./##' | sort)"
check "v0.8.3 @s28 stale fixture has exactly four expected files" "$EXPECTED" "$ACTUAL"
check "v0.8.3 @s28 merge smoke uses checked-in fixture" "1" "$(grep -c 'fixtures/stale-render' "$MERGE_SMOKE"; true)"
check "v0.8.3 @s28 old portfolio MANUAL check removed" "0" "$(grep -cE '# MANUAL:.*portfolio|real portfolio' "$MERGE_SMOKE"; true)"

if [ -d "$FIXTURE/.claude" ]; then
  fixture_target="$WORK/v083-mf4-stale"
  bash "$ROOT/setup.sh" --target "$fixture_target" --answers "$ROOT/examples/python-django/answers.env" >/dev/null 2>&1
  rm "$fixture_target/.claude/CLAUDE.md"
  cp -R "$FIXTURE/.claude/." "$fixture_target/.claude/"
  python3 -c 'import hashlib,json,sys; p=sys.argv[1]; d=json.load(open(p)); root=sys.argv[2]; rels=sys.argv[3:]; d["files"].update({r:{"template_version":"0.8.2","sha256":hashlib.sha256(open(root+"/"+r,"rb").read()).hexdigest()} for r in rels}); json.dump(d,open(p,"w"),indent=2,sort_keys=True); open(p,"a").write("\n")' \
    "$fixture_target/agent-config.lock.json" "$fixture_target" \
    .claude/agents/backend-dev.md .claude/agents/frontend-dev.md .claude/rules/backend-style.md
  fixture_out=$(bash "$ROOT/setup.sh" --target "$fixture_target" --answers "$ROOT/examples/python-django/answers.env" 2>&1); fixture_rc=$?
  check "v0.8.3 @s28 fixture plan exits 1" "1" "$fixture_rc"
  for path in .claude/agents/backend-dev.md .claude/agents/frontend-dev.md .claude/rules/backend-style.md; do
    grep_case "v0.8.3 @s28 fixture labels $path stale" <(printf '%s\n' "$fixture_out") "STALE-MANAGED +$path"
  done
  grep_case "v0.8.3 @s28 fixture labels regular CLAUDE conflict" <(printf '%s\n' "$fixture_out") 'SYMLINK-CONFLICT +\.claude/CLAUDE\.md'
fi

check "v0.8.3 @s29 adaptive MF8 tracks scripts/smoke.sh" "1" "$(python3 - "$ROOT/docs/specs/adaptive-skills/features.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
mf = next(item for item in data["mini_features"] if item["id"] == 8)
print(int("scripts/smoke.sh" in mf.get("files_hint", mf.get("files", []))))
PY
)"

for f in core/.claude/commands/audit.md core/.claude/commands/design.md core/.claude/commands/fix.md plugin/commands/audit.md plugin/commands/design.md plugin/commands/fix.md; do
  file="$ROOT/$f"
  grep_case "v0.8.3 @s30 $f reads agent_style once" "$file" 'Read `agent_style`.*once'
  grep_case "v0.8.3 @s30 $f terse fallback" "$file" 'absent.*`terse`|fallback.*`terse`'
  grep_case "v0.8.3 @s30 $f standard prompt line" "$file" 'agent_style: <terse\|descriptive> — return per "Report format"'
  grep_case "v0.8.3 @s30 $f every spawned subagent" "$file" '[Ee]very subagent prompt.*spawns|[Ee]very subagent.*spawn'
  grep_case "v0.8.3 @s30 $f persisted artifacts stay prose" "$file" '[Pp]ersisted artifacts.*prose'
done
