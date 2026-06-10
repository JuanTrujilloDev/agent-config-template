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


def walk_components(base, kind):
    d = os.path.join(REPO, base)
    if not os.path.isdir(d):
        return
    if kind == "skills":
        for sk in sorted(os.listdir(d)):
            f = os.path.join(d, sk, "SKILL.md")
            if os.path.isdir(os.path.join(d, sk)):
                if not os.path.isfile(f):
                    err(f"{base}/{sk}/SKILL.md missing")
                else:
                    parse_frontmatter(f, f"{base}/{sk}/SKILL.md")
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
print(f"packaging valid @ v{v}: Claude plugin manifests + agents + commands + skills ✓")
