# Setup Evolution (v0.8.x) — Contract

Each scenario is verifiable by rendering with `setup.sh`, piping JSON through a
hook, or grepping the named file. "Rendered" = output of
`setup.sh --target <tmp> --answers <file>`.

## 1. config-scopes-workflow-mode (@s1..@s6)

- @s1 Given `answers.env` with `workflow_mode=SDD+TDD`, When `setup.sh` renders, Then the rendered `.claude/commands/feature.md` states TDD is on by default and Gate 2 (test approval) applies per mini-feature.
- @s2 Given `answers.env` with `workflow_mode=SDD` **or with the key absent**, When rendered, Then `feature.md` states TDD is off by default and available on request ("with TDD") — back-compat for every existing `answers.env`.
- @s3 Given `template.config.yaml`, Then it defines `workflow_mode` (choices `SDD`, `SDD+TDD`, default `SDD`) and its header comments document the three scopes: committed `answers.env` (project policy: workflow_mode, TARGET_HOSTS, limits), gitignored `.claude/answers.local.env` (personal: autonomy_mode, verbosity, companions), session keywords (never persisted).
- @s4 Given `plugin/commands/setup-template.md` step 6 and `docs/upgrade-guide.md`, Then both say `answers.env` is committed; the gitignore block lists `.claude/answers.local.env` and does NOT list `answers.env`.
- @s5 Given `setup.sh`, Then the only change is the synthetic flag (`workflow_tdd=yes` when `workflow_mode` is `SDD+TDD`), following the existing `ticket_tracker_plane` pattern; two consecutive renders with identical inputs produce byte-identical output.
- @s6 Given `docs/sdd-workflow.md`, Then it names `workflow_mode` as the source of the TDD default (one paragraph, no flow change).

**Design notes:** no pattern — a 3-line flag synthesis at a single call site.
**Leverage:** setup.sh already synthesizes `ticket_tracker_*`/`is_*` flags (lines 210–247); `{{#flag}}` sections already exist in feature.md; the KEY=VALUE parser needs zero change.

## 2. autonomy-mode (@s7..@s12)

