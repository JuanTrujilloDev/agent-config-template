<div align="center">

<img src="docs/logo.svg" width="120" alt="agent-config-template logo" />

# agent-config-template

**Spec-driven agent config for Claude Code, Codex, OpenCode & Antigravity. One repo, install on any of them.**

<sub>Stop reconfiguring your agent setup from scratch on every project *and* every tool. Install once on your agent of choice and get a battle-tested workflow: an approved Given/When/Then contract before code, one mini-feature at a time, reviewed and verified.</sub>

[![Install Plugin](https://img.shields.io/badge/Install-Plugin-CC785C?logo=anthropic&logoColor=white&style=flat)](#-install)
[![Use Template](https://img.shields.io/badge/Use-Template-2EA043?logo=githubactions&logoColor=white&style=flat)](#-install)
[![Examples](https://img.shields.io/badge/Examples-4_stacks-8A2BE2?style=flat)](#-pre-filled-examples)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](#license)
[![GitHub Sponsors](https://img.shields.io/badge/♥-Sponsor-30363D?logo=github-sponsors&logoColor=EA4AAA&style=flat)](https://github.com/sponsors/JuanTrujilloDev)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Tip-FF5E5B?logo=ko-fi&logoColor=white&style=flat)](https://ko-fi.com/juantrujillodev)

</div>

---

## 🪄 Why this exists

Reconfiguring `.claude/` and `CLAUDE.md` from scratch every time wastes the patterns you've already debugged. This template packages the `.claude/` layer (the agents, slash commands, hooks, skills, and operating principles) that turns Claude Code from "fancy autocomplete" into a senior teammate who **specs the work before writing it**.

It's not a generic project scaffolder ([cookiecutter](https://github.com/cookiecutter/cookiecutter) exists). It's specifically the workflow layer, built around **Spec-Driven Development**: a task becomes a conversed spec, a signed Given/When/Then contract, then code, one PR-sized mini-feature at a time, reviewed by a `judge`, optionally test-first.

|                            | Without this                                        | With this                                                      |
| -------------------------- | --------------------------------------------------- | -------------------------------------------------------------- |
| **Setup time**             | 30 min copy-pasting old configs                     | One-line install; `/setup-template` calibrates in ~a minute    |
| **Feature workflow**       | Vibes → code → hope                                 | Spec → **approve contract** → implement → judge → micro-commit |
| **Agent coverage**         | Maybe a `code-reviewer.md` you cargo-culted         | `orchestrator`, `pmo`, dev specialists, `judge`, security      |
| **Hooks**                  | None, or one you forgot exists                      | Branch hard-block plus **advisory** agent guidance and format-on-write |
| **PR discipline**          | Vibes-based                                         | ≤12 files / <3000 LOC, one mini-feature at a time              |
| **Existing config**        | A setup script that **overwrites** it               | **Non-destructive**: shows a diff, merges, never clobbers      |

---

## 🚀 Install

One repo, four hosts. Pick yours (each badge links to its full guide):

| Host | Install | What you get |
|---|---|---|
| <a href="docs/install/claude.md"><img alt="Claude Code" src="https://img.shields.io/badge/Claude_Code-D97757?logo=anthropic&logoColor=white&style=for-the-badge" height="34"></a> | `/plugin marketplace add JuanTrujilloDev/agent-config-template` then `/plugin install agent-config-template@juantrujillodev` | Everything: agents, slash commands, skills, **hooks**, live sub-agent orchestration |
| <a href="docs/install/codex.md"><img alt="Codex" src="https://img.shields.io/badge/Codex-000000?logo=openai&logoColor=white&style=for-the-badge" height="34"></a> | add this repo as a marketplace and install from Codex's plugin directory, or `npx skills add JuanTrujilloDev/agent-config-template` | Rules + skills (`spec`, `feature`, `fix`, `verify`, `security-audit`, styles) + bundled MCP config |
| <a href="docs/install/opencode.md"><img alt="OpenCode" src="https://img.shields.io/badge/OpenCode-FF4A00?style=for-the-badge" height="34"></a> | `npx skills add JuanTrujilloDev/agent-config-template` | Rules + skills |
| <a href="docs/install/antigravity.md"><img alt="Antigravity / Gemini" src="https://img.shields.io/badge/Antigravity-4285F4?logo=googlegemini&logoColor=white&style=for-the-badge" height="34"></a> | `gemini extensions install https://github.com/JuanTrujilloDev/agent-config-template` | Rules (context) + native `/spec` `/feature` `/fix` `/verify` `/audit` commands + skills |

> **Where the experience differs (honestly):** Claude Code gets the richest version. The enforcement hooks (protected-branch block, format-on-write) and live multi-agent orchestration run there. On Codex, OpenCode, and Antigravity you get the same **principles, spec-driven workflow, and skills** through `AGENTS.md` and `SKILL.md`; hook *enforcement* is guidance there today (per-host enforcement is on the roadmap).

### Run a feature, spec-first

```
/spec     add CSV export to the holdings list
/feature  add CSV export to the holdings list
```

`/spec` writes the spec, a Given/When/Then **contract**, and PR-sized mini-features, then **stops for your approval**. `/feature` implements one mini-feature at a time (optionally test-first), reviews with `judge`, and micro-commits. Small scoped change with an obvious cause? `/fix`. Before you call anything done: `/verify`.

### Calibrate a project to its stack (Claude Code)

```
/agent-config-template:setup-template
```

Reads your `package.json` / `pyproject.toml` / `go.mod` / `manage.py` / etc., drafts an `answers.env`, waits for approval, then renders a calibrated `.claude/` tree + `CLAUDE.md`. **Non-destructive**: against an existing config it shows a per-file plan and won't write without your `--merge` / `--overwrite` choice, and `.claude/settings.local.json` is never touched. Old-school clone path: `setup.sh --target . --answers ./answers.env [--merge]`.

---

## 🔄 The workflow (SDD + TDD)

```
task in  →  [pmo] spec + Given/When/Then contract + mini-features
         →  ⏸ GATE 1: you approve the contract
         →  [orchestrator] per mini-feature, one at a time:
              ⏸ GATE 2 (only if TDD): approve the failing tests first
              →  [backend-dev | frontend-dev | ui-designer] implement to green
              →  [judge] review code AND tests vs the contract
              →  [security-reviewer] if auth/permissions/data
              →  [mutation-tester] if mutation testing is enabled
              →  micro-commit on a typed branch
         →  done
```

One mini-feature at a time. One mandatory gate (the contract), one optional gate (the tests). **State lives on disk**, not in chat: `docs/specs/<slug>/` holds the spec, contract, `features.json` state machine, and per-feature progress, so it survives restarts. Full detail in **[`docs/sdd-workflow.md`](./docs/sdd-workflow.md)**.

`/fix` is the escape hatch: small scoped change, no spec or contract, but the full Definition of Done still runs.

---

## 📦 What you get

```
.claude/
├── HELP.md                   # Decision tree + worked examples
├── settings.json             # Tightened permissions + hook registrations
├── mcp.json.example          # MCP server template
├── rules/
│   ├── principles.md         # Operating principles (always-loaded)
│   ├── backend-style.md      # Backend conventions
│   └── frontend-style.md     # Frontend conventions (skipped if API-only)
├── agents/
│   ├── orchestrator.md       # Runs the SDD flow, guards the gates (never codes)
│   ├── pmo.md                # Conversed spec + contract + mini-features
│   ├── backend-dev.md        # Backend implementation (Design notes, test-first)
│   ├── frontend-dev.md       # Frontend implementation
│   ├── ui-designer.md        # Wireframes + specs (read-only)
│   ├── judge.md              # Reviews code + tests vs the contract (read-only)
│   ├── security-reviewer.md  # Auth/permissions/data audit (read-only)
│   └── mutation-tester.md    # Validates the tests bite (opt-in)
├── commands/                 # /spec, /feature, /fix, /commit, /pr, /audit, /design
└── hooks/
    ├── agent-enforcement.sh  # Hard-blocks protected branches; advises (no block) on large non-agent edits
    ├── auto-format.sh        # Targeted lint autofix on write; full format runs in the Definition of Done
    └── coding-reminder.sh    # Injects principles on coding prompts
CLAUDE.md                     # Principles, branch rules, agent map, dynamic context
docs/sdd-workflow.md          # The spec-driven flow end-to-end
tools/mutate.py               # No-dep mutation tester (only when mutation testing is on)
```

### Agents

| Agent | Role | Read-only? |
|---|---|---|
| `orchestrator` | Coordinates the SDD flow, guards the gates, launches specialists | Yes |
| `pmo` | Conversed spec → Given/When/Then contract → PR-sized mini-features | No |
| `backend-dev` / `frontend-dev` | Implementation, Design notes, optional test-first | No |
| `ui-designer` | Wireframes + specs (delegated by `frontend-dev`) | Yes |
| `judge` | Pre-merge review of code **and** tests against the contract | Yes |
| `security-reviewer` | Auth/permissions/data audit | Yes |
| `mutation-tester` | Validates the tests bite (opt-in via `enforce_mutation_testing`) | Yes |

Every agent ships with a **Gotchas** section listing its role-specific failure modes.

### Commands

| Command | What it does |
|---|---|
| `/spec` | Idea/SOW → conversed spec + Given/When/Then contract + mini-features (`pmo`) |
| `/feature` | Full spec-driven flow (`orchestrator`): approve contract → optional TDD → implement → `judge` → micro-commit |
| `/fix` | Small, scoped change: skips the spec + Design First, keeps the full Definition of Done |
| `/audit` | Code + security review (`judge` + `security-reviewer`) |
| `/commit`, `/pr` | Conventional commit / open PR, with confirmation gates |
| `/design` | Wireframe + spec via `ui-designer` (folds into `/feature` for UI work) |
| `/setup-template` | Render a calibrated `.claude/` tree into the current project (non-destructive) |


---

## 🧩 What gets parameterized

[`template.config.yaml`](./template.config.yaml) defines every placeholder. Highlights:

| Variable | Example |
| --- | --- |
| `project_name` / `language` / `backend_framework` | `Acme Billing` / `Python` / `FastAPI` |
| `src_dir`, `frontend_dir`, `tests_glob` | `src/`, `frontend/`, `tests/` |
| `format_cmd`, `lint_cmd`, `test_cmd`, `build_cmd` | `ruff format .`, `ruff check .`, `pytest`, `npm run dev` |
| `branch_prefix`, `default_branch` | `ACME`, `main` |
| `max_files_per_pr`, `max_loc_per_pr` | `12`, `3000` |
| `has_frontend`, `has_celery`, `has_e2e`, `enforce_layer_split` *(toggles)* | `yes` / `no` |
| `use_gherkin` *(toggle)* | write contracts as real `.feature` files (needs a runner) |
| `enforce_mutation_testing` *(toggle)* | add a mutation-testing close gate (ships `tools/mutate.py`) |

Toggles drive **conditional sections** (`{{#has_celery}}…{{/has_celery}}`) and file-level conditionals (`<!-- requires: enforce_mutation_testing -->` drops whole files when falsy).

---

## 🎨 Pre-filled examples

| Stack | Best for | Layer split |
| --- | --- | --- |
| [`python-fastapi`](./examples/python-fastapi) | API service, no frontend | n/a |
| [`python-django`](./examples/python-django) | Django + DRF + HTMX/Alpine | yes |
| [`node-express`](./examples/node-express) | Express + TypeScript + Prisma | n/a |
| [`node-nextjs`](./examples/node-nextjs) | Next.js 14 (App Router) full-stack | no |

---

## 🔧 How it works

1. **Placeholders** use mustache syntax: `{{var}}`, `{{#var}}…{{/var}}` (include if truthy), `{{^var}}…{{/var}}` (include if falsy).
2. **File-level conditionals** via `<!-- requires: var -->` at the top of a template file drop the file when the var is falsy.
3. **The renderer** is inline Python inside `setup.sh`, with no Jinja/Mustache dependency. It renders to a staging dir, then applies to the target **non-destructively**: against an existing config it requires an explicit `--merge` / `--overwrite` / `--abort`, union-merges `settings.json`, and never touches `settings.local.json`.

The plugin's bundled template copy is generated from the canonical source (`core/`) by [`scripts/build.sh`](./scripts/build.sh); CI fails on drift.

---

## ♻️ Upgrading an already-configured project

Keep your `answers.env` checked in. After pulling template updates, re-render with `--merge` to add what's new without clobbering your customizations, or render to a temp dir and `diff`. Full guide: [`docs/upgrade-guide.md`](./docs/upgrade-guide.md).

---

## 🚫 Out of scope

- **Not a generic project scaffolder.** [cookiecutter](https://github.com/cookiecutter/cookiecutter) exists.
- **Not a Claude Code plugin marketplace.** See [Claude Code plugins docs](https://docs.claude.com/en/docs/claude-code/plugins).
- **Doesn't replace `/init`.** It complements it: run `/init` after rendering to add codebase-specific notes to `CLAUDE.md`.

---

## 📚 Reference

- [`docs/sdd-workflow.md`](./docs/sdd-workflow.md): the spec-driven flow end-to-end
- [`docs/what-each-file-does.md`](./docs/what-each-file-does.md): per-file explainer
- [`docs/upgrade-guide.md`](./docs/upgrade-guide.md): pulling template updates into existing projects
- [`template.config.yaml`](./template.config.yaml): full placeholder schema

---

## 🙏 Credits & inspiration

The core principles (*Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution*) come from [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills), distilled from Andrej Karpathy's observations on LLM coding pitfalls.

The spec-driven, test-first spine (conversation, then an executable contract, then TDD, judgment, and mutation testing) is inspired by Robert C. Martin's ("Uncle Bob") approach to agentic coding.

Several patterns (embedded "Gotchas" in agents, tighter permission wildcards, dynamic context injection) were adapted from [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice).

---

## ☕ Support

If this saved you time, you can support continued work on it:

[![GitHub Sponsors](https://img.shields.io/badge/♥-Sponsor-30363D?logo=github-sponsors&logoColor=EA4AAA&style=for-the-badge)](https://github.com/sponsors/JuanTrujilloDev)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Tip-FF5E5B?logo=ko-fi&logoColor=white&style=for-the-badge)](https://ko-fi.com/juantrujillodev)

---

## License

MIT. Use it, fork it, ship it. A star on the repo is appreciated but not required.

<div align="center">
<sub>Made with ☕ + lo-fi in Colombia by <a href="https://juantrujillo.dev">Juan Trujillo</a> · <a href="https://github.com/JuanTrujilloDev">@JuanTrujilloDev</a></sub>
</div>
