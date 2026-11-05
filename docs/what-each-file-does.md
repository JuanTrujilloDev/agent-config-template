# What each file does

A reference for everything in `core/` (the canonical source; `template/` before v0.5.0) — what it controls, when it fires, and how to extend it.

## `CLAUDE.md` (project root)

Loaded by Claude Code on every session start. The "always-in-context" overview of the project: principles, tech stack, branch rules, agent map. Keep it short — anything detailed belongs in a skill under `.claude/skills/` that Claude loads when relevant.

## `.claude/HELP.md`

Human-facing usage guide — not auto-loaded. The decision tree ("what do I do when…?") plus worked examples of full feature flows. Reference from `CLAUDE.md` so Claude can pull it on demand.

## `.claude/settings.json`

Project-level Claude Code settings. Three things:
- **`permissions.allow`** — tools Claude can use without asking (e.g. `Bash(pytest:*)`).
- **`permissions.deny`** — tools blocked outright (e.g. `Bash(rm -rf:*)`, `Edit(.env*)`).
- **`permissions.ask`** — tools that prompt for confirmation each call (e.g. `Bash(git commit:*)`).
- **`hooks`** — registers the two shell hooks for `PreToolUse` and `PostToolUse`.
- Allows `Read(docs/epics/**)` and `Write(docs/epics/**)` for epic and slice files.

`.claude/settings.local.json` is per-user / per-machine overrides. **Gitignore it.**

## `.claude/answers.local.env`

Gitignored personal preferences read at session time: `autonomy_mode`,
`output_style`, and companion choices. It is never a renderer
input; shared project policy stays in committed `answers.env`.

## `.claude/mcp.json.example`

Template for MCP server config. Copy to `.claude/mcp.json` and fill in real values. **Gitignore `mcp.json`** if it contains secrets — use environment variables for API keys (`${PLANE_API_KEY}` etc.).

## `.claude/rules/principles.md`

The only always-loaded rule (≤80 lines): Think Before Coding, Simplicity First
(with the leverage ladder), Surgical Changes, Goal-Driven Execution (approved
tests locked), Read Before You Write, Code Health, Commits, Micro-PR Discipline,
Definition of Done, Conciseness, Autonomy Mode, Branch Discipline. If you change
one, change every reference to it in `CLAUDE.md`, `HELP.md` and the skills.

## `.claude/skills/<name>/SKILL.md`

Loaded on demand, never on every turn.

| Skill | Role |
|---|---|
| `epic` (+ `validate-epics.py`) | `/epic`: draft the epic once; `render <ID>` writes the repo copy from tracker cards; validator for `docs/epics/` |
| `slice` | `/slice`: brief one layer of one capability group |
| `tests-first` (+ `tests.md`, `mocking.md`) | All the slice's tests, red run, user approval, `## Approved tests` |
| `implement` | Code to green in the thread; never edits approved tests |
| `code-review` | Standards and Spec axes against a fixed point; fails on approved-test diffs; one fix round |
| `council` | Opt-in single-round review by three providers |
| `update-config` (+ `migrate.py`) | Upgrade a rendered project; migrate `docs/specs/` to `docs/epics/` |
| `backend-style`, `frontend-style` *(UI projects)* | Stack style, loaded by `implement` and `code-review` per slice layer |
| `code-query` | Graph first, grep second, for structural questions |
| `patterns` (+ `references/*.md`) | Name the present force or refuse; six domain references |

## `docs/epics/<ID>/`

`epic.md` (≤120 lines) and `slices/<n>.md` (≤60 lines). The first line says
where the truth lives: `source=<tracker>` (rendered from cards), `source=local`
or `source=migrated`. `archive/<slug>/` holds pre-v0.11 `docs/specs/` folders.
See `docs/epic-story-slice.md`.

## `.claude/agents/*.md`

