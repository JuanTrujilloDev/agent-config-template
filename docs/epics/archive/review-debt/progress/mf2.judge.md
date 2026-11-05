# Judge: MF2 docs-catch-up (@s10..@s14)

**Stats:** 7 planned hand-authored files; generated Cursor copies excluded.
Under 3,000 changed lines.

**Scenario → test:** @s10–@s14 map directly to the grouped assertions in
`scripts/smoke/mf-docs.sh`.

## Adversarial findings

- **Skeptic:** No blocker. Assertions cover every required term and reject the
  stale “every slash command” and mandatory-companion claims.
- **Architect:** No blocker. Capability rows match actual rendering: prompt-hook
  banners on Claude/Grok, instruction fallbacks on Codex/Cursor, and lazy
  MASTER creation on Codex.
- **Minimalist:** No blocker. Existing sections were extended; no parallel guide
  or documentation abstraction was added.

## Checks

- Focused MF2 smoke: pass
- Full `bash scripts/smoke.sh`: pass
- Build drift + packaging validation: pass
- `git diff --check`: pass

## Verdict

- [x] APPROVED
- [ ] CHANGES REQUESTED
