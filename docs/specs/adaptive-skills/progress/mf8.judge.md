## Judge: mf8 agent-style  (@s58..@s66)

**Stats:** 21 files changed in the tree (+190/-10); 9 hand-authored (the 8 named in `features.json` plus `scripts/smoke.sh`), 12 build-generated mirrors. Branch `feature/v0.8.2-adaptive-skills`, uncommitted vs HEAD.

**Scenario → test:**
@s58 → smoke `@s58 *` (8 greps: opt-in, telegraphic, keep negations, tokens verbatim, no invented abbreviations, no arrow chains, net-negative caveat, concise default) ✓ ;
@s59 → smoke `@s59 *` (heading, key/values, local env, absent/empty/unrecognized = terse, return-message only, never human-facing / never disk) ✓ ;
@s60 → smoke `@s60 field order` (first-occurrence order RESULT FILES CHECKS FINDINGS DECISIONS NEXT) + shape/budget/descriptive greps ✓ ;
@s61 → smoke `@s61 *` (progress dir, spec/contract/commits/PR/docs, output_style-not-agent_style) ✓ ;
@s62 → smoke `@s62 feature.md|orchestrator.md read once / prompt line / names subagents` ✓ ;
@s63 → smoke `@s63 core|plugin hook no agent_style` = 0, plus the MF1 banner cases unchanged; `git diff` shows no hook file touched ✓ ;
@s64 → smoke `@s64 template.config.yaml|setup-template scopes table|not asked` ✓ ;
@s65 → smoke `@s65 * has agent_style / parity` + `bash scripts/build.sh --check` exit 0 ✓ ;
@s66 → human scenario, performed by the judge below ✓.

### Verification run

- `bash scripts/smoke.sh`: exit 0, 72 PASS, 0 FAIL (MF1 hook cases plus all new MF8 cases).
- `bash scripts/build.sh` twice: second run produced a byte-identical tree (diff hash equal). `--check` exit 0. `python3 scripts/validate-packaging.py`: "packaging valid @ v0.8.1".
- Hooks: `core/.claude/hooks/coding-reminder.sh` and `plugin/hooks/coding-reminder.sh` untouched in the diff; `grep -c agent_style` = 0 on both.
- Plugin mirrors: `plugin/template/.claude/rules/principles.md` is byte-identical to core; `plugin/skills/principles/SKILL.md` carries identical additions; `plugin/commands/feature.md` and `plugin/agents/orchestrator.md` differ from core only in the reference target (`in the principles skill` vs `in .claude/rules/principles.md`), which is the host-appropriate reference @s65 allows.

### Reading the principles text

- The `terse` definition under "Output style" is unambiguous: it is opt-in, it names what to drop (articles, filler) and what to keep verbatim (negations and every technical token), forbids invented abbreviations and arrow chains, and defers to the existing revert-to-prose list. It does not restate the Conciseness section; Conciseness is the general rule, Output style is the knob, `terse` is one value of the knob.
- The "Report format" subsection is non-duplicative: it introduces a second knob, states the default and the failure modes (absent, empty, unrecognized), scopes it to the return message, and states the fallback when the prompt carries no line. The schema lists six fields in fixed order with value sets for `RESULT`, shapes for `FILES` and `CHECKS`, and the "never drop a finding to fit the budget" clause gives precedence over the ~25-line ceiling, so the two constraints cannot conflict.
- The Boundary rule is explicit and matches D17 word for word in substance: progress files, spec/contract, commit messages, PR bodies, docs are always prose; human-facing output follows `output_style`, never `agent_style`; the revert-to-prose list applies to both channels (D2).
- The prompt-passing line appears exactly once in `core/.claude/commands/feature.md` (step 2) and once in `core/.claude/agents/orchestrator.md` (step 5, with "Steps 5–8 all carry it"), and both name pmo, dev agents, ui-designer, judge, security-reviewer, mutation-tester.

### @s66 performed by the judge

With the schema in front of me, a hypothetical three-file diff with one Blocker and one Suggestion returns as:

```
RESULT: changes-requested
FILES: src/auth/session.py:+42/-6 ; src/auth/__init__.py:+2/-0 ; tests/test_session.py:+55/-0
CHECKS: format=pass lint=pass test=pass coverage=pass
FINDINGS:
- Blocker: src/auth/session.py:37 refresh token still accepted after revoke — contract @s3 has no test
- Suggestion: tests/test_session.py:12 two fixtures build the same session; collapse to one
DECISIONS: security-reviewer required — diff touches auth
NEXT: implementer adds the @s3 revoke test and fixes session.py:37, then re-run judge
```

Eight lines. All three paths and both severities survive because `FILES` is one entry per file touched and `FINDINGS` is one line per finding with no permitted truncation. The verdict file (this file) is prose; `grep -c '^RESULT:'` on it matches only the fenced example, which is illustrative, not the file's own format. The schema forces the outcome the scenario asks for.

### Blockers

None.

### Nits

- File budget: `features.json` names 8 files for MF8; the diff also touches `scripts/smoke.sh` (+68) for the MF8 cases, making 9 hand-authored files. The test harness is the right place for these checks and the micro-PR limit (12) is respected, but the human should confirm the 8-file budget was meant to exclude the shared test script.
- `plugin/commands/feature.md:32` and `plugin/agents/orchestrator.md:69`: the prompt line nests backticks (`` ...in the `principles` skill` ``), which closes the inline code span early in rendered Markdown. Content is correct; rendering is off. Consider quotes around `principles` or dropping the inner backticks.
- `hosts/codex/skills/feature/SKILL.md` is a whole-file override and does not carry the `agent_style:` line, so the codex `/feature` never passes it. Safe by design (no line = `terse`) and outside @s65's named files, but worth a follow-up when codex parity is next touched.
- `core/.claude/agents/orchestrator.md:79`: the line lives inside step 5 but opens with "Before this step"; reads slightly backwards. Contract places it at steps 5–8, so this is placement preference only.
- `terse` is a value of both `output_style` (telegraphic prose) and `agent_style` (field schema). Spec D16 chose this deliberately; the two subsections disambiguate by knob name, so no action, just noting the shared token.

### Verdict

- [x] APPROVED   - [ ] CHANGES REQUESTED

No security review required: the diff is documentation and test text only, no auth, permissions, external input, or hook code touched (contract Design notes: "No hook change (D3/D16), so judge only").
