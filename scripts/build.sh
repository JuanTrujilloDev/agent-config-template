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
#   plugin/skills/<s>/          <- core/.claude/skills/<s>/ for every skill with no {{placeholder}}
#   codex/skills/               <- plugin/skills/ + plugin/commands/ + hosts/codex/
#                                  (+ setup-companions/companions.lock.json)
#   cursor/                     <- core/ + hosts/cursor/ (incl. .claude/skills/, docs/)
#   plugin/cursor/              <- cursor/        (so plugin/setup.sh --host cursor|grok works)
#   plugin/codex/skills/        <- codex/skills/  (so plugin/setup.sh --host codex works)
#
# The plugin's own agents/, commands/, hooks/, and the skills that core/ does not
# ship placeholder-free (principles, the two style skills, lavish, port-config,
# orchestrator-init) are hand-authored, stack-agnostic variants, not touched here.
# codex/assets/, codex/.codex-plugin/plugin.json, and
# .agents/plugins/marketplace.json are hand-authored — not touched either.
#
# Requires: bash 3.2+ (stock macOS) and python3.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
python3 scripts/check-override-headings.py

# Codex derivation (rules from the former hand-sync note, now code):
# - plugin/skills/<s>/SKILL.md      -> codex skill, adding `name:` frontmatter when
#   absent; supporting files in the skill folder (templates, scripts, references)
#   are copied as is. Skills named in CODEX_NOTE_COMMANDS get the note too.
# - plugin/commands/<c>.md          -> codex skill, frontmatter reduced to
#   `name` + quoted `description` (no argument-hint); subagent-spawning
#   workflow commands get the role-adaptation note (Codex has no subagents).
#   A command with the same name as a skill is skipped: the skill covers it.
# - setup-template is not ported (renders a .claude/ tree — Claude-only).
# - hosts/codex/skills/<s>/SKILL.md are whole-file overrides for the
#   codex-specific content deltas (setup-companions, sdd-workflow, feature,
#   port-config).
CODEX_NOTE="hosts/codex/note-role-adaptation.md"
CODEX_NOTE_COMMANDS=" epic slice implement code-review fix audit design "

build_codex_skills() {
  local out="$1" name desc
  rm -rf "$out"
  mkdir -p "$out"
  for d in plugin/skills/*/; do
    name="$(basename "$d")"
    cp -R "${d%/}" "$out/$name"
    {
      if grep -q '^name: ' "$d/SKILL.md"; then cat "$d/SKILL.md"
      else awk -v n="$name" 'NR==1{print; print "name: " n; next} {print}' "$d/SKILL.md"; fi
    } | if [ "${CODEX_NOTE_COMMANDS#* $name }" != "$CODEX_NOTE_COMMANDS" ]; then
      awk -v notefile="$CODEX_NOTE" '{ print } !done && /^# / { print ""
        while ((getline l < notefile) > 0) print l
        print ""; done=1 }'
    else cat; fi > "$out/$name/SKILL.md"
  done
  for c in plugin/commands/*.md; do
    name="$(basename "$c" .md)"
    [ "$name" = "setup-template" ] && continue
    [ -d "plugin/skills/$name" ] && continue
    desc="$(sed -n 's/^description: //p' "$c" | head -1)"
    desc="${desc#\"}"; desc="${desc%\"}"
    mkdir -p "$out/$name"
    {
      printf -- '---\nname: %s\ndescription: "%s"\n---\n' "$name" "$desc"
      if [ "${CODEX_NOTE_COMMANDS#* $name }" != "$CODEX_NOTE_COMMANDS" ]; then
        awk '/^---$/{seen++; if(seen<=2) next} seen>=2{print}' "$c" | awk -v notefile="$CODEX_NOTE" '
          { print }
          !done && /^# / { print ""
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
  cp plugin/companions.lock.json "$out/setup-companions/companions.lock.json"
}

# Core skills without a {{placeholder}} in any file are host-neutral: plugin/skills/<s>
# is a byte copy. The rest (the style skills) render per project and keep their
# hand-authored generic plugin copies.
generic_skills() {
  for d in core/.claude/skills/*/; do
    grep -rq '{{' "$d" || basename "$d"
  done
}

# Cursor derivation (D3 — self-contained, no Claude hooks surface):
# - hosts/cursor/AGENTS.md and principles.mdc are hand-authored sources.
# - .cursor/rules/ holds principles.mdc only; style, code-query and patterns are
#   skills under .claude/skills/, copied from core/.claude/skills/ (a file-level
#   <!-- requires: --> directive stays on line 1 so setup.sh still drops it).
# - .cursor/mcp.json derived from core/.claude/mcp.json.example (comment reworded).
# - .claude/agents/, .claude/rules/, .claude/skills/ and docs/ are byte copies from core/ so the
#   rendered target is self-contained (Cursor reads them natively).
# - .cursor/hooks.json + .cursor/hooks/ come from hosts/cursor/ — two
#   hand-authored adapters (branch-guard on beforeShellExecution, format-on-edit
#   on afterFileEdit) over the core hook logic. coding-reminder.sh is
#   deliberately not ported (D9 — alwaysApply principles rule covers it).
# - core/.claude/commands/<c>.md -> .claude/skills/<c>/SKILL.md, frontmatter
#   reduced to name + quoted description + disable-model-invocation: true,
#   body verbatim (D6 — Cursor has subagents, spawning language stays). A
#   <!-- requires: --> directive stays on line 1 so setup.sh still drops the
#   file when the var is falsy. No exclusions: setup-template lives only in
#   plugin/commands/, not core/.
# - No .claude/settings.json is emitted: a cursor render never contains a
#   Claude hook registration (double-fire prevented structurally).

