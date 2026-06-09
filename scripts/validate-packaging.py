#!/usr/bin/env python3
"""Validate that every host packaging is install-ready.

Checks the things that actually break an install (no auth, no network needed):
malformed manifests, missing components, skills without required frontmatter,
unresolved marketplace paths, and version skew across manifests.

  python3 scripts/validate-packaging.py        # exit 1 on any problem

Used by CI. A true end-to-end install on each host needs that host's CLI + auth
(see .github/workflows/ci.yml for the optional live `npx skills add` smoke).
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

# --- Claude Code plugin ---
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
load("plugin/hooks/hooks.json")  # must be valid JSON if present
for d in ("plugin/agents", "plugin/commands", "plugin/skills", "plugin/template/.claude"):
    if not os.path.isdir(os.path.join(REPO, d)):
        err(f"Claude plugin: missing dir {d}")

# --- Codex native plugin ---
cj = load("codex/.codex-plugin/plugin.json")
if cj:
    for k in ("name", "version", "skills"):
        if k not in cj:
            err(f"codex plugin.json missing '{k}'")
    versions["codex/plugin.json"] = cj.get("version")
    skills_sub = (cj.get("skills") or "./skills/").strip("./").rstrip("/")
    if not os.path.isdir(os.path.join(REPO, "codex", skills_sub)):
        err(f"codex plugin.json: skills path '{cj.get('skills')}' does not resolve")
cm = load(".agents/plugins/marketplace.json")
if cm:
    plugins = cm.get("plugins") or []
    if not plugins:
        err("codex marketplace.json has no plugins[]")
    else:
        p0 = plugins[0]
        pol = p0.get("policy", {})
        for k in ("installation", "authentication"):
            if k not in pol:
                err(f"codex marketplace plugin missing policy.{k}")
        if "category" not in p0:
            err("codex marketplace plugin missing 'category'")
        sp = (p0.get("source") or {}).get("path", "")
        if not sp or not os.path.exists(os.path.join(REPO, sp)):
            err(f"codex marketplace source.path does not resolve: {sp!r}")

# --- Antigravity / Gemini extension ---
gx = load("gemini-extension.json")
if gx:
    for k in ("name", "version"):
        if k not in gx:
            err(f"gemini-extension.json missing '{k}'")
    versions["gemini-extension.json"] = gx.get("version")
    if not re.match(r"^[a-z0-9-]+$", gx.get("name", "")):
        err("gemini-extension.json 'name' must be lowercase letters/numbers/dashes")
    ctx = gx.get("contextFileName", "GEMINI.md")
    if not os.path.exists(os.path.join(REPO, ctx)):
        err(f"gemini-extension.json contextFileName not found: {ctx}")

# --- Skills must have STRICTLY VALID YAML frontmatter with name + description.
# Hosts that consume these (the skills CLI, Codex, OpenCode) use strict YAML
# parsers and SILENTLY SKIP a skill whose frontmatter doesn't parse — e.g. an
# unquoted description containing ': '. That failure mode shipped once; never again.
def parse_frontmatter(path, rel, require_name=True):
    lines = open(path, encoding="utf-8").read().splitlines()
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
            err(f"{rel}: frontmatter is INVALID YAML ({str(e).splitlines()[0]}) — "
                "strict hosts silently skip such skills")
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
                err(f"{rel}: unquoted ':' inside '{k}' value — invalid YAML; "
                    "quote the value (strict hosts silently skip such skills)")
    keys = ("name", "description") if require_name else ("description",)
    for k in keys:
        if not str(data.get(k) or "").strip():
            err(f"{rel}: missing '{k}' in frontmatter")
    desc = str(data.get("description") or "")
    if len(desc) > 1024:
        err(f"{rel}: description is {len(desc)} chars (OpenCode caps it at 1024)")
    nm = str(data.get("name") or "")
    if nm and not re.match(r"^[a-z0-9]+(-[a-z0-9]+)*$", nm):
        err(f"{rel}: name '{nm}' violates host constraints (^[a-z0-9]+(-[a-z0-9]+)*$)")


for base in ("skills", "codex/skills"):
    d = os.path.join(REPO, base)
    if not os.path.isdir(d):
        err(f"missing skills tree: {base}/")
        continue
    names = [n for n in os.listdir(d) if os.path.isdir(os.path.join(d, n))]
    if not names:
        err(f"{base}/ has no skills")
    for sk in sorted(names):
        f = os.path.join(d, sk, "SKILL.md")
        if not os.path.exists(f):
            err(f"{base}/{sk}/SKILL.md missing")
            continue
        parse_frontmatter(f, f"{base}/{sk}/SKILL.md")

# Claude plugin skills: name derives from the directory, so require only description.
pd = os.path.join(REPO, "plugin", "skills")
if os.path.isdir(pd):
    for sk in sorted(os.listdir(pd)):
        f = os.path.join(pd, sk, "SKILL.md")
        if os.path.isfile(f):
            parse_frontmatter(f, f"plugin/skills/{sk}/SKILL.md", require_name=False)

# --- Gemini / Antigravity native commands (generated TOML) ---
cmd_dir = os.path.join(REPO, "commands")
if not os.path.isdir(cmd_dir):
    err("missing commands/ (Gemini native slash commands)")
else:
    tomls = [f for f in sorted(os.listdir(cmd_dir)) if f.endswith(".toml")]
    if not tomls:
        err("commands/ has no .toml files")
    try:
        import tomllib  # py3.11+; soft dependency
    except ImportError:
        tomllib = None
    for f in tomls:
        p = os.path.join(cmd_dir, f)
        if tomllib:
            try:
                data = tomllib.load(open(p, "rb"))
                if not data.get("prompt"):
                    err(f"commands/{f}: missing 'prompt'")
            except Exception as e:
                err(f"commands/{f}: invalid TOML: {e}")
        else:
            s = open(p, encoding="utf-8").read()
            if "prompt = '''" not in s:
                err(f"commands/{f}: missing prompt block")

# --- Cross-tool rules files ---
for rel, limit in (("AGENTS.md", 12000), ("GEMINI.md", 12000)):
    p = os.path.join(REPO, rel)
    if not os.path.exists(p):
        err(f"missing rules file: {rel}")
        continue
    n = len(open(p, encoding="utf-8").read())
    if n == 0:
        err(f"{rel} is empty")
    elif n > limit:
        err(f"{rel} is {n} chars (over the {limit}-char rules-size budget we enforce for portability)")

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
print(f"packaging valid @ v{v}: Claude plugin + Codex plugin/marketplace + "
      f"Antigravity extension + skills + rules ✓")
