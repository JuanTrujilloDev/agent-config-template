# {{project_name}} — Agent Guidelines

{{project_description}}

## Operating Principles (non-negotiable)

Full text: `.claude/rules/principles.md` (always loaded via `.cursor/rules/principles.mdc`).

1. **Think Before Coding** — state assumptions; ask if ambiguous.
2. **Simplicity First (YAGNI)** — minimum code; reuse > stdlib > native > installed deps > new code.
3. **Surgical Changes** — touch only what the task requires.
4. **Goal-Driven Execution** — write 2–4 verifiable success criteria first; loop until they pass.
{{#enforce_layer_split}}
5. **Backend / Frontend Split** — two PRs per feature: BE ships first, FE ships after.
{{/enforce_layer_split}}
- **Micro-PR Discipline** — ≤{{max_files_per_pr}} files changed, <{{max_loc_per_pr}} lines changed per PR.
- **Definition of Done** — Format → Lint → Unit tests → review before declaring done.
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

Commits are conventional: `type(scope): description` — feat, fix, refactor, test, docs, style, chore.

## Commands

```bash
{{build_cmd}}
{{test_cmd}}
{{format_cmd}}
{{lint_cmd}}
```

## Agents (`.claude/agents/`)

Prefer the appropriate agent role for non-trivial work (>50 lines changed or more than one new def/class):

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

## Detail

- Style rules: `.claude/rules/backend-style.md`{{#has_frontend}}, `.claude/rules/frontend-style.md`{{/has_frontend}} (auto-attached via `.cursor/rules/*.mdc`)
- Structural code questions (what depends on what): `.claude/rules/code-query.md` — graph first, grep second
- Full principles: `.claude/rules/principles.md`
- Never commit `.env` files; validate input at every boundary
