# Multi-host migration plan (v0.5.0)

**Status:** proposed — awaiting Juan's approval (no tree changes yet)
**Goal:** one repo, installable with one line on **Claude Code, Codex, OpenCode, and Antigravity**, with the README split per service — and the two-template confusion gone.

---

## 0. Verdict (researched, 2026)

There is **no universal `/plugin install`** across hosts — each has its own mechanism. But one repo *can* serve all four installers simultaneously; multi-host skill repos already do this. The per-host story:

| Host | Install (one line) | Mechanism | What they get |
|---|---|---|---|
| Claude Code | `/plugin marketplace add <owner>/<repo>` → `/plugin install` | Native plugin (exists today) | Everything: agents, commands, skills, hooks, orchestration |
| Codex | **Native plugin**: add our marketplace once (`~/.agents/plugins/marketplace.json`), then install from Codex's plugin directory UI | `.codex-plugin/plugin.json` + marketplace JSON catalog — directly parallel to Claude's format. Official Plugin Directory self-serve publishing is "coming soon" (submit on day one). Quick path: `npx skills add <owner>/<repo>` | Rules + skills + bundled MCP config (principles, SDD flow, spec/fix/verify, security audit) |
| OpenCode | `npx skills add <owner>/<repo>` (skills) or `setup.sh --host opencode` rendering straight into `.opencode/` | **Markdown is the package**: skills/agents/commands under `.opencode/` + `AGENTS.md`. (OpenCode "plugins" proper are JS event-hook modules — a different mechanism, useful for hook parity; see limits below) | Rules + skills + agents/commands as markdown; optional hook enforcement via a tiny npm plugin (fast-follow) |
| Antigravity / Gemini | `gemini extensions install https://github.com/<owner>/<repo>` | **Native** extension — requires `gemini-extension.json` + `GEMINI.md` | Rules + context + commands via the extension |

The shared substrates that make this work: **`AGENTS.md`** (cross-tool rules standard, Linux Foundation) and the **`SKILL.md`** format (near-identical across Claude/Codex/OpenCode). Codex's plugin system (per [developers.openai.com/codex/plugins/build](https://developers.openai.com/codex/plugins/build)) mirrors Claude's almost field-for-field — manifest + skills dir + marketplace catalog — so for Codex this is one more *packaging* of the same content, not a different paradigm.

**Honest limits (go in the README):** at 0.5.0, Claude Code keeps the richest experience — sub-agent orchestration (orchestrator/judge spawning) and the enforcement hooks ship there only; other hosts get the rules + skills layer, with hook *intent* (protected branches, format-in-DoD) expressed in `AGENTS.md` as guidance. But hook **enforcement is portable per host as a fast-follow**, not impossible: OpenCode's plugin API exposes `tool.execute.before` (its docs' own `.env`-protection example is exactly our branch-block shape — a small npm plugin gets parity, one-line install via `opencode.json`), and Codex has a native hooks system of its own. Sub-agent orchestration parity is the genuinely hard part.

---

## 1. Rename

Install strings bake the repo name in — rename **before** publishing multi-host docs. GitHub redirects keep old clones/installs working; the Claude marketplace entry should be re-added by existing users (one-line upgrade note).

**Shortlist:**

| Name | For | Against |
|---|---|---|
| **`agent-config-template`** *(recommended)* | Host-neutral; says exactly what it is; clean successor (swap `claude`→`agent`); good search terms | A bit long; "template" undersells the workflow |
| **`sdd-harness`** | Leads with the methodology; punchy | Crowded namespace (`harness-sdd`, `cc-sdd` exist); SDD is jargon to newcomers |
| **`agent-harness`** | Broad, memorable, room to grow | Generic; weaker SEO; likely name collisions |
| **`spec-driven-agents`** | Describes the actual differentiator | Long; reads like a topic, not a tool |

