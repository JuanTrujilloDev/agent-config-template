#!/bin/bash
# Smoke harness. Thin runner: renders examples/python-fastapi into mktemp -d
# (scripts/smoke/lib.sh), then sources each scripts/smoke/*.sh case file in release order.
# Bash 3.2 + python3 stdlib only. Extend by adding `check` / `grep_case` lines to a case
# file; each v0.11 item has its own scripts/smoke/v011-<n>-*.sh.
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
FAIL=0

. "$ROOT/scripts/smoke/lib.sh"
for mf in mf1-output-style v083-mf1-bugs mf-docs v083-mf3-instructions v083-mf4-hygiene mf4-brand mf6-companions mf7-merge v083-mf5-release v090-mf6-release v091-mf1-verify-preflight v092-mf1-managed-state v092-mf2-override-drift v092-mf3-prune v092-mf4-parser-release v010-mf1-model-evals v010-mf2-brand-tokens v010-mf3-companions v010-mf4-branch-tokenizer v010-mf5-release orchestrator-init v011-1-principles-hooks v011-2-drop-agents v011-3-epic-slice v011-4-slice-loop v011-5-skills-mirror v011-6-update-config v011-7-plugin-hosts v011-8-release; do
  . "$ROOT/scripts/smoke/$mf.sh"
done

exit $FAIL
