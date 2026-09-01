#!/usr/bin/env python3
"""Validate that the Claude Code packaging is install-ready.

Checks the things that actually break an install (no auth, no network needed):
malformed manifests, missing components, skills/commands/agents with broken
frontmatter, and version skew across manifests.

  python3 scripts/validate-packaging.py        # exit 1 on any problem

Used by CI.
"""
import json, os, re, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
errors = []


def err(m):
    errors.append(m)


def load(rel):
    p = os.path.join(REPO, rel)
    if not os.path.exists(p):
        err(f"missing file: {rel}")
        return None
    try:
        return json.load(open(p, encoding="utf-8"))
    except Exception as e:
        err(f"invalid JSON in {rel}: {e}")
        return None


versions = {}

# --- Claude Code plugin manifests ---
pj = load("plugin/.claude-plugin/plugin.json")
if pj:
    for k in ("name", "version", "description"):
        if k not in pj:
            err(f"plugin.json missing '{k}'")
    versions["plugin.json"] = pj.get("version")
mk = load(".claude-plugin/marketplace.json")
if mk:
    plugins = mk.get("plugins") or []
    if not plugins:
        err("marketplace.json has no plugins[]")
    else:
        versions["marketplace.json"] = plugins[0].get("version")
        src = plugins[0].get("source", "")
        if isinstance(src, str) and src.startswith("./") and not os.path.isdir(os.path.join(REPO, src)):
            err(f"marketplace.json source does not resolve: {src}")
load("plugin/hooks/hooks.json")  # must be valid JSON if present
for d in ("plugin/agents", "plugin/commands", "plugin/skills", "plugin/template/.claude"):
    if not os.path.isdir(os.path.join(REPO, d)):
        err(f"Claude plugin: missing dir {d}")


# --- Frontmatter must be STRICTLY VALID YAML. A strict parser silently skips
# components whose frontmatter doesn't parse — e.g. an unquoted value
# containing ': '. That failure mode shipped once; never again.
def parse_frontmatter(path, rel, require=("description",), allow_requires_directive=False):
    text = open(path, encoding="utf-8").read()
    if allow_requires_directive and text.startswith("<!--"):
        text = text.split("\n", 1)[1] if "\n" in text else ""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        err(f"{rel}: missing YAML frontmatter block")
        return
    try:
        close = lines.index("---", 1)
    except ValueError:
        err(f"{rel}: unterminated frontmatter (no closing ---)")
        return
    fm_lines = lines[1:close]
    data = {}
    try:
        import yaml  # real parser when available
        try:
            data = yaml.safe_load("\n".join(fm_lines)) or {}
        except Exception as e:
            err(f"{rel}: frontmatter is INVALID YAML ({str(e).splitlines()[0]})")
            return
        if not isinstance(data, dict):
            err(f"{rel}: frontmatter is not a YAML mapping")
            return
    except ImportError:
        # Heuristic fallback: catch the known killer (unquoted ': ' in a value).
        for ln in fm_lines:
            if ":" not in ln:
                continue
            k, v = ln.split(":", 1)
            k, v = k.strip(), v.strip()
            data[k] = v
            if v and v[0] not in "\"'" and (": " in v or v.endswith(":")):
                err(f"{rel}: unquoted ':' inside '{k}' value — invalid YAML; quote the value")
    for k in require:
        if not str(data.get(k) or "").strip():
            err(f"{rel}: missing '{k}' in frontmatter")
    desc = str(data.get("description") or "")
    if len(desc) > 1024:
        err(f"{rel}: description is {len(desc)} chars (>1024)")
    nm = str(data.get("name") or "")
    if nm and not re.match(r"^[a-z0-9]+(-[a-z0-9]+)*$", nm):
        err(f"{rel}: name '{nm}' violates constraints (^[a-z0-9]+(-[a-z0-9]+)*$)")
    return data


