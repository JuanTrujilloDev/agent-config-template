# v0.9.0 MF6 brownfield guide, README, and release (@s34..@s41).
V090_MF6_README="$ROOT/README.md"
V090_MF6_GUIDE="$ROOT/docs/guides/existing-projects.md"
V090_MF6_FIRST="$WORK/v090-mf6-first-80.md"
head -n 80 "$V090_MF6_README" >"$V090_MF6_FIRST"

for term in '[Ss]urvey' '[Pp]review' --merge '[Ss]ource of truth' '[Hh]ost' 'Gate 1' '[Cc]heck' '[Rr]ollback'; do
  grep_case "v0.9.0 @s34 brownfield guide covers $term" "$V090_MF6_GUIDE" "$term"
done
grep_case "v0.9.0 @s35 guide asks current tracker" "$V090_MF6_GUIDE" '[Ww]hat.*(tracker|tool).*(already|currently)|[Aa]sk.*(tracker|tool).*(already|currently)'
grep_case "v0.9.0 @s35 trackers optional" "$V090_MF6_GUIDE" '[Tt]racker.*optional|optional.*tracker'
for tool in graphify ponytail ui-ux-pro-max; do
  grep_case "v0.9.0 @s35 guide names $tool" "$V090_MF6_GUIDE" "$tool"
done
grep_case "v0.9.0 @s35 UI companion conditional" "$V090_MF6_GUIDE" 'ui-ux-pro-max.*`has_ui`|`has_ui`.*ui-ux-pro-max'

check "v0.9.0 @s38 README line budget" "0" "$(test "$(wc -l <"$V090_MF6_README" | tr -d ' ')" -le 253; echo $?)"
grep_case "v0.9.0 @s36 first 80 value" "$V090_MF6_FIRST" '[Ss]pec-driven.*(workflow|config)|[Ww]orkflow.*spec-driven'
for host in Claude Cursor Grok Codex; do
  grep_case "v0.9.0 @s36 first 80 names $host" "$V090_MF6_FIRST" "$host"
done
grep_case "v0.9.0 @s36 first 80 Claude install" "$V090_MF6_FIRST" 'plugin marketplace add'
grep_case "v0.9.0 @s36 first 80 Cursor install" "$V090_MF6_FIRST" 'Customize.*Plugins'
grep_case "v0.9.0 @s36 first 80 Grok install" "$V090_MF6_FIRST" 'Grok in Cursor'
grep_case "v0.9.0 @s36 first 80 Codex install" "$V090_MF6_FIRST" 'codex plugin marketplace add'
grep_case "v0.9.0 @s36 first 80 first command" "$V090_MF6_FIRST" '/(spec|feature)'
check "v0.9.0 @s37 one workflow diagram" "1" "$(grep -c '<!-- workflow-diagram -->' "$V090_MF6_README" | tr -d ' ')"
check "v0.9.0 @s37 one command table" "1" "$(grep -c '<!-- command-table -->' "$V090_MF6_README" | tr -d ' ')"
for term in 'FR-###' 'SC-###' 'NEEDS CLARIFICATION:' 'schema_version' 'Amended at' 'Principles deviation table'; do
  grep_case "v0.9.0 @s37 README grammar $term" "$V090_MF6_README" "$term"
done
for term in 'docs/upgrade-guide\.md' 'examples/' 'graphify' 'ponytail' 'ui-ux-pro-max' 'Credits' 'Support' 'License'; do
  grep_case "v0.9.0 @s38 README retains $term" "$V090_MF6_README" "$term"
done
grep_case "v0.9.0 @s39 README credits Spec Kit" "$V090_MF6_README" 'github\.com/github/spec-kit'
grep_case "v0.9.0 @s39 README says MIT inspiration" "$V090_MF6_README" 'MIT-licensed inspiration'
grep_case "v0.9.0 @s39 README denies copied artifacts" "$V090_MF6_README" '[Nn]o artifacts.*copied'
grep_case "v0.9.0 @s39 README denies affiliation" "$V090_MF6_README" '[Nn]ot affiliated'

for f in "$ROOT/plugin/.claude-plugin/plugin.json" "$ROOT/.claude-plugin/marketplace.json" "$ROOT/.cursor-plugin/plugin.json" "$ROOT/codex/.codex-plugin/plugin.json"; do
  check "v0.9.0 @s40 $(basename "$f") version" "0.9.0" "$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print((d.get("plugins") or [d])[0]["version"])' "$f")"
done
grep_case "v0.9.0 @s40 upgrade section" "$ROOT/docs/upgrade-guide.md" '^## Upgrading to v0\.9\.0'
for term in 'FR/SC' 'schema v2' 'amend' 'principles'; do
  grep_case "v0.9.0 @s40 upgrade names $term" "$ROOT/docs/upgrade-guide.md" "$term"
done
python3 "$ROOT/scripts/validate-packaging.py" >"$WORK/v090-mf6-packaging.out" 2>&1
check "v0.9.0 @s40 packaging valid" "0" "$?"
grep_case "v0.9.0 @s40 packaging reports version" "$WORK/v090-mf6-packaging.out" 'packaging valid @ v0\.9\.0'

CURSOR_PLUGIN="$ROOT/.cursor-plugin/plugin.json"
check "v0.9.0 Cursor plugin JSON" "0" "$(python3 -m json.tool "$CURSOR_PLUGIN" >/dev/null 2>&1; echo $?)"
for field in rules agents skills commands hooks; do
  check "v0.9.0 Cursor manifest $field exists" "0" "$(python3 -c 'import json,os,sys; v=json.load(open(sys.argv[1]))[sys.argv[2]]; ps=v if isinstance(v,list) else [v]; root=os.path.dirname(os.path.dirname(sys.argv[1])); raise SystemExit(0 if all(os.path.exists(os.path.join(root,p)) for p in ps) else 1)' "$CURSOR_PLUGIN" "$field"; echo $?)"
done
check "v0.9.0 Cursor docs reject clone install" "0" "$(grep -ci 'from a clone\|git clone' "$ROOT/docs/install/cursor.md"; true)"
grep_case "v0.9.0 Cursor docs native install" "$ROOT/docs/install/cursor.md" 'Customize.*Plugins'
grep_case "v0.9.0 Cursor setup uses plugin root" "$ROOT/plugin/commands/setup-template.md" 'CURSOR_PLUGIN_ROOT'
for f in "$ROOT"/plugin/commands/setup-{template,companions}.md; do
  grep_case "v0.9.0 Cursor command $(basename "$f") has name" "$f" '^name: [a-z0-9-]+$'
done
bash -n "$ROOT/plugin/.cursor-plugin/hooks/branch-guard.sh" "$ROOT/plugin/.cursor-plugin/hooks/format-on-edit.sh"
check "v0.9.0 Cursor plugin hook shell syntax" "0" "$?"
HOOK_REPO="$WORK/v090-cursor-hook"
mkdir -p "$HOOK_REPO"
git -C "$HOOK_REPO" init -q -b main
git -C "$HOOK_REPO" -c user.name=test -c user.email=test@example.com commit --allow-empty -q -m init
HOOK_OUT=$(cd "$HOOK_REPO" && printf '%s' '{"command":"git commit -m test"}' | bash "$ROOT/plugin/.cursor-plugin/hooks/branch-guard.sh")
check "v0.9.0 Cursor plugin blocks protected commit" "deny" "$(printf '%s' "$HOOK_OUT" | python3 -c 'import json,sys; print(json.load(sys.stdin)["permission"])')"
