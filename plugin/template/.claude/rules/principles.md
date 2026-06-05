# Core Operating Principles

> Always-loaded. These principles apply to **every** coding task in {{project_name}}. They are non-negotiable. When a request conflicts with a principle, surface the conflict and ask — do not silently override.

## 1. Think Before Coding

State your assumptions explicitly. If a request has multiple valid interpretations, ask before writing. No silent decisions on ambiguous requirements.

Before any implementation:
- Restate the goal in one sentence.
- List 2–4 verifiable success criteria.
- Surface tradeoffs when more than one approach exists.

## 2. Simplicity First (YAGNI)

Write the minimum code that solves the stated problem. **Nothing speculative.**

- No `*Service` classes "in case we need them later."
- No flexible options/parameters that have no current caller.
- No abstractions for hypothetical second use cases.
- Three similar lines beats a premature abstraction.
- Trust internal code and framework guarantees — only validate at system boundaries.

## 3. Surgical Changes

Touch only what the task requires.

- Don't refactor adjacent code.
- Don't reformat unrelated lines.
- Don't "clean up" things you didn't break.
- Match the file's existing style — even if you'd write it differently from scratch.
- Remove only the dependencies your changes created. Pre-existing dead code stays unless cleanup *is* the task.

## 4. Goal-Driven Execution

Define success criteria. Loop until verified.

For each task:
1. Write 2–4 verifiable checks (e.g., *"endpoint X returns 201 with the new record"*, *"`{{test_cmd}}` is green"*).
2. Implement.
3. Run the criteria.
4. Fix gaps.
5. Repeat until all criteria pass — *then* declare done.

{{#enforce_layer_split}}
## 5. Backend / Frontend Split

Every feature touching both BE and FE ships as **two PRs** in sequence. Never a single PR straddling both layers.

**Backend PR** (ships first, exposes a stable API):
- Models, serializers, API views, services, signals, background tasks, filters, permissions
- Tests for those layers
- Branch suffix: `-be`

**Frontend PR** (ships after BE merged, consumes the API):
- Template-rendering views (HTML, not JSON)
- Anything under `{{frontend_dir}}` (templates, static JS, CSS, components)
- FE tests
- Branch suffix: `-fe`

When the `pm` agent decomposes a feature, it creates one BE ticket and one FE ticket (or more of each if the feature is large). The BE ticket is routed to `backend-dev`; the FE ticket to `frontend-dev`.
{{/enforce_layer_split}}

## Design Patterns (when warranted)

Reach for a known design pattern **only when the problem genuinely matches one and it reduces complexity for a real, present need** — Strategy, Factory, Adapter, Repository, Observer, etc. Name it in the spec's Design notes with a one-line *why*. Never impose a pattern speculatively: a pattern with no present second caller or real variation is YAGNI (see Principle 2, and the `backend-dev` gotcha about wrapping a single call site in a `*Service` class).

## Spec-Driven & Test-First (when invoked)

For non-trivial features, prefer the spec-driven flow (`/spec` → `/feature`): an approved Given/When/Then contract **before** code, one mini-feature at a time, optionally test-first. See `.claude/HELP.md` and `docs/sdd-workflow.md`. For a small scoped change with an obvious cause, `/fix` is the right tool — skip the ceremony, keep the Definition of Done.

## Micro-PR Discipline

Every PR must stay under both limits:
- **≤{{max_files_per_pr}} files changed**
- **<{{max_loc_per_pr}} lines changed**

If a feature won't fit, the `pm` agent breaks it into sequential tickets, each its own PR. Bigger ≠ better; smaller PRs review faster, merge cleaner, and roll back safely.

## Definition of Done

A coding task is **NOT** complete until all of these pass, in order:

1. **Format** — `{{format_cmd}}`
2. **Lint** — `{{lint_cmd}}` (zero new warnings)
3. **Unit tests** — `{{test_cmd}}` green, ≥{{test_coverage_target}}% coverage maintained
4. **Code review** — Spawn `code-reviewer` agent; address all blockers it flags.
5. **Security review** — Spawn `security-reviewer` if change touches authentication, permissions, data exposure, or external input boundaries.
{{#has_e2e}}
6. **Live browser verification** — For any change under `{{frontend_dir}}` OR diff exceeding 5 files / 500 lines: use `mcp__playwright__*` tools to walk through the user flow described in success criteria and confirm it works end-to-end.
{{/has_e2e}}

Skipping any step = the task is open. The agent that did the work is responsible for running the checklist and reporting results before declaring done.

## Conciseness

Be brief. Default to short answers and summaries. No filler ("Great question!", "Let me explain...", "I hope this helps!"). No restating the user's question. No unsolicited recap of what you just did when the diff/output already shows it.

- Match length to need: yes/no questions get yes/no; one-line tasks get one-line answers.
- Skip preambles. Lead with the answer or the action.
- Lists only when there are 3+ items. Tables only when comparing.
- Code blocks only for code or terminal output.
- For multi-step work: progress note → result. Not progress note → recap → next-steps → meta-commentary.
- After a tool call, summarize only what's NOT already visible in the tool output.

## Branch Discipline

**Never code on `{{default_branch}}`.** Every change starts with a checkout to a typed branch:

| Type | Pattern | Example |
|---|---|---|
{{#branch_prefix}}
| Feature (tracked) | `feature/{{branch_prefix}}-<#>-<kebab-name>` | `feature/{{branch_prefix}}-87-csv-export` |
{{#enforce_layer_split}}
| Feature (split BE/FE) | append `-be` / `-fe` | `feature/{{branch_prefix}}-87-csv-export-be` |
{{/enforce_layer_split}}
| Fix (tracked) | `fix/{{branch_prefix}}-<#>-<kebab-name>` | `fix/{{branch_prefix}}-104-login-redirect` |
| Fix (untracked) | `fix/<kebab-name>` | `fix/login-redirect` |
{{/branch_prefix}}
{{^branch_prefix}}
| Feature | `feature/<kebab-name>` | `feature/csv-export` |
{{#enforce_layer_split}}
| Feature (split BE/FE) | append `-be` / `-fe` | `feature/csv-export-be` |
{{/enforce_layer_split}}
| Fix | `fix/<kebab-name>` | `fix/login-redirect` |
{{/branch_prefix}}
| Hotfix (urgent prod) | `hotfix/<kebab-name>` (branches from `{{default_branch}}`) | `hotfix/login-500` |
| Refactor | `refactor/<kebab-name>` | `refactor/consolidate-auth` |
| Chore (tooling/config/deps) | `chore/<kebab-name>` | `chore/upgrade-deps` |
| Docs only | `docs/<kebab-name>` | `docs/api-overview` |

Before any code edit, confirm the current branch matches the task type. If on `{{default_branch}}`, check out a properly-named branch first.
