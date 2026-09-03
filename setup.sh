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
#                 .claude/settings.local.json. Add --overwrite-files a,b
#                 (comma list of target-relative paths) to take the template
#                 version of just those files; listing .claude/CLAUDE.md
#                 replaces a regular file there with the ../CLAUDE.md symlink.
#                 Add --prune to delete unchanged managed files no longer in
#                 the template; customized or unproven paths are always kept.
#   --overwrite   Replace template-managed files. Still never touches
#                 .claude/settings.local.json, and never deletes files the
#                 template doesn't manage.
#   --abort       Do nothing (this is the default if no mode is given).
#
# Run with no mode against an existing config to see a per-file change plan:
#   STALE-MANAGED     differs from the new render but matches its saved baseline
#   CUSTOMIZED-MANAGED differs from both the new render and saved baseline
#   LEGACY            differs and has no usable baseline yet
#   CUSTOMIZED        user-filled file differs (root CLAUDE.md, docs/CONTEXT.md,
#                     docs/design-system/) — yours, kept on --merge, never in the line
#   OBSOLETE          recorded managed file no longer emitted; baseline unchanged
#   CUSTOMIZED-OBSOLETE retired managed path that is edited or cannot be proven safe
#   SYMLINK-CONFLICT  .claude/CLAUDE.md is a regular file where a symlink to
#                     ../CLAUDE.md is expected
# The plan ends with one copy-pasteable `--merge --overwrite-files ...` line
# listing every STALE-MANAGED path; customized and legacy paths must be named
# explicitly if you decide to replace them.
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
#   setup.sh --target <dir> --answers <file> [--merge [--overwrite-files a,b] [--prune]|--overwrite|--abort]
#   setup.sh --target <dir> --answers -        # read answers from stdin
#   setup.sh --host <list> ...                  # comma-separated target hosts
#
# Hosts (--host, or TARGET_HOSTS=<list> in the answers file; --host wins):
#   claude   default — the .claude/ tree + CLAUDE.md (byte-identical to a
#            render without --host)
#   cursor   the generated cursor/ tree (AGENTS.md, .cursor/, .claude/ agents+
#            rules+skills — no Claude hooks surface)
#   codex    AGENTS.md + the generated codex skills under .agents/skills/
#   grok     alias: claude tree + AGENTS.md (Grok Build reads .claude natively)
# Anything else (opencode, gemini, windsurf, ...) is unsupported — use the
# port-config skill to generate a port for that host.
#
# Requires: bash 3.2+ (works on stock macOS bash) and python3.
# All non-trivial logic runs in python3 to stay portable across shells.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_VERSION="0.9.2"
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
HOST_ARG=""
OVERWRITE_FILES=""
PRUNE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --answers) ANSWERS_FILE="$2"; shift 2 ;;
    --host) HOST_ARG="$2"; shift 2 ;;
    --merge) MODE="merge"; shift ;;
    --overwrite) MODE="overwrite"; shift ;;
    --abort) MODE="abort"; shift ;;
    --mode) MODE="$2"; shift 2 ;;
    --overwrite-files) OVERWRITE_FILES="$2"; shift 2 ;;
    --prune) PRUNE=1; shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "Error: --target is required." >&2
  echo "Usage: setup.sh --target <dir> --answers <file> [--merge [--overwrite-files a,b] [--prune]|--overwrite|--abort]" >&2
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
if [ -n "$OVERWRITE_FILES" ] && [ "$MODE" != "merge" ]; then
  echo "Error: --overwrite-files is only valid together with --merge." >&2
  exit 1
fi
if [ -n "$PRUNE" ] && [ "$MODE" != "merge" ]; then
  echo "Error: --prune is only valid together with --merge." >&2
  exit 1
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Error: template/ not found at $TEMPLATE_DIR" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required" >&2
  exit 1
fi

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

# Non-claude hosts render from the generated trees shipped next to this script
# (repo root: cursor/, codex/skills/; plugin bundle: same relative paths).
CURSOR_DIR="$SCRIPT_DIR/cursor"
CODEX_SKILLS_DIR="$SCRIPT_DIR/codex/skills"
if [ -f "$SCRIPT_DIR/scripts/build.sh" ]; then
  SOURCE_TREE_HINT="run scripts/build.sh first"
else
  SOURCE_TREE_HINT="reinstall/update the plugin"
fi

