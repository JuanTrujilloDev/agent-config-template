# Setup Evolution (v0.8.x) — Spec

2026-09-01 | branch: feature/setup-evolution | stacked on v0.8.0 (cursor-grok-portability)

## Problem

Setup is interrogative and self-contradictory. `/setup-template` asks about
facts it could infer, one question at a time. `answers.env` is told to be
gitignored by `setup-template.md` step 6 while `docs/upgrade-guide.md` builds
the whole upgrade flow on it being committed — so teams don't know what config
is shared policy vs personal preference vs a one-session override. Workflow
choices that should be project policy (TDD on/off) or personal preference
(autonomy) have no home at all: `/feature` re-asks "Apply TDD?" every run, and
there is no way to say "run autonomous" once. Tool integration (a tracker MCP)
has no path except hand-editing `mcp.json`. Scope was ratified by the
maintainer after a GPT+Grok cross-check of the v0.8 roadmap; that review killed
`/onboard`, per-task autonomy prompts, setup-time MCP-registry crawling, and
default-on companions — none of those return here.

## Goal

One sentence: setup infers facts and asks only decisions (in batched frontier
rounds), every config value has exactly one documented scope (committed
`answers.env` policy, gitignored local prefs, session keywords), and the two
new decisions — `workflow_mode` and `autonomy_mode` — actually drive `/feature`
and a session-start banner, with `/integrate <tool>` covering task-time MCP
wiring.

## Success criteria (release-level, verifiable)

1. `/setup-template` against a project with clear signals (e.g. `examples/python-fastapi` fixtures) produces a full inferred profile citing source files and asks **at most one numbered frontier round** of questions, each with a recommended default; a single "accept defaults" reply completes the interview.
2. `grep -rn "answers.env" plugin/commands/setup-template.md docs/upgrade-guide.md` shows one consistent story: `answers.env` committed, `.claude/answers.local.env` gitignored; the rendered `.gitignore` block no longer lists `answers.env`.
3. Rendering with `workflow_mode=SDD+TDD` produces a `feature.md` where TDD + Gate 2 are on by default; with `workflow_mode=SDD` (or the key absent) TDD is off by default and available on request. Verified by two `setup.sh` renders + grep.
4. On Claude Code, a coding prompt with `autonomy_mode=autonomous` in `.claude/answers.local.env` gets a one-line banner (`mode: autonomous — say 'gate me' to switch`) injected by `coding-reminder.sh`; with the file absent the hook exits 0 with today's output. Verified by piping a prompt JSON through the hook.
5. Action-level confirms (push/merge/publish/destructive) are stated as mode-independent in `principles.md` and the commands that perform them — grep-verifiable.
6. `/integrate <tool>` exists in `core/.claude/commands/`, stops for explicit confirmation before writing, wires `mcp.json` + one CLAUDE.md MCP line on yes, and degrades to manual instructions offline; `scripts/build.sh --check` stays green (it rides the existing command→skill transforms).
7. `bash scripts/build.sh && python3 scripts/validate-packaging.py` green; two consecutive builds produce zero `git status` diff; CI green.

## Decisions

