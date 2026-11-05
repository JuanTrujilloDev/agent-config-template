# MF4 brand-system (@s25..@s32) — templated docs/design-system/MASTER.md gated by has_ui,
# read-before-act lines in ui-designer and implement, code-review brand check, /design refresh, cursor + plugin parity.
MASTER_SRC="$ROOT/core/docs/design-system/MASTER.md"
SECTIONS='Colors & semantic tokens|Typography|Spacing & layout|Radius, shadows & motion|Component conventions|Icon & image style|Voice & tone|Responsive rules|Accessibility & contrast|Anti-patterns'

# @s25 — source: requires guard on line 1, exactly the ten H2s in order, page-overrides note
check "@s25 line 1 requires has_ui" "<!-- requires: has_ui -->" "$(head -1 "$MASTER_SRC" 2>/dev/null)"
check "@s25 ten H2 sections in order" "$SECTIONS" "$(h2_list "$MASTER_SRC")"
grep_case "@s25 page overrides note" "$MASTER_SRC" 'docs/design-system/pages/<page>\.md'
grep_case "@s25 overrides only when a page must deviate" "$MASTER_SRC" '[Oo]nly when.*deviat'
# @s26 — rendered: present + placeholder-free + TODO markers for has_ui examples; absent for API-only
for ex in node-nextjs flutter-mobile unity-game; do
  H="$WORK/brand-$ex"; bash "$ROOT/setup.sh" --target "$H" --answers "$ROOT/examples/$ex/answers.env" >/dev/null 2>&1
  M="$H/docs/design-system/MASTER.md"
  check "@s26 $ex MASTER.md rendered" "1" "$([ -f "$M" ] && echo 1 || echo 0)"
  check "@s26 $ex ten H2 in order" "$SECTIONS" "$(h2_list "$M")"
  check "@s26 $ex zero {{ leftovers" "0" "$(grep -cE "$PH" "$M" 2>/dev/null; true)"
  check "@s26 $ex requires guard stripped" "0" "$(grep -c 'requires: has_ui' "$M" 2>/dev/null; true)"
  grep_case "@s26 $ex TODO markers" "$M" 'TODO:'
  grep_case "@s26 $ex page overrides note" "$M" 'docs/design-system/pages/<page>\.md'
done
check "@s26 python-fastapi (has_frontend=no) MASTER.md absent" "0" "$([ -e "$WORK/docs/design-system/MASTER.md" ] && echo 1 || echo 0)"
# @s27 — cursor host render carries the file (build copies core/docs into cursor/)
H="$WORK/brand-cursor"; bash "$ROOT/setup.sh" --target "$H" --host cursor --answers "$ROOT/examples/node-nextjs/answers.env" >/dev/null 2>&1
check "@s27 cursor MASTER.md rendered" "1" "$([ -f "$H/docs/design-system/MASTER.md" ] && echo 1 || echo 0)"
check "@s27 cursor zero {{ leftovers" "0" "$(grep -cE "$PH" "$H/docs/design-system/MASTER.md" 2>/dev/null; true)"
# @s28 — v0.11: ui-designer and the implement skill read MASTER.md (+ pages/<page>.md) and cite tokens
# before UI work (the frontend-dev/mobile-dev agents are gone).
NEXT="$WORK/brand-node-nextjs"
for A in "$ROOT/core/.claude/agents/ui-designer.md" "$ROOT/core/.claude/skills/implement/SKILL.md"; do
  n=$(basename "$(dirname "$A")")/$(basename "$A")
  grep_case "@s28 $n reads MASTER.md" "$A" 'docs/design-system/MASTER\.md'
  grep_case "@s28 $n pages override" "$A" 'pages/<page>\.md'
  grep_case "@s28 $n cites tokens" "$A" '[Cc]ite.*tokens'