(Avoid `spec-kit` — taken by GitHub's own SDD project.)

Mechanics: GitHub rename (auto-redirect) → update `marketplace.json` name/strings, `plugin.json` homepage/repo, README/docs install strings, LinkedIn announcement.

---

## 2. Target layout

Everything installable is **generated from one source** and committed (all four installers consume the repo straight from GitHub, so generated trees must be in-repo — same model as today's `plugin/`, now CI-guarded everywhere).

```
<repo>/
├── README.md                  # install matrix + per-host quick starts (see §6)
├── AGENTS.md                  # cross-tool rules: principles + workflow + branch discipline
├── core/                      # ★ SINGLE SOURCE OF TRUTH (parameterized markdown)
│   ├── rules/                 # principles, backend-style, frontend-style
│   ├── workflow/sdd-workflow.md
│   ├── agents/                # orchestrator, pmo, judge, *-dev, ui-designer, security-reviewer, mutation-tester
│   ├── skills+commands/       # spec, feature, fix, verify, audit, commit, pr (portable bodies)
│   ├── hooks/                 # Claude-only (agent-enforcement, auto-format, coding-reminder)
│   └── template.config.yaml
├── skills/                    # GENERATED: standard SKILL.md tree → `npx skills add` quick path (Codex + OpenCode)
├── plugin/                    # GENERATED: Claude Code plugin (incl. its bundled template, as today)
├── .claude-plugin/marketplace.json
├── codex/                     # GENERATED: native Codex plugin (.codex-plugin/plugin.json + skills/ + .mcp.json)
├── .agents/plugins/marketplace.json   # Codex marketplace catalog (points at ./codex)
├── gemini-extension.json      # Antigravity/Gemini extension manifest
├── GEMINI.md                  # GENERATED from core rules
├── scripts/build.sh           # core → {plugin, skills, GEMINI.md, AGENTS.md} ; --check for CI (replaces sync-plugin.sh)
├── setup.sh                   # clone-and-render path, reads core/ (unchanged behavior, incl. non-destructive merge)
├── examples/  docs/  tools/  .github/workflows/ci.yml
```

**This kills the two-template confusion:** root `template/` disappears (its content becomes `core/`); `plugin/template/` remains only as a *generated, CI-guarded* output. One place to edit, ever.

---

## 3. Per-host packaging details

- **Claude Code (M1):** unchanged behavior. `plugin/` becomes a build output of `core/`; `scripts/build.sh --check` extends today's drift guard to every generated tree.
- **Codex (M2):** generate a **native Codex plugin** — `codex/.codex-plugin/plugin.json` + bundled `skills/` (+ `.mcp.json` if relevant) — exposed via a marketplace catalog at `.agents/plugins/marketplace.json`. Install today: clone/copy + one-time entry in `~/.agents/plugins/marketplace.json`, then install from Codex's plugin directory UI. Submit to the official Plugin Directory the moment self-serve publishing opens (currently "coming soon"). Validate with a real local install.
- **OpenCode (M2):** markdown *is* the package — render skills/agents/commands into `.opencode/` via `setup.sh --host opencode`, with `AGENTS.md` carrying the rules. OpenCode "plugins" proper are **JS event-hook modules** (npm or `.opencode/plugins/`) — not needed for content, but the vehicle for hook parity later (see §8).
- **Codex + OpenCode quick path (M2):** also generate a root `skills/` tree — one `SKILL.md` dir per portable capability (`principles`, `sdd-workflow`, `spec`, `fix`, `verify`, `security-audit`, `backend-style`, `frontend-style`) — installable with `npx skills add <owner>/<repo>` (the CLI detects both hosts). Validate with a dry run.
- **Antigravity (M3):** add `gemini-extension.json` (manifest: name, version, context file, commands, optional MCP servers — confirm the current schema against Google's docs at build time; the Gemini CLI → Antigravity CLI transition lands June 18, 2026) + generated `GEMINI.md`. Validate with a real `gemini extensions install` from a test clone.
- **Everyone (M4):** `AGENTS.md` at root — principles, SDD workflow summary, branch discipline, DoD — the portable rules layer every host reads.

---

## 4. Migration phases

| Phase | What | Ships as |
|---|---|---|
| **M1** | Restructure: `template/` → `core/`; `setup.sh` reads `core/`; `build.sh` generates `plugin/`; CI drift guard updated. Claude users unaffected. | internal (or 0.5.0-rc) |
| **M2** | Native Codex plugin (`codex/` + `.agents/plugins/marketplace.json`) **and** root `skills/` for the `npx skills add` quick path (Codex + OpenCode); verify both with real installs. | 0.5.0 |
| **M3** | `gemini-extension.json` + `GEMINI.md`; verify `gemini extensions install`. | 0.5.0 |
| **M4** | `AGENTS.md`; README rewrite with install matrix + per-host sections; `docs/install/<host>.md`. | 0.5.0 |
| **M5** | Rename repo; update marketplace/plugin manifests + install strings; tag `v0.5.0`; announce (upgrade note for existing Claude users). | release |

Verification per phase: build.sh --check green; render smoke (all 4 examples) green; per-host install tested for M2/M3 (real CLI runs); no leftover placeholders.

---

## 5. Renderer & CI changes

- `setup.sh`: path change only (`core/` instead of `template/`); the non-destructive merge logic is untouched.
- `scripts/build.sh`: supersedes `sync-plugin.sh` — generates `plugin/` (Claude), `codex/` + `.agents/plugins/marketplace.json` (Codex), `skills/` (quick path), `GEMINI.md`, and `AGENTS.md` from core; `--check` mode for CI.
- CI: drift check across all generated trees + existing render smoke. Optional later: a job that runs `npx skills add` against the repo in CI.

---

## 6. README structure (split per service)

1. Hero + one-paragraph pitch + **install matrix** (the table from §0).
2. **Per-host sections** — `## Claude Code`, `## Codex`, `## OpenCode`, `## Antigravity`: install one-liner, what you get *on this host*, 3-line quick start.
3. The SDD workflow (shared) + the honest capability matrix (what's Claude-only).
4. Calibration (`/setup-template` / `setup.sh`), examples, credits, license.
Long-form per host lives in `docs/install/<host>.md`.

---

## 7. Risks & open questions

- **`skills` CLI conventions** — exact discovery/IDE routing verified by dry run in M2 (docs are thin; the tool is the spec).
- **Codex official Plugin Directory** — self-serve publishing is "coming soon"; until it opens, the Codex native install is clone + one-time marketplace entry rather than a remote one-liner. Submit on day one; README states this honestly.
- **Antigravity transition (June 18, 2026)** — extension mechanism carries over from Gemini CLI, but schema details may shift; M3 validates against live docs.
- **Marketplace identity after rename** — existing Claude users re-add the marketplace once; document in upgrade guide.
- **Version skew** — one version string propagated to all manifests by `build.sh` (single source in `core/`).
- **Scope creep risk** — M2–M4 ship the *portable layer only*. Per-host hook/orchestration emulation is explicitly out of scope for 0.5.0.

## 8. Out of scope (0.5.0)

- Hook enforcement outside Claude Code — 0.5.0 ships `AGENTS.md` guidance only. **Fast-follow (0.5.x):** OpenCode parity via a small npm plugin on `tool.execute.before` (hard-block protected-branch edits; one-line install through `opencode.json`), and Codex parity via its native hooks system.
- Sub-agent orchestration parity on Codex/OpenCode/Antigravity (the genuinely hard gap).
- Publishing to per-host registries/marketplaces beyond GitHub (e.g. skills.sh listing, Gemini extensions gallery) — fast follow.
