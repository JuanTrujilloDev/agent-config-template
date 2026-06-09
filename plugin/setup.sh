#!/usr/bin/env bash
# agent-config-template renderer.
#
# Reads the canonical source (core/ at the repo root, or the plugin's bundled
# template/) + an answers file, substitutes {{var}} placeholders
# (and {{#var}}…{{/var}} / {{^var}}…{{/var}} sections), drops files marked
# `<!-- requires: var -->` when the var is falsy, writes to a target dir.
#
# NON-DESTRUCTIVE BY DEFAULT. If the target already has a Claude config
# (.claude/ tree, settings.json, or a CLAUDE.md), the renderer refuses to write
# anything until you pick a mode:
#
#   --merge       Add files that don't exist; deep-merge .claude/settings.json
#                 (union of permissions.allow/deny/ask + additive hooks); keep
#                 every other existing file as-is. Never touches
#                 .claude/settings.local.json.
#   --overwrite   Replace template-managed files. Still never touches
#                 .claude/settings.local.json, and never deletes files the
#                 template doesn't manage.
#   --abort       Do nothing (this is the default if no mode is given).
#
# Run with no mode against an existing config to see a per-file change plan.
#
# This is NOT an interactive setup. The expected workflow is:
#
#   1. Open Claude Code in your new project.
#   2. Tell Claude: "set up Claude Code config from <path to this template>."
#      Claude reads your project, drafts an answers.env, asks you to confirm.
#   3. Claude runs this script to render.
#
# To drive it by hand, copy a pre-filled example:
#   cp examples/python-fastapi/answers.env ./answers.env
#   ./setup.sh --target /path/to/project --answers ./answers.env            # fresh
#   ./setup.sh --target /path/to/project --answers ./answers.env --merge    # existing
#
# Usage:
#   setup.sh --target <dir> --answers <file> [--merge|--overwrite|--abort]
#   setup.sh --target <dir> --answers -        # read answers from stdin
#
# Requires: bash 3.2+ (works on stock macOS bash) and python3.
# All non-trivial logic runs in python3 to stay portable across shells.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Canonical source is core/ at the repo root; the bundled plugin copy ships as
# template/. The same script works in both locations by auto-detecting.
if [ -d "$SCRIPT_DIR/core" ]; then
  TEMPLATE_DIR="$SCRIPT_DIR/core"
else
  TEMPLATE_DIR="$SCRIPT_DIR/template"
fi

TARGET=""
ANSWERS_FILE=""
MODE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --answers) ANSWERS_FILE="$2"; shift 2 ;;
    --merge) MODE="merge"; shift ;;
    --overwrite) MODE="overwrite"; shift ;;
    --abort) MODE="abort"; shift ;;
    --mode) MODE="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "Error: --target is required." >&2
  echo "Usage: setup.sh --target <dir> --answers <file> [--merge|--overwrite|--abort]" >&2
  exit 1
fi

if [ -z "$ANSWERS_FILE" ]; then
  echo "Error: --answers is required." >&2
  echo "" >&2
  echo "This script is not interactive. The standard flow is:" >&2
  echo "  1. Open Claude Code in your new project." >&2
  echo "  2. Tell Claude: 'set up Claude Code config from $SCRIPT_DIR'." >&2
  echo "  3. Claude drafts an answers.env, asks to confirm, then runs this script." >&2
  echo "" >&2
  echo "To drive it by hand, start from a pre-filled example:" >&2
  echo "  cp $SCRIPT_DIR/examples/python-fastapi/answers.env ./answers.env" >&2
  echo "  $0 --target . --answers ./answers.env" >&2
  exit 1
fi

case "$MODE" in
  ""|merge|overwrite|abort) ;;
  *) echo "Error: --mode must be one of: merge, overwrite, abort" >&2; exit 1 ;;
esac

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: template/ not found at $TEMPLATE_DIR" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required" >&2
  exit 1
fi

mkdir -p "$TARGET"