- @s7 Given `.claude/answers.local.env` with `autonomy_mode=autonomous`, When a coding prompt goes through `coding-reminder.sh` on Claude Code, Then the injected reminder contains exactly one banner line: `mode: autonomous — say 'gate me' to switch`.
- @s8 Given `autonomy_mode=gated` or no local prefs file, When the hook runs, Then output shows the gated banner (or, with no file, today's output plus nothing broken — hook exits 0; default is `gated` per D5/Q2).
- @s9 Given a session where the user says "just go" (or "gate me" / "stop before commit"), Then instructions in `principles.md` direct the agent to treat the keyword as a session-scoped override of the stored mode and never write it to any file.
- @s10 Given `autonomous` mode, Then `principles.md` and the commands that push/merge/publish state that action-level confirms (push, merge, publish, destructive ops) ALWAYS apply regardless of mode — grep-verifiable wording.
- @s11 Given a non-Claude host (no hooks), Then `principles.md`/CLAUDE.md carry the instruction-only fallback: read `.claude/answers.local.env` if present and print the mode banner at task start — works everywhere per the host capability matrix.
- @s12 Given a local prefs file with an unrecognized `autonomy_mode` value, When the hook runs, Then it exits 0 with no banner and no error output; an unreadable or garbled file (indistinguishable from an absent key) falls back to the gated banner, still exit 0, no error output (never blocks a prompt). *(Amended at mf2 review per judge ruling — gated default governs indistinguishable states.)*

**Design notes:** no pattern — one `sed` read + one heredoc line in an existing hook; the rest is instructions.
**Leverage:** `coding-reminder.sh` already fires on coding prompts with a heredoc to append to; `sed -n 's/^autonomy_mode=//p'` matches how setup.sh reads `TARGET_HOSTS`; v0.8.0 D9 already settled that Cursor gets instruction-only.

## 3. zero-question-setup (@s13..@s18)

- @s13 Given a project with clear signals (a `package.json` or `pyproject.toml`, test config, existing branches), When `/setup-template` runs, Then it shows the full inferred profile — every placeholder with value, confidence tier, and cited source file — and asks nothing about inferable facts.
- @s14 Given unresolved or consequential ambiguity remains, Then ALL currently-answerable questions arrive in ONE numbered frontier round, each with a recommended default, and a single reply ("all defaults" or "1: X, 3: Y") resolves the round; a second round occurs only when an answer unlocks new `when:`-gated questions.
- @s15 Given the frontier round, Then decisions asked include `workflow_mode`, `autonomy_mode`, target hosts (existing question, folded into the round), and the companion question "Recommend graphify + ponytail? [Yes / Not now / Never]" — and facts (stack, dirs, commands) are never in the round.
- @s16 Given answers, Then project policy (`workflow_mode`, `TARGET_HOSTS`, …) is written to `answers.env` and personal prefs (`autonomy_mode`, `companions`) to `.claude/answers.local.env`; `Yes` on companions routes to the existing `/setup-companions` flow after render; `Never` suppresses the post-render companions mention.
- @s17 Given a target with an existing config, Then the non-destructive machinery is unchanged: plan first (writes nothing, exit 1), then `--merge`/`--overwrite`; confidence tiers and just-go/`--auto` mode still work as documented.
- @s18 Given the rewritten `setup-template.md`, Then hard rules survive: no invented values (UNKNOWN + one targeted question), explicit approval before `setup.sh`, `when:` clauses honored (unsatisfied = variable doesn't exist).

**Design notes:** no pattern — a markdown rewrite of one command file; the interview shape changes, the machinery does not.
**Leverage:** confidence tiers, `when:` gating, non-destructive modes, `--auto`, and the TARGET_HOSTS question all exist in today's file — the rewrite reorders and batches them rather than inventing a flow.

## 4. integrate-command (@s19..@s23)

- @s19 Given `/integrate linear`, When invoked, Then the command searches for the official/canonical MCP server for the named tool, presents findings (source, package, what it writes) plus an install plan, and STOPS for explicit confirmation — zero writes before "yes".
- @s20 Given confirmation, Then it writes the server entry into `.claude/mcp.json` (seeding from `.claude/mcp.json.example` when absent), appends one line to CLAUDE.md's "MCP Servers" section, and — only when the tool is a ticket tracker — OFFERS to update `ticket_tracker` in `answers.env` (never silently edits it).
- @s21 Given the lookup fails (offline, no results), Then it degrades gracefully: asks the user for a package/URL or prints manual wiring steps, and exits without partial writes.
- @s22 Given the user declines the plan, Then nothing was written (mcp.json, CLAUDE.md, answers.env all untouched).
- @s23 Given `scripts/build.sh` runs, Then `integrate.md` appears in `plugin/commands/` and as cursor/codex skills via the existing transforms, and `--check` + `validate-packaging.py` stay green with no hand edits to generated trees.

**Design notes:** no pattern — a single linear flow in one command file; per-tool variation is data (the search result), not code branches.
**Leverage:** host web search does the lookup (no bundled registry to rot — the exact failure the review killed at setup time); `mcp.json.example` provides the seed structure; CLAUDE.md already has the "MCP Servers" section as an anchor; the v0.8.0 command→skill pipeline ships it to all hosts for free.

## 5. human-verification-offer (@s24..@s26)

- @s24 Given a mini-feature passes the Definition of Done under `/feature`, Then the flow offers exactly one project-type-matched manual check (browser walk for web, run the CLI/app for library-cli/desktop, simulator for mobile, artifact/screenshot otherwise) — an offer, never a gate.
- @s25 Given the user verifies, declines, or is absent, Then the mini-feature's entry in `features.json` records `verified_by_human: yes|no|skipped` (skipped when the offer gets no answer or the user says skip).
- @s26 Given `/fix` completes its Definition of Done, Then the same one-line offer applies, recorded the same way when a features.json entry exists (freeform fixes without one just get the offer).

**Design notes:** no pattern — instruction text in three markdown files plus one optional JSON field.
**Leverage:** the DoD checklist is the natural anchor (the offer is step "6.5"); `features.json` already tracks per-mini-feature state — one more key, no schema machinery; project type is already known via `project_type`/`primary_dev_agent` placeholders.

## 6. release-docs-version (@s27..@s29)

- @s27 Given the release, Then the version (recommended `0.8.1`, Q3) is bumped in `plugin.json`, `marketplace.json`, and the codex manifest in this mini-feature only.
- @s28 Given `docs/upgrade-guide.md`, Then a new "Upgrading to v0.8.x (setup evolution)" section covers: `answers.env` explicitly committed (and how to un-gitignore it), the new `.claude/answers.local.env`, the `workflow_mode` key (absent = SDD), `autonomy_mode`, and `/integrate` — with the standard "add keys, re-render with `--merge`" migration.
- @s29 Given `bash scripts/build.sh` twice then `python3 scripts/validate-packaging.py`, Then zero `git status` diff between builds, validation green, CI green.

**Design notes:** no pattern — version strings + one docs section.
**Leverage:** the upgrade-guide section format is established (v0.4–v0.6 sections); build/validate/CI pipeline from v0.8.0 needs zero change.
