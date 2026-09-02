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
- **The senior-engineer test:** before shipping, ask whether a senior engineer would call this overcomplicated for the stated problem — if yes, simplify before moving on.

**The leverage ladder.** Before writing any new code, walk down — stop at the
first rung that solves it:

1. **Does it need to exist at all?** (YAGNI — maybe the requirement dissolves on inspection)
2. **Already in this codebase?** Reuse it — `.claude/rules/code-query.md` shows how to find it.
3. **In the standard library?** Use the built-in.
4. **A native platform feature?** (`<input type="date">` beats a date-picker dependency)
5. **In an already-installed dependency?** Don't add a new one for what an existing one does.
6. **Only then** write the minimum functional solution.

Be lazy about the *solution*, never about the *requirements*: security,
validation, error handling, and accessibility are never rungs to skip —
minimizing them is negligence, not simplicity.

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
2. Work in the shape `[step] → verify: [check]` — every step names the check that proves it landed (e.g., *"add the redirect → verify: the auth test passes"*).
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

When the `pmo` agent decomposes a feature, it creates one BE mini-feature and one FE mini-feature (or more of each if the feature is large). The BE ticket is routed to `backend-dev`; the FE ticket to `frontend-dev`.
{{/enforce_layer_split}}

## Design Patterns (when warranted)

Catalogue and selection guide: `.claude/rules/patterns.md`. Four hard rules:

1. **Inspect existing patterns first** — reuse what the codebase already does before introducing anything new.
2. **Name the present force before selecting** — a pattern answers a force that exists now (real variation, a second caller), never one you predict.
3. **One-line why** in the spec's Design notes: `pattern / force / rejected alternative`.
4. **Refusal is valid** — "no pattern — single call site" is a complete answer.

Default-reject without a stated force: single-implementation Strategy, speculative Repository, unnecessary Factory, Singleton / Service Locator.

## Spec-Driven & Test-First (when invoked)

For non-trivial features, prefer the spec-driven flow (`/spec` → `/feature`): an approved Given/When/Then contract **before** code, one mini-feature at a time, optionally test-first. See `.claude/HELP.md` and `docs/sdd-workflow.md`. For a small scoped change with an obvious cause, `/fix` is the right tool — skip the ceremony, keep the Definition of Done.

## Principles Double Gate

Before Gate 1, PMO checks every mini-feature against these principles and
records the result in the spec's `### Principles deviation table`.
Judge rechecks the diff against the same table before approval; missing, unrecorded,
or unused deviations block the mini-feature.

## Read Before You Write

Never modify code you haven't read. Before editing, read the target file end to
end and check its callers/usages — an edit made on a pattern-match guess is how
context gets lost and regressions ship. For structural questions (what depends
on this, how are these connected), `.claude/rules/code-query.md` finds the
callers cheaply — graph first, grep second; then read what it surfaces.

- For non-trivial changes, state what you found (current behavior, who depends
  on it) before proposing the diff — that's the human's chance to catch a wrong
  assumption while it's still cheap.
- **Bypass:** the human can say "just go" / "skip the walkthrough" for changes
  they consider low-risk, and trivial edits (≤50 lines, no new def/class) don't
  need the narration. The *reading* is never skipped — only the reporting.

## Code Health

Leave the codebase no worse than you found it — within the surgical-changes rule.

- **DRY by the rule of three.** Don't extract on the second occurrence;
  *do* extract on the third. Never paste a third copy.
- **Small units.** Functions that do one thing (aim well under ~40 lines);
  split any file that grows past ~400 lines or mixes responsibilities. If your
  change would push a file past the limit, split *as part of the change*.
- **No god objects / spaghetti.** Dependencies point one way; modules have one
  reason to change. If your diff adds an import cycle or a "misc" dump, stop.
- **Comments explain *why*, not *what*.** No narration of obvious code, no
  commented-out code (delete it — git remembers), no decorative banners.
  Docstrings for the public surface; one-liners elsewhere when needed.

## Autonomy Mode

A **personal** preference, read at session time from the gitignored
`.claude/answers.local.env` (`autonomy_mode=gated|autonomous`). Absent file or
key = `gated`. It is never rendered into committed files.

- **gated** (default) — stop for user review before each micro-commit: present
  the diff, wait for the user, then commit.
- **autonomous** — proceed through the flow (implement → review → micro-commit)
  without pausing at the commit step.
- **Session keyword overrides** — "just go" switches this session to
  autonomous; "gate me" or "stop before commit" switches it to gated. These are
  session-scoped overrides of the stored mode: apply them immediately and
  **never write them to any file**.