- **D1 — `answers.env` is committed project policy; the contradiction resolves in upgrade-guide's favor.** The upgrade flow (`setup.sh --answers ./answers.env --merge`) is only reproducible if the file is in git; step 6 of `setup-template.md` drops `answers.env` from the gitignore block and adds `.claude/answers.local.env` instead. *Alternative discarded:* keep gitignoring and invent a second committed file — a rename with no benefit.
- **D2 — Local prefs are runtime-read, not render-time placeholders.** `.claude/answers.local.env` (same KEY=VALUE grammar as `answers.env`, gitignored, next to the existing `settings.local.json` precedent) is read *at session/task time* by the hook and by command instructions. Investigated the renderer-overlay alternative (~3 lines in setup.sh to append a second answers file): rejected because it would bake personal prefs into committed rendered files — wrong scope by construction, and changing autonomy would require a re-render. setup.sh's renderer is untouched for this.
- **D3 — `workflow_mode` wires through the existing synthetic-flag mechanism.** New `template.config.yaml` variable (`SDD` | `SDD+TDD`, default `SDD`, recorded in `answers.env`); setup.sh sets `workflow_tdd=yes` when the value is `SDD+TDD` (same 3-line pattern as `ticket_tracker_plane`); `feature.md` gates its TDD/Gate-2 text with `{{#workflow_tdd}}`/`{{^workflow_tdd}}`. Absent key = `SDD` — existing projects keep a working `/feature` and can opt in per-invocation ("with TDD"). No RPI (cut at review; not relitigated).
- **D4 — Autonomy banner: hook-injected on Claude, instruction-only elsewhere.** Investigated per the ratified scope: `coding-reminder.sh` already fires on coding prompts and already emits a heredoc — reading `autonomy_mode` is one `sed -n 's/^autonomy_mode=//p'` and one extra output line, so hook injection costs ~4 lines and makes the banner deterministic. Instruction-only (CLAUDE.md/principles: "read `.claude/answers.local.env` if present; print the mode line") is kept as the degradation path for every non-Claude host — consistent with v0.8.0 D9 (coding-reminder is not ported to Cursor; the alwaysApply rule carries instructions there). Keyword overrides ("just go", "gate me", "stop before commit") are session-scoped instructions, never persisted. Action-level confirms always apply regardless of mode.
- **D5 — Default `autonomy_mode` is `gated`.** Matches today's behavior exactly (gates everywhere); `autonomous` is an explicit opt-in per user. A silent behavior change on upgrade would be the worst outcome for a defaults decision. (Flagged as open question Q2 for Gate 1 since the roadmap note is ambiguous.)
- **D6 — Companion recommendation is one question, stored locally, routed to the existing flow.** "Recommend graphify + ponytail? [Yes / Not now / Never]" joins the frontier round; the answer lands in `.claude/answers.local.env` as `companions=yes|not_now|never`. `Yes` → run the existing `/setup-companions` (which has its own confirmation gate — no double-build); `Never` suppresses the post-render mention that `setup-template.md` already makes today. No default-on install, no hard gates (ratified).
- **D7 — `/integrate <tool>` is a command file, and it replaces any setup-time registry crawl.** Hand-authored `core/.claude/commands/integrate.md`; the v0.8.0 build pipeline turns it into a cursor/codex skill for free. At invocation it uses the host's web search to find the official MCP server for the named tool; findings + install plan + explicit confirmation before any write. Offline/lookup-failure → ask the user for the package/URL or print manual wiring steps; no partial writes. Writes: `.claude/mcp.json` (seeded from `mcp.json.example` when absent — and mcp.json is already gitignored per setup-template step 6), one line in CLAUDE.md's "MCP Servers" section, and an *offer* (not a silent edit) to set `ticket_tracker` in `answers.env` when the tool is a tracker.
- **D8 — End-of-task manual verification offer is IN.** Judgment call per the maintainer's ask: it is instruction-only (three markdown files), completes the autonomy story — an `autonomous` session needs exactly one human checkpoint at the end, and this is it — and costs no new machinery: `verified_by_human: yes|no|skipped` is one field on the existing `features.json` mini-feature entry. Excluding it would leave `autonomous` mode with no closing human touchpoint in the same release that ships it.
- **D9 — Frontier rounds replace the one-question-at-a-time interview, keeping all existing machinery.** Confidence tiers (HIGH/LOW/UNKNOWN), `when:` clause gating, non-destructive render (plan → `--merge`/`--overwrite`), and just-go mode all survive verbatim. The change is interview *shape*: facts inferred and shown, only decisions asked, all currently-answerable questions in one numbered batch with recommended defaults. A second round happens only if an answer unlocks new `when:`-gated questions.
- **D10 — Micro-PR limits count hand-authored files; generated mirrors ride along** (carried from v0.8.0 D2 — every `core/` edit churns `plugin/template/`, `cursor/`, `codex/` 1:1).

## Out of scope

- `/onboard` as a new command, per-task autonomy prompts, MCP-registry crawling at setup, default-on companions (all killed at the GPT+Grok review — do not reopen).
- RPI workflow mode (cut at review); `workflow_mode` accepts exactly `SDD` | `SDD+TDD`.
- New hosts or capability-matrix expansion; new hooks; any setup.sh change beyond the D3 synthetic flag.
- Auto-installing anything `/integrate` finds without the explicit confirmation stop.
- Persisting session keyword overrides anywhere.
- A verification *gate* — D8 is an offer, recorded either way, never blocking.

## Open questions (recommended answers; not blocking)

- **Q1 — Local prefs filename.** *Recommendation (proceeding with):* `.claude/answers.local.env` — sits beside the `settings.local.json` precedent, same grammar as `answers.env`, and the `.local.` infix already means "gitignored" in this repo.
- **Q2 — Default autonomy when no local prefs exist.** *Recommendation (proceeding with, per D5):* `gated` — today's behavior; `autonomous` is opt-in. If the maintainer intended `autonomous` as the ratified default, only D5 and two lines of contract text flip.
- **Q3 — Version number.** Release train is "v0.8.x", so *recommendation:* `0.8.1` across `plugin.json` + `marketplace.json` + codex manifest, bumped in MF6 only (same rationale as v0.8.0 Q2).
- **Q4 — Should the banner also fire on Cursor via `beforeSubmitPrompt`?** *Recommendation:* no for this release — v0.8.0 D9 deliberately kept coding-reminder off Cursor; the instruction-only path covers it. Revisit if users report the instruction being ignored.
- **Q5 — Where does `/integrate` record a non-tracker tool?** *Recommendation:* mcp.json + CLAUDE.md line only; `answers.env` is touched only for the `ticket_tracker` offer. Adding an `integrations=` key to answers.env is YAGNI until a re-render needs to reproduce MCP wiring.

## Design notes

Per-mini-feature notes live in `contract.md` next to each block. Shared:

- **No design pattern anywhere in this release.** Every change is markdown instructions, a 3-line synthetic flag, or a 4-line hook read — single call sites throughout (no pattern — YAGNI).
- **Leverage (release-wide):** the mustache renderer, synthetic-flag mechanism, confidence tiers, non-destructive modes, `coding-reminder.sh` heredoc, `/setup-companions` flow, `mcp.json.example`, `features.json` schema, and the v0.8.0 build/drift pipeline all exist — every mini-feature extends one of them; nothing new is built except two markdown files (`integrate.md` and the docs section).