done
before "@s28 ui-designer reads before wireframes" "$ROOT/core/.claude/agents/ui-designer.md" 'docs/design-system/MASTER\.md' 'Create wireframes'
before "@s28 implement reads before writing code" "$ROOT/core/.claude/skills/implement/SKILL.md" 'docs/design-system/MASTER\.md' 'Implement to green'
grep_case "@s28 rendered implement keeps the MASTER.md ref" "$NEXT/.claude/skills/implement/SKILL.md" 'docs/design-system/MASTER\.md'
# @s29 — v0.11: code-review (judge's successor) flags untraceable UI values, citing file:line
J="$ROOT/core/.claude/skills/code-review/SKILL.md"
grep_case "@s29 code-review UI design-system source" "$J" 'docs/design-system/MASTER\.md'
grep_case "@s29 code-review names color/spacing/radius/font" "$J" 'hardcoded.*colou?r.*spacing.*radius.*font'
grep_case "@s29 code-review reports file:line" "$J" 'file:line'
check "@s29 rendered code-review zero {{ leftovers" "0" "$(grep -cE "$PH" "$NEXT/.claude/skills/code-review/SKILL.md" 2>/dev/null; true)"
# @s30 — /design step 2: read MASTER.md, create from the @s25 list when missing, optional ui-ux-pro-max delegate then normalize
D="$ROOT/core/.claude/commands/design.md"
awk '/^2\. /{on=1} /^3\. /{exit} on' "$D" >"$WORK/design_2.md"
grep_case "@s30 step 2 reads MASTER.md" "$WORK/design_2.md" 'docs/design-system/MASTER\.md'
grep_case "@s30 step 2 creates when missing" "$WORK/design_2.md" '([Cc]reate|[Ww]rite).*(missing|absent)|(missing|absent).*([Cc]reate|[Ww]rite)'
grep_case "@s30 step 2 lists the ten sections" "$WORK/design_2.md" 'Colors & semantic tokens.*Anti-patterns'
grep_case "@s30 step 2 may delegate to ui-ux-pro-max" "$WORK/design_2.md" 'ui-ux-pro-max.*(delegate|installed)|(delegate|installed).*ui-ux-pro-max'
grep_case "@s30 step 2 normalizes after delegation" "$WORK/design_2.md" '[Nn]ormali[sz]e'
grep_case "@s30 ui-ux-pro-max optional, never vendored" "$D" 'ui-ux-pro-max.*optional.*never vendored|optional.*never vendored.*ui-ux-pro-max'
# @s31 — plugin mirrors carry the same additions, placeholder-free
parity "@s31 plugin ui-designer MASTER.md refs" 'docs/design-system/MASTER\.md' "$ROOT/core/.claude/agents/ui-designer.md" "$ROOT/plugin/agents/ui-designer.md"
check "@s31 plugin ui-designer zero {{" "0" "$(grep -cE "$PH" "$ROOT/plugin/agents/ui-designer.md" 2>/dev/null; true)"
parity "@s31 plugin code-review brand check" 'hardcoded.*colou?r.*spacing.*radius.*font' "$J" "$ROOT/plugin/skills/code-review/SKILL.md"
parity "@s31 plugin design MASTER.md refs" 'docs/design-system/MASTER\.md' "$D" "$ROOT/plugin/commands/design.md"
parity "@s31 plugin design ui-ux-pro-max" 'ui-ux-pro-max' "$D" "$ROOT/plugin/commands/design.md"
check "@s31 plugin design zero {{" "0" "$(grep -cE "$PH" "$ROOT/plugin/commands/design.md" 2>/dev/null; true)"
# @s32 — build --check clean; cursor copy is byte-identical to core source
check "@s32 build --check clean" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
check "@s32 cursor MASTER.md == core" "0" "$(cmp -s "$MASTER_SRC" "$ROOT/cursor/docs/design-system/MASTER.md"; echo $?)"
# (no MANUAL scenarios in MF4 — @s25..@s32 are all executable)
