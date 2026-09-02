#!/bin/bash
# Smoke harness for docs/specs/adaptive-skills/contract.md **(smoke)** scenarios.
# Thin runner: renders examples/python-fastapi into mktemp -d (scripts/smoke/lib.sh),
# then sources scripts/smoke/mf*.sh in mini-feature run order. Bash 3.2 + python3
# stdlib only. Extend by adding `hook_case` / `check` / `grep_case` lines to an mf file.
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
FAIL=0

. "$ROOT/scripts/smoke/lib.sh"
for mf in mf1-output-style v083-mf1-bugs mf-docs v083-mf3-instructions v083-mf4-hygiene mf8-agent-style mf2-patterns mf3-ledger mf4-brand mf5-vocabulary mf6-companions mf7-merge v083-mf5-release v090-mf1-contract-grammar v090-mf2-mini-feature-grammar v090-mf3-schema-migration v090-mf4-contract-amendments v090-mf5-principles-gates v090-mf6-release v091-mf1-verify-preflight v091-mf2-two-axis-verdicts v091-mf3-review-convergence v091-mf4-tdd-guardrails v091-mf5-release; do
  . "$ROOT/scripts/smoke/$mf.sh"
done

exit $FAIL
