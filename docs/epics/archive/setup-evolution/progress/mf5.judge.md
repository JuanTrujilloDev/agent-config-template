# Judge: human-verification-offer (@s24..@s26)

**Stats:** 7 hand-authored files, 17 added instruction lines, plus workflow state; 12 generated mirrors excluded by D10. The original 5-file estimate was corrected to 7 after impact analysis found Codex whole-file overrides for `feature` and `sdd-workflow`. Limit: 7 files / 200 LOC. Branch: `feature/setup-evolution`.

| Scenario | Evidence | Status |
|---|---|---|
| @s24 one project-matched offer after DoD; never a gate | `feature.md`: one mapping line between review/mutation and micro-commit; explicitly optional and non-blocking | ✓ |
| @s25 record `yes|no|skipped` | `feature.md`: records on verified, explicit decline, skip/no answer | ✓ |
| @s26 same behavior for `/fix`; freeform remains offer-only | `fix.md` step 5, before commit; conditional `features.json` recording | ✓ |

## Review

- Mapping is explicit: web app → browser; library/CLI/desktop → run; mobile → simulator; other → artifact/screenshot.
- Claude, Cursor, Codex, plugin-only, and rendered-project paths contain the instruction.
- Web and mobile example renders substituted `project_type` correctly with no surviving decision placeholder.
- Ponytail: instruction-only change; no schema, script, dependency, or abstraction added.
- Security review not required: no auth, permissions, data, or executable behavior changed.
- Manual artifact review was offered at the commit gate; the user continued without requesting it, so MF5 records `verified_by_human: skipped`.

## Checks

- `bash scripts/build.sh --check` — generated trees in sync.
- `python3 scripts/validate-packaging.py` — packaging valid at v0.8.0.
- `git diff --check` — clean.

## Verdict

- [x] APPROVED
- [ ] CHANGES REQUESTED
