#!/usr/bin/env bash
# Build the plugin's bundled template from the canonical source.
#
# Usage:
#   scripts/build.sh           # regenerate the generated tree
#   scripts/build.sh --check   # verify nothing has drifted (used by CI)
#
# Generated outputs (never hand-edit — edit core/, setup.sh, template.config.yaml, then run this):
#   plugin/template/            <- core/
#   plugin/setup.sh             <- setup.sh
#   plugin/template.config.yaml <- template.config.yaml
#   plugin/examples/            <- examples/
#
# The plugin's own agents/, commands/, hooks/, and skills/ are hand-authored,
# stack-agnostic variants — not mirrors of core/, and not touched by this build.
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
  diff -r examples plugin/examples >/dev/null 2>&1 || { echo "DRIFT: plugin/examples != examples/"; drift=1; }
  if [ "$drift" = "0" ]; then
    echo "generated trees in sync ✓"
    exit 0
  fi
  echo "Run scripts/build.sh to regenerate." >&2
  exit 1
fi

rm -rf plugin/template plugin/examples
cp -R core plugin/template
cp -R examples plugin/examples
cp setup.sh plugin/setup.sh
cp template.config.yaml plugin/template.config.yaml

echo "Built: plugin/template + plugin/setup.sh + plugin/template.config.yaml from core/."
