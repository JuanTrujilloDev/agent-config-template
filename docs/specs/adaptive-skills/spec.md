# Adaptive Skills (v0.8.2) — Spec

2026-09-02 | branch: feature/v0.8.2-adaptive-skills | stacked on v0.8.1 (setup-evolution) | mode: SDD+TDD, gated

## Problem

Five gaps, all visible in the `portfolio` regression fixture and in day-to-day use:

1. **Output is one-size.** The Conciseness principle says "be brief" but has no
   observable shape (what goes first, when to number, when prose is *required*),
   and no personal knob — a user who wants explanations has to ask every turn.
2. **Design-pattern guidance is a paragraph.** `principles.md` says "only when
   warranted"; pmo writes a Design-notes line; nobody has a force→pattern
   routing table or a default-reject list, and judge has nothing concrete to
   check, so pattern-stuffing (one-implementation Strategy, speculative
   Repository) slips through.
3. **UI projects have no brand contract.** `frontend-dev` warns against
   off-token styles but there is no committed token source; `/design` points
   at a `docs/design-system/` that the template never creates.
4. **`--merge` hides staleness.** In `portfolio`, `--merge` kept Jan-2026
   `backend-dev.md`/`frontend-dev.md`/`ui-designer.md` (no Design notes, no
   judge/security handoff, no browser verification) and reported them as
   "kept as-is"; `.claude/CLAUDE.md` is an old regular file where a fresh render
   makes a symlink — the plan says nothing about either.
5. **Subagent reports are prose aimed at nobody.** judge, security-reviewer,
   the dev agents and pmo return free-form reports to the main conversation;
   the orchestrator only needs verdict, files, checks, findings, next step.
   The prose costs context every hand-off and there is no knob to switch it.

Plus: companion recommendations cover only two tools, and upstream skills
(caveman, i-have-adhd, code-design-patterns, ui-ux-pro-max, spec-kit,
mattpocock) hold ideas worth adapting without vendoring.

## Goal

One sentence: a personal `output_style` (with an opt-in `terse`), a personal
`agent_style` for subagent return messages, a `patterns` rule with restraint
tests, a rendered brand master for UI projects, a lazily-created glossary and
diagnosis gate, a grouped companions question, and a `--merge` plan that names
stale/conflicting files with exact per-file overwrite commands — all from
canonical sources, regenerated, byte-stable across hosts.

## Success criteria (release-level, verifiable)

1. Rendered `coding-reminder.sh` prints exactly one banner line
   `mode: gated | output: concise — say "just go" or "explain more" to override this session`
   with no `.claude/answers.local.env`; `output_style=detailed` flips the token;
   an unrecognized value falls back to the v0.8.1 mode-only line. Verified by
   `scripts/smoke.sh` (pipes prompt JSON through the rendered hook).
2. `.claude/rules/patterns.md` renders on `claude`, `grok`, `cursor`;
   `patterns` skill exists in `plugin/skills/` and `codex/skills/` with
   `references/` for six domains; `grep -c "no pattern —" core/.claude/rules/patterns.md ≥ 1`.
3. A `has_ui=yes` render contains `docs/design-system/MASTER.md` with all ten
   required sections and zero `{{}}`; a `has_ui` falsy render does not contain it.
4. `setup.sh --merge` plan against a fixture (stale managed agent + regular
   `.claude/CLAUDE.md`) prints `STALE-MANAGED`, `SYMLINK-CONFLICT`, and a
   copy-pasteable `--overwrite-files` line; `--merge --overwrite-files <a>`
   overwrites only `<a>`. Verified by `scripts/smoke.sh`.
5. `/setup-template` frontier round still has exactly one companions item
   (item 4); `companions=` accepts `yes|not_now|never|<list>`.
6. `bash scripts/build.sh --check`, `python3 scripts/validate-packaging.py`,
   render smoke for `claude,cursor,grok,codex`, and two consecutive builds with
   zero `git status` diff — all green; CI green.
