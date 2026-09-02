## TDD: verify-preflight (@s1..@s7)

### Public behavior seams

- `/verify` with no argument reviews changes after one captured `HEAD` SHA.
- `/verify <base-ref>` reviews changes after one validated merge-base SHA.
- Invalid refs and empty scopes refuse before reviewer dispatch.
- Spec discovery follows one visible, deterministic priority order.

### Scenario → check

- @s1 → source, plugin, and rendered `/verify` capture `HEAD` into
  `VERIFY_BASE_SHA`; every explicit `git diff`/`git log` reuses it.
- @s2 → the same surfaces validate a supplied ref and capture its merge-base.
- @s3 → invalid refs have an explicit refusal path.
- @s4 → the empty-scope result is exactly `Nothing to verify.`
- @s5 → untracked files are included, their contents are read as newly added,
  and paths stay data, never commands.
- @s6 → changed spec path precedes commit/branch reference, which precedes a
  single active ledger; ambiguity is reported.
- @s7 → no unique spec falls back honestly to the user request; source/plugin
  parity is asserted.

### Red

`bash scripts/smoke.sh` → exit 1 on 2026-09-02.

All pre-v0.9.1 checks passed. The 51 new assertions failed because current
`/verify` has no pinned SHA, ref validation, empty-scope refusal, untracked-file
scope, or deterministic spec-discovery preflight. No production instruction was
changed.

### Green

`bash scripts/smoke.sh` → exit 0. All @s1–@s7 assertions pass across
source, direct-plugin, and rendered command surfaces; the full pre-v0.9.1 suite
remains green.

Review cycle 1 added a regression assertion that every recorded untracked path
is read, not merely counted for the empty-scope check.

### Refactor

Kept the behavior inside the existing `/verify` instructions. The supplied ref
is resolved with `--end-of-options`, and only its full SHA reaches `merge-base`.
No helper, dependency, or new command was added.