build_cursor_tree() {
  local out="$1" name desc
  rm -rf "$out"
  mkdir -p "$out/.cursor/rules" "$out/.claude"
  cp hosts/cursor/AGENTS.md "$out/AGENTS.md"
  cp hosts/cursor/principles.mdc "$out/.cursor/rules/principles.mdc"
  sed 's|^  "//": .*|  "//": "Cursor MCP config (generated from core/.claude/mcp.json.example) — fill in real values after render.",|' \
    core/.claude/mcp.json.example > "$out/.cursor/mcp.json"
  cp -R core/.claude/agents "$out/.claude/agents"
  cp -R core/.claude/rules "$out/.claude/rules"
  cp -R core/.claude/skills "$out/.claude/skills"
  cp -R core/docs "$out/docs"
  mkdir -p "$out/.cursor/hooks"
  cp hosts/cursor/hooks.json "$out/.cursor/hooks.json"
  cp hosts/cursor/hooks/branch-guard.sh hosts/cursor/hooks/format-on-edit.sh "$out/.cursor/hooks/"
  chmod +x "$out/.cursor/hooks/branch-guard.sh" "$out/.cursor/hooks/format-on-edit.sh"
  for c in core/.claude/commands/*.md; do
    name="$(basename "$c" .md)"
    desc="$(sed -n 's/^description: //p' "$c" | head -1)"
    desc="${desc#\"}"; desc="${desc%\"}"
    mkdir -p "$out/.claude/skills/$name"
    {
      if head -n 1 "$c" | grep -q '^<!-- requires:'; then
        head -n 1 "$c"
      fi
      printf -- '---\nname: %s\ndescription: "%s"\ndisable-model-invocation: true\n---\n' "$name" "$desc"
      awk '/^---$/{seen++; if(seen<=2) next} seen>=2{print}' "$c"
    } > "$out/.claude/skills/$name/SKILL.md"
  done
}

if [ "${1:-}" = "--check" ]; then
  drift=0
  diff -r core plugin/template >/dev/null 2>&1 || { echo "DRIFT: plugin/template != core/"; drift=1; }
  diff -q setup.sh plugin/setup.sh >/dev/null 2>&1 || { echo "DRIFT: plugin/setup.sh != setup.sh"; drift=1; }
  diff -q template.config.yaml plugin/template.config.yaml >/dev/null 2>&1 || { echo "DRIFT: plugin/template.config.yaml != template.config.yaml"; drift=1; }
  diff -r examples plugin/examples >/dev/null 2>&1 || { echo "DRIFT: plugin/examples != examples/"; drift=1; }
  for s in $(generic_skills); do
    diff -r "core/.claude/skills/$s" "plugin/skills/$s" >/dev/null 2>&1 || { echo "DRIFT: plugin/skills/$s != core/.claude/skills/$s"; drift=1; }
  done
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  build_codex_skills "$tmp/skills"
  diff -r "$tmp/skills" codex/skills >/dev/null 2>&1 || { echo "DRIFT: codex/skills != generated (plugin/ + hosts/codex/)"; drift=1; }
  build_cursor_tree "$tmp/cursor"
  diff -r "$tmp/cursor" cursor >/dev/null 2>&1 || { echo "DRIFT: cursor/ != generated (core/ + hosts/cursor/)"; drift=1; }
  diff -r cursor plugin/cursor >/dev/null 2>&1 || { echo "DRIFT: plugin/cursor != cursor/"; drift=1; }
  diff -r codex/skills plugin/codex/skills >/dev/null 2>&1 || { echo "DRIFT: plugin/codex/skills != codex/skills/"; drift=1; }
  if [ "$drift" = "0" ]; then
    echo "generated trees in sync ✓"
    exit 0
  fi
  echo "Run scripts/build.sh to regenerate." >&2
  exit 1
fi

rm -rf plugin/template plugin/examples plugin/cursor plugin/codex
cp -R core plugin/template
cp -R examples plugin/examples
cp setup.sh plugin/setup.sh
cp template.config.yaml plugin/template.config.yaml
for s in $(generic_skills); do
  rm -rf "plugin/skills/$s"
  cp -R "core/.claude/skills/$s" "plugin/skills/$s"
done
build_codex_skills codex/skills
build_cursor_tree cursor
cp -R cursor plugin/cursor
mkdir -p plugin/codex
cp -R codex/skills plugin/codex/skills

echo "Built: plugin/template + plugin/setup.sh + plugin/template.config.yaml from core/, plugin/skills/{$(generic_skills | paste -sd, -)} from core/.claude/skills/, codex/skills from plugin/ + hosts/codex/, cursor/ from core/ + hosts/cursor/, plugin/{cursor,codex/skills} bundles."
