## Judge: contract-amendments (@s21..@s27)

**Stats:** 12 hand-authored files; generated mirrors excluded.

**Scenario → test:** @s21–@s23 → exact marker and scoped status-reset assertions
✓; @s24/@s25 → stale Gate 1 refusal and append-only reapproval assertions ✓;
@s26 → direct valid/invalid status fixtures ✓; @s27 → workflow parity ✓.

### Adversarial findings

- **Skeptic:** checks initially depended on Markdown line wrapping; split them
  into semantic assertions so reflow does not weaken or break the contract.
- **Architect:** state transition instructions reuse `features.json` and
  `progress/gate1.md`; no new state store is justified.
- **Minimalist:** one allowed-status addition plus concise workflow text is the
  smallest implementation of the approved contract.

### Principles deviation

- None.

### Blockers

- None.

### Verdict

- [x] APPROVED
- [ ] CHANGES REQUESTED
