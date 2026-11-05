# Adaptive Skills (v0.8.2) — Contract

Rules for every mini-feature (implicit scenarios, checked by `judge`):
edit canonical sources only (`core/`, `plugin/{agents,commands,skills,hooks}`,
`hosts/`, `scripts/`, `setup.sh`, `template.config.yaml`, `docs/`); regenerate
with `bash scripts/build.sh`; `bash scripts/build.sh --check` and
`python3 scripts/validate-packaging.py` green; two consecutive builds → empty
`git status --porcelain`; renders for `--host claude`, `cursor`, `grok`, `codex`
(each against `examples/node-nextjs/answers.env` and `examples/python-fastapi/answers.env`)
contain zero `{{`…`}}` and zero `<!-- requires` leftovers; all frontmatter
strict YAML; all JSON parses; hand-authored files ≤12 / <3000 LOC (mirrors
excluded); `judge` review per MF; `security-reviewer` for MF1 and MF7.

Test harness: `scripts/smoke.sh` (created in MF1, extended in MF7) renders
`examples/*` into `mktemp -d` and asserts the scenarios below marked **(smoke)**.
Scenarios marked **(human)** are recorded via `verified_by_human` in `features.json`.

## MF1 — output-style  (@s1..@s9)

Design notes: no pattern — one more `sed`/`case` read in an existing hook; a
subsection in an existing principle. Leverage: `coding-reminder.sh` autonomy
read, `principles.md` Conciseness, CLAUDE.md Autonomy bullet, `plugin/hooks/`
and `plugin/skills/principles` hand-authored mirrors.

- @s1 **(smoke)** Given a rendered project with no `.claude/answers.local.env`, When `{"prompt":"fix the login redirect"}` is piped to `.claude/hooks/coding-reminder.sh`, Then line 1 is exactly `mode: gated | output: concise — say "just go" or "explain more" to override this session` and the exit code is 0.
- @s2 **(smoke)** Given `.claude/answers.local.env` = `autonomy_mode=autonomous` + `output_style=detailed`, When the same prompt is piped, Then line 1 is `mode: autonomous | output: detailed — say "gate me" or "be brief" to override this session`; Given `output_style=terse`, Then the token reads `output: terse` (the `case` recognizes all four values).
- @s3 **(smoke)** Given `output_style=verbose` (unrecognized), When piped, Then line 1 equals the v0.8.1 banner `mode: gated — say 'just go' for autonomous` and no value from the file appears in the output (`grep -c verbose` = 0).
- @s4 **(smoke)** Given `{"prompt":"what is a closure?"}` (non-coding), When piped, Then output is empty and exit 0 (hook trigger unchanged).
- @s5 Given `core/.claude/rules/principles.md`, Then the Conciseness section contains an "Output style" subsection defining `concise` with each of: answer/action first; code or diff before explanation; normal grammar; number only real multi-step actions; ≤5 bullets unless detail requested; one concrete next action; no preamble/filler/recap/closing phrase; errors stated plainly with recovery action — and states `balanced`/`detailed` relax length only.
- @s6 Given the same section, Then it states that full prose is mandatory regardless of style for security warnings, irreversible confirmations (push/merge/publish/destructive), explicit "explain" requests, ambiguity (2–4 ranked options), and a debugging loop past three turns; and that session phrases ("explain more", "be brief") are never persisted.
- @s7 Given `core/CLAUDE.md` and `hosts/cursor/principles.mdc`, Then the hosts-without-hooks fallback reads both `autonomy_mode` and `output_style` and prints the one-line banner of @s1; `grep -rn verbosity template.config.yaml plugin/commands/setup-template.md` returns nothing and `output_style` appears in both scope tables.
- @s8 Given `core/.claude/rules/principles.md`, Then Simplicity First contains one senior-engineer overcomplication test line and Goal-Driven Execution shows the `[step] → verify: [check]` shape; `plugin/skills/principles/SKILL.md` carries the same additions (diff limited to placeholder lines).
- @s9 Given `plugin/hooks/coding-reminder.sh`, When @s1–@s4 are run against it with `CLAUDE_PROJECT_DIR` set, Then results are identical to the core hook.

## MF8 — agent-style  (@s58..@s66) — runs second, after MF1

Design notes: no pattern — one subsection in an existing principle, one line
in two orchestrator files, two scope-table rows. Leverage: MF1's "Output
style" subsection (extended with `terse`); `/feature` step 2 and
`orchestrator.md` steps 5–8 already pass scenarios and Design notes to each
subagent (the `agent_style:` line goes beside them); the
`.claude/answers.local.env` key convention; the `plugin/skills/principles`
mirror. No hook change (D3/D16), so judge only.

