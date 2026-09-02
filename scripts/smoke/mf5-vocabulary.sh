# MF5 workflow-vocabulary (@s33..@s39) — sentences in existing files: pmo intent-first +
# brownfield + lazy docs/CONTEXT.md glossary, /fix red-repro gate, tooling-upgrade
# separation, sdd-workflow taxonomy note, plugin/codex parity, CLAUDE.md untouched.
PMO_SRC="$ROOT/core/.claude/agents/pmo.md"; FIX="$WORK/.claude/commands/fix.md"
FIX_SRC="$ROOT/core/.claude/commands/fix.md"; FEAT_SRC="$ROOT/core/.claude/commands/feature.md"
SPEC_SRC="$ROOT/core/.claude/commands/spec.md"; UPG="$ROOT/docs/upgrade-guide.md"
SDD="$ROOT/docs/sdd-workflow.md"; P_SDD="$ROOT/plugin/skills/sdd-workflow/SKILL.md"
X_SDD="$ROOT/hosts/codex/skills/sdd-workflow/SKILL.md"
GLOSSARY='\*\*Term\*\* — what it IS \(1–2 sentences\)\. Avoid: <synonyms>'
UPGRADE_SEP='setup\.sh --merge.*`?chore:?`?.*(never|not) mixed|(never|not) mixed.*setup\.sh --merge'

# @s33 — pmo CONVERSE: intent (user-observable change) before implementation; brownfield = survey via code-query, spec the change
grep_case "@s33 pmo intent = user-observable change" "$PMO" '\*\*[Ii]ntent\*\*.*user-observable|user-observable.*\*\*[Ii]ntent\*\*'
grep_case "@s33 pmo intent before implementation" "$PMO" '[Ii]ntent.*before.*implementation'
grep_case "@s33 pmo brownfield surveys via code-query" "$PMO" '[Bb]rownfield.*code-query\.md|code-query\.md.*[Bb]rownfield'
grep_case "@s33 pmo spec defines the change, not a retro-spec" "$PMO" 'defines the change, not a retro-spec'
before "@s33 pmo intent precedes brownfield note" "$PMO" 'user-observable' 'retro-spec'
# @s34 — pmo reads docs/CONTEXT.md at CONVERSE when present, creates lazily; glossary format; never rendered
grep_case "@s34 pmo reads CONTEXT.md when present" "$PMO" 'docs/CONTEXT\.md.*(when|if) (present|it exists)|(when|if) (present|it exists).*docs/CONTEXT\.md'
grep_case "@s34 pmo creates lazily on first project term" "$PMO" '[Ll]azily.*(first|coin|disambiguat)|(first|coin|disambiguat).*[Ll]azily'
grep_case "@s34 pmo glossary entry format" "$PMO" "$GLOSSARY"
grep_case "@s34 pmo project terms only" "$PMO" '[Pp]roject terms only'
before "@s34 pmo CONTEXT.md read at CONVERSE (before Decomposition rules)" "$PMO" 'docs/CONTEXT\.md' '^## Decomposition rules'
check "@s34 CONTEXT.md referenced nowhere else in core/" "" "$(cd "$ROOT" && grep -rl 'CONTEXT\.md' core/ | grep -v 'agents/pmo\.md')"
check "@s34 setup.sh never renders docs/CONTEXT.md" "0" "$([ -e "$WORK/docs/CONTEXT.md" ] && echo 1 || echo 0)"
# @s35 — /fix step 1: red-capable repro before naming the cause; no repro in one step → /feature; 2–4 ranked hypotheses; one variable at a time
awk '/^1\. /{on=1} /^2\. /{exit} on' "$FIX" >"$WORK/fix_1.md"
grep_case "@s35 step 1 requires red-capable reproduction" "$WORK/fix_1.md" '[Rr]ed-capable|failing test or (a )?command'
grep_case "@s35 step 1 repro goes green only when fixed" "$WORK/fix_1.md" 'green only when (the )?(fix|bug is fixed|fixed)'
grep_case "@s35 step 1 repro before naming the cause" "$WORK/fix_1.md" '(repro|reproduction).*before.*cause|before naming (the|a) cause'
grep_case "@s35 step 1 escape hatch: no repro in one step -> /feature" "$WORK/fix_1.md" '(no|cannot|can.t).*(repro|reproduction).*one step.*`/feature`|one step.*(no|cannot|can.t).*(repro|reproduction).*`/feature`'
grep_case "@s35 step 1 2–4 ranked falsifiable hypotheses" "$WORK/fix_1.md" '2–4 ranked falsifiable hypotheses'
grep_case "@s35 step 1 hypotheses only when repro is ambiguous" "$WORK/fix_1.md" 'hypotheses.*only when|only when.*hypotheses'
grep_case "@s35 step 1 one variable at a time" "$WORK/fix_1.md" '[Oo]ne variable at a time'
before "@s35 repro gate precedes root-cause statement" "$FIX" '[Rr]ed-capable|green only when' '\*\*State the root cause\*\*'
check "@s35 rendered fix.md zero {{ leftovers" "0" "$(grep -cE "$PH" "$FIX" 2>/dev/null; true)"
# @s36 — docs/sdd-workflow.md: artifact table row for docs/CONTEXT.md + Skill taxonomy note
for f in "$SDD" "$P_SDD" "$X_SDD"; do
  b=$(basename "$(dirname "$f")")/$(basename "$f")
  grep_case "@s36 $b table row docs/CONTEXT.md (pmo, lazily)" "$f" '^\| `docs/CONTEXT\.md` \| `pmo` \|.*[Ll]azily'
  grep_case "@s36 $b Skill taxonomy heading" "$f" '[Ss]kill taxonomy'
  grep_case "@s36 $b commands user-invoked" "$f" '[Cc]ommands.*user-invoked'
  grep_case "@s36 $b cursor disable-model-invocation" "$f" 'disable-model-invocation: true'
  grep_case "@s36 $b rules/skills model-invoked" "$f" '(rules|skills).*model-invoked'
  grep_case "@s36 $b suggest yes, instruct never" "$f" '[Ss]uggest.*(never|not) instruct|(never|not) instruct.*[Ss]uggest'
