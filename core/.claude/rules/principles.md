# Operating Principles — {{project_name}}

> Always loaded. Non-negotiable for every coding task. When a request conflicts with one, say so and ask.

## 1. Think Before Coding

Restate the goal in one sentence and list 2–4 verifiable success criteria. State assumptions; ask when a request has more than one valid reading, and name the tradeoffs.

## 2. Simplicity First (YAGNI)

Write the minimum code for the stated problem: nothing speculative, no option without a caller, three similar lines before a premature abstraction. Before writing, stop at the first rung that holds:

1. Does it need to exist at all?
2. Is it already in this codebase? (`.claude/rules/code-query.md`)
3. Standard library, then a native platform feature, then an installed dependency.
4. Only then, the minimum new code.

Before adding a pattern or abstraction, name the force present today or refuse (`.claude/rules/patterns.md`). Security, validation, error handling and accessibility are never rungs to skip.

## 3. Surgical Changes

Touch only what the task needs: no adjacent refactors, no reformatting, no cleanup of code you did not break. Match the file's style. Remove only what your own change orphaned.

## 4. Goal-Driven Execution

Work as `[step] → verify: [check]` and loop until every criterion passes. Features run `/epic` → `/slice` → `tests-first` → `implement` → `code-review` (see `.claude/HELP.md`); a small change with an obvious cause uses `/fix`.

Approved tests are locked. Once the user approves a slice's tests, never edit them to go green; if one must change, stop and ask. The `agent-enforcement` hook blocks edits to the paths under `## Approved tests` in the slice file (override: `AGENT_CONFIG_UNLOCK_TESTS=1`).

## Read Before You Write

Read the target file end to end and check its callers before editing (graph first, grep second). For a non-trivial change, state the current behaviour and who depends on it before the diff. "Just go" skips that narration, never the reading.

## Code Health

- DRY by the rule of three: extract on the third copy, not the second.
- Functions well under ~40 lines; split a file past ~400 lines or one that mixes responsibilities.
- Dependencies point one way (no import cycles, no "misc" modules). Comments explain why; no commented-out code, no banners.

## Commits

One logical change per commit, at every green point, via `/commit`. Conventional message: `type(scope): description`.

## Micro-PR Discipline

One slice per PR and one layer per slice (db → be → fe, stacked per capability group). Aim for 200–400 non-test lines. Hard cap: ≤{{max_files_per_pr}} files and <{{max_loc_per_pr}} lines changed; a slice that would exceed it is split, never shipped over the cap.

## Definition of Done

Not done until each step passes, in order. Paste the command and its output; a step not run means the task is open.

1. Format: `{{format_cmd}}`
2. Lint: `{{lint_cmd}}`, zero new warnings
3. Tests: `{{test_cmd}}` green, ≥{{test_coverage_target}}% coverage
4. Review: `code-review` (Standards and Spec axes); one fix round for its blockers
5. Security: `security-reviewer` when the change touches auth, permissions, data exposure or input boundaries
{{#has_e2e}}
6. Browser: for changes under `{{frontend_dir}}` or over 5 files / 500 lines, walk the success criteria with `mcp__playwright__*`
{{/has_e2e}}

## Conciseness

Lead with the answer or the action. No filler, no preamble, no recap of output already visible. Lists for 3+ items, tables only to compare, code blocks only for code or terminal output.

### Output style

Personal preference `output_style=concise|balanced|detailed|terse` in the gitignored `.claude/answers.local.env`; absent or unknown = `concise`. `balanced` and `detailed` relax length only. `terse` drops articles and filler but keeps every path, command, identifier and number verbatim. Write full prose regardless of style for security warnings, irreversible confirmations, an explicit "explain", real ambiguity (2–4 ranked options) and any debugging loop past three turns. "Explain more" and "be brief" apply to this session only.

## Autonomy Mode

Personal preference `autonomy_mode=gated|autonomous` in the same file; absent = `gated`. Never rendered into committed files.

- `gated`: show the diff and wait before each commit. `autonomous`: commit without pausing.
- "just go" and "gate me" switch this session only; never write them to a file. Push, merge, publish and destructive operations always need explicit confirmation.
- At task start print one line: `mode: <gated|autonomous> | output: <style> — say "just go"/"gate me" or "explain more"/"be brief" to override this session`.

## Branch Discipline

Never code on `{{default_branch}}`; check the branch before the first edit. Slices use `feature/<ID>-<group>-<layer>`{{#branch_prefix}} (ID like `{{branch_prefix}}-87`){{/branch_prefix}}; other work uses `fix/<slug>`, `hotfix/<slug>` (from `{{default_branch}}`), `refactor/<slug>`, `chore/<slug>` or `docs/<slug>`.