7. `core/.claude/rules/principles.md` has a "Report format" subsection naming
   the six fields `RESULT/FILES/CHECKS/FINDINGS/DECISIONS/NEXT` and the
   boundary rule (`docs/specs/*/progress` verdict files always prose);
   `grep -c agent_style core/.claude/hooks/coding-reminder.sh` = 0 (banner
   untouched); `/feature` and `orchestrator.md` pass `agent_style:` in every
   subagent prompt.

## Upstream adopt / adapt / reject

Source: `scratchpad/upstream-research-2026-09-01.md` (2026-09-01). Original
wording throughout; nothing is copied or vendored.

| Repo | Distinct value | Overlap with template | License | Maint. cost | Decision |
|---|---|---|---|---|---|
| caveman v2.4.0 | 6-level output compression; revert-to-prose rule for security warnings / irreversible confirms / multi-step; "terse in chat, prose in artifacts" boundary; agent-to-agent telegraphic reports | Conciseness principle already covers "no filler"; compression beyond that is net-negative on our already-terse flows (+1–1.5k input tokens/turn self-reported) | MIT skill; **BSL-1.1** engine/proxy; telemetry ON by default in proxy | High (proxy), low (skill text) | **Adapt** internally: revert-to-prose (D2); opt-in `terse` user style (one level, not six — D1); `terse` agent-report schema + artifact boundary rule (D16/D17). Compression levels, engine and proxy **rejected**; **no install option** — never vendor/auto-install, never enable telemetry |
| i-have-adhd 0.2.0 | Action-first: next action first, number multi-step, cap lists at 5, one closing action, matter-of-fact errors, no preamble/recap; break conditions (explain request, destructive ahead, debug spiral, ambiguity → 2–4 ranked options) | Partial — Conciseness has "lead with the answer" only | MIT | Low | **Adapt** rules 1,2,3,8,9,10 + break conditions as the `concise` definition — the default `output_style`; no medical framing |
| andrej-karpathy-skills 1.0.0 | Same four principles; adds "would a senior engineer call this overcomplicated?" and `[step] → verify: [check]` plan shape | ~95% — our Think/Simplicity/Surgical/Goal-Driven | Claimed MIT, **no LICENSE file**, stale since 2026-04 | Very low but compliance gap | **Reject** as dependency; **import 2 lines** (senior-engineer test → Simplicity First; step→check → Goal-Driven) |
| code-design-patterns v1.1.0 | Force→pattern routing; "no pattern without a force"; simplest-defaults (functions > Strategy, dicts > Factory, ctor injection > DI container, enums > State); required rejected alternative; ledger; smell tier (Singleton, Service Locator, Anemic model) | Our Design Patterns paragraph + pmo gotcha | MIT | Low; single-author risk | **Adapt** restraint rules + ledger + per-domain references, our wording, our rungs |
| ui-ux-pro-max v2.15.0 | Local design DB; `MASTER.md` + `pages/*.md` overrides schema; sections Colors/Typography/Effects/Motion/Avoid/Checklist | None in template today | MIT | High to vendor (257 files/9.9 MB); low as optional shell-out | **Adapt** the MASTER + page-overrides schema; **optional** companion (has_ui only — the local design DB cannot be replicated internally, D0); `/design` may delegate generation when installed; never vendored |
| spec-kit v1.0.3 | Tooling upgrades separate from feature artifacts; brownfield "spec defines the change, not a retro-spec"; intent before implementation | Our SDD flow covers spec/contract/gates | MIT | High as dep, low as concepts | **Adapt** three sentences (pmo, /feature, upgrade guide); reject the managed-files manifest (our `--overwrite-files` + plan labels cover the need) |
| mattpocock/skills v1.2.3 | CONTEXT.md glossary ("what it IS", project terms only, lazily created); diagnosis gates (no hypothesis without a red-capable reproduction; one variable at a time); user-invoked vs model-invoked taxonomy invariant | code-query covers architecture surveying; /fix has no diagnosis gate; no glossary | MIT | Medium | **Adapt** glossary format, red-repro gate for `/fix`, taxonomy note; do not duplicate spec/TDD/verify/review flows |