# All real work happens in python3 — works on macOS bash 3.2 because we
# never use associative arrays in bash itself. Python renders into a staging
# dir, detects any existing config, then applies per MODE.
PY_RC=0
ANSWERS_INPUT="$ANSWERS_INPUT" \
  TEMPLATE_DIR="$TEMPLATE_DIR" \
  TARGET="$TARGET" \
  MODE="$MODE" \
  OVERWRITE_FILES="$OVERWRITE_FILES" \
  PRUNE="$PRUNE" \
  ANSWERS_FILE="$ANSWERS_FILE" \
  SCRIPT="$0" \
  TEMPLATE_VERSION="$TEMPLATE_VERSION" \
  HOST_ARG="$HOST_ARG" \
  CURSOR_DIR="$CURSOR_DIR" \
  CODEX_SKILLS_DIR="$CODEX_SKILLS_DIR" \
  SOURCE_TREE_HINT="$SOURCE_TREE_HINT" \
  python3 - <<'PYEOF' || PY_RC=$?
import hashlib, json, os, re, shlex, shutil, stat, sys, tempfile

TEMPLATE_DIR = os.environ["TEMPLATE_DIR"]
TARGET = os.environ["TARGET"]
ANSWERS_INPUT = os.environ["ANSWERS_INPUT"]
MODE = os.environ.get("MODE", "")
OVERWRITE_FILES = [p for p in os.environ.get("OVERWRITE_FILES", "").split(",") if p]
PRUNE = os.environ.get("PRUNE") == "1"
CURSOR_DIR = os.environ.get("CURSOR_DIR", "")
CODEX_SKILLS_DIR = os.environ.get("CODEX_SKILLS_DIR", "")
SOURCE_TREE_HINT = os.environ["SOURCE_TREE_HINT"]
TEMPLATE_VERSION = os.environ["TEMPLATE_VERSION"]

# 1. Parse KEY=VALUE answers (skip blank lines + #-comments).
def answer_value(value, line_number):
    if not value or value[0] not in "\"'":
        return value
    quote = value[0]
    escaped = False
    closing = None
    for index, char in enumerate(value[1:], 1):
        if quote == '"' and char == "\\" and not escaped:
            escaped = True
            continue
        if char == quote and not escaped:
            closing = index
            break
        escaped = False
    if closing != len(value) - 1:
        print(f"Error: answers line {line_number}: malformed quoted value.", file=sys.stderr)
        sys.exit(1)
    try:
        parsed = shlex.split(value, comments=False, posix=True)
    except ValueError:
        parsed = []
    if len(parsed) != 1:
        print(f"Error: answers line {line_number}: malformed quoted value.", file=sys.stderr)
        sys.exit(1)
    return parsed[0]

ANS = {}
for line_number, line in enumerate(ANSWERS_INPUT.splitlines(), 1):
    line = line.rstrip("\n")
    if not line or line.lstrip().startswith("#"):
        continue
    if "=" not in line:
        continue
    k, v = line.split("=", 1)
    ANS[k.strip()] = answer_value(v, line_number)

# Host selection (D4/D11): --host wins; else parsed TARGET_HOSTS; else claude.
HOST_ORDER = ("claude", "grok", "cursor", "codex")
raw_hosts = os.environ.get("HOST_ARG") or ANS.get("TARGET_HOSTS") or "claude"
selected_hosts = {host.strip().lower() for host in raw_hosts.replace(",", " ").split()}
unsupported = sorted(selected_hosts - set(HOST_ORDER))
if unsupported:
    print(f"Error: unsupported host '{unsupported[0]}'. Supported hosts: claude, cursor, codex (alias: grok).", file=sys.stderr)
    print("For other hosts (opencode, gemini, windsurf, ...) use the port-config skill", file=sys.stderr)
    print("to generate a port of this config for that host.", file=sys.stderr)
    sys.exit(1)
HOSTS = [host for host in HOST_ORDER if host in selected_hosts]
if any(host in HOSTS for host in ("cursor", "grok", "codex")) and not os.path.isfile(os.path.join(CURSOR_DIR, "AGENTS.md")):
    print(f"Error: cursor source tree not found at {CURSOR_DIR} ({SOURCE_TREE_HINT}).", file=sys.stderr)
    sys.exit(1)
