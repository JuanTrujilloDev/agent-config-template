#!/usr/bin/env bash
# Build every packaging from the canonical source.
#
# Usage:
#   scripts/build.sh           # regenerate all generated trees
#   scripts/build.sh --check   # verify nothing has drifted (used by CI)
#
# Generated outputs (never hand-edit — edit core/ and plugin/ sources, then run this):
#   plugin/template/  plugin/setup.sh  plugin/template.config.yaml   <- core/, setup.sh, config (Claude Code)
#   skills/                                                          <- portable SKILL.md tree (npx skills add: Codex + OpenCode)
#   codex/  .agents/plugins/marketplace.json                         <- Codex native plugin + marketplace
#
# Requires: bash 3.2+ (stock macOS) and python3.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ "${1:-}" = "--check" ]; then
  drift=0
  diff -r core plugin/template >/dev/null 2>&1 || { echo "DRIFT: plugin/template != core/"; drift=1; }
  diff -q setup.sh plugin/setup.sh >/dev/null 2>&1 || { echo "DRIFT: plugin/setup.sh != setup.sh"; drift=1; }
  diff -q template.config.yaml plugin/template.config.yaml >/dev/null 2>&1 || { echo "DRIFT: plugin/template.config.yaml != template.config.yaml"; drift=1; }
  python3 "$ROOT/scripts/gen-skills.py" --check || drift=1
  if [ "$drift" = "0" ]; then
    echo "generated trees in sync ✓"
    exit 0
  fi
  echo "Run scripts/build.sh to regenerate." >&2
  exit 1
fi

# Claude Code: bundled template copy
rm -rf plugin/template
cp -R core plugin/template
cp setup.sh plugin/setup.sh
cp template.config.yaml plugin/template.config.yaml

# Codex + OpenCode: portable skills tree + native Codex plugin
python3 "$ROOT/scripts/gen-skills.py"

echo "Built: plugin/ (Claude) + skills/ + codex/ (Codex/OpenCode) from core/ and plugin/."
