# Judge: MF4 build-test-hygiene (@s24..@s31)

**Stats:** 17 planned hand-authored files; generated mirrors and progress files
excluded. Under 3,000 changed lines; the Gate 1 file-budget exception applies.

**Scenario → test:** @s24–@s30 map directly to
`scripts/smoke/v083-mf4-hygiene.sh`; @s31 is covered by the standard checks and
the explicit double-build comparison.

## Adversarial findings

- **Skeptic:** No blocker. The malformed-description seed fails in both parser
  modes and is restored by a trap.
- **Architect:** No blocker. The fixture replaces the former project-specific
  dependency without changing merge classification behavior.
- **Minimalist:** No blocker. Validation uses a small stdlib scanner; command
  surfaces reuse the existing `agent_style` handoff contract.

## Checks

- Focused MF4 smoke + full smoke suite: pass
- PyYAML and no-PyYAML packaging validation: pass
- Double build + generated drift check: pass
- Bash syntax, JSON parse, and `git diff --check`: pass

## Verdict

- [x] APPROVED
- [ ] CHANGES REQUESTED