if "codex" in HOSTS and not os.path.isdir(CODEX_SKILLS_DIR):
    print(f"Error: codex skills tree not found at {CODEX_SKILLS_DIR} ({SOURCE_TREE_HINT}).", file=sys.stderr)
    sys.exit(1)
os.makedirs(TARGET, exist_ok=True)

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

# 2a. Synthesize workflow_tdd=yes when workflow_mode is SDD+TDD (absent = SDD).
if ANS.get("workflow_mode", "").strip() == "SDD+TDD":
    ANS["workflow_tdd"] = "yes"

# 2b. Synthesize project-type flags + the primary dev agent for this stack.
#     {{primary_dev_agent}} lets every reference to "the implementer" render
#     to the right specialist; {{#is_*}} sections gate type-specific files.
pt = (ANS.get("project_type") or "web-app").strip().lower()
PT_FLAGS = {
    "web-app":     ("is_web",     "backend-dev"),
    "api-service": ("is_web",     "backend-dev"),
    "mobile-app":  ("is_mobile",  "mobile-dev"),
    "desktop-app": ("is_desktop", "desktop-dev"),
    "game":        ("is_game",    "game-dev"),
    "library-cli": ("is_generic", "core-dev"),
    "data-ml":     ("is_generic", "core-dev"),
    "other":       ("is_generic", "core-dev"),
}
flag, dev = PT_FLAGS.get(pt, ("is_generic", "core-dev"))
ANS.setdefault("project_type", pt)
ANS[flag] = "yes"
ANS["primary_dev_agent"] = dev
# UI-bearing projects get ui-designer; web frontends additionally get frontend-dev.
if ANS.get("has_frontend", "").strip().lower() in ("yes", "true") or flag in ("is_mobile", "is_desktop", "is_game"):
    ANS["has_ui"] = "yes"
# Persistence-aware sections (style guide DB rules etc.).
if (ANS.get("database") or "").strip().lower() not in ("", "none", "n/a", "no"):
    ANS["has_database"] = "yes"
# Back-compat: accept old has_celery as has_background_jobs.
if "has_background_jobs" not in ANS and "has_celery" in ANS:
    ANS["has_background_jobs"] = ANS["has_celery"]

# 3. Normalize yes/no booleans — anything blank/no/false → empty (= falsy).
for k in ("has_frontend", "has_background_jobs", "has_e2e", "enforce_layer_split", "use_gherkin", "enforce_mutation_testing", "has_ui", "has_database"):
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

