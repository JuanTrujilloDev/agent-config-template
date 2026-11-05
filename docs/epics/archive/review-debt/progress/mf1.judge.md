# Judge: MF1 hook-and-setup-bugs (@s1..@s9)

**Stats:** 9 planned hand-authored implementation/test files plus process
artifacts; generated mirrors excluded. Under 3,000 changed lines.

**Scenario → test:** @s1–@s2 → `mf1-output-style.sh`; @s3 → `mf7-merge.sh`;
@s4–@s8 → `v083-mf1-bugs.sh`; @s9 → full smoke/build/packaging/syntax checks.

## Adversarial findings

- **Skeptic:** No blocker. CRLF, padding, hostile values, stdin plans,
  duplicated host traversal, both layouts, both env-key precedence directions,
  legacy fallback, and defaults are exercised.
- **Architect:** No blocker. The changes extend the existing fixed-string
  whitelist, staged-path collection, and layout detection; no new abstraction
  or dependency was introduced.
- **Minimalist:** No blocker. A set replaces an integer for unique counting;
  the remaining fixes are direct conditionals/pipelines at their existing call
  sites.

## Checks

- Targeted MF1 smoke: pass
- Full `bash scripts/smoke.sh`: pass
- `bash scripts/build.sh --check`: pass
- `python3 scripts/validate-packaging.py`: pass
- Rendered/canonical shell syntax and `git diff --check`: pass

## Verdict

- [x] APPROVED
- [ ] CHANGES REQUESTED
