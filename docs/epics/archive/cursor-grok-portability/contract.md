# Cursor/Grok Portability — Executable Contract

Scenario tags are global (@s1..@s24; @s22–@s24 added by the Gate-1 host-aware
install amendment). "Rendered cursor target" = output of
`setup.sh --host cursor --target <dir> --answers <example>.env`.

## 1. codex-drift-elimination  (@s1..@s4)

- @s1 Given a clean checkout, When `bash scripts/build.sh` runs twice, Then `codex/skills/` is regenerated from `plugin/skills/` + `plugin/commands/` per the derivation rules (skill: add `name:`; command: frontmatter reduced to `name` + quoted `description`; subagent-spawning workflow skills get the role-adaptation note appended) And the second run leaves `git status --porcelain` empty.
- @s2 Given a hand edit to any file under `codex/skills/` (or a `plugin/skills/` edit without rebuild), When `bash scripts/build.sh --check` runs, Then it exits 1 and prints a `DRIFT:` line naming the codex tree.
- @s3 Given the codex-specific content deltas (setup-companions `codex plugin`/`--platform codex` commands; hat-switching notes in `sdd-workflow` and `feature`), When `build.sh` runs, Then that content comes from checked-in sources under `hosts/codex/` — `git grep` finds no content in `codex/skills/` that lacks a source in `plugin/` or `hosts/codex/`.
- @s4 Given the existing CI `plugin-mirror` job (unchanged), When a PR introduces codex drift, Then the job fails — verifiable locally by seeding drift and running `bash scripts/build.sh --check; test $? -eq 1`.

**Design notes:** no pattern — a generation function in `build.sh` beside the
existing plugin copy block; overrides are plain files appended/substituted, not a
templating engine. `codex/SYNC_NOTE.md` is rewritten to "generated — edit
plugin/ or hosts/codex/". **Leverage:** the derivation rules already written in
SYNC_NOTE become the code; `--check` reuses the existing `diff -r` idiom;
`.agents/plugins/marketplace.json` and `codex/assets/` are untouched (not
derivable — they stay sources).

## 2. model-agnostic-phrasing  (@s5..@s6)

- @s5 Given the pass is complete, When grepping `core/CLAUDE.md` and `core/.claude/{rules,agents,commands}` for Claude-as-actor idioms (model self-reference, "Claude will/should", "ask Claude", "Claude Code expands" phrased as a universal), Then none remain — surviving matches are only host mechanics: `.claude/` paths, `mcp__*` tool names, "Claude Code" where it factually names the Claude Code host (e.g. the Dynamic Context section gains a "Claude Code only" qualifier rather than deletion).
- @s6 Given the reworded files, When `bash scripts/build.sh && bash scripts/build.sh --check && python3 scripts/validate-packaging.py` runs, Then all pass And the core diff is reword-only: file set, headings, and placeholder set unchanged (`git diff --stat` shows no added/deleted files; `grep -o '{{[^}]*}}' | sort -u` identical before/after).

**Design notes:** no pattern — surgical text edits. Ordered before the cursor
target so generated cursor content is born model-agnostic instead of churning
twice. **Leverage:** nothing new to build; the grep in @s5 doubles as the review
tool.

## 3. cursor-static-target  (@s7..@s10)

- @s7 Given `bash scripts/build.sh` runs, Then `cursor/` contains: `AGENTS.md` (distilled from `core/CLAUDE.md`, still `{{templated}}`, sourced from `hosts/cursor/`); `.cursor/rules/principles.mdc` with `alwaysApply: true`, body under 200 words, pointing at `@.claude/rules/principles.md`; `.cursor/rules/backend-style.mdc` and `frontend-style.mdc` whose bodies are the `core/.claude/rules/*` content and whose `globs` derive from `{{src_dir}}`/`{{frontend_dir}}`; `.cursor/mcp.json` derived from `core/.claude/mcp.json.example`; and generated copies of `core/.claude/agents/` and `core/.claude/rules/`.
- @s8 Given an edit to `core/.claude/rules/backend-style.md` without rebuilding, When `bash scripts/build.sh --check` runs, Then it exits 1 with a `DRIFT:` line naming `cursor/`.
- @s9 Given every generated `.mdc` file, When its frontmatter is parsed as YAML, Then it parses And uses only the keys `description`, `globs`, `alwaysApply`.
- @s10 Given the `cursor/` tree, When searched for Claude hook registrations, Then no `.claude/settings.json` `hooks` block exists anywhere under `cursor/` (double-fire prevented structurally, per D3).

