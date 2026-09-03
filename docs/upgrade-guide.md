# Upgrade guide

How to pull updates from the template into a project that's already configured.

## The model

As of **v0.4.0**, `setup.sh` is **non-destructive**. Run against a project that
already has a Claude config, it renders to a staging dir, detects your existing
`.claude/` (and root `CLAUDE.md`), and **writes nothing** until you pick a mode:

- `--merge` — add files that don't exist, **union-merge `.claude/settings.json`**
  (combine `permissions.allow/deny/ask` + additive hooks), and **keep every other
  existing file as-is**. Add `--prune` only after reviewing the plan to remove
  unchanged managed files retired by the template. Never touches
  `.claude/settings.local.json`.
- `--overwrite` — replace template-managed files (still never touches
  `settings.local.json`, never deletes files the template doesn't manage).
- `--abort` — do nothing (the default).

Run with **no mode** first to print a per-file change plan (it writes nothing and
exits non-zero), then re-run with the mode you want.

## Recommended workflow

### Once: keep your `answers.env` in the project

```bash
~/code/agent-config-template/setup.sh --target . --answers ./answers.env
git add answers.env   # the source of truth — re-renders the same config later
```

### To upgrade

```bash
# 1. Pull the latest template (or check out a tag for stability)
cd ~/code/agent-config-template && git pull origin main   # or: git checkout v0.10.0

# 2. Preview what would change in your project
cd ~/code/my-project
~/code/agent-config-template/setup.sh --target . --answers ./answers.env        # prints the plan, writes nothing

# 3. Apply — merge keeps your customizations and your settings.local.json
~/code/agent-config-template/setup.sh --target . --answers ./answers.env --merge

# 4. Commit
git add .claude/ CLAUDE.md docs/ agent-config.lock.json && git commit -m "chore: upgrade agent-config-template to v0.10.0"
```

A template upgrade (`setup.sh --merge`) is its own `chore:` commit — never mixed into a feature PR.

For fine-grained control, render into a temp dir and cherry-pick:

```bash
TMP=$(mktemp -d)
~/code/agent-config-template/setup.sh --target "$TMP" --answers ./answers.env --overwrite
diff -r .claude "$TMP/.claude"
```

---

## Upgrading from v0.9.2 to v0.10.0 (ecosystem)

v0.10.0 adds four opt-in or capability-gated surfaces without changing
`answers.env` or `features.json` schema v2:

- `python3 scripts/evals/run.py validate` checks the six-case model behavior
  catalog without calling a model. Add `--run` to execute a selected host;
  write-capable `/spec` → `/feature` evaluation also requires `--allow-writes`
  and uses a disposable project.
- UI renders add `docs/design-system/tokens.json`. Run `/design` to resolve the
  values used by the feature, generate exactly one stack-native theme target,
  and record both files in `tokens.lock.json`.
- `/setup-companions plan|doctor|install|update|uninstall [list]` reads pinned
  metadata from `companions.lock.json`. Plan/doctor are offline; install, update,
  and removal still stop for per-tool confirmation.
- Cursor now tokenizes direct, chained, path-qualified, and common shell-wrapped
  git commands. It allows quoted/search mentions but remains a guardrail, not a
  security boundary.

Preview and merge as usual. Existing `docs/design-system/` files remain
user-owned; review the new token source instead of overwriting your brand work.

---

## Upgrading to v0.9.2 (upgrade fidelity)

v0.9.2 makes upgrade decisions evidence-based without adding dependencies:

- Each successful render maintains `agent-config.lock.json` with the current
  hosts and SHA-256 baselines for overwrite-managed files.
- Preview labels changed files `STALE-MANAGED`, `CUSTOMIZED-MANAGED`, or
  `LEGACY`. Retired managed paths are `OBSOLETE` when unchanged and
  `CUSTOMIZED-OBSOLETE` when edited or unsafe.
- Ordinary `--merge` deletes nothing. After approving every `OBSOLETE` path,
  `--merge --prune` deletes only those unchanged regular files and updates the
  lock; customized, unrecorded, user-owned, and symlinked paths remain.
- Fully quoted answers are unwrapped, unquoted spaces and `#` remain literal,
  and host lists are case-insensitive and deduplicated. `--host` still wins.
- After a successful write, an existing `.claude/answers.local.env` adds one
  exact rule to `.gitignore`; preview, abort, and parse failures do not touch it.

On the first upgrade from an older release there is no baseline, so differing
managed files are `LEGACY`. Review them and explicitly select only the upstream
files you want with `--merge --overwrite-files <paths>`; that successful write
establishes their v0.9.2 baselines. Then future previews can distinguish stale
template output from user edits exactly.

```bash
# Preview only
./setup.sh --target . --answers ./answers.env --host cursor

# Keep all existing files; establish baselines for additions and identical files
./setup.sh --target . --answers ./answers.env --host cursor --merge

# Optional, only after approving every OBSOLETE line from preview
./setup.sh --target . --answers ./answers.env --host cursor --merge --prune
```

Commit `agent-config.lock.json` with the generated project configuration. Keep
`.claude/answers.local.env` local; setup now protects it automatically.

---

## Upgrading to v0.9.1 (review convergence)

v0.9.1 makes review and TDD decisions reproducible without changing schema v2
or adding dependencies:

- `/verify` uses a pinned review scope, includes untracked paths, rejects empty
  work, and locates the originating spec in a fixed order.
- Judge reports separate `Spec fidelity` and `Standards & health` axes. Only a
  `hard-violation` blocks; a `judgment-call` stays advisory.
- A mini-feature gets at most two review cycles. Continued disagreement records
  both positions and waits for a human instead of looping.
- Gate 2 names public behavior seams and the first failing test. Expected values
  come from an independent source, mocks stop at external boundaries, and work
  advances one vertical test/implementation slice at a time.
- Existing schema v2 ledgers remain valid. New ledgers initialize
  `review_cycles: 0`; the field is optional for old ledgers and limited to 0–2.

A focused check proved every current dispatch command passes `agent_style`
through the central handoff. No per-agent pointers were added.

Pull or update the plugin, restart the host, preview project changes, then merge
only the managed files you want to refresh:

```bash
./setup.sh --target . --answers ./answers.env --host cursor
./setup.sh --target . --answers ./answers.env --host cursor --merge
```

---

## Upgrading to v0.9.0 (explicit SDD grammar)

v0.9.0 makes the on-disk workflow more deterministic across Claude, Cursor,
Grok, and Codex:

- Specs separate numbered FR/SC statements and trace every contract scenario
  to both; unresolved `NEEDS CLARIFICATION:` markers block Gate 1.
- `features.json` now requires schema v2, explicit dependencies, budgets,
  status, and human-verification state. Migrate old ledgers once with
  `python3 scripts/migrate-specs.py`.
- Post-approval amendments reset only affected work and transitive dependents,
  then require a newer approval in `progress/gate1.md`.
- PMO and judge use one principles-deviation table as a planning and review
  gate.
- README is shorter, and `docs/guides/existing-projects.md` adds the safe
  brownfield survey → preview → merge → verify path.

Pull or install v0.9.0, preview the generated diff, then merge it as a separate
tooling commit:

```bash
./setup.sh --target . --answers ./answers.env --host cursor
./setup.sh --target . --answers ./answers.env --host cursor --merge
```

Do not overwrite customized root instructions. Review `STALE-MANAGED` files and
use the printed `--overwrite-files` list only for upstream files you intend to
refresh.

---

## Upgrading to v0.8.3 (review-debt patch)

v0.8.3 fixes setup and hook edge cases without changing the workflow:

- Preference hooks now normalize CRLF and surrounding spaces before applying
  the fixed-value whitelist.
- Stdin merge plans keep `--answers -` and explain that the same answers must be
  piped again; multi-host summaries count each unique skipped path once.
- An installed bundle with a missing generated tree now says to reinstall the
  plugin instead of suggesting the repository-only build script.
- Branch guards prefer `AGENT_CONFIG_PROTECTED_BRANCHES`, with
  `CLAUDE_CONFIG_PROTECTED_BRANCHES` retained as the legacy fallback.
- Optional UI companion installs now default to the reproducible
  `ui-ux-pro-max-cli@2.15.0` pin. The unpinned latest release remains an explicit
  opt-in.

Update an installed Claude Code plugin, then restart or reload plugins:

```bash
claude plugin marketplace update juantrujillodev
claude plugin update agent-config-template@juantrujillodev
```

Preview and apply generated project updates separately:

```bash
./setup.sh --target . --answers ./answers.env
./setup.sh --target . --answers ./answers.env --merge
```

---

## Upgrading to v0.8.2 (adaptive skills + merge reporting)

v0.8.2 adds per-project answer styles, the companions list grammar, and a
`--merge` plan that says *why* a file differs instead of a bare `DIFFERS`.

1. New personal keys in the gitignored `.claude/answers.local.env` (both
   optional; absent = today's behaviour; never committed):

   ```dotenv
   output_style=concise      # what Claude says to you
   agent_style=terse         # what subagents return to the orchestrator
   ```

   `output_style` accepts `output_style=concise|balanced|detailed|terse` (default `concise`).
   Caveat: `terse` is lossy and not for beginners — ask before enabling it on a shared project.
   `agent_style` accepts `agent_style=terse|descriptive` (default `terse`).
   Boundary rule: `agent_style` shapes only the return message a subagent hands
   back to the orchestrator, never the user-facing `output_style`. `companions=yes|not_now|never|<comma list>` (for example
   `companions=graphify,ponytail`) is unchanged from v0.8.1.
2. Run the plan and read the three labels:

   ```bash
   ./setup.sh --target . --answers ./answers.env
   ```

   - `STALE-MANAGED` — a template-managed file (agents, commands, rules, hooks,
     skills, patterns, `.claude/HELP.md`, `mcp.json.example`, `AGENTS.md`,
     `.cursor/`, `.agents/skills/`) differs; usually an old render, sometimes a
     hand edit. Content cannot tell the two apart, so nothing is overwritten
     automatically. `.claude/settings.json` is deep-merged instead and cannot be listed.
   - `CUSTOMIZED` — a user-filled file differs: root `CLAUDE.md`, `docs/CONTEXT.md`,
     `docs/design-system/`. Keep it; `--merge` never touches it and never lists it.
   - `SYMLINK-CONFLICT` — `.claude/CLAUDE.md` is a regular file where the
     template expects a symlink to `../CLAUDE.md`. Never auto-listed.

   The plan ends with one copy-pasteable line:
   `--merge --overwrite-files <every STALE-MANAGED path>`. Delete the entries
   you edited on purpose, then run it. `--overwrite-files` is only valid with
   `--merge`; unknown paths, `.claude/settings.json`, a path that resolves outside
   the target through a symlink, or `.claude/CLAUDE.md` without a regular root
   `CLAUDE.md` exit non-zero before anything is written; `settings.local.json`
   is never touched.

### Portfolio-style resolution (many old renders, one team `CLAUDE.md`)

1. Keep root `CLAUDE.md` — your team conventions live there; the template adds
   nothing to it on merge.
2. Run the plan (no mode) and read the labels file by file.
3. Regenerate the STALE-MANAGED agents/rules with the printed `--merge --overwrite-files` line.
4. Diff `.claude/CLAUDE.md` against root `CLAUDE.md`, fold anything worth keeping into root, then add `.claude/CLAUDE.md` to the list to replace the regular file with the symlink.

Land the tooling upgrade as its own `chore:` commit, separate from feature work.

---

## Upgrading to v0.8.x (setup evolution)

v0.8.1 separates shared project policy from personal agent preferences, batches
setup decisions, and adds safe task-time MCP integration.

1. **Commit `answers.env`.** Run `git check-ignore -v answers.env`, remove the
   matching ignore rule from the file it reports, then add `answers.env`. Keep
   `.claude/answers.local.env` gitignored.
2. Add the workflow policy to `answers.env`:

   ```dotenv
   workflow_mode=SDD
   ```

   `SDD` is the backward-compatible default when absent. Use `SDD+TDD` to make
   test-first + Gate 2 the per-mini-feature default.
3. Create `.claude/answers.local.env` for personal preferences (do not commit it):

   ```dotenv
   autonomy_mode=gated
   companions=not_now
   ```

   `autonomy_mode` accepts `gated` or `autonomous`; session phrases such as
   “just go” and “gate me” override it without changing the file.
   `companions` accepts `companions=yes|not_now|never|<comma list>`; the
   companions are graphify, ponytail and ui-ux-pro-max (only when `has_ui` is
   truthy), so `companions=graphify,ponytail` installs those two and never
   re-recommends the rest.
4. Preview, then merge the new files:

   ```bash
   ./setup.sh --target . --answers ./answers.env
   ./setup.sh --target . --answers ./answers.env --merge
   ```

   Merge preserves existing customized files. Render to a temp directory and
   copy individual upstream updates, or use `--overwrite` only after reviewing
   the plan, when you also want changed existing commands.

Use `/integrate <tool>` (for example `/integrate linear`) to research the
official MCP server, review the exact install/write plan, and approve it before
anything changes.

---

## Upgrading to v0.6.0 (Claude-focused + any-stack)

v0.6.0 refocuses the repo on Claude Code and makes the template stack-agnostic.

- **Multi-host packagings removed** (Codex plugin, Gemini extension, portable
  `skills/` tree, `AGENTS.md`/`GEMINI.md`). To use the workflow on another
  host, run the new **`port-config`** skill — it generates a config for that
  host against its *current* docs instead of shipping packagings that rot.
- **`project_type` added** (`web-app`, `api-service`, `mobile-app`,
  `desktop-app`, `game`, `library-cli`, `data-ml`, `other`). It picks which dev
  agents render: `backend-dev`/`frontend-dev` (web), `mobile-dev`, `game-dev`,
  `desktop-dev`, or `core-dev`.
- **answers.env key changes:** `backend_framework` → `framework`;
  `has_celery` → `has_background_jobs` (the old key is still accepted).
  Omitting `project_type` defaults to `web-app` (old behavior).
- **New principles:** Read Before You Write (bypassable reporting, mandatory
  reading), Code Health (DRY rule-of-three, ~40/~400-line guidelines,
  why-comments), Commits (one logical change per commit).

**Migration:** add `project_type=` to your `answers.env`, rename the two keys,
re-render with `--merge`.

---

## Upgrading to v0.5.0 (rename + multi-host)

v0.5.0 renamed the repo **`claude-config-template` → `agent-config-template`** and briefly added Codex, OpenCode, and Antigravity packaging alongside Claude Code. Nothing about the Claude Code experience changes — same agents, commands, hooks, and `/setup-template`.

GitHub redirects old URLs, so existing `/plugin marketplace add JuanTrujilloDev/claude-config-template` keeps resolving. To move cleanly onto the new name:

```
/plugin marketplace remove juantrujillodev
/plugin marketplace add JuanTrujilloDev/agent-config-template
/plugin install agent-config-template@juantrujillodev
/reload-plugins
```

The plugin identifier is now `agent-config-template@juantrujillodev` (the marketplace handle `juantrujillodev` is unchanged). Other hosts: see the per-host guides under [`docs/install/`](./install/). The canonical source folder is now `core/` (was `template/`); if you maintain a fork, `template/` → `core/` and `scripts/sync-plugin.sh` → `scripts/build.sh`.

## Upgrading to v0.4.0 (from v0.3.x)

v0.4.0 is a big jump. Nothing breaks immediately — old agents/commands remain as
deprecated stubs — but the workflow and several behaviors changed.

**What changed**

- **Hooks are advisory now.** `agent-enforcement.sh` no longer *blocks* non-trivial
  edits — it prints guidance and exits 0. The only hard block is editing on a
  **protected branch**, now configurable via `CLAUDE_CONFIG_PROTECTED_BRANCHES`
  (default `main,master`). The dead `CLAUDE_AGENT_ACTIVE` gate was removed.
- **`auto-format.sh`** runs only targeted lint autofixes inline (`ruff --fix` /
  `eslint --fix`); whole-file formatters (`black`, `prettier`, …) moved to the
  Definition of Done, so per-edit diffs stay surgical.
- **Setup is non-destructive** (see above) — the wipe-on-render footgun is gone.
- **Spec-driven workflow.** New agents `orchestrator`, `pmo` (merges `pm` +
  `po-manager`), and `judge` (renames `code-reviewer`); new `/spec` (replaces
  `/idea` + `/sow`) and `/fix`; `/feature` rebuilt around an approved
  Given/When/Then contract. See [`sdd-workflow.md`](./sdd-workflow.md).
- **New opt-in toggles:** `use_gherkin` (real `.feature` contracts) and
  `enforce_mutation_testing` (adds `tools/mutate.py` + the `mutation-tester`
  agent). Both default `no`.
- **Permissions:** `git commit` and `git checkout` moved from `ask` to `allow`.

**Migration steps**

1. Add the new keys to `answers.env` if you want them: `use_gherkin=no`,
   `enforce_mutation_testing=no` (both optional — omitting them = off).
2. Re-render with `--merge`. This adds the new agents/commands and merges your
   `settings.json`; your customizations and `settings.local.json` stay intact.
3. **Cleanup** — the deprecated files were removed upstream in v0.5.x:
   `pm.md`, `po-manager.md`, `code-reviewer.md` (agents) and `idea.md`, `sow.md`,
   `plan.md` (commands). The renderer never deletes, so remove your local copies
   by hand once you've moved over.
4. If you overrode `CLAUDE_CONFIG_DEFAULT_BRANCH` via env, switch to
   `CLAUDE_CONFIG_PROTECTED_BRANCHES` (the old var is no longer read).

---

## Common upgrade scenarios

### New placeholder added

Re-render with your existing `answers.env`; a new variable renders blank and its
`{{#var}}…{{/var}}` blocks drop. **Fix:** add the new line to `answers.env`.

### Placeholder renamed

Breaking change → noted in the release. Update the key in `answers.env`.

### Agent added or modified

`--merge` adds new agents but **keeps** your existing (possibly customized) ones.
To take the upstream version of a file you've changed, render to a temp dir and
copy that one file over.

### File removed / deprecated

Preview labels a recorded, unchanged retired file `OBSOLETE`. Review it, then
use `--merge --prune`; edited, unrecorded, and older pre-lock files remain for
manual resolution.

---

## When to NOT upgrade

- You've heavily customized an agent to your team's patterns (merge keeps yours;
  overwrite would replace it).
- A new version changes a principle you've already trained your team on.
- You're mid-sprint and don't want to learn new hook behavior right now.

Stay on your current tag and apply specific upstream changes by hand.

## Tracking template version

```markdown
<!-- agent-config-template version: v0.4.0 -->
```
