# TDD: model-eval-harness (@s1..@s8)

## Public seams

- `python3 scripts/evals/run.py validate|list --catalog <path>`
- `python3 scripts/evals/run.py run --host <host> [--case <id>] [--run] [--allow-writes]`
- `scripts/evals/cases.jsonl`

## Scenario to test

- @s1–@s2: catalog validation/listing and inert default behavior.
- @s3–@s4: fake CLI argv, normalization, skips, failures, malformed output, timeout.
- @s5–@s6: explicit live/write gates and disposable working directory.
- @s7: deterministic rubric output.
- @s8: manual workflow, ordinary-CI validation, result sanitization.

## Red

`scripts/smoke/v010-mf1-model-evals.sh` exited 1 on 2026-09-02 because
`scripts/evals/run.py`, `scripts/evals/cases.jsonl`, CI integration, and the
result ignore rule did not exist. The public seam failed before any model call.

## Green

The focused smoke passed all @s1–@s8 checks with fake host executables. Catalog
validation, plan mode, missing/auth skips, malformed output, timeout, rubrics,
write gating, temporary cwd, CI dispatch, and secret omission are covered.

## Refactor

Kept one stdlib module and a data table. Response extraction ignores event
metadata strings so Codex JSONL cannot replace the actual agent message.
