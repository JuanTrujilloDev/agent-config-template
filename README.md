<div align="center">

<img src="docs/logo.png" width="160" alt="agent-config-template logo" />

# agent-config-template

**A concise, spec-driven coding-agent workflow for Claude Code, Cursor, Grok, and Codex—adapted to your stack instead of copied by hand.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](#license)
[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-GitHub-EA4AAA)](https://github.com/sponsors/JuanTrujilloDev)

</div>

It turns a task into an approved contract, PR-sized implementation slices, skeptical review, checks, and small commits. Project state lives on disk, so the workflow survives restarts across web, backend, mobile, Unity, desktop, CLI, and data projects.

## v0.10.0

- Opt-in model behavior evaluations for Claude, Codex, Cursor, and Grok.
- UI projects get semantic `tokens.json`; `/design` emits one stack-native theme plus a `tokens.lock.json` hash record.
- `/setup-companions plan|doctor|install|update|uninstall [list]` uses one pinned lock; every network or removal action remains confirmed.
- Cursor tokenizes commit/push commands instead of blocking quoted mentions.

Upgrade path: `0.9.2 → 0.10.0` via the existing preview + merge flow.

## Install

### Claude Code

```text
/plugin marketplace add JuanTrujilloDev/agent-config-template
/plugin install agent-config-template@juantrujillodev
/agent-config-template:setup-template
```

[Claude install details](docs/install/claude.md)

### Cursor

```text
Cursor → Customize → Plugins → search "Agent Config Template" → Install
/setup-template
```

[Cursor install details](docs/install/cursor.md)

### Grok in Cursor

```text
Install the same Cursor plugin, select a Grok model, then run:
/setup-template
```

[Standalone Grok Build details](docs/install/grok.md)

### Codex

```bash
codex plugin marketplace add JuanTrujilloDev/agent-config-template
codex plugin add agent-config-template@juantrujillodev
```

[Codex install details](docs/install/codex.md) ·
[host capability matrix](docs/install/host-capability-matrix.md)

Start with:

```text
/spec add CSV export to the holdings list
/feature add CSV export to the holdings list
```

`/spec` converses and writes the contract, then stops for approval. `/feature`
implements one ready mini-feature at a time. Use `/fix` for a small change with
an obvious cause.

## Workflow

<!-- workflow-diagram -->

```text
task
  └─ pmo: spec + contract + mini-features
       └─ GATE 1: approve contract
            └─ tests first when TDD is active
                 └─ implement → verify → judge → security when relevant
                      └─ optional manual check → micro-commit → next slice
```

The v0.9 contract grammar is explicit:

- `spec.md` separates numbered `FR-###` requirements from measurable `SC-###`
  success criteria; every Given/When/Then scenario traces to both.
- `NEEDS CLARIFICATION: <question>` blocks Gate 1 until resolved.
- `features.json` declares `schema_version: 2`, dependencies, limits, status,
  and human verification for every mini-feature.
- Post-approval changes append `*(Amended at <ISO date/time> — <reason>)*`,
  reset affected work, and require a newer Gate 1 approval.
- PMO and judge check the same `Principles deviation table` before planning and
  before approval.
- `/verify` pins one base SHA and refuses empty review scopes.
- Judge separates `Spec fidelity` from `Standards & health`; preferences do not
  become blockers.
- Review gets at most two fix/re-review cycles before a human resolves the
  recorded disagreement.
- TDD names public seams, derives expectations independently, mocks only
  external boundaries, and completes one vertical red/green slice at a time.

Full rules: [SDD workflow](docs/sdd-workflow.md).

## Commands

<!-- command-table -->

| Command | Purpose |
|---|---|
| `/spec` | Converse → spec → traced contract → mini-features |
| `/feature` | Run the approved SDD/TDD flow one slice at a time |
| `/fix` | Fast path for a small change with an obvious cause |
| `/verify` | Re-read the request, diff, and checks skeptically |
| `/audit` | Adversarial code-quality and security review |
| `/design` | UI wireframe and component contract before code |
| `/integrate <tool>` | Research and connect the user's chosen MCP/tool |
| `/setup-companions <action> [list]` | Plan, inspect, install, update, or remove optional helpers |
| `/commit`, `/pr` | Commit or open a PR behind confirmation gates |

## What gets installed

- Stack-matched dev agents plus `pmo`, `orchestrator`, `judge`, and security review.
- Always-loaded principles, backend/frontend style rules, and the restrained `patterns` guide.
- Branch protection, targeted formatting hooks, and host-native skills.
- `docs/design-system/MASTER.md` plus machine-readable `tokens.json` for UI brand colors, typography, spacing, radius, motion, and accessibility.
- `docs/CONTEXT.md`, created lazily when the project needs a shared glossary.
- Versioned specs and progress under `docs/specs/<slug>/`.

See [what each file does](docs/what-each-file-does.md).

## Adapt it to a project

Run `/setup-template` from Cursor, or `/agent-config-template:setup-template` in Claude Code. It infers the project, asks one decision round, previews conflicts, and renders the selected hosts.

For CI or offline rendering, use the repository CLI with `answers.env`:

```bash
./setup.sh --target . --answers ./answers.env --host cursor
./setup.sh --target . --answers ./answers.env --host cursor --merge
```

The preview is read-only. `--merge` keeps custom files and union-merges settings; `--overwrite-files <paths>` replaces only selected stale managed files. The template supports `SDD` or `SDD+TDD`, project type, language/framework, commands, directories, branch policy, PR limits, Gherkin, layer split, mutation testing, background jobs, and UI toggles.

Successful renders maintain `agent-config.lock.json` with exact managed-file baselines. Preview distinguishes `STALE-MANAGED`, `CUSTOMIZED-MANAGED`, or `LEGACY`, plus retired `OBSOLETE` or `CUSTOMIZED-OBSOLETE` files. After review, `--merge --prune` deletes only unchanged `OBSOLETE` files; user edits stay. Fully quoted `answers.env` values are accepted, host names are case-insensitive, and an existing `.claude/answers.local.env` is automatically added to `.gitignore` after a successful write.

For a configured codebase, use the short
[existing-project guide](docs/guides/existing-projects.md). For every setting,
see [template.config.yaml](template.config.yaml).

## Personal output preferences

Keep shared policy in committed `answers.env`. Keep personal choices in
gitignored `.claude/answers.local.env`:

```dotenv
autonomy_mode=gated
output_style=concise
agent_style=terse
companions=not_now
```

`output_style` controls human-facing detail; `agent_style` keeps internal agent
reports compact. At task start, choose autonomous execution or review gates.
Push, merge, publish, and destructive actions still require explicit approval.

## Optional companions

Run `/setup-companions plan|doctor|install|update|uninstall [list]` after setup. `graphify` adds graph-first code queries; `ponytail` enforces the smallest useful solution; `ui-ux-pro-max` is offered only when `has_ui` is enabled. Use `companions=yes|not_now|never|<comma list>`, for example `companions=graphify,ponytail`. Pins and the verified Cursor download digest live in `plugin/companions.lock.json`; mutations are shown and confirmed first.

Trackers and external MCP tools are also opt-in. `/integrate <tool>` asks what
you already use, researches the official integration, and shows the exact plan.

## Model behavior checks

These commands are inert unless `--run` is present:

```bash
python3 scripts/evals/run.py validate
python3 scripts/evals/run.py run --host cursor --case pattern-restraint
python3 scripts/evals/run.py run --host cursor --case pattern-restraint --run
```

The `/spec` → `/feature` workspace case additionally needs `--allow-writes` and
runs in a disposable rendered project. See [evaluation details](scripts/evals/README.md).

## Examples

- [FastAPI](examples/python-fastapi)
- [Django](examples/python-django)
- [Express](examples/node-express)
- [Next.js](examples/node-nextjs)
- [Flutter](examples/flutter-mobile)
- [Unity](examples/unity-game)

## Upgrade

Keep `answers.env`, pull the desired release, preview, then use `--merge`.
Never mix a template upgrade into a feature commit. See the
[upgrade guide](docs/upgrade-guide.md).

## Reference

- [SDD workflow](docs/sdd-workflow.md)
- [Existing projects](docs/guides/existing-projects.md)
- [Host installs](docs/install/)
- [File map](docs/what-each-file-does.md)
- [Plugin package notes](plugin/README.md)

## Credits & inspiration

The operating principles build on [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills), with a leverage ladder adapted from [ponytail](https://github.com/dietrichgebert/ponytail), graph-first querying designed around [Graphify](https://github.com/Graphify-Labs/graphify), and pattern restraint inspired by [code-design-patterns](https://github.com/00suryavanshi00/code-design-patterns).

[GitHub Spec Kit](https://github.com/github/spec-kit) is MIT-licensed inspiration for separating specification, planning, tasks, and convergence. No artifacts were copied; this project is not affiliated with or endorsed by GitHub.

[Matt Pocock's MIT-licensed skills](https://github.com/mattpocock/skills) inspired the fixed-point review and TDD seam/expectation rules. All wording and artifacts here are original to this project; this project is not affiliated with Matt Pocock.

## Support

[GitHub Sponsors](https://github.com/sponsors/JuanTrujilloDev) ·
[Ko-fi](https://ko-fi.com/juantrujillodev)

## License

MIT. Use it, fork it, ship it.

Made in Colombia by [Juan Trujillo](https://juantrujillo.dev).