**Design notes:** no pattern — three more copy/transform steps in the same
`build.sh` pipeline; the mdc transform is "prepend frontmatter to an existing
body". **Leverage:** rule bodies, agents, and mcp config are byte-reused from
`core/`; only `AGENTS.md` and `principles.mdc` are new hand-authored sources
(in `hosts/cursor/`), and both are pointers/distillations, not rewrites.

## 4. cursor-hooks-and-skills  (@s11..@s14)

- @s11 Given `bash scripts/build.sh` runs, Then `cursor/.cursor/hooks.json` exists, is valid JSON, registers ONLY native Cursor events (`beforeShellExecution`, `afterFileEdit`; no Claude event names), and every referenced script exists in the generated tree with `bash -n` passing.
- @s12 Given a rendered cursor target checked out on `{{default_branch}}`, When the branch-guard adapter receives a `beforeShellExecution` payload whose command is `git commit`/`git push`, Then it responds `{"permission":"deny"}` with the typed-branch guidance; And on a `feature/*` branch the same payload is allowed. (Nearest native equivalent of the Claude pre-edit hard block — gap documented in the matrix, per D5.)
- @s13 Given a rendered cursor target, When the format adapter receives an `afterFileEdit` payload for a `.py` file, Then it invokes the same targeted-autofix logic as `core/.claude/hooks/auto-format.sh` (ruff `--fix` path) and never blocks.
- @s14 Given each `core/.claude/commands/<c>.md`, When `build.sh` runs, Then `cursor/.claude/skills/<c>/SKILL.md` exists with frontmatter `name: <c>`, a quoted `description`, and `disable-model-invocation: true`, And the body preserves the command content including subagent references (per D6).
**Design notes:** **Adapter** pattern for the two hook wrappers — same guard/format
logic, incompatible payload schema, two real hosts today (the one pattern in this
release that earns its name). `coding-reminder.sh` deliberately not ported (D9).
**Leverage:** branch-list parsing and autofix dispatch reused from the existing
hook scripts (source them or extract the shared function — implementer's call
within surgical limits).

## 5. host-aware-install  (@s15, @s22..@s24)

- @s15 Given `setup.sh --target <tmp> --answers examples/<x>/answers.env` with no `--host` and no `TARGET_HOSTS` in the answers file, When it completes, Then the output is byte-identical to today's claude render; And `--host grok` renders the claude tree plus rendered AGENTS.md (D4 alias); And `--host codex` renders AGENTS.md plus the generated codex skills per the Q4 mapping; And `--host opencode` (or any unsupported value) exits non-zero naming the supported set (`claude`, `cursor`, `codex`, alias `grok`) and pointing to the `port-config` skill.
- @s22 Given `setup.sh --host claude,cursor --target <tmp> --answers examples/<x>/answers.env`, When it completes, Then the target contains both host trees with zero `{{...}}` leftovers, `.claude/settings.json` hooks register only Claude event names, `.cursor/hooks.json` registers only Cursor event names, no event is registered twice within either surface (D3 invariant extended: per rendered target, exactly one hook surface per host), And any file emitted by more than one selected host is byte-identical (a differing collision aborts the render with an error).
- @s23 Given an `answers.env` containing `TARGET_HOSTS=claude,cursor`, When `setup.sh` runs without `--host`, Then exactly that host set renders (re-renders stay consistent); And `setup.sh --host codex` with the same answers file renders codex only (explicit flag overrides the recorded value); And `template.config.yaml` documents `target_hosts` as multi-value with default `claude`.
- @s24 Given `plugin/commands/setup-template.md`, When read, Then its interview contains exactly one multi-select host question over the supported targets, with the inferred default rule stated (`claude` included by default; `cursor` added when `.cursor/` exists in the target; `codex` added when Codex project config exists), And the drafted `answers.env` records the choice as `TARGET_HOSTS` — And the change to the command file is wording-only (no new steps, no flow restructure; onboarding redesign stays v0.8.x).

