# Judge: MF3 instruction-text-debt (@s15..@s23)

**Stats:** 13 planned hand-authored files; generated mirrors and progress files
excluded. Under 3,000 changed lines.

**Scenario → test:** @s15–@s23 map directly to the grouped assertions in
`scripts/smoke/v083-mf3-instructions.sh`.

## Adversarial findings

- **Skeptic:** No blocker. Both workflow modes render unambiguous TDD wording,
  and setup just-go still cannot trigger overwrite.
- **Architect:** No blocker. Canonical sources and host/plugin mirrors stay in
  sync through the existing build pipeline.
- **Minimalist:** No blocker. The change only reorders or clarifies existing
  instructions and adds focused regression assertions.

## Checks

- Focused MF3 smoke: pass
- Full `bash scripts/smoke.sh`: pass
- Build drift + packaging validation: pass
- `git diff --check`: pass

## Verdict

- [x] APPROVED
- [ ] CHANGES REQUESTED