- @s58 Given `core/.claude/rules/principles.md` Output style subsection, Then it defines `terse` (opt-in) as: telegraphic prose — drop articles and filler; keep negations and every technical token (paths, commands, identifiers, versions, numbers) verbatim; never invent abbreviations; no arrow chains; the @s6 revert-to-prose list applies unchanged — and states the caveat that `terse` is often net-negative versus `concise` on already-short output and that `concise` remains the default.
- @s59 Given the same file, Then a "Report format" subsection states `agent_style=terse|descriptive` is read from `.claude/answers.local.env`; absent, empty, or unrecognized = `terse`; it governs only the return message a subagent sends to the orchestrator — never human-facing output, never what the agent writes to disk.
- @s60 Given the same subsection, Then the `terse` schema lists exactly, in order, `RESULT:` (values `pass|fail|approved|changes-requested|blocked`), `FILES:` (`path:+n/-m`), `CHECKS:` (`name=pass|fail`), `FINDINGS:` (severity + one line each), `DECISIONS:` (one line each), `NEXT:` (one line); no prose; ≤ ~25 lines; paths and commands verbatim — and `descriptive` = the prose report, named as the choice for debugging the workflow or onboarding a human.
- @s61 Given the same subsection, Then the boundary rule states that verdict/findings files under `docs/specs/*/progress/`, `spec.md`/`contract.md`, commit messages, PR bodies, and docs are always normal prose regardless of `agent_style` or `output_style`, and that human-facing output follows `output_style`, never `agent_style` (`grep -c 'docs/specs/\*/progress' core/.claude/rules/principles.md` ≥ 1).
- @s62 Given `core/.claude/commands/feature.md` step 2 and `core/.claude/agents/orchestrator.md` steps 5–8, Then both say: read `agent_style` from `.claude/answers.local.env` once per run (absent = `terse`) and include one line `agent_style: <terse|descriptive> — return per "Report format" in .claude/rules/principles.md` in every subagent prompt (pmo, dev agents, ui-designer, judge, security-reviewer, mutation-tester).
- @s63 Given `core/.claude/hooks/coding-reminder.sh` and `plugin/hooks/coding-reminder.sh`, Then neither mentions `agent_style` (`grep -c agent_style` = 0 on both) and the @s1/@s2 banner lines are unchanged.
- @s64 Given `template.config.yaml` (local-prefs comment) and `plugin/commands/setup-template.md` (scopes table + local-prefs bullet), Then `agent_style` is listed beside `output_style` as a personal pref — `.claude/answers.local.env` only, never rendered, not asked in the frontier round.
- @s65 Given `plugin/skills/principles/SKILL.md`, `plugin/commands/feature.md`, `plugin/agents/orchestrator.md`, Then they carry the same additions with skill-style references; `diff` against the core file differs only on placeholder/path lines; `bash scripts/build.sh --check` green.
- @s66 **(human, restraint/quality)** Given `agent_style=terse` and a diff touching three files with two findings (one Blocker, one Suggestion), When `judge` runs via `/feature`, Then its return message follows the @s60 schema in ≤25 lines and carries all three paths and both severities (nothing dropped), while the verdict file it writes under `docs/specs/<slug>/progress/` is prose (`grep -c '^RESULT:' <verdict file>` = 0).

## MF2 — patterns-rule  (@s10..@s17)

Design notes: no pattern — static rule text + two `cp` lines in `build.sh`.
Leverage: `code-query` rule/skill dual; `build_cursor_tree` agents/rules copy;
`build_codex_skills` loop; `stage_tree` (codex `.agents/skills` render carries
`references/` for free).