Credits: ideas adapted from caveman (JuliusBrussee), i-have-adhd (ayghri),
andrej-karpathy-skills (multica-ai), code-design-patterns (00suryavanshi00),
ui-ux-pro-max-skill (nextlevelbuilder), spec-kit (github), skills (mattpocock).
All MIT unless noted; no text reused.

## Decisions

Prior decisions are not reopened: companions opt-in, no per-task prompts,
`gated` default, no `/onboard`, never require Plane (v0.8.1 D5/D6, review kill list).

- **D0 — Internal-first.** Every adopted or adapted idea ships as internal
  rules/skills/templates in this repo; an external companion is offered only
  where the value cannot be replicated in markdown — graphify (knowledge
  graph), ponytail (runtime enforcement), ui-ux-pro-max (local design DB, `has_ui`
  only). *Why:* companions add install/maintenance/licence surface that rule
  text does not; the template already proved (caveman) that a rule's useful
  part is one sentence. *Discarded:* caveman as an optional companion — its
  adapted value (revert-to-prose, `terse` style, agent-report schema) is
  internal in MF1/MF8 (D1, D2, D16, D17) and its compression engine is
  rejected, so an install option would ship nothing we want.
- **D1 — `output_style` extends Conciseness; it does not add a principle.** The
  Conciseness section gains an "Output style" subsection defining `concise`
  (default): answer or action first; code/diff before explanation; normal
  grammar, not fragments; number only real multi-step actions; ≤5 bullets unless
  detail is requested; one concrete next action; no preamble, filler, recap of
  visible output, or closing phrase; errors stated plainly with the recovery
  action. `balanced`/`detailed` relax *length only* — every other rule holds.
  A fourth value, `terse` (opt-in, caveman-adapted), compresses *below*
  concise: telegraphic prose — drop articles and filler, keep negations and
  every technical token (paths, commands, identifiers, versions, numbers)
  verbatim, never invent abbreviations (the tokenizer splits them, so they
  cost more and read worse), no arrow chains. Documented caveat: on already
  short outputs `terse` is often net-negative versus `concise` — it is a
  personal choice, never recommended by setup. `concise` stays the default.
  *Why:* a second principle would duplicate the first's intent; the hook and
  CLAUDE.md already point at Conciseness. *Discarded:* a separate `output.md`
  rule (one more always-loaded file for a paragraph).
- **D2 — Prose is mandatory, not optional, for security warnings and
  irreversible confirmations** (push/merge/publish/destructive, secrets, data
  loss) regardless of `output_style` (including `terse`) and regardless of
  `agent_style` (D16), and when the user asks to explain, when
  a request is ambiguous (2–4 ranked options), or a debugging loop passes three
  turns (state what is known). *Why:* caveman's own revert rule and
  i-have-adhd's break conditions both exist because terse output around danger
  causes mistakes.
- **D3 — Banner is one line, hook-injected on Claude, instruction-only
  elsewhere** (extends v0.8.1 D4). `coding-reminder.sh` reads
  `output_style=` with the same `sed -n 's/^output_style=//p' | head -1` as
  `autonomy_mode` and maps it through a `case` to fixed strings — no file
  content reaches the injected output. Absent/empty = `concise`; unrecognized =
  the v0.8.1 mode-only banner (never blocks). CLAUDE.md/principles fallback text
  says: read both keys, print the one line. Session overrides ("explain more",
  "be brief", "detailed for this session") are never persisted — same rule as
  "just go". `agent_style` (D16) is **not** in the banner and not read by the
  hook: the banner stays one short line about what the *user* sees, and the
  hook already carries the security surface for MF1 — a third key buys
  nothing the orchestrator prompt line does not already deliver.
- **D4 — `verbosity` is renamed to `output_style` in the two places it was
  mentioned** (`template.config.yaml` scopes comment, `setup-template.md`
  scopes table). It was never read by anything. Not asked in the frontier round:
  it is a personal preference with a safe default, not a decision that changes
  what renders.
