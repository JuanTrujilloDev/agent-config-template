## Judge: brownfield-readme-release (@s34..@s41)

**Stats:** initial MF6: 9 hand-authored files. Native Cursor follow-up: exactly
12 hand-authored files. Generated mirrors and progress artifacts excluded.
README: 223 lines, down from 253.

**Scenario → test:** @s34/@s35 → brownfield guide coverage ✓; @s36–@s39 →
first-80 quick starts, one diagram/table, v0.9 grammar, retained links, and
Spec Kit credit ✓; @s40 → Claude, Cursor, and Codex 0.9.0 manifests plus the
upgrade section ✓; @s41 →
spec/build/package/full-smoke, deterministic-build, and 24-render sweep ✓.

### Principles deviation table check

- Applicable row: none. MF6 stays within its 12-file budget and uses existing
  build, packaging, smoke, and documentation structures.

### Adversarial findings

- **Skeptic:** the historical v0.8.3 smoke hard-coded the then-current manifest
  version and failed a valid release; changed it to verify semantic versions
  and current packaging consistency.
- **Architect:** Cursor/Grok quick starts initially omitted creation of
  `answers.env`; added an actionable example copy before the render command.
- **Architect:** Cursor's documented native plugin support made the clone-first
  install obsolete; added the root Cursor manifest and native rule/hooks, with
  `/setup-template` using `CURSOR_PLUGIN_ROOT`.
- **Minimalist:** removed repeated agent/config tables and kept one command
  table, linking to deeper docs instead.

### Packaging review

- Repository packaging validator: pass at v0.9.0.
- Cursor manifest paths, command metadata, hook syntax, and protected-branch
  behavior: pass.
- Codex plugin validator: pass.
- Spec Kit credit verified against the official MIT-licensed repository; no
  artifacts copied and no affiliation claimed.

### Blockers

- None.

### Verdict

- [x] APPROVED
- [ ] CHANGES REQUESTED
