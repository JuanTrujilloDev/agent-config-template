#!/usr/bin/env python3
"""Generate the portable skill tree and the Codex native plugin from the
de-parameterized (stack-agnostic) content under plugin/.

Outputs (all generated — don't hand-edit):
  skills/<name>/SKILL.md              # `npx skills add` quick path (Codex + OpenCode)
  codex/.codex-plugin/plugin.json     # Codex native plugin manifest
  codex/skills/<name>/SKILL.md        # bundled copy
  .agents/plugins/marketplace.json    # Codex marketplace catalog -> ./codex

Usage:
  python3 scripts/gen-skills.py            # regenerate
  python3 scripts/gen-skills.py --check    # verify in sync (exit 1 on drift)

Source of truth for portable bodies is plugin/ (already stack-agnostic); the
parameterized core/ is the Claude template. Requires Python 3.x only.
"""
import json, os, shutil, sys, tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGIN = os.path.join(REPO, "plugin")

# capability -> (source file under repo, optional override name/description)
PASSTHROUGH = {  # already SKILL.md with good frontmatter — copy verbatim
    "principles": "plugin/skills/principles/SKILL.md",
    "sdd-workflow": "plugin/skills/sdd-workflow/SKILL.md",
    "backend-style": "plugin/skills/backend-style/SKILL.md",
    "frontend-style": "plugin/skills/frontend-style/SKILL.md",
}
WRAP = {  # command markdown (no frontmatter) -> wrap as a skill
    "spec": ("plugin/commands/spec.md",
             "Spec-driven: turn an idea, ticket, or SOW into a Given/When/Then contract and PR-sized mini-features before any code is written."),
    "fix": ("plugin/commands/fix.md",
            "Small, scoped change with an obvious cause — skip the spec and Design First, keep the full Definition of Done."),
    "verify": ("plugin/commands/verify.md",
               "Skeptical self-review of your own diff before review or commit — re-read the request, read every changed line, actually run it, fix and re-review."),
}
REFRAME = {  # agent markdown -> skill under a new name
    "security-audit": ("plugin/agents/security-reviewer.md",
                       "OWASP-grounded security review: secrets, access control, injection, auth/session, crypto, misconfiguration, SSRF, and vulnerable dependencies. Read-only, severity-ranked findings."),
}

# Portable always-on rules layer. Emitted as AGENTS.md (cross-tool: Codex,
# OpenCode, Cursor, …) and GEMINI.md (Antigravity/Gemini). One source, so the
# two never drift. Kept well under Antigravity's 12,000-char rule limit.
RULES_DOC = """# Agent operating rules

> Portable rules for any coding agent (Claude Code, Codex, OpenCode, Antigravity).
> This is the always-on baseline. The full capabilities — `spec`, `fix`, `verify`,
> `security-audit`, and the style guides — install as skills (see the README).

## Principles (non-negotiable)

1. **Think before coding.** State assumptions; if a request has multiple readings, ask before writing. Restate the goal and list 2–4 verifiable success criteria first.
2. **Simplicity first (YAGNI).** Write the minimum code that solves the stated problem. No speculative classes, options, or abstractions. Reach for a design pattern only when the problem genuinely matches one.
3. **Surgical changes.** Touch only what the task needs. No drive-by refactors or reformatting. Match the file's existing style.
4. **Goal-driven execution.** Define success criteria, implement, run them, fix gaps, repeat until they pass — then declare done.

## Spec-driven workflow (non-trivial features)

Prefer: idea → a conversed spec with a **Given/When/Then contract** you approve → implement **one PR-sized mini-feature at a time** → review (and, under TDD, write the failing tests first and approve them before code) → self-review → micro-commit. Use the `spec` then `feature` flow. For a small change with an obvious cause, use `fix` (skip the spec, keep the Definition of Done). Before declaring done, run `verify` — re-read the request, read the diff, and actually run it.

## Branch discipline

Never commit on a **protected branch** (e.g. `main`/`master`, or your environment branches). Start every change on a typed branch: `feature/…`, `fix/…`, `hotfix/…`, `refactor/…`, `chore/…`, `docs/…`.

## Definition of Done

Format → lint → tests green (coverage maintained) → code review → security review when the change touches auth, permissions, data, or external input → then done. Keep PRs small (≈ ≤12 files / <3000 lines); split if larger.

## Security baseline

Run the `security-audit` skill on anything touching auth, secrets, user data, or external input: no committed secrets, strong password hashing, parameterized queries, escaped output, security headers and cookie flags, rate limiting on sensitive endpoints, and no known-vulnerable dependencies.
"""


