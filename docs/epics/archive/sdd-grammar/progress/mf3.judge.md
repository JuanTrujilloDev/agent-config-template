## Judge: schema-version-and-migration (@s14..@s20)

**Stats:** 22 hand-authored files; generated mirrors excluded. Gate 1 approved
one atomic migration across every live ledger, exact fixtures, and two
compatibility smoke updates so the repository never carries mixed schemas.

**Scenario → test:** @s14–@s17 → four historical fixtures migrate, preserve
stable fields/modes, validate, and rerun byte-identically ✓; @s18/@s19 → strict
version rejection, exact recovery command, and five live v2 ledgers ✓; @s20 →
build, packaging, focused, and full smoke checks ✓.

### Adversarial findings

- **Skeptic:** atomic replacement initially changed ledger modes to `0600`;
  fixed by preserving the original mode and regression-tested.
- **Architect:** the schema switch exposed two old smoke assumptions; both now
  read v2 fields while retaining narrow compatibility where required.
- **Minimalist:** one stdlib migrator plus the existing validator is sufficient;
  no migration framework or dependency was added.

### Principles deviation

- Atomic schema migration exceeds the normal file budget. Splitting it would
  knowingly leave the repository in an invalid mixed-version state; the ledger
  records the approved 22-file exception.

### Blockers

- None.

### Verdict

- [x] APPROVED
- [ ] CHANGES REQUESTED