- **D5 — `patterns` ships as a rule + references, following the `code-query`
  precedent.** Hosts reach content three ways today: `core/.claude/rules/*`
  (rendered for claude/grok; byte-copied into `cursor/.claude/rules`),
  `plugin/skills/<s>/SKILL.md` (plugin host; derived into `codex/skills/`),
  and nothing else for codex renders. So: `core/.claude/rules/patterns.md`
  (compact, always-loaded, ≤120 lines) + `plugin/skills/patterns/SKILL.md`
  (hand-authored stack-agnostic variant, like `code-query`). Domain references
  live in `core/.claude/patterns/<domain>.md` (six files; `.claude/HELP.md`
  precedent — inside `.claude/`, not auto-loaded), and `build.sh` copies them
  to `cursor/.claude/patterns/` (next to the existing agents/rules copy) and
  to `codex/skills/patterns/references/` (so the codex render carries them via
  the existing `stage_tree`). The plugin skill points at
  `${CLAUDE_PLUGIN_ROOT}/template/.claude/patterns/` — already a generated
  mirror, zero extra build. *Discarded:* references under `.claude/rules/`
  (always-loaded catalogue); a `docs/` render (commits catalogue text into
  every user repo).
- **D6 — Implementer-side pattern rules live in `principles.md` (Design
  Patterns section), not in six dev agents.** The section becomes a pointer +
  the four hard rules (inspect existing patterns first via code-query; name the
  present force; one-line why; refusal is valid). Dev agents already say
  "honor the spec's Design notes / never speculatively" — unchanged. *Why:*
  rule of three in reverse — one always-loaded paragraph beats twelve agent
  edits (six core + six plugin mirrors).
- **D7 — Pattern ledger is one line per pattern in pmo's Design notes:**
  `pattern / force / rejected alternative`. Default-reject list: Strategy with
  one implementation, speculative Repository, Factory for one product,
  Singleton, Service Locator. judge adds a checklist line (ledger present when
  a pattern is used; flag pattern-stuffing: any pattern without a stated force
  or with a simpler rejected alternative that was not tried); `/verify` step 1
  gains the same question for the author. Restraint tests are contract
  scenarios: two grep-verifiable (rule text), two human-verified (`/spec` on a
  single-call-site brief yields "no pattern — single call site"; on a brief
  with three real variants yields a named pattern with force + rejected
  alternative), recorded via the existing `verified_by_human` field.
- **D8 — Brand master renders at `docs/design-system/MASTER.md`, page
  overrides at `docs/design-system/pages/<page>.md` only when a page must
  deviate.** *Why:* `/design` already tells the model to check
  `docs/design-system/`; MASTER + `pages/` mirrors the ui-ux-pro-max schema so
  an optional generation drops into the same place; `docs/` is where the
  template already writes rendered artifacts (`docs/specs`, `docs/plans`).
  Source `core/docs/design-system/MASTER.md`, file-level
  `<!-- requires: has_ui -->`, placeholders where inferable
  (`{{project_name}}`, `{{frontend_framework}}`), `TODO:` markers otherwise.
  Sections (all required): Colors + semantic tokens; Typography; Spacing/layout;
  Radius/shadows/motion; Component conventions; Icon/image style; Voice/tone;
  Responsive rules; Accessibility/contrast; Anti-patterns. `build.sh` copies
  `core/docs` into the cursor tree; codex renders have no `.claude` tree, so
  `/design` creates MASTER.md lazily from its section list when missing (also
  covers projects whose `has_ui` flips later). *Discarded:* `docs/design/brand.md`
  (no existing pointer; single file with no override story).
- **D9 — Wiring:** `ui-designer`, `frontend-dev`, `mobile-dev` read MASTER.md
  (and the page override, if any) before designing/coding and cite the token
  they use; `judge` checks UI diffs against it (no hardcoded colors/spacing
  off the token list; flag with file:line). `game-dev`/`desktop-dev` are
  covered through `ui-designer` (rendered for every `has_ui` project); direct
  wiring for them is out of scope this release. ui-ux-pro-max: when installed,
  `/design` may delegate MASTER generation to it, then normalizes the output
  into our section list; never vendored, never required.
