# Cursor/Grok Portability Foundation (v0.8.0) — Spec

2026-09-01 | branch: feature/cursor-grok-portability

## Problem

The template's operating system (principles, rules, hooks, commands, agents) only
fully works on Claude Code. Teams driving Cursor (with Grok/GPT models) or Grok
Build get a degraded, undocumented experience. Worse, the one existing port —
`codex/` — is hand-maintained and `codex/SYNC_NOTE.md` admits CI does not check
its drift: the cautionary tale for adding more surfaces. Every new host added
without generation multiplies silent-drift risk.

## Goal

One sentence: every packaging surface (`plugin/`, `codex/`, new `cursor/`) is
generated from `core/` by `scripts/build.sh`, drift-checked in CI, and documented
per host — with `core/` content reworded to be model-agnostic so non-Claude models
behave equivalently.

## Success criteria (release-level)

1. `scripts/build.sh --check` exits 1 on any hand-edit to `codex/skills/` or `cursor/`; CI runs it (existing `plugin-mirror` job, no new job needed).
2. `bash scripts/build.sh` twice in a row produces zero `git status` diff (deterministic generation) and emits a complete `cursor/` target (AGENTS.md, `.cursor/rules/*.mdc`, `.cursor/hooks.json`, `.cursor/mcp.json`, cursor skills, generated `.claude/agents` + `.claude/rules` copies).
3. `python3 scripts/validate-packaging.py` validates the cursor tree (mdc frontmatter, JSON files, skill frontmatter) and fails on a seeded breakage.
4. A rendered target — for any supported `--host` combination — contains zero unrendered `{{placeholders}}` and, per host, exactly one hook surface: Claude events only in `.claude/settings.json`, Cursor events only in `.cursor/hooks.json`, no event registered twice within either surface. An unsupported `--host` value exits non-zero pointing at the `port-config` skill.
5. `grep -riE 'claude (will|should|can)|ask claude' core/.claude/{rules,agents,commands}` returns only host-mechanics references (paths, tool names, the product name "Claude Code" naming the host).
6. `docs/install/cursor.md`, `docs/install/grok.md`, and the host capability matrix exist and CI is green.

## Decisions

- **D1 — Generate `codex/`, don't just drift-check it.** A drift check against a hand-maintained tree can only verify what generation would verify anyway (the SYNC_NOTE derivation rules are already algorithmic: copy skill + add `name:`, command→skill frontmatter reduction, append role-adaptation note). The 3 codex-specific content deltas (`setup-companions` codex commands, orchestrator hat-switching notes in `sdd-workflow` and `feature`) become small checked-in override sources. Generation makes `--check` exact (plain `diff -r`, same as `plugin/template`) instead of a fuzzy rules-checker that itself needs maintenance. *Alternative discarded:* CI-only drift check — cheaper today, but it either re-implements the derivation rules (a second generator) or degrades to structural existence checks that miss content drift.
- **D2 — Micro-PR limits count source files; generated mirrors are excluded.** Precedent: every `core/` edit already churns `plugin/template/` 1:1; counting mirrors would make any core change violate the limit. `features.json` limits below refer to hand-authored files; regenerated output rides along.
- **D3 — `cursor/` is self-contained.** It ships its own *generated* copies of `core/.claude/agents/` (Cursor reads them natively) and `core/.claude/rules/` (the pointer `.mdc` targets them), plus AGENTS.md and the `.cursor/` tree — and ships **no** `.claude/settings.json` hooks block. This structurally prevents the Claude+Cursor hook double-fire instead of policing it: a cursor render never contains a Claude hook registration. *Alternative discarded:* overlay render (core minus hooks plus `.cursor/`) — needs settings.json surgery in setup.sh, not trivially cheap.
- **D4 — setup.sh gains a host-aware `--host <list>` flag** *(amended at Gate 1; supersedes the single-host draft)*. Comma-separated values from the supported static targets: `claude` (default — byte-identical to today's behavior when absent), `cursor`, `codex`. `grok` is an accepted alias that renders the claude tree plus AGENTS.md (Grok Build reads `.claude` natively; the templated AGENTS.md source already exists in `hosts/cursor/`, so the alias is cheap). Unsupported hosts (opencode, gemini, windsurf, …) exit non-zero with a message naming the supported set and pointing to the `port-config` skill — no packagings for them this release. Each host maps to a source tree via the same switch setup.sh already uses to auto-detect `core/` vs `template/`; multi-host is a loop over the existing single-tree renderer. Files emitted by more than one selected host (cursor's generated `.claude/agents` + `.claude/rules` copies vs the claude tree) are byte-identical by construction — the renderer treats a differing collision as a build error.
- **D5 — Branch hard-block on Cursor maps to `beforeShellExecution`.** Cursor has no native pre-edit gate; the nearest equivalents are `beforeShellExecution` denying mutating git commands (`commit`, `push`) on a protected branch, plus `afterFileEdit` advisory. This is a documented capability gap in the matrix, not something to fake.
- **D6 — Cursor commands→skills keep subagent references.** Unlike the codex port (no subagents → role-adaptation notes), Cursor reads `.claude/agents/` natively (verified fact), so `/spec`, `/feature` etc. keep spawning language; frontmatter becomes `name` + `description` + `disable-model-invocation: true` (Cursor is deprecating plain commands in favor of skills).
- **D7 — Per-host semantic smoke test (run /spec, /feature end-to-end) is deferred.** It requires live model invocations per host — paid, slow, flaky in CI — disproportionate for a packaging release. Static validation + render smoke covers everything that breaks an install. Revisit under the (out-of-scope) eval-harness item.
- **D8 — The alwaysApply principles rule points, never duplicates.** `<200` words, references `@.claude/rules/principles.md`. A rewrite would be a second copy of the most-maintained file in the repo.
- **D9 — `coding-reminder.sh` is not ported to Cursor.** Its job (inject principles on coding prompts) is covered by the `alwaysApply: true` principles rule, which Cursor injects on every prompt anyway. Porting it via `beforeSubmitPrompt` would double the reminder. YAGNI.
- **D10 — Grok Build gets docs only, no packaging tree.** Verified: Grok Build auto-discovers the whole `.claude` tree, AGENTS.md and CLAUDE.md; `grok inspect` verifies. Ratified in scope. The `--host grok` alias (D4) is a render shortcut, not a packaging tree.
- **D11 — Install is host-aware** *(Gate-1 amendment)*. `template.config.yaml` gains a multi-value `target_hosts` variable (default `claude`); the chosen set is recorded in `answers.env` as `TARGET_HOSTS` so re-renders stay consistent — an explicit `--host` on the CLI overrides it. `/setup-template`'s interview gains exactly ONE multi-select question over the supported hosts, with an inferred default: `claude` included by default, plus `cursor` when `.cursor/` exists in the target, plus `codex` when Codex project config exists (user may deselect any). Projects get only the config trees for the hosts they actually use. Existing `examples/*/answers.env` files are untouched — absence of `TARGET_HOSTS` means the `claude` default. The broader onboarding redesign stays out of scope (v0.8.x); this is a wording change to the existing command file.

