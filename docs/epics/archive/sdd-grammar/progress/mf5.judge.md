## Judge: principles-double-gate (@s28..@s33)

**Stats:** 12 hand-authored files; generated mirrors excluded.

**Scenario → test:** @s28–@s30 → required table, complete columns, explicit
`None`, present-reason rule, and justified example ✓; @s31/@s32 → same-row
citation plus missing/unrecorded/unused blockers ✓; @s33 → Claude, Cursor,
Grok, and Codex source parity ✓.

### Principles deviation table check

- Applicable row: none for MF5. The existing Micro-PR-discipline row applies
  only to MF3's atomic migration; MF5 stays within its 12-file budget.

### Adversarial findings

- **Skeptic:** “unused deviation” could wrongly reject a later mini-feature for
  a feature-wide row already used by MF3; scoped the blocker to the reviewed
  mini-feature.
- **Architect:** PMO and judge now share the spec table instead of maintaining
  two policy records.
- **Minimalist:** instruction assertions are sufficient because the agents are
  the runtime; a Markdown parser would duplicate the policy without enforcing
  model behavior.

### Blockers

- None.

### Verdict

- [x] APPROVED
- [ ] CHANGES REQUESTED