- **D10 — Workflow vocabulary is three small additions, no new flows.**
  (a) `docs/CONTEXT.md` glossary: pmo creates it lazily on the first project
  term it coins or disambiguates; entry = `**Term** — what it IS (1–2
  sentences). Avoid: <synonyms>`; project terms only, no general vocabulary;
  pmo reads it at CONVERSE. (b) `/fix` diagnosis gate: before naming a cause,
  produce a red-capable reproduction (a failing test or command that goes
  green only when fixed); if none can be produced in one step the cause is not
  obvious → `/feature`. Rank 2–4 falsifiable hypotheses only when the first
  repro does not point at one; change one variable at a time. (c) pmo
  CONVERSE states **intent** (the user-observable change) before any
  implementation talk, and for brownfield work surveys the touched modules
  (code-query) and writes the *change*, not a retro-spec of the system.
  Taxonomy invariant documented in `docs/sdd-workflow.md`: commands are
  user-invoked (cursor: `disable-model-invocation: true`), rules/skills are
  model-invoked; a command may lean on model-invoked material and may *suggest*
  another command to the user, but never instructs the model to invoke one.
  No static check — it needs semantic judgment; the existing build already
  stamps the frontmatter flag.
- **D11 — Tooling upgrades are separate commits.** `docs/upgrade-guide.md`
  and `/feature` say: a template upgrade (`setup.sh --merge`) is its own
  `chore:` commit, never mixed into a feature PR. (spec-kit concept; enforces
  itself via the existing micro-PR check.)
- **D12 — Companions stays one frontier item with grouped
  recommendations.** Item 4 lists: core quality — graphify + ponytail;
  output — native `concise` (already on; nothing to install); UI (only
  when `has_ui`) — ui-ux-pro-max. Trackers and other tools remain
  user-selected via `/integrate`; Plane is never required. Answer grammar
  `companions=yes|not_now|never|<comma list>`: `yes` = all recommended,
  `<list>` = that subset (unlisted tools are recorded as skipped by omission
  and not re-recommended), `not_now` re-asks next run (unchanged), `never`
  suppresses everything (unchanged). `/setup-companions [list]` extends its
  existing detect → exact plan → confirmation gate to one new tool:
  ui-ux-pro-max installs as a skill (exact command verified from the upstream
  README at implementation, printed in the plan); external per D0 because its
  design DB cannot be replicated. ponytail:
  `orchestrator` mentions that dev subagents pick up its ruleset when
  `PONYTAIL_SUBAGENT_MATCHER` matches `dev` (one line; install text already
  covers it).