- @s10 Given `core/.claude/rules/patterns.md`, Then it is ≤120 lines and contains, in order: inspect existing project patterns first (`.claude/rules/code-query.md`); name the present force before selecting; one-line why; refusal wording `no pattern — single call site`; a default-reject list naming single-implementation Strategy, speculative Repository, unnecessary Factory, Singleton, Service Locator; the ledger format `pattern / force / rejected alternative`; a six-row domain table (backend/API/persistence, frontend/UI/state, mobile, Unity/game, desktop, concurrency/distributed) each linking `.claude/patterns/<domain>.md`.
- @s11 Given `core/.claude/patterns/`, Then exactly six files exist matching the table, each ≤150 lines, each with a "Simplest default first" list (plain function/dict/enum/constructor injection before the pattern) and a force→pattern table; none contains `{{`.
- @s12 Given `plugin/skills/patterns/SKILL.md`, Then it has strict-YAML frontmatter with a `description`, the same rules as @s10 with skill-style references (`the \`code-query\` skill`), and points at `${CLAUDE_PLUGIN_ROOT}/template/.claude/patterns/` and `references/` for the domain files.
- @s13 Given `bash scripts/build.sh`, Then `cursor/.claude/patterns/` equals `core/.claude/patterns/`, `cursor/.claude/rules/patterns.md` exists, `codex/skills/patterns/SKILL.md` exists with `name: patterns`, and `codex/skills/patterns/references/` equals `core/.claude/patterns/`; `--check` flags a hand-edit to any of them.
- @s14 Given `setup.sh --host claude` (and `grok`, `cursor`), Then the target contains `.claude/rules/patterns.md` and `.claude/patterns/*.md` (six); Given `--host codex`, Then `.agents/skills/patterns/SKILL.md` and `.agents/skills/patterns/references/*.md` (six) exist.
- @s15 Given `python3 scripts/validate-packaging.py`, Then it passes and fails when `plugin/skills/patterns/SKILL.md`'s description is made unquoted-invalid YAML (seeded breakage, reverted).
- @s16 Given `README.md` and `plugin/README.md`, Then the skills list counts seven and names `patterns`.
- @s17 **(human, restraint)** Given a brief "add a single CSV export endpoint for orders", When `/spec` runs with the rule loaded, Then Design notes read `no pattern — single call site` and no pattern name appears.

## MF3 — pattern-ledger-integration  (@s18..@s24)

Design notes: no pattern — checklist lines in existing agent/command files.
Leverage: `principles.md` Design Patterns section; pmo Design notes; judge
checklist; `/verify` step 1.

- @s18 Given `core/.claude/rules/principles.md` Design Patterns section, Then it points at `.claude/rules/patterns.md` and states the four hard rules (inspect first; name the force; one-line why; refusal valid) and the default-reject list in one line each.
- @s19 Given `core/.claude/agents/pmo.md`, Then Design notes require a ledger line `pattern / force / rejected alternative` for every named pattern and the literal refusal `no pattern — single call site` otherwise; the Gotchas keep "Pattern cargo-culting".
- @s20 Given `core/.claude/agents/judge.md`, Then the Traceability checklist has a line: ledger present for each pattern used; flag pattern-stuffing (pattern without a stated force, or a default-reject-list pattern with no written justification — amended at mf3 review) as a Blocker; and the Minimalist lens names the default-reject list.
- @s21 Given `core/.claude/commands/verify.md` step 1, Then it asks for each new abstraction whether it has a ledger entry and whether the simplest default (`.claude/rules/patterns.md`) was tried first.
- @s22 Given `plugin/agents/{pmo,judge}.md`, `plugin/commands/verify.md`, `plugin/skills/principles/SKILL.md`, Then they carry the same additions with skill-style references; `diff` against the core file differs only on placeholder/path lines.
- @s23 **(human, restraint)** Given a brief with three real, present payment providers, When `/spec` runs, Then Design notes name one pattern with a force and a rejected alternative (plain `if`/dict) and nothing else.
- @s24 **(human, restraint)** Given a diff that wraps one call site in a `*Strategy` class with a single implementation, When `judge` reviews it, Then the verdict lists it under Blockers citing pattern-stuffing.

## MF4 — brand-system  (@s25..@s32)

Design notes: no pattern — one templated markdown file + read-before-act
lines. Leverage: `stage_tree` + `<!-- requires: has_ui -->`; `/design` step 2
already points at `docs/design-system/`; `build_cursor_tree` copy lines.

