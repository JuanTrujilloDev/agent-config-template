<div align="center">

<img src="docs/logo.svg" width="120" alt="claude-config-template logo" />

# claude-config-template

**The Claude Code config you wished you had — set up by Claude itself.**

<sub>Stop reconfiguring `.claude/` from scratch on every project. Clone the template once, tell Claude *"set this up"*, and a minute later your repo has a battle-tested `.claude/` tree calibrated to your stack.</sub>

[![Install Plugin](https://img.shields.io/badge/Install-Plugin-CC785C?logo=anthropic&logoColor=white&style=flat)](#-quick-start)
[![Use Template](https://img.shields.io/badge/Use-Template-2EA043?logo=githubactions&logoColor=white&style=flat)](#-quick-start)
[![Examples](https://img.shields.io/badge/Examples-4_stacks-8A2BE2?style=flat)](#-pre-filled-examples)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](#license)
[![GitHub Sponsors](https://img.shields.io/badge/♥-Sponsor-30363D?logo=github-sponsors&logoColor=EA4AAA&style=flat)](https://github.com/sponsors/JuanTrujilloDev)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Tip-FF5E5B?logo=ko-fi&logoColor=white&style=flat)](https://ko-fi.com/juantrujillodev)

</div>

---

## 🪄 Why this exists

Reconfiguring `.claude/` and `CLAUDE.md` from scratch every time wastes the patterns you've already debugged. This template extracts a **battle-tested config** (originally a Django/HTMX project where it had time to bake) and parameterizes the project-specific bits, so the same scaffold works on FastAPI, Next.js, Go services, or whatever you're shipping next.

It's not a generic project scaffolder — [cookiecutter](https://github.com/cookiecutter/cookiecutter) exists. It's specifically for the `.claude/` and `CLAUDE.md` layer: the agents, slash commands, hooks, and operating principles that turn Claude Code from "fancy autocomplete" into a senior teammate.

|                                  | Without this                                                | With this                                                |
| -------------------------------- | ----------------------------------------------------------- | -------------------------------------------------------- |
| **Setup time**                   | 30 min copy-pasting old configs, hand-editing paths         | 60 seconds; Claude infers from your project files        |
| **`.claude/` consistency**       | Different on every repo, none of them current               | Same battle-tested patterns everywhere                   |
| **Agent coverage**               | Maybe a `code-reviewer.md` you cargo-culted                 | 7 agents (pm, *-dev, ui-designer, code/security review)  |
| **Hooks**                        | None, or one `auto-format.sh` you forgot exists             | Branch discipline (hard), agent guidance (advisory), format-on-write |
| **Slash commands**               | Whatever you remember to type each time                     | `/feature`, `/plan`, `/commit`, `/pr`, `/audit`, etc.    |
| **PR discipline**                | Vibes-based                                                 | ≤12 files / <3000 LOC, enforced before commit            |
| **Updates**                      | Re-cargo-cult next project                                  | `setup.sh --target . --answers ./answers.env` re-renders |

---

## 🚀 Quick start

One install gets you everything. Optional second step calibrates a specific project to its exact stack.

### Install once

Inside Claude Code:

```
/plugin marketplace add JuanTrujilloDev/claude-config-template
/plugin install claude-config-template@juantrujillodev
```

You now have **7 agents** (`pm`, `*-dev`, `ui-designer`, `code-reviewer`, `security-reviewer`), **10 slash commands** (`/claude-config-template:feature`, `:fix`, `:plan`, `:pr`, `:audit`, `:setup-template`, etc.), **3 skills** (principles + style guides), and **3 hooks** (branch discipline, agent guidance, auto-format) available across every project where the plugin is enabled.

The hooks use generic defaults — `src/` for source dir, `main` for default branch. Override per-project via env vars in `.envrc` (direnv) or your shell rc:

```bash
export CLAUDE_CONFIG_SRC_DIR=apps                       # default: src
export CLAUDE_CONFIG_FRONTEND_DIR=apps/frontend         # default: (none)
export CLAUDE_CONFIG_PROTECTED_BRANCHES="main,qa,prod"  # default: main,master
```

### Calibrate a specific project (optional)

When you want a project to have a fully-tailored `.claude/` tree — agents and hooks with your *exact* test/lint/format commands, branch prefix, layer-split toggle, framework-specific style guides — run the bundled command from inside the project:

```
/claude-config-template:setup-template
```

Claude will:

1. Read `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / `manage.py` / etc.
2. Draft an `answers.env` with confidence labels (HIGH / LOW / UNKNOWN).
3. Show it to you and **wait for your approval or edits.**
4. Run the bundled renderer to write a calibrated `.claude/` tree + `CLAUDE.md`. It's **non-destructive** — if you already have a `.claude/` config (or a root `CLAUDE.md`), it shows a per-file change plan and won't write without your `--merge` / `--overwrite` choice.
5. Update `.gitignore` and remind you to restart Claude Code.

The whole flow takes about a minute on a conventional project. After it runs, both layers are active — the plugin commands stay namespaced (`/claude-config-template:feature`); the project-root commands are unnamespaced (`/feature`) and take precedence when they collide, because they have your project's specifics baked in.

### Old-school: clone + render manually

For maintainers, advanced users, or anyone who'd rather not depend on the plugin install:

```bash
git clone https://github.com/JuanTrujilloDev/claude-config-template.git ~/code/claude-config-template
cd ~/code/my-new-project
cp ~/code/claude-config-template/examples/python-fastapi/answers.env ./answers.env
~/code/claude-config-template/setup.sh --target . --answers ./answers.env
```

Same renderer, same template, no plugin required.

### Plugin only vs Plugin + calibration vs Manual clone

|                                | Plugin only           | Plugin + `/setup-template` | Manual clone           |
| ------------------------------ | --------------------- | -------------------------- | ---------------------- |
| **Install effort**             | One line              | One line + 1 min/project   | Clone + edit answers   |
| **Project specifics**          | Generic + env vars    | Baked in                   | Baked in               |
| **Style guides**               | Stack-agnostic        | Tailored                   | Tailored               |
| **Best for**                   | Many repos at once    | Flagship projects          | Forks, customization   |

---

## 📦 What you get

```
.claude/
├── HELP.md                   # Decision tree + worked examples for the team
├── settings.json             # Tightened permissions + hook registrations
├── mcp.json.example          # MCP server template (copy → mcp.json, fill in)
├── rules/
│   ├── principles.md         # 8 always-loaded operating principles
│   ├── backend-style.md      # Backend code conventions
│   └── frontend-style.md     # Frontend code conventions (skipped if API-only)
├── agents/
│   ├── pm.md                 # Decomposes features into PR-sized tickets
│   ├── po-manager.md         # Briefs / SOWs / PRDs
│   ├── backend-dev.md        # Backend implementation, Design First
│   ├── frontend-dev.md       # Frontend implementation, Design First
│   ├── ui-designer.md        # Wireframes + specs (delegated by frontend-dev)
│   ├── code-reviewer.md      # Pre-merge correctness review (read-only)
│   └── security-reviewer.md  # Auth/permissions/data audit (read-only)
├── commands/                 # /feature, /fix, /plan, /commit, /pr, /audit, /design, /idea, /sow
└── hooks/
    ├── agent-enforcement.sh  # Hard-blocks edits on protected branches; advises (no block) on large non-agent edits
    ├── auto-format.sh        # Targeted lint autofix on write; full format runs in the Definition of Done
    └── coding-reminder.sh    # Injects principles reminder on coding prompts
CLAUDE.md                     # Project root: principles, branch rules, agent map, dynamic context
```

Every agent ships with a **Gotchas** section calling out the specific failure modes for that role — `pm` against ticket inflation, `backend-dev` against speculative `*Service` classes, `code-reviewer` against confusing nits with blockers, etc.

---

## 🧩 What gets parameterized

[`template.config.yaml`](./template.config.yaml) defines every placeholder. Highlights:

| Variable                                                                   | Example                                                |
| -------------------------------------------------------------------------- | ------------------------------------------------------ |
| `project_name`                                                             | `Acme Billing`                                         |
| `language` / `language_version`                                            | `Python` / `3.12+`                                     |
| `backend_framework`                                                        | `FastAPI`                                              |
| `frontend_framework`                                                       | `Next.js 14` (or skip if API-only)                     |
| `src_dir`, `frontend_dir`, `tests_glob`                                    | `src/`, `frontend/`, `tests/`                          |
| `format_cmd`, `lint_cmd`, `test_cmd`, `build_cmd`                          | `ruff format .`, `ruff check .`, `pytest`, `npm run dev` |
| `branch_prefix`, `default_branch`                                          | `ACME`, `main`                                         |
| `max_files_per_pr`, `max_loc_per_pr`                                       | `12`, `3000`                                           |
| `has_frontend`, `has_celery`, `has_e2e`, `enforce_layer_split` *(toggles)* | `yes` / `no`                                           |

The toggles drive **conditional sections** — `{{#has_celery}}…{{/has_celery}}` — so you don't end up with Celery boilerplate in a project that doesn't use it, or a `frontend-dev` agent in an API-only repo. File-level conditionals via `<!-- requires: has_frontend -->` drop whole files when the flag is falsy.

---

## 🎨 Pre-filled examples

| Stack                                       | Best for                                          | Layer split |
| ------------------------------------------- | ------------------------------------------------- | ----------- |
| [`python-fastapi`](./examples/python-fastapi) | API service, no frontend                          | n/a         |
| [`python-django`](./examples/python-django)   | Django + DRF + HTMX/Alpine (closest to the original) | yes      |
| [`node-express`](./examples/node-express)     | Express + TypeScript + Prisma                     | n/a         |
| [`node-nextjs`](./examples/node-nextjs)       | Next.js 14 (App Router) full-stack                | no          |

These are the answers Claude would arrive at for a vanilla version of each stack. Use them as starting points when the AI flow isn't an option.

---

## 🔧 How it works

1. **Placeholders** use mustache syntax: `{{var}}` for direct substitution, `{{#var}}…{{/var}}` for "include if truthy", `{{^var}}…{{/var}}` for "include if falsy".
2. **File-level conditionals** use a directive at the top of a template file: `<!-- requires: has_frontend -->`. The renderer drops the file if the var is falsy.
3. **The renderer** is inline Python inside `setup.sh` — about 50 lines. No Jinja/Mustache library dependency, no surprise behavior. Standalone-tag whitespace cleanup keeps conditionals from leaving blank-line forests.

That's the whole engine. You can read it in five minutes and modify it without learning a new DSL.

---

## ♻️ Upgrading an already-configured project

Keep your `answers.env` checked into the project. Re-render after pulling template updates and `git diff` to see what changed:

```bash
cd ~/code/my-project
TMP=$(mktemp -d)
~/code/claude-config-template/setup.sh --target "$TMP" --answers ./answers.env
diff -r .claude "$TMP/.claude"
# Apply selectively, or replace .claude entirely if you don't have local mods.
```

Full guide: [`docs/upgrade-guide.md`](./docs/upgrade-guide.md).

---

## 🚫 Out of scope

- **Not a generic project scaffolder.** [cookiecutter](https://github.com/cookiecutter/cookiecutter) exists.
- **Not a Claude Code plugin marketplace.** See [Claude Code plugins docs](https://docs.claude.com/en/docs/claude-code/plugins).
- **Doesn't replace Claude Code's built-in `/init`.** It complements it — run `/init` after rendering if you want Claude to scan your codebase and add project-specific notes to `CLAUDE.md`.

---

## 📚 Reference

- [`docs/what-each-file-does.md`](./docs/what-each-file-does.md) — per-file explainer
- [`docs/upgrade-guide.md`](./docs/upgrade-guide.md) — pulling template updates into existing projects
- [`template.config.yaml`](./template.config.yaml) — full placeholder schema
- [`ai_setup_prompt.md`](./ai_setup_prompt.md) — verbatim setup prompt, for users who want to script it

---

## 🙏 Credits & inspiration

The four core principles — *Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution* — come from [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills), distilled from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls. If you only want the principles and not the agents/hooks/commands scaffold, that single-file `CLAUDE.md` is a great starting point.

Several patterns — embedded "Gotchas" sections in agents, tighter permission wildcards, dynamic context injection via `` !`command` `` — were adapted from [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice).

The agent / hook / micro-PR architecture was lifted from a working Django/HTMX project where it had time to bake.

---

## ☕ Support

If this saved you time, you can support continued work on it:

[![GitHub Sponsors](https://img.shields.io/badge/♥-Sponsor-30363D?logo=github-sponsors&logoColor=EA4AAA&style=for-the-badge)](https://github.com/sponsors/JuanTrujilloDev)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Tip-FF5E5B?logo=ko-fi&logoColor=white&style=for-the-badge)](https://ko-fi.com/juantrujillodev)

Sponsorship buys me time. Time becomes side-project hours. Side-project hours become open-source releases — like a from-scratch async Python web framework I'm currently shipping (third attempt, this is the one), [`notihub`](https://pypi.org/project/notihub/) on PyPI, and whatever the next "I keep rebuilding this on every project" tool turns out to be.

---

## License

MIT. Use it, fork it, ship it. A star on the repo is appreciated but not required.

<div align="center">
<sub>Made with ☕ + lo-fi in Colombia by <a href="https://juantrujillo.dev">Juan Trujillo</a> · <a href="https://github.com/JuanTrujilloDev">@JuanTrujilloDev</a></sub>
</div>