- **D13 — `--merge` plan labels, no content heuristic.** `classify()` keeps
  `ADD|SAME|DIFFERS`; `print_plan()` labels a `DIFFERS` file under
  `.claude/{agents,commands,rules,hooks,skills}/`, `.claude/HELP.md`, `.cursor/`,
  `.agents/skills/`, or `AGENTS.md` as `STALE-MANAGED` (template-managed
  content differs — usually an old render), root `CLAUDE.md` as
  `CUSTOMIZED (keep; template adds nothing on merge — reconcile by hand)`, and
  a regular-file `.claude/CLAUDE.md` next to a root `CLAUDE.md` as
  `SYMLINK-CONFLICT`. Then it prints one copy-pasteable line:
  `--merge --overwrite-files <every STALE-MANAGED rel, comma-separated>`.
  *Why no "customized" heuristic:* content cannot tell an old render from a
  deliberate edit; a wrong guess overwrites someone's work. The user deletes
  entries from the printed list; nothing project-specific is ever overwritten
  automatically. New flag `--overwrite-files a,b` (comma list of target-relative
  paths, valid with `--merge`): listed files take the template version; listing
  `.claude/CLAUDE.md` replaces the regular file with the `../CLAUDE.md` symlink
  (the template's version of that path *is* the symlink). Unknown paths in the
  list exit non-zero before writing anything. Bash 3.2 + python3 stdlib only —
  the whole change is inside the existing python block plus one arg case.
- **D14 — Micro-PR limits count hand-authored files; generated mirrors ride
  along** (v0.8.0 D2, v0.8.1 D10). Hand-authored = `core/`, `plugin/{agents,
  commands,skills,hooks}`, `hosts/`, `scripts/`, `setup.sh`, `template.config.yaml`,
  `docs/`, `README*`.
- **D15 — Version `0.8.2` across the three manifests, bumped in the last
  mini-feature only** (v0.8.0 Q2 / v0.8.1 Q3 precedent).
- **D16 — Two channels, two knobs.** Human-facing output follows
  `output_style` (D1). The **return message** a subagent hands back to the
  orchestrator (the main conversation) follows a second personal pref,
  `agent_style=terse|descriptive`, in `.claude/answers.local.env`; absent,
  empty, or unrecognized = `terse`. `terse` is a fixed field schema, no
  prose, ≤ ~25 lines, paths and commands verbatim:
  `RESULT: <pass|fail|approved|changes-requested|blocked>` /
  `FILES: <path:+n/-m, …>` / `CHECKS: <name=pass|fail …>` /
  `FINDINGS: <severity: one line each>` / `DECISIONS: <one line each>` /
  `NEXT: <one line>`. `descriptive` = today's prose report (for debugging
  the workflow or onboarding a human to it). The schema lives once, in a
  "Report format" subsection of `principles.md`; the orchestrator (the main
  conversation per `/feature`, and `orchestrator.md`) reads the key once per
  run and puts one line — `agent_style: <value> — return per "Report format"
  in .claude/rules/principles.md` — in every subagent prompt, so hosts
  without hooks and subagents that never see the pref file still honor it;
  a subagent whose prompt carries no line defaults to `terse`. *Why:* the
  orchestrator consumes these messages, not a human — it needs the verdict,
  the paths, the severities and the next step; a schema is cheaper to read
  and impossible to pad. *Why a second knob:* a user who wants prose from
  Claude usually still wants agents to report tersely, and vice versa; one
  knob would couple them. *Discarded:* a `SubagentStart` hook injecting the
  value (hook surface, Claude-only, and the prompt line is needed for other
  hosts anyway); per-agent copies of the schema (twelve core + eleven plugin
  files to keep in sync for one table); a per-agent pointer line to the
  shared subsection (Q7).
- **D17 — Boundary rule: persisted artifacts are always prose.** Verdict and
  findings files under `docs/specs/*/progress/`, `spec.md`/`contract.md`,
  commit messages, PR bodies, and docs are written in normal prose regardless
  of `output_style` or `agent_style`; `terse` applies to the return message
  only, never to what an agent writes to disk. Human-facing output follows
  `output_style`, never `agent_style`. *Why:* artifacts outlive the session
  and are read by people without the session's context — caveman's own
  "prose in artifacts" boundary exists for the same reason. D2 (prose around
  danger) applies to both channels.

## Out of scope

- Any caveman/ui-ux-pro-max/graphify/ponytail code in this repo; any
  auto-install; any telemetry; any caveman install option (D0). Per-turn
  compression levels beyond the four `output_style` values.
- `agent_style` in the hook or banner (D3/D16); a `SubagentStart` injection
  hook; per-agent pointer lines to "Report format" (Q7); passing
  `agent_style:` from commands other than `/feature` (`/audit`, `/design`,
  `/fix` spawn subagents too — they fall back to `terse` by default; wire
  them when a need shows).
- Cursor `beforeSubmitPrompt` banner (v0.8.1 Q4 stands); host-capability-matrix
  rewrite (one row added for the banner and brand file is fine).
- Brand wiring for `game-dev`/`desktop-dev` beyond `ui-designer`; brand
  *tokens as code* (CSS variables, Tailwind config) — MASTER.md is prose + names.