- @s25 Given `core/docs/design-system/MASTER.md`, Then line 1 is `<!-- requires: has_ui -->` and the body has exactly these H2 sections in order: Colors & semantic tokens; Typography; Spacing & layout; Radius, shadows & motion; Component conventions; Icon & image style; Voice & tone; Responsive rules; Accessibility & contrast; Anti-patterns — plus a "Page overrides" note pointing at `docs/design-system/pages/<page>.md` (create only when a page must deviate).
- @s26 **(smoke)** Given `setup.sh` with `has_frontend=yes` (`examples/node-nextjs`), Then `docs/design-system/MASTER.md` exists in the target with zero `{{` and ≥1 `TODO:` marker; Given `examples/python-fastapi` (`has_frontend=no`, `project_type` web), Then the file is absent.
- @s27 Given `setup.sh --host cursor` with `has_frontend=yes`, Then `docs/design-system/MASTER.md` exists (build copies `core/docs` into `cursor/`).
- @s28 Given `core/.claude/agents/{ui-designer,frontend-dev,mobile-dev}.md`, Then each has a line before its Design/implementation step: read `docs/design-system/MASTER.md` (and `pages/<page>.md` if present) and cite the tokens used; `frontend-dev`'s inline-styles gotcha references MASTER.md.
- @s29 Given `core/.claude/agents/judge.md`, Then the checklist has a UI line: for diffs under `{{frontend_dir}}`/UI files, no hardcoded color, spacing, radius, or font value outside `docs/design-system/MASTER.md`; report `file:line` for each.
- @s30 Given `core/.claude/commands/design.md`, Then step 2 reads MASTER.md, creates it from the @s25 section list when missing, and when ui-ux-pro-max is installed may delegate generation and then normalize to those sections; the file states ui-ux-pro-max is optional and never vendored.
- @s31 Given `plugin/agents/{ui-designer,frontend-dev,mobile-dev,judge}.md` and `plugin/commands/design.md`, Then the same additions are present (placeholder-free).
- @s32 Given `bash scripts/build.sh --check` after the above, Then it is green and `cursor/docs/design-system/MASTER.md` equals the core source.

## MF5 — workflow-vocabulary  (@s33..@s39)

Design notes: no pattern — sentences in existing files. Leverage: pmo CONVERSE
step, `/fix` step 1, `/spec` step 1, `docs/sdd-workflow.md` artifact table,
`hosts/codex/skills/sdd-workflow` override.

- @s33 Given `core/.claude/agents/pmo.md`, Then CONVERSE states intent (user-observable change) before implementation talk; brownfield work surveys touched modules via `.claude/rules/code-query.md` and "the spec defines the change, not a retro-spec of the system".
- @s34 Given `core/.claude/agents/pmo.md`, Then it reads `docs/CONTEXT.md` at CONVERSE when present and creates it lazily on the first coined/disambiguated project term; entry format `**Term** — what it IS (1–2 sentences). Avoid: <synonyms>`; project terms only; the file is never rendered by `setup.sh` (`grep -rl CONTEXT.md core/ | grep -v agents/pmo.md` is empty).
- @s35 Given `core/.claude/commands/fix.md`, Then step 1 requires a red-capable reproduction (failing test or command that goes green only when fixed) before naming the cause; no repro in one step → switch to `/feature`; 2–4 ranked falsifiable hypotheses only when the repro does not point at one; one variable at a time.
- @s36 Given `docs/sdd-workflow.md`, Then the artifact table lists `docs/CONTEXT.md` (pmo, lazily created) and a "Skill taxonomy" note: commands user-invoked (`disable-model-invocation: true` on cursor), rules/skills model-invoked; commands may suggest another command to the user but never instruct the model to invoke one.
- @s37 Given `core/.claude/commands/feature.md` and `docs/upgrade-guide.md`, Then both state a template upgrade (`setup.sh --merge`) is its own `chore:` commit, never mixed into a feature PR.
- @s38 Given `plugin/agents/pmo.md`, `plugin/commands/{fix,spec,feature}.md`, `plugin/skills/sdd-workflow/SKILL.md`, `hosts/codex/skills/sdd-workflow/SKILL.md`, Then the same additions are present; `build.sh --check` green.
- @s39 **(human)** Given `/fix "button does nothing"` with no reproduction available, When run, Then the model stops and asks for a repro or redirects to `/feature` instead of proposing a cause.

## MF6 — companions  (@s40..@s47)

Design notes: no pattern — one frontier item reworded, one entry in an
existing gated flow (D0: internal-first; caveman has no install option). Leverage: item 4 + step 8 of `setup-template.md`;
`/setup-companions` detect → plan → gate; `companions=` key.