# 5. Render each selected host's source tree(s) into ONE staging dir, honoring
#    <!-- requires: var --> directives. Every host goes through this same
#    renderer. A file emitted by more than one selected host must render
#    byte-identical — a differing collision aborts (D4 invariant).
STAGING = tempfile.mkdtemp(prefix="cct-render-")
try:
    skipped = set()

    def collide(rel):
        print(f"Error: host collision on {rel} — the selected hosts render different content for the same path.", file=sys.stderr)
        sys.exit(1)

    def stage_file(src, rel):
        dst = os.path.join(STAGING, rel)
        d = os.path.dirname(dst)
        if d:
            os.makedirs(d, exist_ok=True)
        try:
            with open(src, "r", encoding="utf-8") as f:
                content = f.read()
            first_nl = content.find("\n")
            if first_nl > 0:
                first_line = content[:first_nl]
                req_match = re.match(r"\s*<!--\s*requires:\s*(\w+)\s*-->\s*$", first_line)
                if req_match and not truthy(ANS.get(req_match.group(1))):
                    skipped.add(rel)
                    return
                if req_match:
                    content = content[first_nl + 1:]
            rendered = render(content)
        except UnicodeDecodeError:
            if os.path.exists(dst):
                with open(src, "rb") as a, open(dst, "rb") as b:
                    if a.read() != b.read():
                        collide(rel)
                return
            shutil.copy2(src, dst)
            return
        if os.path.exists(dst):
            with open(dst, "r", encoding="utf-8") as f:
                if f.read() != rendered:
                    collide(rel)
            return
        with open(dst, "w", encoding="utf-8") as f:
            f.write(rendered)
        if rel.endswith(".sh"):
            os.chmod(dst, os.stat(dst).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

    def stage_tree(src_root, prefix=""):
        for root, dirs, files in os.walk(src_root):
            rel_dir = os.path.relpath(root, src_root)
            for name in files:
                rel = name if rel_dir == "." else os.path.join(rel_dir, name)
                if prefix:
                    rel = os.path.join(prefix, rel)
                stage_file(os.path.join(root, name), rel)

    # Host -> source mapping (D4 alias for grok; Q4 mapping for codex).
    for h in HOSTS:
        if h in ("claude", "grok"):
            stage_tree(TEMPLATE_DIR)
        if h == "cursor":
            stage_tree(CURSOR_DIR)
        if h in ("grok", "codex"):
            stage_file(os.path.join(CURSOR_DIR, "AGENTS.md"), "AGENTS.md")
        if h == "codex":
            stage_tree(CODEX_SKILLS_DIR, os.path.join(".agents", "skills"))

    # 6. List staged files (relative paths).
    staged = []
    for root, dirs, files in os.walk(STAGING):
        for n in files:
            staged.append(os.path.relpath(os.path.join(root, n), STAGING))
    staged.sort()

    SETTINGS_REL = os.path.join(".claude", "settings.json")
    LOCAL_SETTINGS = "settings.local.json"
    LOCAL_ANSWERS_REL = os.path.join(".claude", "answers.local.env")
    GITIGNORE_REL = ".gitignore"
    LOCK_REL = "agent-config.lock.json"
    LOCK_SCHEMA = 1
    DOT_CLAUDE_MD = os.path.join(".claude", "CLAUDE.md")  # never staged: the template's version is the ../CLAUDE.md symlink
    # D13: user-filled files are yours — never labelled stale, never in --overwrite-files.
    NON_MANAGED = {"CLAUDE.md", os.path.join("docs", "CONTEXT.md")}
    NON_MANAGED_DIRS = (os.path.join("docs", "design-system") + os.sep,)
    MANAGED_EXACT = {
        "AGENTS.md",
        os.path.join(".claude", "HELP.md"),
        os.path.join(".claude", "mcp.json.example"),
        os.path.join(".cursor", "hooks.json"),
        os.path.join(".cursor", "mcp.json"),
    }
    MANAGED_DIRS = tuple(
        path + os.sep
        for path in (
            os.path.join(".agents", "skills"),
            os.path.join(".claude", "agents"),
            os.path.join(".claude", "commands"),
            os.path.join(".claude", "hooks"),
            os.path.join(".claude", "patterns"),
            os.path.join(".claude", "rules"),
            os.path.join(".claude", "skills"),
            os.path.join(".cursor", "hooks"),
            os.path.join(".cursor", "rules"),
            "tools",
        )
    )
    REAL_TARGET = os.path.realpath(TARGET) + os.sep

    def non_managed(rel):
        return rel in NON_MANAGED or rel.startswith(NON_MANAGED_DIRS)

    def tpath(rel):
        return os.path.join(TARGET, rel)

    def check_inside(rels):
        # Refuse before any write: a symlinked file or intermediate dir must not lead outside TARGET.
        outside = [r for r in rels if not os.path.realpath(tpath(r)).startswith(REAL_TARGET)]
        if outside:
            print(f"Error: path(s) resolve outside {TARGET} via symlink; refusing to write: {','.join(outside)}", file=sys.stderr)
            sys.exit(1)

    def lock_managed(rel):
        return (
            rel != LOCK_REL
            and rel != SETTINGS_REL
            and rel != DOT_CLAUDE_MD
            and os.path.basename(rel) != LOCAL_SETTINGS
            and not non_managed(rel)
            and (rel in MANAGED_EXACT or rel.startswith(MANAGED_DIRS))
        )

    def safe_lock_rel(rel):
        return (
            isinstance(rel, str)
            and rel not in ("", ".")
            and "\0" not in rel
            and not os.path.isabs(rel)
            and os.path.normpath(rel) == rel
            and not rel.startswith(".." + os.sep)
            and rel != LOCK_REL
        )

    def sha256(path):
        digest = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    def load_lock():
        path = tpath(LOCK_REL)
        if not os.path.lexists(path):
            return None
        try:
            if os.path.islink(path) or not os.path.isfile(path):
                raise ValueError("state path is not a regular file")
            if not os.path.realpath(path).startswith(REAL_TARGET):
                raise ValueError("state path resolves outside target")
            with open(path, encoding="utf-8") as f:
                data = json.load(f)
            if not isinstance(data, dict) or data.get("schema_version") != LOCK_SCHEMA:
                raise ValueError("unsupported schema")
            if not isinstance(data.get("template_version"), str):
                raise ValueError("invalid template version")
            hosts = data.get("hosts")
            if not isinstance(hosts, list) or any(not isinstance(h, str) for h in hosts):
                raise ValueError("invalid hosts")
            files = data.get("files")
            if not isinstance(files, dict):
                raise ValueError("invalid files map")
            for rel, entry in files.items():
                if not safe_lock_rel(rel) or not lock_managed(rel) or not isinstance(entry, dict):
                    raise ValueError("unsafe managed path")
                if not isinstance(entry.get("template_version"), str):
                    raise ValueError("invalid file version")
                if not re.fullmatch(r"[0-9a-f]{64}", str(entry.get("sha256", ""))):
                    raise ValueError("invalid file hash")
            return data
        except (OSError, ValueError, json.JSONDecodeError) as e:
            print(f"  ⚠ Ignoring invalid {LOCK_REL}: {e}")
            return None

    previous_lock = load_lock()
    previous_files = {
        rel: {"template_version": entry["template_version"], "sha256": entry["sha256"]}
        for rel, entry in (previous_lock["files"].items() if previous_lock else [])
    }

    def classify(rel):
        t = tpath(rel)
        if not os.path.lexists(t):
            return "ADD"
        if os.path.islink(t) or not os.path.isfile(t):
            return "DIFFERS"
        try:
            with open(os.path.join(STAGING, rel), "rb") as a, open(t, "rb") as b:
                return "SAME" if a.read() == b.read() else "DIFFERS"
        except OSError:
            return "DIFFERS"

    def managed_difference(rel):
        entry = previous_files.get(rel)
        target = tpath(rel)
        if not entry:
            return "LEGACY"
        if os.path.islink(target) or not os.path.isfile(target):
            return "CUSTOMIZED-MANAGED"
        if not os.path.realpath(target).startswith(REAL_TARGET):
            return "CUSTOMIZED-MANAGED"
        try:
            return "STALE-MANAGED" if sha256(target) == entry["sha256"] else "CUSTOMIZED-MANAGED"
        except OSError:
            return "CUSTOMIZED-MANAGED"

    def obsolete_difference(rel):
        target = tpath(rel)
        if os.path.islink(target) or not os.path.isfile(target):
            return "CUSTOMIZED-OBSOLETE"
        if not os.path.realpath(target).startswith(REAL_TARGET):
            return "CUSTOMIZED-OBSOLETE"
        try:
            return "OBSOLETE" if sha256(target) == previous_files[rel]["sha256"] else "CUSTOMIZED-OBSOLETE"
        except OSError:
            return "CUSTOMIZED-OBSOLETE"

    obsolete = [
        (rel, obsolete_difference(rel))
        for rel in sorted(set(previous_files) - set(staged))
    ]

    def symlink_conflict():
        t = tpath(DOT_CLAUDE_MD)
        return DOT_CLAUDE_MD not in staged and os.path.isfile(t) and not os.path.islink(t)

    # 6a. --overwrite-files must name template-managed paths (or .claude/CLAUDE.md); fail before writing anything.
    overwritable = {r for r in staged if not non_managed(r) and os.path.basename(r) != LOCAL_SETTINGS} | {DOT_CLAUDE_MD}
    unknown = [p for p in OVERWRITE_FILES if p not in overwritable]
    if unknown:
        print(f"Error: --overwrite-files names path(s) the template does not manage: {','.join(unknown)}", file=sys.stderr)
        sys.exit(1)
    if SETTINGS_REL in OVERWRITE_FILES:
        print(f"Error: {SETTINGS_REL} is merge-managed (deep-merged on --merge); remove it from --overwrite-files.", file=sys.stderr)
        sys.exit(1)
    if DOT_CLAUDE_MD in OVERWRITE_FILES and not (os.path.isfile(tpath("CLAUDE.md")) and not os.path.islink(tpath("CLAUDE.md"))):
        print(f"Error: --overwrite-files {DOT_CLAUDE_MD} needs a regular root CLAUDE.md to link to; move {DOT_CLAUDE_MD} to CLAUDE.md first.", file=sys.stderr)
        sys.exit(1)
    check_inside(OVERWRITE_FILES)

    # 7. Detect existing Claude config in the target.
    markers = [
        LOCK_REL,
        os.path.join(".claude", "CLAUDE.md"), "CLAUDE.md",
        os.path.join(".claude", "settings.json"),
        os.path.join(".claude", "agents"), os.path.join(".claude", "commands"),
        os.path.join(".claude", "hooks"), os.path.join(".claude", "rules"),
    ]
    # Non-destructive detection extends to every selected host's surface.
    if any(h in ("cursor", "grok", "codex") for h in HOSTS):
        markers.append("AGENTS.md")
    if "cursor" in HOSTS:
        markers += [os.path.join(".cursor", "rules"), os.path.join(".cursor", "hooks.json")]
    if "codex" in HOSTS:
        markers.append(os.path.join(".agents", "skills"))
    present = [m for m in markers if os.path.exists(tpath(m))]

    def write_file(rel):
        check_inside([rel])
        src = os.path.join(STAGING, rel); dst = tpath(rel)
        d = os.path.dirname(dst)
        if d:
            os.makedirs(d, exist_ok=True)
        shutil.copy2(src, dst)

    def write_lock(advance, remove=()):
        path = tpath(LOCK_REL)
        files = {rel: entry for rel, entry in previous_files.items() if lock_managed(rel)}
        for rel in remove:
            files.pop(rel, None)
        for rel in advance:
            target = tpath(rel)
            if not lock_managed(rel):
                files.pop(rel, None)
            elif os.path.isfile(target) and not os.path.islink(target) and os.path.realpath(target).startswith(REAL_TARGET):
                files[rel] = {"template_version": TEMPLATE_VERSION, "sha256": sha256(target)}
        state = {
            "schema_version": LOCK_SCHEMA,
            "template_version": TEMPLATE_VERSION,
            "hosts": HOSTS,
            "files": dict(sorted(files.items())),
        }
        fd, temporary = tempfile.mkstemp(prefix=".agent-config.lock.", dir=TARGET)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump(state, f, indent=2, sort_keys=True)
                f.write("\n")
            os.replace(temporary, path)
        finally:
            if os.path.exists(temporary):
                os.remove(temporary)

    def ensure_lock_writable():
        path = tpath(LOCK_REL)
        if os.path.lexists(path) and (os.path.islink(path) or not os.path.isfile(path)):
            print(f"Error: {LOCK_REL} is not a regular file; refusing to replace it.", file=sys.stderr)
            sys.exit(1)
        check_inside([LOCK_REL])

    def ignore_local_answers():
        if not os.path.isfile(tpath(LOCAL_ANSWERS_REL)):
            return
        check_inside([GITIGNORE_REL])
        path = tpath(GITIGNORE_REL)
        try:
            data = open(path, "rb").read() if os.path.exists(path) else b""
            rule = LOCAL_ANSWERS_REL.encode()
            if rule in data.splitlines():
                return
            with open(path, "ab") as f:
                if data and not data.endswith(b"\n"):
                    f.write(b"\n")
                f.write(rule + b"\n")
        except OSError as e:
            print(f"Error: cannot update {GITIGNORE_REL}: {e}", file=sys.stderr)
            sys.exit(1)
        print(f"  Added {LOCAL_ANSWERS_REL} to {GITIGNORE_REL}")

    def remove_empty_managed_dirs(deleted):
        roots = tuple(path.rstrip(os.sep) for path in MANAGED_DIRS)
        candidates = set()
        for rel in deleted:
            parent = os.path.dirname(rel)
            while parent and any(parent == root or parent.startswith(root + os.sep) for root in roots):
                candidates.add(parent)
                parent = os.path.dirname(parent)
        for rel in sorted(candidates, key=lambda path: path.count(os.sep), reverse=True):
            path = tpath(rel)
            if os.path.realpath(path).startswith(REAL_TARGET):
                try:
                    os.rmdir(path)
                except OSError:
                    pass

    def merge_settings(rel):
        check_inside([rel])  # never union-merge through a symlink that escapes TARGET
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
        stale = []
        for rel in staged:
            if os.path.basename(rel) == LOCAL_SETTINGS:
                continue
            st = classify(rel)
            if st == "ADD":
                adds += 1; print(f"  ADD               {rel}")
            elif st == "DIFFERS":
                diffs += 1
                if non_managed(rel):
                    print(f"  CUSTOMIZED        {rel}  (yours — keep; --merge never touches it, reconcile by hand)")
                elif rel == SETTINGS_REL:
                    print(f"  STALE-MANAGED     {rel}  (mergeable)")
                else:
                    label = managed_difference(rel)
                    if label == "STALE-MANAGED":
                        stale.append(rel)
                    print(f"  {label:<20}{rel}")
            else:
                sames += 1
        for rel, label in obsolete:
            diffs += 1; print(f"  {label:<20}{rel}")
        if symlink_conflict():
            diffs += 1; print(f"  SYMLINK-CONFLICT  {DOT_CLAUDE_MD}  (regular file; expected symlink to ../CLAUDE.md)")
        if sames:
            print(f"  SAME              ({sames} file(s) already identical)")
        print("")
        print(f"  {adds} to add, {diffs} differ, {sames} identical.")
        if stale:
            print("  Regenerate the STALE-MANAGED files (delete any you want to keep):")
            print(f"  {shlex.quote(os.environ['SCRIPT'])} --target {shlex.quote(TARGET)} --answers {shlex.quote(os.environ['ANSWERS_FILE'])} --merge --overwrite-files {','.join(stale)}")
            if os.environ["ANSWERS_FILE"] == "-":
                print("  Note: pipe the same answers to stdin when running this command.")

    # 8. Apply according to MODE.
    to_write = [r for r in staged if os.path.basename(r) != LOCAL_SETTINGS]
    initial_state = {rel: classify(rel) for rel in to_write}
    if not present:
        # Fresh target: write everything.
        ensure_lock_writable()
        check_inside(to_write)
        for rel in to_write:
            write_file(rel)
        relink_claude_md()
        write_lock(to_write)
        print(f"✓ Template rendered to {TARGET}" + (f" (skipped {len(skipped)} files)" if skipped else ""))
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
            ensure_lock_writable()
            check_inside(to_write)
            for rel in to_write:
                write_file(rel)
            relink_claude_md()
            write_lock(to_write)
            print(f"✓ Overwrote template-managed files in {TARGET} (your settings.local.json untouched)")
        elif MODE == "merge":
            added = merged = kept = overwritten = 0
            advance = set()
            removed = []
            ensure_lock_writable()
            prunable = [rel for rel, label in obsolete if PRUNE and label == "OBSOLETE"]
            check_inside([r for r in to_write if not os.path.exists(tpath(r)) or r in OVERWRITE_FILES] + prunable)
            for rel, label in obsolete:
                if PRUNE and label == "OBSOLETE" and obsolete_difference(rel) == "OBSOLETE":
                    try:
                        os.remove(tpath(rel))
                    except OSError as e:
                        print(f"Error: cannot prune {rel}: {e}", file=sys.stderr)
                        sys.exit(1)
                    removed.append(rel); print(f"  - {rel}")
                else:
                    kept += 1; print(f"  {obsolete_difference(rel):<20}{rel}  (kept)")
            remove_empty_managed_dirs(removed)
            for rel in to_write:
                if not os.path.exists(tpath(rel)):
                    write_file(rel); advance.add(rel); added += 1; print(f"  + {rel}")
                elif rel in OVERWRITE_FILES:
                    write_file(rel); advance.add(rel); overwritten += 1; print(f"  ~ {rel}")
                elif rel == SETTINGS_REL:
                    merge_settings(rel); merged += 1
                else:
                    kept += 1  # keep the user's existing file
                    if initial_state[rel] == "SAME":
                        advance.add(rel)
            if DOT_CLAUDE_MD in OVERWRITE_FILES and symlink_conflict():
                os.remove(tpath(DOT_CLAUDE_MD)); overwritten += 1; print(f"  ~ {DOT_CLAUDE_MD}  (relinked to ../CLAUDE.md)")
            relink_claude_md()
            write_lock(advance, removed)
            print(f"✓ Merge complete: {added} added, {merged} settings merged, {overwritten} overwritten, {len(removed)} pruned, {kept} kept as-is.")

    ignore_local_answers()
    print("")
    print("Next steps:")
    print("  1. Review CLAUDE.md and .claude/HELP.md — adjust if needed")
    print("  2. cp .claude/mcp.json.example .claude/mcp.json  (if you use MCPs)")
    print("  3. Add to .gitignore:  .claude/settings.local.json, .claude/mcp.json (answers.local.env is automatic)")
    print("  4. (Re)start Claude Code to load the new config")
finally:
    shutil.rmtree(STAGING, ignore_errors=True)
PYEOF

exit "$PY_RC"