# Pipe answers (file or stdin) into python; everything else happens there.
if [ "$ANSWERS_FILE" = "-" ]; then
  ANSWERS_INPUT="$(cat)"
else
  if [ ! -f "$ANSWERS_FILE" ]; then
    echo "Error: answers file not found: $ANSWERS_FILE" >&2
    exit 1
  fi
  ANSWERS_INPUT="$(cat "$ANSWERS_FILE")"
fi

# All real work happens in python3 — works on macOS bash 3.2 because we
# never use associative arrays in bash itself. Python renders into a staging
# dir, detects any existing config, then applies per MODE.
PY_RC=0
ANSWERS_INPUT="$ANSWERS_INPUT" \
  TEMPLATE_DIR="$TEMPLATE_DIR" \
  TARGET="$TARGET" \
  MODE="$MODE" \
  python3 - <<'PYEOF' || PY_RC=$?
import os, re, sys, shutil, stat, json, tempfile

TEMPLATE_DIR = os.environ["TEMPLATE_DIR"]
TARGET = os.environ["TARGET"]
ANSWERS_INPUT = os.environ["ANSWERS_INPUT"]
MODE = os.environ.get("MODE", "")

# 1. Parse KEY=VALUE answers (skip blank lines + #-comments).
ANS = {}
for line in ANSWERS_INPUT.splitlines():
    line = line.rstrip("\n")
    if not line or line.lstrip().startswith("#"):
        continue
    if "=" not in line:
        continue
    k, v = line.split("=", 1)
    ANS[k.strip()] = v

# 2. Synthesize ticket_tracker_<flag>=yes for {{#flag}} sections.
tt = ANS.get("ticket_tracker", "")
flag_map = {
    "Plane":  "ticket_tracker_plane",
    "Jira":   "ticket_tracker_jira",
    "Linear": "ticket_tracker_linear",
    "GitHub": "ticket_tracker_github",
}
if tt in flag_map:
    ANS[flag_map[tt]] = "yes"

# 3. Normalize yes/no booleans — anything blank/no/false → empty (= falsy).
for k in ("has_frontend", "has_celery", "has_e2e", "enforce_layer_split", "use_gherkin", "enforce_mutation_testing"):
    v = ANS.get(k, "").strip().lower()
    if v in ("", "no", "false"):
        ANS[k] = ""

def truthy(v):
    if v is None: return False
    s = str(v).strip().lower()
    return s not in ("", "no", "false", "0", "none")

# 4. Mustache-style template renderer with standalone-tag whitespace cleanup.
STANDALONE_RE = re.compile(r"^[ \t]*\{\{[#^/](\w+)\}\}[ \t]*\n", re.MULTILINE)
SECTION_RE = re.compile(r"\{\{([#^])(\w+)\}\}(.*?)\{\{/\2\}\}", re.DOTALL)
VAR_RE = re.compile(r"\{\{(\w+)\}\}")

def render(text):
    text = STANDALONE_RE.sub(lambda m: m.group(0).rstrip("\n") + "\x00\n", text)
    prev = None
    while text != prev:
        prev = text
        def repl(m):
            kind, name, body = m.group(1), m.group(2), m.group(3)
            keep = truthy(ANS.get(name)) if kind == "#" else not truthy(ANS.get(name))
            return body if keep else ""
        text = SECTION_RE.sub(repl, text)
    text = re.sub(r"\x00\n", "", text)
    text = VAR_RE.sub(lambda m: ANS.get(m.group(1), ""), text)
    return text