Sub-agent definitions. Each has frontmatter (`name`, `description`) and a body that defines responsibilities, scope, and protocols. Claude Code spawns these as separate sub-conversations with their own context window.

| Agent | Role | Read-only? |
|---|---|---|
| `ui-designer` | Wireframes + specs (UI projects) | Yes |
| `security-reviewer` | Auth/permissions/data audit; writes `docs/epics/<ID>/slices/<n>.security.md` | Yes |
| `mutation-tester` | Checks the slice's approved tests bite (opt-in, `enforce_mutation_testing`) | Yes |

There is no coordinator or dev subagent: the slice loop runs in the thread.

Read-only agents never edit code — they report findings to the implementing agent.

## `.claude/commands/*.md`

Slash command definitions. Each file becomes `/<filename>` in Claude Code.

| Command | What it does |
|---|---|
| `/fix` | Small, scoped change: no epic, keeps the full Definition of Done |
| `/verify` | Implementer's skeptical self-review of its own diff before `code-review`/commit |
| `/integrate <tool>` | Research and connect an official MCP/tool after an explicit confirmation |
| `/audit` | Code + security review via the `code-review` Standards axis + `security-reviewer` |
| `/commit` | Conventional commit, with confirmation gate |
| `/pr` | Push + open PR (stacked on the previous layer's branch), with confirmation gate |
| `/design` | Wireframe + spec via `ui-designer` before UI code |

`/epic` and `/slice` are skills (above), invoked the same way.

Commands pause at approval gates. Never silently proceed past a brief, plan, or PR creation.

## `docs/design-system/MASTER.md` *(UI projects)*

The project brand contract: color tokens, typography, spacing, components,
responsive behavior, accessibility, and anti-patterns. Page-specific exceptions
live under `docs/design-system/pages/` only when needed.

## `docs/CONTEXT.md` *(created lazily)*

The glossary for project-specific terms, read by `/epic` and `tests-first`. It is not rendered by
setup and appears only after the workflow coins or disambiguates a term.

## `.claude/hooks/*.sh`

Shell scripts that fire on Claude Code events. Each reads the event's JSON payload from stdin.

### `agent-enforcement.sh` (PreToolUse: Edit | Write | MultiEdit | NotebookEdit)

Runs **before** every Edit or Write. Two hard blocks (exit 2 → Claude Code feeds the message back so the model self-corrects):
1. **Branch discipline** — blocks edits to the source directory while on a *protected* branch: the default branch plus anything in `AGENT_CONFIG_PROTECTED_BRANCHES` (legacy `CLAUDE_CONFIG_PROTECTED_BRANCHES`).
2. **Approved-tests lock** — blocks edits to the paths under `## Approved tests` in the slice file whose `- Branch:` line names the current branch. `AGENT_CONFIG_UNLOCK_TESTS=1` lifts it.

Anything it cannot parse passes: a guardrail, not a security boundary.

### `auto-format.sh` (PostToolUse: Edit | Write)

Runs **after** every Edit or Write. Policy: only *targeted* lint autofixers run inline; whole-file formatters do **not** run per-edit (they reformat untouched code and bloat diffs — a Surgical-Changes violation). The full formatter runs once, on the changed set, in the Definition of Done.
- `.py` → `ruff check --fix` (targeted). `black` runs in the DoD, not here.
- `.ts` / `.tsx` / `.js` / `.jsx` → project-local `eslint --fix` (targeted). `prettier` runs in the DoD, not here.
- `.go` / `.rs` → whole-file formatters (`gofmt`/`rustfmt`) run in the DoD, not here.
- `.html` → skipped (template tags break prettier).

Issues a tool can't auto-fix are surfaced to stderr (no longer silently swallowed), but the hook never blocks (exit 0).

## Where to add what

| Need | Where |
|---|---|
| A rule every coding turn needs | `rules/principles.md` (keep it ≤80 lines) |
| A procedure or reference loaded when relevant | `skills/<name>/SKILL.md` |
| A read-only role with its own context window | `agents/` |
| A user-triggered shortcut | `commands/` |
| A check that should run before/after every Edit | `hooks/` |

---|---|
| A repeatable workflow with multiple steps | `agents/` |
| A coding pattern that should be auto-loaded for a file glob | `rules/` |
| A user-triggered shortcut | `commands/` |
| A check that should run before/after every Edit | `hooks/` |

---

## Generated host and test surfaces

- `hosts/` contains hand-authored host adapters and overrides used as build inputs.
- `cursor/` and `codex/` are generated packaging trees; never edit them directly.
- `scripts/smoke/` contains the shared harness plus one focused file per release item (`v011-<n>-*.sh` for v0.11).
- `docs/epics/EXAMPLE/` is the grammar fixture `validate-epics.py` must pass clean.
- `setup.sh --merge --overwrite-files a,b` replaces only the named managed files;
  the plan prints the safe candidate list first.

---

## Plugin variant — what's different

The repo ships a parameterized template plus native Claude, Cursor, and Codex
plugin manifests. Cursor's root `.cursor-plugin/plugin.json` points at the
shared `plugin/` bundle, so users install from Customize and run
`/setup-template` without cloning the repository.

### `plugin/.claude-plugin/plugin.json`

The plugin manifest — name, description, version, author, license. Claude Code reads this when listing/installing plugins. The `name` field also acts as the namespace for slash commands (`/agent-config-template:epic`, `/agent-config-template:fix`, etc.).

### `plugin/agents/`

`security-reviewer` and `ui-designer`, with stack-agnostic phrasing ("your project's test command" instead of `pytest`); references to `.claude/rules/principles.md` become `the principles skill`.

### `plugin/commands/`

`/fix`, `/verify`, `/audit`, `/pr`, `/design`, `/commit`, `/integrate`, plus the plugin-only `/setup-template`, `/setup-companions` and `/orchestrator-init`. Available as `/agent-config-template:<name>` once installed.

### `plugin/skills/`

Every placeholder-free skill in `core/.claude/skills/` (`epic`, `slice`, `tests-first`, `implement`, `code-review`, `council`, `update-config`, `code-query`, `patterns`) is a byte copy made by `scripts/build.sh`; `build.sh --check` fails on drift. `principles`, `backend-style`, `frontend-style`, `port-config`, `lavish` and `orchestrator-init` are hand-authored generic versions.

### `plugin/hooks/hooks.json` + `plugin/hooks/*.sh`

The two hooks (agent-enforcement with the branch block and approved-tests lock, auto-format) wired through `hooks.json` (the plugin format) instead of the project's `settings.json`. `agent-enforcement.sh` reads env vars (`CLAUDE_CONFIG_SRC_DIR`, `CLAUDE_CONFIG_FRONTEND_DIR`, `AGENT_CONFIG_PROTECTED_BRANCHES`, with legacy `CLAUDE_CONFIG_PROTECTED_BRANCHES` fallback) with sensible defaults.

### `.claude-plugin/marketplace.json`

The repo-as-marketplace listing. Lets users do `/plugin marketplace add JuanTrujilloDev/agent-config-template` and discover the single plugin inside.

## When to use plugin vs template

| | Plugin | Template |
|---|---|---|
| **Install** | `/plugin install` (one line) | Clone + Claude-driven render |
| **Project specifics** | env vars override generic defaults | Baked-in placeholders |
| **CLAUDE.md for the project** | You write a short one yourself | Generated, fully calibrated |
| **Hooks** | Read env vars, fall back to defaults | Hardcoded to your project |
| **Style guides** | Stack-agnostic skills | Tailored prose |
| **Best for** | Quick adoption across many repos | One repo where you want full precision |

You can use both — the plugin gives every project a baseline of skills/commands/principles; the template promotes a specific project to "fully calibrated" status.
