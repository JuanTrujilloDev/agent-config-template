<div align="center">

<img src="docs/logo.png" width="160" alt="agent-config-template logo" />

# agent-config-template

**A concise epic → story → slice coding-agent workflow for Claude Code, Cursor, Grok, and Codex—tests first, adapted to your stack instead of copied by hand.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](#license)
[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-GitHub-EA4AAA)](https://github.com/sponsors/JuanTrujilloDev)

</div>

It turns a ticket or an ask into one approved epic of one-case stories, then ships it one layered slice at a time: tests first and locked, code to green, two-axis review, one small PR. Epics and slices live on disk (or on your tracker), so the workflow survives restarts across web, backend, mobile, Unity, desktop, CLI, and data projects.

## Unreleased

- `orchestrator-init`: `bin/state.py` accepts the `tests` run kind, validates `tracker.state` and reads `plane.<x>` as `tracker.<x>`; `validate-packaging.py` fails if those drift. The skeleton gains `plans/launch-standing-orders.md` and the fresh-thread, owner-round and epic → story → slice rules.

## v0.11.1 — fixes

Patch release from the v0.11.0 review: slice reports no longer fail `validate-epics.py`, `--merge --prune` drops the stale v0.10 prompt hook from `settings.json`, `code-review` treats the slice's `## Approved tests` as append-only, `migrate.py` reads the older `@sN` grammar, and the test lock resolves symlinks and case. See the [upgrade guide](docs/upgrade-guide.md).

## v0.11.0 — breaking

- `/spec` and `/feature` are gone: `/epic` → `/slice` → `tests-first` → `implement` → `code-review` → `/pr`, all in your thread.
- Nine agents are gone (`pmo`, `orchestrator`, `judge` and the six dev agents); `security-reviewer` and `ui-designer` stay.
- Approved tests are locked by a hook and by `code-review`.
- The always-loaded text drops from about 9.5k to about 3k tokens: one ≤80-line principles file, everything else is a skill loaded on demand.
- `update-config` upgrades a rendered project and migrates old `docs/specs/` folders to `docs/epics/`.

Upgrade path: `0.10.0 → 0.11.1` via `update-config`; see the [upgrade guide](docs/upgrade-guide.md).

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
/epic add CSV export to the holdings list
/slice EXPORT 1
```

`/epic` drafts the whole epic once and stops for your approval; `/slice` briefs
one layer of one capability group. Use `/fix` for a small change with an obvious
cause.

## Workflow

<!-- workflow-diagram -->

```text
ticket or ask
  └─ /epic: capability groups, one-case stories, AC, Given/When/Then TS, layered slices
       └─ you approve by number (tracker cards, or docs/epics/<ID>/ with source=local)
            └─ /slice <ID> <n>: one layer (db → be → fe) of one group → you say yes
                 └─ tests-first: all the slice's tests, red → you approve → locked
                      └─ implement → code-review (Standards + Spec, one fix round)
                           └─ /pr, stacked on the previous layer's branch → next slice
```

- One case per story: one When per test scenario, literal values; `TSn` tests `Sn`, tests are named `test_S<n>_<case>`.
- Approved tests are listed under `## Approved tests` in the slice file; a hook blocks edits to them and `code-review` fails on any diff to them.
- One slice per PR, one layer per slice, 200–400 non-test lines.
- `validate-epics.py` checks the grammar and warns on size; CI runs it here.
- `council` is an opt-in, single-round review by three providers.

Full rules: [epic → story → slice](docs/epic-story-slice.md).

## Commands

<!-- command-table -->

| Command | Purpose |
|---|---|
| `/epic <ID or ask>` | Draft the epic once; `/epic render <ID>` writes the repo copy from tracker cards |
| `/slice <ID> <n>` | Brief the next slice: stories, seams, fixtures, tests |
| `tests-first`, `implement`, `code-review` | Tests red and locked, code to green, two-axis review |
| `/fix` | Fast path for a small change with an obvious cause |
| `/verify` | Re-read the request, diff, and checks skeptically |
| `/audit` | Adversarial code-quality and security review |
| `/design` | UI wireframe and component contract before code |
| `/integrate <tool>` | Research and connect the user's chosen MCP/tool |
| `/setup-companions <action> [list]` | Plan, inspect, install, update, or remove optional helpers |
| `update-config` | Upgrade a rendered project; migrate old `docs/specs/` |
| `/commit`, `/pr` | Commit or open a PR behind confirmation gates |

## What gets installed

- `security-reviewer`, plus `ui-designer` for UI projects; no coordinator or dev subagents.
- One always-loaded principles file; the slice-loop skills, backend/frontend style skills, `code-query` and the restrained `patterns` guide load on demand.
- Branch protection, the approved-tests lock, targeted formatting hooks, and host-native skills.
- `docs/design-system/MASTER.md` plus machine-readable `tokens.json` for UI brand colors, typography, spacing, radius, motion, and accessibility.
- `docs/CONTEXT.md`, created lazily when the project needs a shared glossary.
- Epics and slices under `docs/epics/<ID>/`.

See [what each file does](docs/what-each-file-does.md).

## Adapt it to a project

Run `/setup-template` from Cursor, or `/agent-config-template:setup-template` in Claude Code. It infers the project, asks one decision round, previews conflicts, and renders the selected hosts.

For CI or offline rendering, use the repository CLI with `answers.env`:

```bash
./setup.sh --target . --answers ./answers.env --host cursor
./setup.sh --target . --answers ./answers.env --host cursor --merge
```

The preview is read-only. `--merge` keeps custom files and union-merges settings; `--overwrite-files <paths>` replaces only selected stale managed files. The template supports project type, language/framework, commands, directories, branch policy, ticket tracker, PR limits, mutation testing, background jobs, and UI toggles.

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
companions=not_now
```

`output_style` controls human-facing detail. At task start, choose autonomous execution or review gates.
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

The `/epic` → `implement` workspace case additionally needs `--allow-writes` and
runs in a disposable rendered project. See [evaluation details](scripts/evals/README.md).

## Examples

- [FastAPI](examples/python-fastapi)
- [Django](examples/python-django)
- [Express](examples/node-express)
- [Next.js](examples/node-nextjs)
- [Flutter](examples/flutter-mobile)
- [Unity](examples/unity-game)

## Upgrade

Keep `answers.env`, pull the desired release, then run `update-config` (or preview and `--merge` by hand).
Never mix a template upgrade into a feature commit. See the
[upgrade guide](docs/upgrade-guide.md).

## Reference

- [Epic → story → slice](docs/epic-story-slice.md)
- [v0.11 design](docs/design/epic-story-slice.md)
- [Existing projects](docs/guides/existing-projects.md)
- [Host installs](docs/install/)
- [File map](docs/what-each-file-does.md)
- [Plugin package notes](plugin/README.md)

## Credits & inspiration

The operating principles build on [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills), with a leverage ladder adapted from [ponytail](https://github.com/dietrichgebert/ponytail), graph-first querying designed around [Graphify](https://github.com/Graphify-Labs/graphify), and pattern restraint inspired by [code-design-patterns](https://github.com/00suryavanshi00/code-design-patterns).

[GitHub Spec Kit](https://github.com/github/spec-kit) is MIT-licensed inspiration for separating specification, planning, tasks, and convergence. No artifacts were copied; this project is not affiliated with or endorsed by GitHub.

The `epic`, `slice`, `tests-first`, `implement` and `code-review` skills are adapted from [Matt Pocock's MIT-licensed skills](https://github.com/mattpocock/skills) (`to-spec`, `to-tickets`, `tdd`, `implement`, `code-review`); `tests-first/tests.md` and `mocking.md` are copied verbatim, with the MIT notice beside them. `council` is adapted from [tstack](https://github.com/t3dotgg/tstack) (MIT). This project is not affiliated with either author.

## Support

[GitHub Sponsors](https://github.com/sponsors/JuanTrujilloDev) ·
[Ko-fi](https://ko-fi.com/juantrujillodev)

## License

MIT. Use it, fork it, ship it.

Made in Colombia by [Juan Trujillo](https://juantrujillo.dev).
