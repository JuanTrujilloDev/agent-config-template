# v0.9.1 MF5 agent-style evidence and release (@s34..@s40).
for side in core plugin; do
  if [ "$side" = core ]; then command_dir="$ROOT/core/.claude/commands"; else command_dir="$ROOT/plugin/commands"; fi
  for name in audit design feature fix; do
    f="$command_dir/$name.md"
    grep_case "v0.9.1 @s34 $side/$name reads style once" "$f" '[Rr]ead `agent_style`.*once'
    grep_case "v0.9.1 @s34 $side/$name terse fallback" "$f" '(absent|missing).*`terse`|fallback.*`terse`'
    grep_case "v0.9.1 @s34 $side/$name standard handoff" "$f" 'agent_style: <terse\|descriptive> — return per "Report format"'
    grep_case "v0.9.1 @s34 $side/$name covers subagents" "$f" '[Ee]very subagent prompt|[Ee]very subagent.*spawn'
  done
done

V091_STYLE_AGENTS=$(grep -Rl 'agent_style' "$ROOT/core/.claude/agents" "$ROOT/plugin/agents" 2>/dev/null | sed "s#$ROOT/##" | sort)
V091_STYLE_EXPECTED='core/.claude/agents/orchestrator.md
plugin/agents/orchestrator.md'
check "v0.9.1 @s35/@s36 no redundant agent pointers" "$V091_STYLE_EXPECTED" "$V091_STYLE_AGENTS"
grep_case "v0.9.1 @s35 upgrade records evidence" "$ROOT/docs/upgrade-guide.md" '[Ff]ocused check.*agent_style'
grep_case "v0.9.1 @s35 upgrade records no pointers" "$ROOT/docs/upgrade-guide.md" '[Nn]o per-agent pointers were added'

grep_case "v0.9.1 @s37 README credits Matt Pocock" "$ROOT/README.md" 'github\.com/mattpocock/skills'
grep_case "v0.9.1 @s37 README says MIT inspiration" "$ROOT/README.md" 'Matt Pocock.*MIT|MIT.*Matt Pocock'
grep_case "v0.9.1 @s37 README names original material" "$ROOT/README.md" '[Ww]ording and artifacts'
grep_case "v0.9.1 @s37 README says original" "$ROOT/README.md" '[Oo]riginal to this project'
grep_case "v0.9.1 @s37 README denies affiliation" "$ROOT/README.md" '[Nn]ot affiliated.*Matt Pocock|Matt Pocock.*not affiliated'

V091_CURRENT_VERSION=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["version"])' "$ROOT/plugin/.claude-plugin/plugin.json")
for f in "$ROOT/plugin/.claude-plugin/plugin.json" "$ROOT/.claude-plugin/marketplace.json" "$ROOT/.cursor-plugin/plugin.json" "$ROOT/codex/.codex-plugin/plugin.json"; do
  V091_MANIFEST_VERSION=$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print((d.get("plugins") or [d])[0]["version"])' "$f")
  check "v0.9.1 @s38 $(basename "$f") version stays aligned" "$V091_CURRENT_VERSION" "$V091_MANIFEST_VERSION"
done

grep_case "v0.9.1 @s39 upgrade section" "$ROOT/docs/upgrade-guide.md" '^## Upgrading to v0\.9\.1'
for term in 'pinned review scope' 'Spec fidelity' 'two review cycles' 'public behavior seams' 'schema v2'; do
  grep_case "v0.9.1 @s39 upgrade names $term" "$ROOT/docs/upgrade-guide.md" "$term"
done

check "v0.9.1 @s40 build --check" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
V091_PACKAGING=$(cd "$ROOT" && python3 scripts/validate-packaging.py 2>&1); V091_PACKAGING_RC=$?
check "v0.9.1 @s40 packaging valid" "0" "$V091_PACKAGING_RC"
grep_case "v0.9.1 @s40 packaging reports current version" <(printf '%s\n' "$V091_PACKAGING") "v${V091_CURRENT_VERSION}"
