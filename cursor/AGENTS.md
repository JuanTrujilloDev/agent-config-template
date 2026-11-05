# {{project_name}} — Agent Guidelines

{{project_description}}

## Operating Principles (non-negotiable)

Full text: `.claude/rules/principles.md` (always loaded via `.cursor/rules/principles.mdc`).

1. **Think Before Coding** — state assumptions; ask if ambiguous.
2. **Simplicity First (YAGNI)** — minimum code; reuse > stdlib > native > installed deps > new code.
3. **Surgical Changes** — touch only what the task requires.
4. **Goal-Driven Execution** — write 2–4 verifiable success criteria first; loop until they pass. Approved tests are locked: never edit one to go green; stop and ask.
- **Micro-PR Discipline** — one slice per PR, one layer per slice (db → be → fe); aim for 200–400 non-test lines; cap ≤{{max_files_per_pr}} files, <{{max_loc_per_pr}} lines.
- **Definition of Done** — Format → Lint → Tests → `code-review` before declaring done.
- **Branch Discipline** — never code on `{{default_branch}}`; check out a typed branch first.

Before any coding task: restate the goal in one sentence + list 2–4 verifiable success criteria.

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| Language | {{language}} {{language_version}} |
| Framework | {{framework}} |
{{#has_frontend}}
| Frontend | {{frontend_framework}} |
{{/has_frontend}}
| Database | {{database}} |
| Tools | {{formatter}}, {{linter}} |

Primary source: `{{src_dir}}`{{#has_frontend}} · Frontend: `{{frontend_dir}}`{{/has_frontend}} · Tests: `{{tests_glob}}`

## Branch Naming (MANDATORY)

Never code on `{{default_branch}}`.

{{#branch_prefix}}
| Type | Pattern | Example |
|---|---|---|
| Slice | `feature/{{branch_prefix}}-<#>-<group>-<layer>` | `feature/{{branch_prefix}}-87-export-be` |
| Fix (tracked) | `fix/{{branch_prefix}}-<#>-<kebab-name>` | `fix/{{branch_prefix}}-104-login-redirect` |
| Fix (untracked) | `fix/<kebab-name>` | `fix/login-redirect` |
{{/branch_prefix}}
{{^branch_prefix}}
| Type | Pattern | Example |
|---|---|---|
| Slice | `feature/<ID>-<group>-<layer>` | `feature/EXPORT-csv-be` |
| Fix | `fix/<kebab-name>` | `fix/login-redirect` |
{{/branch_prefix}}
| Hotfix (urgent prod) | `hotfix/<kebab-name>` | `hotfix/login-500` |
| Refactor | `refactor/<kebab-name>` | `refactor/consolidate-auth` |
| Chore | `chore/<kebab-name>` | `chore/upgrade-deps` |
| Docs only | `docs/<kebab-name>` | `docs/api-overview` |

Commits are conventional: `type(scope): description` — feat, fix, refactor, test, docs, style, chore.

## Commands

```bash
{{build_cmd}}
{{test_cmd}}
{{format_cmd}}
{{lint_cmd}}
```

## Workflow

`/epic` → `/slice` → `tests-first` → `implement` → `code-review` → `/pr`, all in this thread (skills under `.claude/skills/`). Epics and slices live in `docs/epics/<ID>/`. A small change with an obvious cause uses `/fix`.

## Agents (`.claude/agents/`)

| Trigger | Agent | Scope |
|---|---|---|
{{#has_ui}}
| New UI/UX | `ui-designer` (before UI implementation) | wireframes/mockups (read-only) |
{{/has_ui}}
| Security audit | `security-reviewer` | mandatory for auth/permissions/data |

## Visual review (lavish)

For a plan, comparison, diagram, table, or report the user asked to mark up, use the `lavish` skill. Pin `lavish-axi@0.1.90`. Set `LAVISH_AXI_TELEMETRY=0` and leave `LAVISH_AXI_HOST` unset. Write the HTML outside this repository and never beside `.env`. Do not run `share`, `update`, `setup hooks`, or `setup plugin`. Product UI follows this project's design system, not the lavish CDN snippet. The review server has no password; stop it when the review ends.

## Detail

- Project skills: `.claude/skills/` — Cursor reads these rendered, stack-dependent skills natively
- Style skills: `.claude/skills/backend-style/`{{#has_frontend}}, `.claude/skills/frontend-style/`{{/has_frontend}} (loaded per slice layer)
- Structural code questions (what depends on what): the `code-query` skill (`.claude/skills/code-query/`) — graph first, grep second
- Full principles: `.claude/rules/principles.md`
- Never commit `.env` files; validate input at every boundary