- @s40 Given `plugin/commands/setup-template.md`, Then the frontier round still numbers companions as item 4 and there are no new numbered items; item 4 lists three groups: core quality (graphify + ponytail), output (native `concise`, on by default — nothing to install), UI (ui-ux-pro-max, shown only when `has_ui`); recommended answer stays `Not now`.
- @s41 Given the same file, Then the `companions` grammar is `yes|not_now|never|<comma list>`: `yes` = all recommended; a list installs only those and records the rest as skipped by omission (not re-recommended); `not_now` re-asks next run; `never` suppresses all mention; the key stays in `.claude/answers.local.env` only.
- @s42 Given `plugin/commands/setup-companions.md`, Then it accepts an optional list argument, detects ui-ux-pro-max as already-installed, and the plan prints for each tool: exact install command (from the upstream README), source, and what is written; caveman does not appear anywhere in the file (`grep -ci caveman` = 0); nothing installs before an explicit yes.
- @s43 Given `hosts/codex/skills/setup-companions/SKILL.md`, Then it carries the same ui-ux-pro-max entry with codex commands; `build.sh --check` green.
- @s44 Given `core/.claude/agents/orchestrator.md` and `plugin/agents/orchestrator.md`, Then one line says ponytail's ruleset applies to dev subagents when `PONYTAIL_SUBAGENT_MATCHER` matches `dev`, when installed.
- @s45 Given `README.md`, `plugin/README.md`, `docs/upgrade-guide.md`, Then companions documentation names the three tools (graphify, ponytail, ui-ux-pro-max), marks ui-ux-pro-max as `has_ui`-only, does not mention caveman, and shows the list grammar; no text claims Plane or any tracker is required (`grep -n "require.*Plane"` empty).
- @s46 Given a `has_ui` falsy render context, When the frontier round is composed, Then ui-ux-pro-max does not appear in item 4.
- @s47 Given `.claude/answers.local.env` with `companions=graphify,ponytail`, When `/setup-template` runs again, Then item 4 is not re-asked and ui-ux-pro-max is not mentioned.

## MF7 — merge-reporting + release  (@s48..@s57)

Design notes: no pattern — labels in `print_plan()`, one flag, one branch in
merge. Leverage: `classify()`, `print_plan()`, `relink_claude_md()`,
`warn_dual_claude_md()`, existing `--mode` parsing, `scripts/smoke.sh`, CI
`render-smoke`. Bash 3.2 + python3 stdlib only.

- @s48 **(smoke)** Given a fixture target with a rendered `.claude/` tree where `.claude/agents/backend-dev.md` was altered and `.claude/CLAUDE.md` is a regular file beside root `CLAUDE.md`, When `setup.sh --target F --answers A` runs (no mode), Then the plan shows `STALE-MANAGED .claude/agents/backend-dev.md`, `SYMLINK-CONFLICT .claude/CLAUDE.md`, `CUSTOMIZED CLAUDE.md` (with the keep hint), exits 1, and writes nothing (`find F -newer marker` empty).
- @s49 **(smoke)** Given the same plan, Then it ends with one line `--merge --overwrite-files .claude/agents/backend-dev.md[,…]` listing every STALE-MANAGED path and no CUSTOMIZED path.
- @s50 **(smoke)** Given `--merge --overwrite-files .claude/agents/backend-dev.md`, Then that file equals the staged render, every other DIFFERS file is byte-unchanged, and the summary counts `1 overwritten`.
- @s51 **(smoke)** Given `--merge --overwrite-files .claude/CLAUDE.md`, Then `.claude/CLAUDE.md` becomes a symlink to `../CLAUDE.md` and root `CLAUDE.md` is byte-unchanged.
- @s52 **(smoke)** Given `--overwrite-files` with an unknown path, or combined with `--overwrite`/no mode, Then exit non-zero with a one-line error and nothing written.
- @s53 Given `bash -n setup.sh` and `grep -c 'declare -A' setup.sh` = 0, Then bash 3.2 compatibility holds; `python3 -c "import ast; ast.parse(open('setup.sh').read().split('PYEOF')[1])"` parses.
- @s54 Given `docs/upgrade-guide.md`, Then an "Upgrading to v0.8.2" section covers `output_style` (four values, `terse` caveat), `agent_style` (default `terse`; boundary rule), `companions` list grammar, the three plan labels, `--overwrite-files`, and the portfolio-style resolution: keep root `CLAUDE.md` conventions; regenerate STALE-MANAGED agents via the printed line; diff then convert `.claude/CLAUDE.md` to the symlink; tooling upgrade as its own `chore:` commit.
- @s55 Given `.github/workflows/ci.yml`, Then `render-smoke` renders `--host grok` and `--host codex` in addition to claude and cursor and runs `bash scripts/smoke.sh`.
- @s56 Given `setup.sh --help`, Then it documents `--overwrite-files`.
- @s57 Given `plugin/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `codex/.codex-plugin/plugin.json`, Then all read `0.8.2` and `validate-packaging.py` reports `packaging valid @ v0.8.2`.
