# Upgrade guide

How to pull updates from the template into a project that's already configured.

## The model

As of **v0.4.0**, `setup.sh` is **non-destructive**. Run against a project that
already has a Claude config, it renders to a staging dir, detects your existing
`.claude/` (and root `CLAUDE.md`), and **writes nothing** until you pick a mode:

- `--merge` — add files that don't exist, **union-merge `.claude/settings.json`**
  (combine `permissions.allow/deny/ask` + additive hooks), and **keep every other
  existing file as-is**. Never touches `.claude/settings.local.json`.
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
cd ~/code/agent-config-template && git pull origin main   # or: git checkout v0.4.0

# 2. Preview what would change in your project
cd ~/code/my-project
~/code/agent-config-template/setup.sh --target . --answers ./answers.env        # prints the plan, writes nothing

# 3. Apply — merge keeps your customizations and your settings.local.json
~/code/agent-config-template/setup.sh --target . --answers ./answers.env --merge

# 4. Commit
git add .claude/ CLAUDE.md docs/ && git commit -m "chore: upgrade agent-config-template to v0.4.0"
```

For fine-grained control, render into a temp dir and cherry-pick:

```bash
TMP=$(mktemp -d)
~/code/agent-config-template/setup.sh --target "$TMP" --answers ./answers.env --overwrite
diff -r .claude "$TMP/.claude"
```

---

## Upgrading to v0.5.0 (rename + multi-host)

v0.5.0 renames the repo **`claude-config-template` → `agent-config-template`** and adds Codex, OpenCode, and Antigravity packaging alongside Claude Code. Nothing about the Claude Code experience changes — same agents, commands, hooks, and `/setup-template`.

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

The renderer never deletes. Remove deprecated files by hand (e.g. the old
`pm`/`po-manager`/`code-reviewer` stubs, removed upstream in v0.5.x) once
you're ready.

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