- Rendering `docs/CONTEXT.md` — it is created lazily by pmo, never templated.
- A static taxonomy-invariant checker; a version stamp in rendered files
  (see Q3); deleting files on `--merge`.
- Eval harness for the restraint tests (human-verified this release).
- Reopening: companions default, per-task prompts, `/onboard`, Plane, gated default.

## Open questions (Q1–Q6 resolved at Gate 1, 2026-09-02; Q7 open)

- **Q1 — Where do session overrides for output live once given?** *Resolved:*
  nowhere — mirror "just go": apply for the session, never write. Persisting
  is a `.claude/answers.local.env` edit the user makes.
- **Q2 — Should `output_style` be asked in the frontier round?** *Resolved:* no —
  personal pref with a safe default; setup-template's scopes table documents
  it and the upgrade guide shows the line. Asking would lengthen the interview.
- **Q3 — Version stamp in rendered managed files (`<!-- agent-config-template v0.8.2 -->`)
  to distinguish STALE-MANAGED from CUSTOMIZED reliably?** *Resolved:* defer to
  v0.8.3; it changes every rendered file (noise in this release's diffs) and
  D13's printed list already makes the safe path one copy-paste.
- **Q4 — Codex render lacks the brand file and pattern references unless
  `build.sh` copies them.** *Resolved:* copy pattern references into
  `codex/skills/patterns/references/` (D5, two lines); rely on `/design`'s
  lazy MASTER creation for the brand file on codex (D8).
- **Q5 — Exact install command for ui-ux-pro-max.** *Resolved:* the install
  stays (cannot be replicated, D0); the exact command is resolved at MF6
  implementation from the upstream README; the contract only requires the
  plan to print the exact command + source + what is written. Caveman is
  removed from the companion set entirely (D0).
- **Q6 — Should `--overwrite-files` also be accepted without `--merge`?**
  *Resolved:* no — it is a merge refinement; with `--overwrite` everything is
  replaced anyway. Error out on the combination to keep semantics obvious.
- **Q7 — Should every agent file carry a one-line pointer to "Report
  format"?** The request asked for one; it is 12 core + 11 plugin files for a
  pointer that duplicates what every subagent already gets twice — the
  always-loaded `principles.md` subsection and the orchestrator's
  `agent_style:` prompt line (D16) — and it does not fit the MF8 budget
  without a second mini-feature. *Recommendation:* **no** per-agent lines
  this release; revisit in v0.8.3 only if a subagent is observed ignoring the
  prompt line. If the maintainer insists: `MF9 — agent-report-pointers-core`
  (12 files) and `MF10 — agent-report-pointers-plugin` (11 files), judge-only.

## Design notes (release-wide; per-MF notes in `contract.md`)

- **No design pattern in this release.** Every change is markdown, a `case`
  arm, a copy line in `build.sh`, or a labelled branch in `print_plan()` —
  single call sites (no pattern — YAGNI). The `patterns` rule is *about*
  patterns; it does not need one.
- **Leverage:** `coding-reminder.sh` sed/case read (extended, not rewritten);
  `principles.md` Conciseness + Design Patterns sections (extended); `code-query`
  rule/skill dual (precedent for `patterns`); `stage_tree`/`requires:` directive
  (brand file renders for free); `build_cursor_tree` copy lines; `classify()`
  / `print_plan()` / `relink_claude_md()` (labels and the flag slot in);
  `/setup-companions` gate (one more entry); `features.json`
  `verified_by_human` (restraint tests); CI `render-smoke` (one more host loop
  + `scripts/smoke.sh` call); `/feature` step 2 and `orchestrator.md` steps
  5–8 (the `agent_style:` prompt line slots in where scenarios and Design
  notes are already passed). New code: `scripts/smoke.sh` (~60 lines),
  `core/docs/design-system/MASTER.md`, `core/.claude/rules/patterns.md`, six
  reference files, one plugin skill.
