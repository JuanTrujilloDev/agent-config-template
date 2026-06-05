#!/usr/bin/env bash
# Mirror the canonical template into the bundled plugin copy.
#
# The plugin must be self-contained — Claude Code uses only the plugin/ directory
# on install — so these three are byte-for-byte copies of the repo-root canonical
# versions:
#   plugin/template/            <-  template/
#   plugin/setup.sh             <-  setup.sh
#   plugin/template.config.yaml <-  template.config.yaml
#
# This mirrors ONLY the bundled template. The plugin's own generic
# agents/commands/hooks/skills (plugin/agents, plugin/commands, plugin/hooks,
# plugin/skills) are hand-authored, stack-agnostic variants and are NOT synced.
#
# Usage:
#   scripts/sync-plugin.sh           # re-mirror canonical -> plugin/
#   scripts/sync-plugin.sh --check   # verify in sync; exit 1 on drift (used by CI)
#
# Requires: bash 3.2+ (stock macOS). No other dependencies.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ "${1:-}" = "--check" ]; then
  drift=0
  diff -r template plugin/template >/dev/null 2>&1 || { echo "DRIFT: plugin/template != template/"; drift=1; }
  diff -q setup.sh plugin/setup.sh >/dev/null 2>&1 || { echo "DRIFT: plugin/setup.sh != setup.sh"; drift=1; }
  diff -q template.config.yaml plugin/template.config.yaml >/dev/null 2>&1 || { echo "DRIFT: plugin/template.config.yaml != template.config.yaml"; drift=1; }
  if [ "$drift" = "0" ]; then
    echo "plugin mirror in sync ✓"
    exit 0
  fi
  echo "Run scripts/sync-plugin.sh to re-mirror." >&2
  exit 1
fi

rm -rf plugin/template
cp -R template plugin/template
cp setup.sh plugin/setup.sh
cp template.config.yaml plugin/template.config.yaml
echo "Mirrored canonical -> plugin/  (template/, setup.sh, template.config.yaml)"