**Design notes:** no pattern — a host→source-tree mapping (bash `case`) inside
setup.sh's existing source-dir switch, and multi-host as a loop over the existing
single-tree renderer; single call site (no pattern — YAGNI). **Leverage:**
renderer, placeholder substitution, and answers.env parsing all exist —
`TARGET_HOSTS` is one more variable through the same parser; `examples/*/answers.env`
untouched (absent variable = `claude` default); the AGENTS.md source for the
`grok` alias is the `hosts/cursor/` file MF3 already ships.

## 6. portability-docs  (@s16..@s18)

- @s16 Given `docs/install/cursor.md`, When read, Then it leads with "Skills and agents: zero porting. Rules, hooks, commands: generated", documents the render flow (`setup.sh --host cursor`), notes that Cursor ignores agent `tools:` frontmatter and that read-only agents (judge, security-reviewer, ui-designer) should be treated as `readonly: true`, and states the branch hard-block gap (@s12 semantics).
- @s17 Given `docs/install/grok.md`, When read, Then it documents that Grok Build discovers the rendered `.claude` tree, AGENTS.md and CLAUDE.md natively, shows `grok inspect` as the verification step, documents `setup.sh --host grok` as the render shortcut (claude tree + AGENTS.md, per D4), and the repo contains no `grok/` packaging tree.
- @s18 Given `docs/install/host-capability-matrix.md`, When read, Then it is a table over hosts {Claude Code, Codex, Cursor, Grok Build, AGENTS.md-only} × capabilities {subagents, hooks, branch hard-block, MCP, skills discovery, commands/skills invocation}, with per-cell native/generated/gap status matching @s4/@s11/@s12/@s17.

**Design notes:** no pattern — prose. **Leverage:** matrix rows cite the verified
facts from the release brief and the shipped scenarios; `docs/install/` already
exists (claude.md, codex.md) — same structure, plus a one-line pointer from
README.

## 7. packaging-validation-ci  (@s19..@s21)

- @s19 Given `python3 scripts/validate-packaging.py`, When run on a clean build, Then it additionally validates: every `cursor/.cursor/rules/*.mdc` frontmatter (YAML, `description` present, key whitelist), `cursor/.cursor/hooks.json` + `mcp.json` parse as JSON, every `cursor/.claude/skills/*/SKILL.md` has `name`/`description`/`disable-model-invocation: true`, and every `codex/skills/*/SKILL.md` has `name` + `description` — and exits 0.
- @s20 Given a seeded breakage (unquoted `: ` in an `.mdc` description, or invalid `hooks.json`), When the validator runs, Then it exits 1 naming the exact file.
- @s21 Given `.github/workflows/ci.yml`, When the render-smoke job runs, Then it also renders the cursor target for one example answers file and applies the existing checks (no leftover placeholders, hooks `bash -n`); And manifests (plugin.json, marketplace.json, codex manifest) agree on version `0.8.0` (existing version-skew check extended to codex).

**Design notes:** no pattern — new checks appended to the existing linear script.
**Leverage:** `parse_frontmatter` and `walk_components` in
`validate-packaging.py` already do 90% of @s19 (mdc = same frontmatter block);
the ci.yml render-smoke loop gains one iteration, and the drift job needs zero
change (covered by MF1/MF3's `--check`).