done
# @s37 — /feature + upgrade guide: template upgrade (setup.sh --merge) is its own chore: commit, never mixed into a feature PR
grep_case "@s37 feature.md upgrade = own chore commit" "$FEAT" "$UPGRADE_SEP"
grep_case "@s37 feature.md never mixed into a feature PR" "$FEAT" '(never|not) mixed into a feature PR'
grep_case "@s37 upgrade-guide upgrade = own chore commit" "$UPG" "$UPGRADE_SEP"
grep_case "@s37 upgrade-guide never mixed into a feature PR" "$UPG" '(never|not) mixed into a feature PR'
# @s38 — plugin + codex mirrors carry the same additions; build --check green
parity "@s38 plugin pmo intent" '[Ii]ntent' "$PMO_SRC" "$P_PMO"
parity "@s38 plugin pmo retro-spec" 'retro-spec' "$PMO_SRC" "$P_PMO"
parity "@s38 plugin pmo CONTEXT.md" 'docs/CONTEXT\.md' "$PMO_SRC" "$P_PMO"
parity "@s38 plugin pmo glossary format" "$GLOSSARY" "$PMO_SRC" "$P_PMO"
parity "@s38 plugin fix red-capable" '[Rr]ed-capable|green only when' "$FIX_SRC" "$ROOT/plugin/commands/fix.md"
parity "@s38 plugin fix hypotheses" 'falsifiable hypotheses' "$FIX_SRC" "$ROOT/plugin/commands/fix.md"
parity "@s38 plugin fix one variable" '[Oo]ne variable at a time' "$FIX_SRC" "$ROOT/plugin/commands/fix.md"
parity "@s38 plugin spec intent" '[Ii]ntent' "$SPEC_SRC" "$ROOT/plugin/commands/spec.md"
parity "@s38 plugin feature upgrade separation" "$UPGRADE_SEP" "$FEAT_SRC" "$ROOT/plugin/commands/feature.md"
parity "@s38 plugin sdd-workflow taxonomy" '[Ss]kill taxonomy' "$SDD" "$P_SDD"
parity "@s38 plugin sdd-workflow CONTEXT.md" 'docs/CONTEXT\.md' "$SDD" "$P_SDD"
parity "@s38 codex sdd-workflow taxonomy" '[Ss]kill taxonomy' "$SDD" "$X_SDD"
parity "@s38 codex sdd-workflow CONTEXT.md" 'docs/CONTEXT\.md' "$SDD" "$X_SDD"
check "@s38 build --check clean" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
# lean surface: CLAUDE.md gains nothing (contract grants MF5 no pointer)
check "@s34 CLAUDE.md no CONTEXT.md/taxonomy/repro text" "0" "$(grep -ciE 'CONTEXT\.md|taxonomy|red-capable|retro-spec' "$WORK/CLAUDE.md" 2>/dev/null; true)"
# MANUAL @s39 — /fix "button does nothing" with no reproduction available: the model stops and asks for a repro or redirects to `/feature`; it never proposes a cause first.