def ensure_name(text, name):
    """Codex/OpenCode SKILL.md require both name and description. Claude skills
    omit name (derived from dir), so inject it when missing."""
    lines = text.splitlines()
    if lines and lines[0].strip() == "---":
        try:
            close = lines.index("---", 1)
        except ValueError:
            close = None
        if close is not None:
            fm = lines[1:close]
            if not any(l.strip().startswith("name:") for l in fm):
                fm = [f"name: {name}"] + fm
            rebuilt = "\n".join(["---"] + fm + ["---"] + lines[close + 1:])
            return rebuilt + ("\n" if text.endswith("\n") else "")
    return f"---\nname: {name}\ndescription: {name}\n---\n\n" + text


def strip_frontmatter(text):
    if text.startswith("---"):
        nl = text.find("\n")
        end = text.find("\n---", nl)
        if end != -1:
            rest = text[end + 4:]
            return rest.lstrip("\n")
    return text


def build_skill_bodies():
    """Return {name: SKILL.md text}."""
    out = {}
    for name, rel in PASSTHROUGH.items():
        out[name] = ensure_name(open(os.path.join(REPO, rel), encoding="utf-8").read(), name)
    for name, (rel, desc) in WRAP.items():
        body = open(os.path.join(REPO, rel), encoding="utf-8").read()
        out[name] = f"---\nname: {name}\ndescription: {desc}\n---\n\n" + body
    for name, (rel, desc) in REFRAME.items():
        body = strip_frontmatter(open(os.path.join(REPO, rel), encoding="utf-8").read())
        out[name] = f"---\nname: {name}\ndescription: {desc}\n---\n\n" + body
    return out


def plugin_version():
    p = json.load(open(os.path.join(PLUGIN, ".claude-plugin", "plugin.json"), encoding="utf-8"))
    return p.get("version", "0.0.0")


