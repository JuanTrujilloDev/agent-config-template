# MF4 answers-and-release — TDD

## Public seams

- Answers parsing strips one matching outer quote pair, preserves compatible
  unquoted content, and rejects malformed quoted values with a line number.
- Recorded and CLI host lists share case-insensitive validation,
  deduplication, canonical order, and CLI precedence.
- After a successful write only, an existing `.claude/answers.local.env`
  causes one exact `.gitignore` rule to be appended safely and reported.
- README, upgrade guidance, four manifests, and release checks agree on
  `0.9.2`.

## Red

- Scenario: `@s24` renders `TARGET_HOSTS="Cursor,GROK"` and
  `project_name="Quoted # Project"` without outer quotes.
- Test: `scripts/smoke/v092-mf4-parser-release.sh`.
- Observed: setup exits 1 before rendering because the current Bash host
  selector sees the unparsed token `"Cursor`.

## Green

- Gate 2 approved.
- Moved answers parsing and host selection into one Python path so recorded
  and CLI hosts share normalization, validation, deduplication, and ordering.
- Added post-success, exact-rule `.gitignore` protection for local answers.
- Updated release docs and all four manifests to `0.9.2`.
- Added focused coverage for `@s24`–`@s33`; the complete smoke suite passes.
- Self-review added the missing single-quoted-value assertion required by
  FR-006 before judge review.

## Refactor

- Removed the duplicate Bash host parser and reused the existing path-safety
  guard for `.gitignore`.
- Kept the generated `plugin/setup.sh` mirror build-derived.
- Made the v0.9.1 release smoke assert manifest alignment instead of pinning an
  obsolete version.

## Scenario map

- `@s24`–`@s28`: quoted/unquoted parsing, host normalization, CLI precedence,
  malformed-value rejection before writes.
- `@s29`–`@s31`: exact local-answer ignore rule and no-write safety paths.
- `@s32`: README, upgrade guide, and manifest release consistency.
- `@s33`: validators, syntax/JSON checks, deterministic build, and 24
  example/host renders without placeholders.
