# MF1 managed-baseline — TDD

## Public seams

- `setup.sh` writes `<target>/agent-config.lock.json` after a successful render.
- The lock uses schema version 1 and exposes `template_version`, canonical
  `hosts`, and sorted `files` entries with per-file `template_version` and
  SHA-256 baseline.
- Only overwrite-managed regular files appear in `files`.

## Red

- Scenario: `@s1` fresh render writes a deterministic managed baseline.
- Test: `scripts/smoke/v092-mf1-managed-state.sh`.
- Observed: exit 1; `agent-config.lock.json` does not exist.

## Green

- Gate 2 approved by the maintainer on 2026-09-02.
- `@s1` → fresh schema, hashes, exclusions, deterministic overwrite.
- `@s2` → unchanged baseline rendered with different answers is stale.
- `@s3` → edited baseline is customized and absent from the suggestion.
- `@s4`, `@s7` → missing state is legacy.
- `@s5` → user-owned/merge-managed paths are excluded; a state symlink cannot
  authorize a write.
- `@s6` → merge preserves an edited file's baseline; explicit overwrite advances it.
- `@s8` → malformed/schema/path/hash/namespace fixtures warn once and become legacy.
- `@s9` → Claude, Cursor, Codex, Grok, and bundled setup produce valid state.

All focused checks and the full smoke suite pass.
