# Judge: release-docs-version (@s27..@s29)

**Stats:** 7 hand-authored release files plus workflow state; 80 insertions / 24 deletions before this verdict. The estimate moved from 6 to 7 to close the known root/plugin/Cursor documentation drift in one release pass. Limit: 7 files / 200 LOC. Branch: `feature/setup-evolution`.

| Scenario | Evidence | Status |
|---|---|---|
| @s27 all release manifests are `0.8.1` | Claude plugin, Claude marketplace entry, and Codex manifest checked with `jq`; packaging skew check passes | ✓ |
| @s28 v0.8.x migration is complete | upgrade guide covers committed/unignored `answers.env`, local prefs, `workflow_mode` default, `autonomy_mode`, `/integrate`, preview + `--merge` | ✓ |
| @s29 deterministic build and green validation | two final builds produced identical diff SHA-256 `087eadc0df3705d7a94abbd3c95f8225f1783be36b5940060c1dd7de47dca6b2`; build check, packaging, and render-smoke pass | ✓ |

## Review

- Command counts and `/integrate` documentation now match the packaged surfaces.
- Setup docs describe batched frontier decisions and the committed/local config split without hiding the possible gated second round.
- The stricter Codex plugin validator found missing interface metadata; required `longDescription`, `capabilities`, and three short default prompts were added and validation now passes.
- Release manifests keep strict semver `0.8.1`; no local-development cachebuster or marketplace mutation was introduced.
- Ponytail: reused existing build, validation, migration format, and CI commands; no release tooling added.
- Security review not required: metadata and documentation only.

## Checks

- `bash scripts/build.sh` twice — identical diff hash.
- `bash scripts/build.sh --check` — generated trees in sync.
- `python3 scripts/validate-packaging.py` — packaging valid at v0.8.1.
- plugin-creator `validate_plugin.py codex` — passed.
- CI render-smoke logic — all six Claude examples and one Cursor render passed.
- `git diff --check` — clean.
- Remote GitHub CI was not triggered because nothing was pushed.
- Manual fresh-thread testing was offered; the user chose to publish first, so MF6 records `verified_by_human: skipped`.

## Verdict

- [x] APPROVED
- [ ] CHANGES REQUESTED