# 5. Render template/ into a staging dir, honoring <!-- requires: var --> directives.
STAGING = tempfile.mkdtemp(prefix="cct-render-")
try:
    skipped = 0
    for root, dirs, files in os.walk(TEMPLATE_DIR):
        rel = os.path.relpath(root, TEMPLATE_DIR)
        out_dir = STAGING if rel == "." else os.path.join(STAGING, rel)
        os.makedirs(out_dir, exist_ok=True)
        for name in files:
            src = os.path.join(root, name)
            dst = os.path.join(out_dir, name)
            try:
                with open(src, "r", encoding="utf-8") as f:
                    content = f.read()
                first_nl = content.find("\n")
                if first_nl > 0:
                    first_line = content[:first_nl]
                    req_match = re.match(r"\s*<!--\s*requires:\s*(\w+)\s*-->\s*$", first_line)
                    if req_match and not truthy(ANS.get(req_match.group(1))):
                        skipped += 1
                        continue
                    if req_match:
                        content = content[first_nl + 1:]
                rendered = render(content)
            except UnicodeDecodeError:
                shutil.copy2(src, dst)
                continue
            with open(dst, "w", encoding="utf-8") as f:
                f.write(rendered)
            if name.endswith(".sh"):
                os.chmod(dst, os.stat(dst).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    # 6. List staged files (relative paths).
    staged = []
    for root, dirs, files in os.walk(STAGING):
        for n in files:
            staged.append(os.path.relpath(os.path.join(root, n), STAGING))
    staged.sort()

    SETTINGS_REL = os.path.join(".claude", "settings.json")
    LOCAL_SETTINGS = "settings.local.json"

    def tpath(rel):
        return os.path.join(TARGET, rel)

    def classify(rel):
        t = tpath(rel)
        if not os.path.exists(t):
            return "ADD"
        try:
            with open(os.path.join(STAGING, rel), "rb") as a, open(t, "rb") as b:
                return "SAME" if a.read() == b.read() else "DIFFERS"
        except OSError:
            return "DIFFERS"

    # 7. Detect existing Claude config in the target.
    markers = [
        os.path.join(".claude", "CLAUDE.md"), "CLAUDE.md",
        os.path.join(".claude", "settings.json"),
        os.path.join(".claude", "agents"), os.path.join(".claude", "commands"),
        os.path.join(".claude", "hooks"), os.path.join(".claude", "rules"),
    ]
    present = [m for m in markers if os.path.exists(tpath(m))]

    def write_file(rel):
        src = os.path.join(STAGING, rel); dst = tpath(rel)
        d = os.path.dirname(dst)
        if d:
            os.makedirs(d, exist_ok=True)
        shutil.copy2(src, dst)

    def merge_settings(rel):
        src = os.path.join(STAGING, rel); dst = tpath(rel)
        try:
            s = json.load(open(src, encoding="utf-8"))
        except Exception as e:
            print(f"    ! staged settings.json unparseable ({e}); skipped"); return
        try:
            t = json.load(open(dst, encoding="utf-8"))
        except Exception as e:
            print(f"    ! your settings.json is not valid JSON ({e}); left untouched"); return
        out = dict(t)
        sp = s.get("permissions", {}) or {}; tp = t.get("permissions", {}) or {}
        op = dict(tp)
        for key in ("allow", "deny", "ask"):
            merged = list(tp.get(key, []) or [])
            for item in (sp.get(key, []) or []):
                if item not in merged:
                    merged.append(item)
            if merged:
                op[key] = merged
        if op:
            out["permissions"] = op
        sh = s.get("hooks", {}) or {}; th = t.get("hooks", {}) or {}
        oh = dict(th)
        for event, arr in sh.items():
            existing = list(oh.get(event, []) or [])
            seen = {json.dumps(x, sort_keys=True) for x in existing}
            for entry in (arr or []):
                ek = json.dumps(entry, sort_keys=True)
                if ek not in seen:
                    existing.append(entry); seen.add(ek)
            oh[event] = existing
        if oh:
            out["hooks"] = oh
        with open(dst, "w", encoding="utf-8") as f:
            json.dump(out, f, indent=2); f.write("\n")
        print("    merged .claude/settings.json (union permissions + additive hooks)")

    def relink_claude_md():
        cm = tpath("CLAUDE.md"); dot = tpath(".claude")
        if os.path.isfile(cm) and os.path.isdir(dot):
            link = os.path.join(dot, "CLAUDE.md")
            if (not os.path.exists(link)) or os.path.islink(link):
                try:
                    if os.path.islink(link) or os.path.exists(link):
                        os.remove(link)
                except OSError:
                    pass
                try:
                    os.symlink(os.path.join("..", "CLAUDE.md"), link)
                except OSError:
                    pass

    def warn_dual_claude_md():
        root_cm = tpath("CLAUDE.md"); dot_cm = tpath(os.path.join(".claude", "CLAUDE.md"))
        if os.path.isfile(root_cm) and os.path.isfile(dot_cm) and not os.path.islink(dot_cm):
            try:
                a = open(root_cm, "rb").read(); b = open(dot_cm, "rb").read()
            except OSError:
                return
            if a != b:
                print("  ⚠ Both CLAUDE.md (root) and .claude/CLAUDE.md exist with DIFFERENT")
                print("    content. The template treats root CLAUDE.md as the source of truth")
                print("    (.claude/CLAUDE.md is normally a symlink to it). Reconcile these")
                print("    before relying on either — Claude Code may load the wrong one.")

    def print_plan():
        print(f"Existing Claude config detected in {TARGET}:")
        for m in present:
            print(f"  - {m}")
        print("")
        print("Planned changes (nothing written yet):")
        adds = diffs = sames = 0
        for rel in staged:
            if os.path.basename(rel) == LOCAL_SETTINGS:
                continue
            st = classify(rel)
            if st == "ADD":
                adds += 1; print(f"  ADD      {rel}")
            elif st == "DIFFERS":
                diffs += 1
                extra = "  (mergeable)" if rel == SETTINGS_REL else ""
                print(f"  DIFFERS  {rel}{extra}")
            else:
                sames += 1
        if sames:
            print(f"  SAME     ({sames} file(s) already identical)")
        print("")
        print(f"  {adds} to add, {diffs} differ, {sames} identical.")

    # 8. Apply according to MODE.
    if not present:
        # Fresh target: write everything.
        for rel in staged:
            if os.path.basename(rel) == LOCAL_SETTINGS:
                continue
            write_file(rel)
        relink_claude_md()
        print(f"✓ Template rendered to {TARGET}" + (f" (skipped {skipped} files)" if skipped else ""))
    else:
        warn_dual_claude_md()
        if MODE in ("", "abort"):
            print_plan()
            print("")
            if MODE == "":
                print("Nothing was written. Re-run with one of:")
                print("  --merge      add missing files, deep-merge settings.json, keep your other files")
                print("  --overwrite  replace template-managed files (settings.local.json is never touched)")
                print("  --abort      do nothing (this is the default)")
                sys.exit(1)
            else:
                print("Aborted — nothing was written.")
                sys.exit(0)
        elif MODE == "overwrite":
            for rel in staged:
                if os.path.basename(rel) == LOCAL_SETTINGS:
                    continue
                write_file(rel)
            relink_claude_md()
            print(f"✓ Overwrote template-managed files in {TARGET} (your settings.local.json untouched)")
        elif MODE == "merge":
            added = merged = kept = 0
            for rel in staged:
                if os.path.basename(rel) == LOCAL_SETTINGS:
                    continue
                if not os.path.exists(tpath(rel)):
                    write_file(rel); added += 1; print(f"  + {rel}")
                elif rel == SETTINGS_REL:
                    merge_settings(rel); merged += 1
                else:
                    kept += 1  # keep the user's existing file
            relink_claude_md()
            print(f"✓ Merge complete: {added} added, {merged} settings merged, {kept} kept as-is.")

    print("")
    print("Next steps:")
    print("  1. Review CLAUDE.md and .claude/HELP.md — adjust if needed")
    print("  2. cp .claude/mcp.json.example .claude/mcp.json  (if you use MCPs)")
    print("  3. Add to .gitignore:  .claude/settings.local.json, .claude/mcp.json")
    print("  4. (Re)start Claude Code to load the new config")
finally:
    shutil.rmtree(STAGING, ignore_errors=True)
PYEOF

exit "$PY_RC"
