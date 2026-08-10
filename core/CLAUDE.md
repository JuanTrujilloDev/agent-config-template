# {{project_name}} — Project Guidelines

## Overview

{{project_description}}

## Core Operating Principles (READ FIRST)

Read `.claude/rules/principles.md`. The principles are **non-negotiable**:

1. **Think Before Coding** — State assumptions; ask if ambiguous.
2. **Simplicity First (YAGNI)** — Minimum code, no speculation; walk the leverage ladder (reuse > stdlib > native > installed deps > new code) before writing.
3. **Surgical Changes** — Touch only what the task requires.
4. **Goal-Driven Execution** — Write 2–4 verifiable success criteria first; loop until they pass.
{{#enforce_layer_split}}
5. **Backend / Frontend Split** — Two PRs per feature: BE ships first, FE ships after.
{{/enforce_layer_split}}
- **Read Before You Write** — never edit code you haven't read; check callers first (reporting bypassable, reading isn't).
- **Code Health** — DRY (rule of three), small functions/files (~40/~400 lines), no god objects, comments explain *why* (no narration, no commented-out code).
- **Micro-PR Discipline** — ≤{{max_files_per_pr}} files changed, <{{max_loc_per_pr}} lines changed per PR; one logical change per commit.
- **Definition of Done** — Format → Lint → Unit tests → `judge` → `security-reviewer` (when relevant){{#has_e2e}} → live browser verification (auto for FE / big changes){{/has_e2e}}.
- **Conciseness** — Be brief. No filler, no recaps of visible output, no preambles.
- **Branch Discipline** — Never code on `{{default_branch}}`. Always check out a typed branch first.

Before any coding task: restate the goal in one sentence + list 2–4 verifiable success criteria.

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| Language | {{language}} {{language_version}} |
| Type | {{project_type}} |
| Framework | {{framework}} |
{{#has_frontend}}
| Frontend | {{frontend_framework}} |
{{/has_frontend}}
| Database | {{database}} |
| Tools | {{formatter}}, {{linter}} |

## Project Structure

Primary source: `{{src_dir}}`
{{#has_frontend}}
Frontend source: `{{frontend_dir}}`
{{/has_frontend}}
Tests: `{{tests_glob}}`

## Code Style

- **Line length:** {{line_length}} chars
- **Formatter:** {{formatter}} — run `{{format_cmd}}`
- **Linter:** {{linter}} — run `{{lint_cmd}}`

Detailed patterns: `.claude/rules/backend-style.md`{{#has_frontend}}, `.claude/rules/frontend-style.md`{{/has_frontend}}. Structural code questions (what depends on what): `.claude/rules/code-query.md` — graph first, grep second.

## Git Workflow

### Branch Naming (MANDATORY)

Never code on `{{default_branch}}`. Always check out a typed branch first.

{{#branch_prefix}}
| Type | Pattern | Example |
|---|---|---|
| Feature (tracked) | `feature/{{branch_prefix}}-<#>-<kebab-name>` | `feature/{{branch_prefix}}-87-csv-export` |
{{#enforce_layer_split}}
| Feature split BE/FE | append `-be` / `-fe` | `feature/{{branch_prefix}}-87-csv-export-be` |
{{/enforce_layer_split}}
| Fix (tracked) | `fix/{{branch_prefix}}-<#>-<kebab-name>` | `fix/{{branch_prefix}}-104-login-redirect` |
| Fix (untracked) | `fix/<kebab-name>` | `fix/login-redirect` |
{{/branch_prefix}}
{{^branch_prefix}}
| Type | Pattern | Example |
|---|---|---|
| Feature | `feature/<kebab-name>` | `feature/csv-export` |
{{#enforce_layer_split}}
| Feature split BE/FE | append `-be` / `-fe` | `feature/csv-export-be` |
{{/enforce_layer_split}}
| Fix | `fix/<kebab-name>` | `fix/login-redirect` |
{{/branch_prefix}}
| Hotfix (urgent prod) | `hotfix/<kebab-name>` | `hotfix/login-500` |
| Refactor | `refactor/<kebab-name>` | `refactor/consolidate-auth` |
| Chore | `chore/<kebab-name>` | `chore/upgrade-deps` |
| Docs only | `docs/<kebab-name>` | `docs/api-overview` |

### Commits (Conventional)

`type(scope): description` — types: feat, fix, refactor, test, docs, style, chore.

## Commands

```bash
{{build_cmd}}
{{test_cmd}}
{{format_cmd}}
{{lint_cmd}}
```

## Claude Code Workflow

### Agents (`.claude/agents/`) — PREFER FOR NON-TRIVIAL WORK

**Prefer** the appropriate agent for **non-trivial** edits. "Trivial" = ≤50 lines added/changed and at most one new `def`/`class`/`export class`. The `agent-enforcement` hook is advisory here — it guides, it doesn't block — so this discipline is on you, not the hook.

| Trigger | Agent | Scope |
|---|---|---|
| Spec a feature (idea/SOW → contract + mini-features) | `pmo` | `docs/specs/<slug>/` |
| Run the full spec-driven flow for a feature | `orchestrator` | coordinates; never edits code |
| Implementation ticket | `{{primary_dev_agent}}` | Code in `{{src_dir}}` |
{{#has_frontend}}
| Frontend ticket | `frontend-dev` | UI code in `{{frontend_dir}}` |
{{/has_frontend}}
{{#has_ui}}
| New UI/UX | `ui-designer` (before UI implementation) | wireframes/mockups (read-only) |
{{/has_ui}}
| Review before commit/PR | `judge` | code + tests vs contract, micro-PR limits, principles |
| Security audit | `security-reviewer` | mandatory for auth/permissions/data |
{{#enforce_mutation_testing}}
| Validate tests bite | `mutation-tester` | runs `tools/mutate.py` (opt-in) |
{{/enforce_mutation_testing}}

> The end-to-end flow lives in `docs/sdd-workflow.md`.

**Hard rules:**

{{#enforce_layer_split}}
1. Tasks touching **both** BE and FE → run `/feature` (the `orchestrator` sequences it) or spawn `pmo` first. **Never** cross the BE/FE boundary in a single response.
2. Both `*-dev` agents follow **Design First**: produce a design artifact (DB models/API surface for BE; wireframes/flow for FE) → user approves → implement. Skipping is allowed only for trivial fixes/hotfixes with obvious root cause.
{{/enforce_layer_split}}
{{^enforce_layer_split}}
1. The `*-dev` agent follows **Design First**: produce a design artifact (data model / public surface{{#has_ui}}; wireframes/flow for UI work{{/has_ui}}) → user approves → implement. Skipping is allowed only for trivial fixes/hotfixes with obvious root cause.
{{/enforce_layer_split}}
- Before declaring a task complete, run the **Definition of Done** (rules/principles.md).
- Before any code edit, confirm the current branch matches the task type. If on `{{default_branch}}`, check out the right branch first.

### Commands (`.claude/commands/`)
- `/spec [{{#branch_prefix}}{{branch_prefix}}-<#> or {{/branch_prefix}}description]` — Idea/SOW → conversed spec + Given/When/Then contract + mini-features (`pmo`).
- `/feature [{{#branch_prefix}}{{branch_prefix}}-<#> or {{/branch_prefix}}description]` — Full spec-driven flow (`orchestrator`): approve contract → optional TDD → implement → `judge` → micro-commit
- `/fix [description]` — Small, scoped change: skips brief/plan + formal Design First, keeps the full Definition of Done
- `/verify` — Skeptical self-review of your own diff before `judge`/commit (run it, don't just claim it)
- `/commit`, `/pr`, `/audit` — see individual command files

### Hooks (`.claude/hooks/`)
- **PostToolUse** on `Edit|Write` → `auto-format.sh`: runs only targeted lint autofixes (`ruff --fix` / `eslint --fix`) on the changed file; whole-file formatting (`{{format_cmd}}`) runs in the Definition of Done, not per-edit
- **PreToolUse** on `Edit|Write` → `agent-enforcement.sh`: **hard-blocks** edits while on a protected branch (`{{default_branch}}` or `$CLAUDE_CONFIG_PROTECTED_BRANCHES`); **advises** (does not block) on large non-agent edits to `{{src_dir}}`
- **UserPromptSubmit** → `coding-reminder.sh`: injects principles + workflow reminder on coding prompts

### Rules (`.claude/rules/`)
- `principles.md` — Core Operating Principles (always-loaded)
- `backend-style.md` — backend patterns
{{#has_frontend}}
- `frontend-style.md` — frontend patterns
{{/has_frontend}}

### MCP Servers
{{#has_e2e}}
- `playwright` — Live browser automation for E2E verification (`@playwright/mcp`)
{{/has_e2e}}
{{#ticket_tracker_plane}}
- `plane` — Plane.so ticket pull (used by `/feature`)
{{/ticket_tracker_plane}}
{{#ticket_tracker_jira}}
- `atlassian` — Jira ticket pull (used by `/feature`)
{{/ticket_tracker_jira}}
{{#ticket_tracker_linear}}
- `linear` — Linear ticket pull (used by `/feature`)
{{/ticket_tracker_linear}}

## Dynamic Context (optional)

Claude Code expands `` !`shell command` `` in this file at session start, injecting the live output into context. Useful for keeping the model oriented to the current state of the repo without you having to mention it.

Pick the lines that are useful for your team and uncomment them. Skip everything that's noise.

```markdown
<!-- Current branch + status — keeps the model honest about where you are -->
<!-- Current branch: !`git rev-parse --abbrev-ref HEAD` -->
<!-- Recent commits: !`git log --oneline -5` -->
<!-- Uncommitted changes: !`git status --short` -->

<!-- Open PRs / issues — useful when /feature pulls a ticket -->
<!-- Open PRs: !`gh pr list --limit 5 --json number,title,headRefName --jq '.[] | "  #\(.number) [\(.headRefName)] \(.title)"' 2>/dev/null || echo "  (gh not configured)"` -->

<!-- Test coverage — surface drift before judge asks -->
<!-- Coverage: !`{{test_cmd}} --cov={{src_dir}} 2>/dev/null | tail -1 || echo "(run tests to see coverage)"` -->
```

Inject only what's cheap to compute (sub-second commands). Anything slow makes session start sluggish.

## Security

- Never commit `.env` files; use env vars for secrets
- Validate input at every boundary; CSRF on forms; rate-limit sensitive endpoints

## References

- **Usage guide:** `.claude/HELP.md` — decision tree, worked examples
- **SDD/TDD workflow:** `docs/sdd-workflow.md` — the spec-driven flow end-to-end
- **Principles:** `.claude/rules/principles.md`