def walk_components(base, kind, require=None, allow_requires=False, need_disable=False):
    d = os.path.join(REPO, base)
    if not os.path.isdir(d):
        return
    if kind == "skills":
        for sk in sorted(os.listdir(d)):
            f = os.path.join(d, sk, "SKILL.md")
            if os.path.isdir(os.path.join(d, sk)):
                rel = f"{base}/{sk}/SKILL.md"
                if not os.path.isfile(f):
                    err(f"{rel} missing")
                else:
                    data = parse_frontmatter(
                        f, rel, require=require or ("description",),
                        allow_requires_directive=allow_requires) or {}
                    if need_disable and str(data.get("disable-model-invocation")).lower() != "true":
                        err(f"{rel}: missing 'disable-model-invocation: true' in frontmatter")
    else:  # agents / commands: flat .md files
        for fn in sorted(os.listdir(d)):
            if fn.endswith(".md"):
                req = ("name", "description") if kind == "agents" else ("description",)
                parse_frontmatter(os.path.join(d, fn), f"{base}/{fn}",
                                  require=req, allow_requires_directive=True)


# Plugin components (live) + core sources (rendered into projects).
walk_components("plugin/skills", "skills")
walk_components("plugin/agents", "agents")
walk_components("plugin/commands", "commands")
walk_components("core/.claude/agents", "agents")
walk_components("core/.claude/commands", "commands")

# --- Cursor tree (generated by build.sh, installed by setup.sh --host cursor) ---
MDC_ALLOWED_KEYS = {"description", "globs", "alwaysApply"}
mdc_dir = os.path.join(REPO, "cursor/.cursor/rules")
if not os.path.isdir(mdc_dir):
    err("cursor tree: missing dir cursor/.cursor/rules")
else:
    for fn in sorted(os.listdir(mdc_dir)):
        if not fn.endswith(".mdc"):
            continue
        rel = f"cursor/.cursor/rules/{fn}"
        data = parse_frontmatter(os.path.join(mdc_dir, fn), rel,
                                 allow_requires_directive=True) or {}
        extra = sorted(set(data) - MDC_ALLOWED_KEYS)
        if extra:
            err(f"{rel}: unexpected frontmatter keys {extra} (allowed: {sorted(MDC_ALLOWED_KEYS)})")

load("cursor/.cursor/hooks.json")  # must be valid JSON


def check_mustache_json(rel, truthy=frozenset()):
    """cursor/.cursor/mcp.json is a mustache TEMPLATE — not valid JSON pre-render
    (it carries {{#var}}...{{/var}} conditionals). Per the mf3 judge ruling we
    validate the RENDERED form: resolve sections against a truthy-var set, stub
    {{var}} placeholders, then require the result to parse as JSON."""
    p = os.path.join(REPO, rel)
    if not os.path.exists(p):
        err(f"missing file: {rel}")
        return
    text = open(p, encoding="utf-8").read()
    sec = re.compile(r"\{\{([#^])([a-zA-Z0-9_]+)\}\}(.*?)\{\{/\2\}\}", re.S)
    while True:
        m = sec.search(text)
        if m is None:
            break
        keep = (m.group(2) in truthy) == (m.group(1) == "#")
        text = text[:m.start()] + (m.group(3) if keep else "") + text[m.end():]
    text = re.sub(r"\{\{[a-zA-Z0-9_]+\}\}", "X", text)
    try:
        json.loads(text)
    except Exception as e:
        err(f"invalid JSON in {rel} (rendered form, truthy={sorted(truthy)}): {e}")


check_mustache_json("cursor/.cursor/mcp.json")  # all conditionals falsy
check_mustache_json("cursor/.cursor/mcp.json", truthy={"has_e2e", "ticket_tracker_plane"})
check_mustache_json("cursor/.cursor/mcp.json", truthy={"has_e2e"})  # default config: e2e without an MCP tracker

walk_components("cursor/.claude/skills", "skills",
                require=("name", "description"), allow_requires=True, need_disable=True)

# --- Codex tree ---
walk_components("codex/skills", "skills", require=("name", "description"))
cx = load("codex/.codex-plugin/plugin.json")
if cx:
    for k in ("name", "version", "description"):
        if k not in cx:
            err(f"codex plugin.json missing '{k}'")
    versions["codex plugin.json"] = cx.get("version")

# --- Version consistency ---
distinct = {v for v in versions.values() if v}
if len(distinct) > 1:
    err(f"version skew across manifests: {versions}")

if errors:
    print("PACKAGING VALIDATION FAILED:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

v = next(iter(distinct), "?")
print(f"packaging valid @ v{v}: Claude plugin manifests + agents + commands + skills "
      f"+ cursor rules/hooks/mcp/skills + codex skills/manifest ✓")
