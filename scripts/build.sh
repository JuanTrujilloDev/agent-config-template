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
#   codex/skills/               <- plugin/skills/ + plugin/commands/ + hosts/codex/
#
# The plugin's own agents/, commands/, hooks/, and skills/ are hand-authored,
# stack-agnostic variants — not mirrors of core/, and not touched by this build.
# codex/assets/, codex/.codex-plugin/plugin.json, and
# .agents/plugins/marketplace.json are hand-authored — not touched either.
#
# Requires: bash 3.2+ (stock macOS) and python3.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Codex derivation (rules from the former hand-sync note, now code):
# - plugin/skills/<s>/SKILL.md      -> codex skill, adding `name:` frontmatter.
# - plugin/commands/<c>.md          -> codex skill, frontmatter reduced to
#   `name` + quoted `description` (no argument-hint); subagent-spawning
#   workflow commands get the role-adaptation note (Codex has no subagents).
# - setup-template is not ported (renders a .claude/ tree — Claude-only).
# - hosts/codex/skills/<s>/SKILL.md are whole-file overrides for the
#   codex-specific content deltas (setup-companions, sdd-workflow, feature,
#   port-config).
CODEX_NOTE="hosts/codex/note-role-adaptation.md"
CODEX_NOTE_COMMANDS=" spec feature fix audit design "

build_codex_skills() {
  out="$1"
  rm -rf "$out"
  mkdir -p "$out"
  for d in plugin/skills/*/; do
    name="$(basename "$d")"
    mkdir -p "$out/$name"
    awk -v n="$name" 'NR==1{print; print "name: " n; next} {print}' \
      "$d/SKILL.md" > "$out/$name/SKILL.md"
  done
  for c in plugin/commands/*.md; do
    name="$(basename "$c" .md)"
    [ "$name" = "setup-template" ] && continue
    desc="$(sed -n 's/^description: //p' "$c" | head -1)"
    desc="${desc#\"}"; desc="${desc%\"}"
    mkdir -p "$out/$name"
    {
      printf -- '---\nname: %s\ndescription: "%s"\n---\n' "$name" "$desc"
      if [ "${CODEX_NOTE_COMMANDS#* $name }" != "$CODEX_NOTE_COMMANDS" ]; then
        awk '/^---$/{seen++; if(seen<=2) next} seen>=2{print}' "$c" | awk -v notefile="$CODEX_NOTE" '
          { print }
          !done && /^# \// { print ""
                             while ((getline l < notefile) > 0) print l
                             print ""; done=1 }'
      else
        awk '/^---$/{seen++; if(seen<=2) next} seen>=2{print}' "$c"
      fi
    } > "$out/$name/SKILL.md"
  done
  for o in hosts/codex/skills/*/; do
    name="$(basename "$o")"
    mkdir -p "$out/$name"
    cp "$o/SKILL.md" "$out/$name/SKILL.md"
  done
}

if [ "${1:-}" = "--check" ]; then
  drift=0
  diff -r core plugin/template >/dev/null 2>&1 || { echo "DRIFT: plugin/template != core/"; drift=1; }
  diff -q setup.sh plugin/setup.sh >/dev/null 2>&1 || { echo "DRIFT: plugin/setup.sh != setup.sh"; drift=1; }
  diff -q template.config.yaml plugin/template.config.yaml >/dev/null 2>&1 || { echo "DRIFT: plugin/template.config.yaml != template.config.yaml"; drift=1; }
  diff -r examples plugin/examples >/dev/null 2>&1 || { echo "DRIFT: plugin/examples != examples/"; drift=1; }
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  build_codex_skills "$tmp/skills"
  diff -r "$tmp/skills" codex/skills >/dev/null 2>&1 || { echo "DRIFT: codex/skills != generated (plugin/ + hosts/codex/)"; drift=1; }
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
build_codex_skills codex/skills

echo "Built: plugin/template + plugin/setup.sh + plugin/template.config.yaml from core/, codex/skills from plugin/ + hosts/codex/."