def render(dest_root):
    """Write the full generated set under dest_root (the repo, or a temp dir for --check)."""
    skills = build_skill_bodies()
    version = plugin_version()

    skills_dir = os.path.join(dest_root, "skills")
    codex_dir = os.path.join(dest_root, "codex")
    shutil.rmtree(skills_dir, ignore_errors=True)
    shutil.rmtree(codex_dir, ignore_errors=True)

    for name, body in skills.items():
        d = os.path.join(skills_dir, name)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "SKILL.md"), "w", encoding="utf-8") as f:
            f.write(body)

    # Codex native plugin: bundle the same skills + manifest.
    # dirs_exist_ok keeps this idempotent even where rmtree is restricted.
    shutil.copytree(skills_dir, os.path.join(codex_dir, "skills"), dirs_exist_ok=True)
    os.makedirs(os.path.join(codex_dir, ".codex-plugin"), exist_ok=True)
    manifest = {
        "name": "agent-config-template",
        "version": version,
        "description": "Spec-driven agent config: principles, the SDD/TDD workflow, /spec /fix /verify, and an OWASP security audit — as portable skills.",
        "author": {"name": "Juan Trujillo", "url": "https://juantrujillo.dev"},
        "homepage": "https://github.com/JuanTrujilloDev/agent-config-template",
        "repository": "https://github.com/JuanTrujilloDev/agent-config-template",
        "license": "MIT",
        "keywords": ["sdd", "tdd", "code-review", "security", "workflow"],
        "skills": "./skills/",
        "interface": {
            "displayName": "Agent Config — SDD",
            "shortDescription": "Spec-driven workflow + reviews as skills",
            "category": "Productivity",
        },
    }
    with open(os.path.join(codex_dir, ".codex-plugin", "plugin.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")

    # Codex marketplace catalog (source.path relative to the marketplace root = repo root).
    mkt_dir = os.path.join(dest_root, ".agents", "plugins")
    os.makedirs(mkt_dir, exist_ok=True)
    marketplace = {
        "name": "juantrujillodev",
        "interface": {"displayName": "Juan Trujillo — Agent Config"},
        "plugins": [{
            "name": "agent-config-template",
            "source": {"source": "local", "path": "./codex"},
            "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
            "category": "Productivity",
        }],
    }
    with open(os.path.join(mkt_dir, "marketplace.json"), "w", encoding="utf-8") as f:
        json.dump(marketplace, f, indent=2)
        f.write("\n")

    # Portable rules layer: AGENTS.md (cross-tool) + GEMINI.md (Antigravity), one source.
    with open(os.path.join(dest_root, "AGENTS.md"), "w", encoding="utf-8") as f:
        f.write(RULES_DOC)
    with open(os.path.join(dest_root, "GEMINI.md"), "w", encoding="utf-8") as f:
        f.write(RULES_DOC)

    # Antigravity / Gemini CLI extension manifest (install via `gemini extensions install <repo-url>`).
    extension = {
        "name": "agent-config-template",
        "version": version,
        "description": "Spec-driven agent config — principles, the SDD/TDD workflow, and reviews as portable context + skills.",
        "contextFileName": "GEMINI.md",
    }
    with open(os.path.join(dest_root, "gemini-extension.json"), "w", encoding="utf-8") as f:
        json.dump(extension, f, indent=2)
        f.write("\n")

    return sorted(skills.keys())


def main():
    if "--check" in sys.argv:
        tmp = tempfile.mkdtemp(prefix="gen-skills-")
        try:
            render(tmp)
            drift = 0
            for rel in ("skills", "codex", os.path.join(".agents", "plugins", "marketplace.json"),
                        "AGENTS.md", "GEMINI.md", "gemini-extension.json"):
                a, b = os.path.join(REPO, rel), os.path.join(tmp, rel)
                cmd = os.path.exists(a) and os.path.exists(b)
                if not cmd:
                    print(f"DRIFT: missing {rel}"); drift = 1; continue
                # compare recursively via a simple walk
                import filecmp
                if os.path.isdir(a):
                    d = filecmp.dircmp(a, b)
                    if d.left_only or d.right_only or d.diff_files or _deep_diff(a, b):
                        print(f"DRIFT: {rel} differs"); drift = 1
                else:
                    if open(a, encoding="utf-8").read() != open(b, encoding="utf-8").read():
                        print(f"DRIFT: {rel} differs"); drift = 1
            if drift:
                print("Run scripts/gen-skills.py to regenerate.", file=sys.stderr); sys.exit(1)
            print("skills/ + codex/ + marketplace in sync ✓")
        finally:
            shutil.rmtree(tmp, ignore_errors=True)
    else:
        names = render(REPO)
        print(f"Generated {len(names)} skills: {', '.join(names)}")
        print("  -> skills/, codex/ (native plugin), .agents/plugins/marketplace.json")
        print("  -> AGENTS.md + GEMINI.md (rules), gemini-extension.json (Antigravity)")


def _deep_diff(a, b):
    import filecmp
    for root, _, files in os.walk(a):
        rel = os.path.relpath(root, a)
        for fn in files:
            fa = os.path.join(root, fn); fb = os.path.join(b, rel, fn)
            if not os.path.exists(fb) or not filecmp.cmp(fa, fb, shallow=False):
                return True
    return False


if __name__ == "__main__":
    main()
