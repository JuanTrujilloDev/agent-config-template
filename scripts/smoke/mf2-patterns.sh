# MF2 patterns-rule (@s10..@s17) — rule text, six domain references, plugin skill,
# generated copies (cursor/codex), host renders, packaging, lean always-loaded surface.
DOMAINS="backend frontend mobile game desktop concurrency"
RULE="$WORK/.claude/rules/patterns.md"
SKILL="$ROOT/plugin/skills/patterns/SKILL.md"
ANS="$ROOT/examples/python-fastapi/answers.env"

# @s10 — rendered rule: size + restraint rules in order
line_max "@s10 rule <=120 lines" "$RULE" 120
grep_case "@s10 inspect existing first (code-query)" "$RULE" 'code-query\.md'
grep_case "@s10 name the force" "$RULE" '[Nn]ame the (present )?force'
grep_case "@s10 one-line why" "$RULE" '[Oo]ne-line why'
grep_case "@s10 refusal wording" "$RULE" 'no pattern — single call site'
grep_case "@s10 reject Strategy" "$RULE" 'Strategy'
grep_case "@s10 reject Repository" "$RULE" '[Ss]peculative Repository|Repository.*speculative'
grep_case "@s10 reject Factory" "$RULE" 'Factory'
grep_case "@s10 reject Singleton" "$RULE" 'Singleton'
grep_case "@s10 reject Service Locator" "$RULE" 'Service Locator'
grep_case "@s10 ledger columns" "$RULE" 'pattern / force / rejected alternative'
grep_case "@s10 progressive disclosure" "$RULE" 'force.*(points|routes).*(there|reference)|read.*only when'
check "@s10 order inspect<force<why<refusal<reject<ledger" "1" "$(awk '
  /code-query\.md/&&!a{a=NR} /[Nn]ame the (present )?force/&&!b{b=NR} /[Oo]ne-line why/&&!c{c=NR}
  /no pattern — single call site/&&!d{d=NR} /Service Locator/&&!e{e=NR} /pattern \/ force \/ rejected alternative/&&!f{f=NR}
  END{print (a&&a<b&&b<c&&c<d&&d<e&&e<f)?1:0}' "$RULE" 2>/dev/null)"
for d in $DOMAINS; do grep_case "@s10 table links $d" "$RULE" "\.claude/patterns/$d\.md"; done
# @s11 — six references in core and rendered tree
check "@s11 exactly six core refs" "6" "$(ls "$ROOT"/core/.claude/patterns/*.md 2>/dev/null | wc -l | tr -d ' ')"
for d in $DOMAINS; do
  f="$WORK/.claude/patterns/$d.md"
  line_max "@s11 $d <=150 lines" "$f" 150
  grep_case "@s11 $d simplest default first" "$f" 'Simplest default first'
  grep_case "@s11 $d force->pattern table header" "$f" '^\| *[Ff]orce *\|.*[Pp]attern'
  check "@s11 $d no mustache" "0" "$([ -f "$f" ] && { grep -c '{{' "$f"; true; } || echo missing)"
done
# @s12 — plugin skill: strict frontmatter, skill-style refs, points at references
check "@s12 skill frontmatter opens" "---" "$(head -1 "$SKILL" 2>/dev/null)"
grep_case "@s12 skill description" "$SKILL" '^description: "'
grep_case "@s12 skill code-query skill ref" "$SKILL" 'the `code-query` skill'
grep_case "@s12 skill refusal wording" "$SKILL" 'no pattern — single call site'
grep_case "@s12 skill -> template patterns" "$SKILL" 'CLAUDE_PLUGIN_ROOT\}/template/\.claude/patterns/'
grep_case "@s12 skill -> references/" "$SKILL" 'references/'
# @s13 — generated copies byte-equal to core; --check flags hand-edits
check "@s13 cursor patterns == core" "0" "$(diff -r "$ROOT/core/.claude/patterns" "$ROOT/cursor/.claude/patterns" >/dev/null 2>&1; echo $?)"
check "@s13 cursor rules/patterns.md exists" "1" "$([ -f "$ROOT/cursor/.claude/rules/patterns.md" ] && echo 1 || echo 0)"
grep_case "@s13 codex skill name" "$ROOT/codex/skills/patterns/SKILL.md" '^name: patterns$'
check "@s13 codex references == core" "0" "$(diff -r "$ROOT/core/.claude/patterns" "$ROOT/codex/skills/patterns/references" >/dev/null 2>&1; echo $?)"
check "@s13 --check clean" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
seed_check "@s13 --check flags cursor hand-edit" "$ROOT/cursor/.claude/patterns/backend.md"
seed_check "@s13 --check flags codex hand-edit" "$ROOT/codex/skills/patterns/references/backend.md"
# @s14 — host renders
for h in grok cursor; do
  H="$WORK/host-$h"; bash "$ROOT/setup.sh" --target "$H" --host "$h" --answers "$ANS" >/dev/null 2>&1
  check "@s14 $h rule rendered" "1" "$([ -f "$H/.claude/rules/patterns.md" ] && echo 1 || echo 0)"
  check "@s14 $h six refs" "6" "$(ls "$H"/.claude/patterns/*.md 2>/dev/null | wc -l | tr -d ' ')"
done
H="$WORK/host-codex"; bash "$ROOT/setup.sh" --target "$H" --host codex --answers "$ANS" >/dev/null 2>&1
check "@s14 codex skill rendered" "1" "$([ -f "$H/.agents/skills/patterns/SKILL.md" ] && echo 1 || echo 0)"
check "@s14 codex six refs" "6" "$(ls "$H"/.agents/skills/patterns/references/*.md 2>/dev/null | wc -l | tr -d ' ')"
# @s15 — validate-packaging passes; seeded unquoted-invalid description fails
check "@s15 validate-packaging passes" "0" "$(cd "$ROOT" && python3 scripts/validate-packaging.py >/dev/null 2>&1; echo $?)"
if [ -f "$SKILL" ]; then
  cp "$SKILL" "$WORK/skill.bak"
  sed -i.tmp '2s/.*/description: restraint: rules: for patterns/' "$SKILL"; rm -f "$SKILL.tmp"
  rc=$(cd "$ROOT" && python3 scripts/validate-packaging.py >/dev/null 2>&1; echo $?)
  mv "$WORK/skill.bak" "$SKILL"
  check "@s15 seeded invalid YAML fails" "1" "$rc"
else check "@s15 seeded invalid YAML fails" "1" "skill missing"; fi
# @s16 — READMEs count seven skills and name patterns
grep_case "@s16 plugin README seven skills" "$ROOT/plugin/README.md" '\*\*7 skills\*\*|[Ss]even skills'
grep_case "@s16 plugin README names patterns" "$ROOT/plugin/README.md" '`patterns`'
grep_case "@s16 README names patterns" "$ROOT/README.md" '`patterns`'
# lean always-loaded surface: CLAUDE.md + principles.md reference patterns.md at most once each
check "@s10 CLAUDE.md refs patterns.md <=1" "1" "$([ "$(grep -c 'rules/patterns\.md' "$WORK/CLAUDE.md" 2>/dev/null; true)" -le 1 ] && echo 1 || echo 0)"
check "@s10 principles.md refs patterns.md <=1" "1" "$([ "$(grep -c 'rules/patterns\.md' "$PRIN" 2>/dev/null; true)" -le 1 ] && echo 1 || echo 0)"
# MANUAL @s17 — /spec on brief "add a single CSV export endpoint for orders" with the rule loaded: Design notes read `no pattern — single call site`; no pattern name appears.