## Out of scope (v0.8.x+)

Onboarding changes (sole exception: the single host question in /setup-template,
per D11), /integrate, autonomy modes, companions default-on, FR/SC grammar,
review-pipeline changes, brand/design tokens, RPI, eval harness, packagings for
hosts beyond claude/cursor/codex (opencode, gemini, windsurf → `port-config`
skill), and the per-host end-to-end semantic smoke test (D7).

## Open questions (recommendations chosen; not blocking)

- **Q1 — Where do hand-authored host sources live?** (cursor AGENTS.md distillation, principles-pointer.mdc, codex override files, hook adapters.) *Recommendation (proceeding with):* a top-level `hosts/` dir — `hosts/cursor/`, `hosts/codex/` — inputs only; `cursor/` and `codex/` remain pure build outputs. Mirrors the existing `core/ → plugin/template/` source/output split.
- **Q2 — Version bump mechanics.** v0.8.0 across `plugin.json` + `marketplace.json` (+ codex manifest). *Recommendation:* bump in the final mini-feature (MF6) so intermediate merges to the feature branch don't claim the release version.
- **Q3 — Should `auto-format.sh` port to Cursor `afterFileEdit`?** *Recommendation:* yes, via a thin adapter that maps Cursor's payload to the file path and reuses the existing script logic; if the payload mapping turns out unstable, ship branch-guard only and note it in the matrix.
- **Q4 — What does `--host codex` render into a project?** Codex installs the packaging as a plugin, not a project tree (docs/install/codex.md). *Recommendation (proceeding with):* render AGENTS.md plus the generated `codex/skills/` into the target's project-local Codex skill-discovery path (verify the exact path at implementation); if Codex has no project-local skill discovery, fallback: render AGENTS.md only and print the plugin-install commands from docs/install/codex.md.

## Design notes

Per-mini-feature notes live in `contract.md` next to each block; the shared ones:

- **No pattern anywhere except MF1/MF3 generators:** the build steps are a *pipeline of pure file transforms* inside the existing `build.sh` — not a Strategy/Factory; single call site each, bash functions suffice (no pattern — YAGNI).
- **Hook adapters (MF4) are Adapters in the honest sense:** Cursor's JSON-over-stdio payload differs from Claude's hook schema; a thin per-hook wrapper maps payload → existing script expectations. Named because it is exactly the pattern's problem: same logic, incompatible interface, two real hosts today.
- **Leverage (release-wide):** `build.sh` exists — extended, not replaced. `validate-packaging.py` exists — extended (its `parse_frontmatter` already handles the mdc case modulo the delimiter-free `.mdc` variant). CI `plugin-mirror` and `render-smoke` jobs exist — the first needs zero change, the second one new loop iteration. Hook logic reused via adapters, not rewritten. `setup.sh`'s renderer already substitutes placeholders in arbitrary trees — cursor files get templating for free, and multi-host (D4/D11) is a loop over that same renderer plus one more answers.env variable through the existing parser.
