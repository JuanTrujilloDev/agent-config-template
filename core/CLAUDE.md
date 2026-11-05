# {{project_name}} — Project Guidelines

## Overview

{{project_description}}

## Operating Principles (read first)

`.claude/rules/principles.md` is always loaded and non-negotiable: think before coding, simplicity and the leverage ladder, surgical changes, goal-driven execution with approved tests locked, read before you write, code health, small commits, micro-PRs (≤{{max_files_per_pr}} files, <{{max_loc_per_pr}} lines), the Definition of Done, conciseness, autonomy mode and branch discipline.

Before any coding task: restate the goal in one sentence and list 2–4 verifiable success criteria.

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
Epics and slices: `docs/epics/<ID>/epic.md`, `docs/epics/<ID>/slices/<n>.md`

## Code Style

- **Line length:** {{line_length}} chars
- **Formatter:** {{formatter}} — run `{{format_cmd}}`
- **Linter:** {{linter}} — run `{{lint_cmd}}`

Detailed patterns: `.claude/rules/backend-style.md`{{#has_frontend}}, `.claude/rules/frontend-style.md`{{/has_frontend}}. Structural code questions: `.claude/rules/code-query.md` (graph first, grep second). Before adding an abstraction: `.claude/rules/patterns.md` (name the force or refuse).

## Commands

```bash
{{build_cmd}}
{{test_cmd}}
{{format_cmd}}
{{lint_cmd}}
```

## Workflow

`/epic` → `/slice` → `tests-first` → `implement` → `code-review` → `/pr`, all in this thread.

1. **`/epic <{{#branch_prefix}}{{branch_prefix}}-<#> or {{/branch_prefix}}ask>`** drafts the epic once: capability groups, one-case stories, acceptance criteria, Given/When/Then test scenarios, layered slices. You approve by number.
2. **`/slice <ID> <n>`** briefs the next slice in `db → be → fe` order: stories, seams, fixtures, expected behaviour. You say yes.
3. **`tests-first`** writes the slice's tests through the public seam, runs them red and commits them. You read the tests and say yes; their paths go under `## Approved tests` in the slice file and are locked.
4. **`implement`** writes the code to green without touching approved tests, then runs the Definition of Done.
5. **`code-review`** checks the diff against the principles, the style rule and the slice; one fix round, then `/pr`.

Branches stack per capability group: `feature/<ID>-<group>-db` → `-be` → `-fe`. A small change with an obvious cause uses `/fix` instead.

### Agents (`.claude/agents/`)

| Trigger | Agent | Scope |
|---|---|---|
{{#has_ui}}
| New UI/UX, before UI code | `ui-designer` | wireframes and component specs (read-only) |
{{/has_ui}}
| Auth, permissions, data exposure, input boundaries | `security-reviewer` | findings report (read-only) |
{{#enforce_mutation_testing}}
| Check that the slice's tests bite | `mutation-tester` | runs `tools/mutate.py` (opt-in) |
{{/enforce_mutation_testing}}

### Commands (`.claude/commands/`)

`/fix`, `/verify`, `/commit`, `/pr`, `/audit`{{#has_ui}}, `/design`{{/has_ui}} — see each file.

### Hooks (`.claude/hooks/`)

- **PreToolUse** on `Edit|Write` → `agent-enforcement.sh`: blocks edits under `{{src_dir}}` on a protected branch (`{{default_branch}}` or `$AGENT_CONFIG_PROTECTED_BRANCHES`), and blocks edits to the current slice's approved tests (override `AGENT_CONFIG_UNLOCK_TESTS=1`).
- **PostToolUse** on `Edit|Write` → `auto-format.sh`: targeted lint autofixes on the changed file; whole-file formatting runs in the Definition of Done.

### MCP Servers
{{#has_e2e}}
- `playwright` — live browser checks for the Definition of Done (`@playwright/mcp`)
{{/has_e2e}}
{{#ticket_tracker_plane}}
- `plane` — reads and renders epic and slice cards (`/epic`)
{{/ticket_tracker_plane}}
{{#ticket_tracker_jira}}
- `atlassian` — reads the epic ticket (`/epic`)
{{/ticket_tracker_jira}}
{{#ticket_tracker_linear}}
- `linear` — reads the epic ticket (`/epic`)
{{/ticket_tracker_linear}}

## Dynamic Context (optional)

Claude Code expands `` !`shell command` `` in this file at session start; other hosts read these lines as plain text. Uncomment only cheap, sub-second commands.

```markdown
<!-- Current branch: !`git rev-parse --abbrev-ref HEAD` -->
<!-- Recent commits: !`git log --oneline -5` -->
<!-- Uncommitted changes: !`git status --short` -->
<!-- Open PRs: !`gh pr list --limit 5 --json number,title,headRefName --jq '.[] | "  #\(.number) [\(.headRefName)] \(.title)"' 2>/dev/null || echo "  (gh not configured)"` -->
```

## Visual review (lavish)

For a plan, comparison, diagram, table, or report the user asked to mark up, use the `lavish` skill. Pin `lavish-axi@0.1.90`. Set `LAVISH_AXI_TELEMETRY=0` and leave `LAVISH_AXI_HOST` unset. Write the HTML outside this repository and never beside `.env`. Do not run `share`, `update`, `setup hooks`, or `setup plugin`. Product UI follows this project's design system, not the lavish CDN snippet. The review server has no password; stop it when the review ends.

## Security

- Never commit `.env` files; use env vars for secrets
- Validate input at every boundary; CSRF on forms; rate-limit sensitive endpoints

## References

- **Usage guide:** `.claude/HELP.md` — what to run when
- **Principles:** `.claude/rules/principles.md`