- **“Just go” is scoped.** In Read Before You Write it skips only narration; here it switches session autonomy; in setup it skips the frontier round. A recorded `autonomy_mode=autonomous` does not activate setup just-go.
- **Action-level confirms ALWAYS apply regardless of mode**: push, merge,
  publish, and destructive operations require explicit user confirmation even
  in autonomous mode.
- **Hosts without hooks** (anywhere `coding-reminder.sh` doesn't run): at task
  start, read `autonomy_mode` and `output_style` from `.claude/answers.local.env`
  if present and print the one-line banner —
  `mode: gated | output: concise — say "just go" or "explain more" to override this session`
  (`mode: autonomous | output: <style> — say "gate me" or "be brief" …` when autonomous).

## Commits

Ship small, traceable commits.

- One logical change per commit — never batch unrelated changes.
- Commit at every green point (each mini-feature / each DoD pass), via `/commit`.
- Conventional message (`type(scope): description`); the diff should be
  reviewable in one sitting.

## Micro-PR Discipline

Every PR must stay under both limits:
- **≤{{max_files_per_pr}} files changed**
- **<{{max_loc_per_pr}} lines changed**

If a feature won't fit, the `pmo` agent breaks it into sequential mini-features, each its own PR. Bigger ≠ better; smaller PRs review faster, merge cleaner, and roll back safely.

## Definition of Done

A coding task is **NOT** complete until all of these pass, in order:

1. **Format** — `{{format_cmd}}`
2. **Lint** — `{{lint_cmd}}` (zero new warnings)
3. **Unit tests** — `{{test_cmd}}` green, ≥{{test_coverage_target}}% coverage maintained
4. **Code review** — a `judge` review of the change (the main conversation spawns it); address all blockers it flags.
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

### Output style

A **personal** preference, read at session time from the gitignored
`.claude/answers.local.env` (`output_style=concise|balanced|detailed|terse`).
Absent or empty = `concise`; an unrecognized value is ignored (mode-only banner, as the hook does). Never rendered into committed files.

- **concise** (default):
  - Answer or action first.
  - Code or diff before explanation.
  - Normal grammar — readable sentences, not fragments.
  - Number only real multi-step actions.
  - ≤5 bullets unless detail is requested.
  - End with one concrete next action.
  - No preamble, filler, recap of visible output, or closing phrase.
  - Errors stated plainly, with the recovery action.
- **balanced** / **detailed** — relax *length only*; every other rule above holds.
- **terse** (opt-in) — telegraphic prose: drop articles and filler; keep negations and every technical token (paths, commands, identifiers, versions, numbers) verbatim; never invent abbreviations; no arrow chains; the revert-to-prose list below applies unchanged. Caveat: on already-short output `terse` is often net-negative versus `concise` — `concise` remains the default.
- **Prose is mandatory regardless of style** (including `terse`) for: security
  warnings; irreversible confirmations (push, merge, publish, destructive ops,
  secrets, data loss); an explicit "explain" request; real ambiguity (present
  2–4 ranked options); and any debugging loop past three turns (state what
  is known).
- **Session overrides** — "explain more" / "detailed for this session" widen,
  "be brief" tightens, for this session only. Apply immediately and **never
  write them to any file** — same rule as "just go".

### Report format

A second **personal** preference, `agent_style=terse|descriptive`, read from the same gitignored `.claude/answers.local.env`. Absent, empty, or unrecognized = `terse`. It governs only the return message a subagent hands back to the orchestrator — never human-facing output, never what the agent writes to disk. The orchestrator passes the value as one prompt line; a prompt with no line means `terse`.

- **terse** — a fixed field schema, exactly these fields in this order, no prose, ≤ ~25 lines, paths and commands verbatim:
  - `RESULT:` — one of `pass|fail|approved|changes-requested|blocked`
  - `FILES:` — `path:+n/-m`, one per file touched
  - `CHECKS:` — `name=pass|fail`, one per check run
  - `FINDINGS:` — severity + one line each (never drop a finding to fit the budget)
  - `DECISIONS:` — one line each
  - `NEXT:` — one line
- **descriptive** — the prose report; the choice for debugging the workflow or onboarding a human to it.
- **Boundary rule** — verdict and findings files under `docs/specs/*/progress/`, `spec.md`/`contract.md`, commit messages, PR bodies, and docs are always normal prose regardless of `agent_style` or `output_style`. Human-facing output follows `output_style`, never `agent_style`. The revert-to-prose list above applies to both channels.

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
