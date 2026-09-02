# v0.9.0 MF5 principles double gate (@s28..@s33).
for f in "$ROOT/core/.claude/agents/pmo.md" "$ROOT/plugin/agents/pmo.md"; do
  grep_case "v0.9.0 @s28 $(basename "$f") deviation heading" "$f" '### Principles deviation table'
  grep_case "v0.9.0 @s28 $(basename "$f") four columns" "$f" 'Principle.*Decision.*Present reason.*Mitigation'
  grep_case "v0.9.0 @s28 $(basename "$f") pre-Gate check" "$f" '[Bb]efore Gate 1'
  grep_case "v0.9.0 @s29 $(basename "$f") None row" "$f" '\| None \| No deviation \|'
  grep_case "v0.9.0 @s30 $(basename "$f") speculative reason refused" "$f" '[Ss]peculative convenience.*not.*acceptable'
  grep_case "v0.9.0 @s32 $(basename "$f") justified fixture" "$f" '\| Simplicity First \| Use a small parser \| Required input has nested syntax today \| Keep it stdlib and local \|'
done

for f in "$ROOT/core/.claude/agents/judge.md" "$ROOT/plugin/agents/judge.md"; do
  grep_case "v0.9.0 @s31 $(basename "$f") same table" "$f" 'same.*Principles deviation table'
  grep_case "v0.9.0 @s31 $(basename "$f") cites row" "$f" '[Cc]ite.*applicable row'
  grep_case "v0.9.0 @s31 $(basename "$f") unrecorded hard violation" "$f" '[Uu]nrecorded.*hard-violation'
  grep_case "v0.9.0 @s32 $(basename "$f") missing table fails" "$f" '[Mm]issing.*table.*hard-violation'
  grep_case "v0.9.0 @s32 $(basename "$f") unused row fails" "$f" '[Uu]nused.*deviation.*hard-violation'
  grep_case "v0.9.0 @s32 $(basename "$f") justified fixture cited" "$f" 'Simplicity First.*Use a small parser'
done

for f in "$ROOT/core/.claude/rules/principles.md" "$ROOT/plugin/skills/principles/SKILL.md" "$ROOT/hosts/cursor/principles.mdc"; do
  grep_case "v0.9.0 @s33 $(basename "$f") pre-Gate principles" "$f" '[Bb]efore Gate 1'
  grep_case "v0.9.0 @s33 $(basename "$f") judge recheck" "$f" '[Jj]udge.*same.*table'
done

for f in "$ROOT/docs/sdd-workflow.md" "$ROOT/plugin/skills/sdd-workflow/SKILL.md" "$ROOT/hosts/codex/skills/sdd-workflow/SKILL.md"; do
  grep_case "v0.9.0 @s33 $(basename "$f") deviation heading" "$f" '### Principles deviation table'
  grep_case "v0.9.0 @s33 $(basename "$f") None valid" "$f" 'None.*valid'
  grep_case "v0.9.0 @s33 $(basename "$f") two gates" "$f" '[Bb]efore Gate 1.*[Jj]udge|[Jj]udge.*[Bb]efore Gate 1'
done
