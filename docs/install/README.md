# Install

## One command

Run it at the root of the git repository you want to set up:

```bash
curl -fsSL https://raw.githubusercontent.com/JuanTrujilloDev/agent-config-template/<tag>/bootstrap.sh | sh -s -- --host claude
```

`--host` takes `claude`, `cursor` or `codex` (a comma list renders several;
`grok` is the claude tree plus `AGENTS.md`). `--ref <tag>` picks another
release. To check the script before running it, download it, compare its
sha256 with the one in the [README](../../README.md#install), then run
`sh bootstrap.sh --host claude`.

What it does, in order:

1. Checks `git`, `python3` and `bash`; refuses outside a git repository, and on
   uncommitted changes unless you pass `--force`.
2. Shallow-clones the template at the pinned tag into a temp folder. That clone
   is its only network call; there is no telemetry.
3. Uses the repo's `answers.env`. Without one, it generates a generic one from
   the defaults in `template.config.yaml`.
4. Prints the `setup.sh` change plan. Nothing is written yet.
5. Asks `Apply? (y/N)` on your terminal. Only `y` runs `setup.sh --merge`,
   which adds missing files and keeps yours, then writes `answers.env` and
   `agent-config.lock.json`. It removes the temp folder either way.

The generated `answers.env` is generic, not inferred from your code. Calibrate
it with `/setup-template` from a plugin (below), or edit it and run the command
again.

## Plugin install (alternative)

The plugins add the commands and skills to the host itself. Calibrate a project
with `/setup-template` afterwards.

**Claude Code**

```text
/plugin marketplace add JuanTrujilloDev/agent-config-template
/plugin install agent-config-template@juantrujillodev
/agent-config-template:setup-template
```

Details: [Claude Code](claude.md).

**Codex**

```bash
codex plugin marketplace add JuanTrujilloDev/agent-config-template
codex plugin add agent-config-template@juantrujillodev
```

Restart Codex or start a new thread. Codex has no `/setup-template`; render the
project files with the one command and `--host codex`. Details: [Codex](codex.md).

**Cursor**

A Cursor marketplace listing is not yet verified. Once it is listed: open
**Customize → Plugins**, search for **Agent Config Template**, select
**Install**, then run `/setup-template`. Until then, use the one command with
`--host cursor`. Details: [Cursor](cursor.md) · [Grok](grok.md) ·
[host capability matrix](host-capability-matrix.md).

## Update an existing repo

Run the one command again with the new tag (`--ref <tag>`). It reuses your
`answers.env`, shows `STALE-MANAGED`, `CUSTOMIZED-MANAGED` and `OBSOLETE` rows,
and applies `--merge` only after you say yes. With a plugin installed, the
`update-config` skill does the same and also migrates old `docs/specs/`.

Rendered before `agent-config.lock.json` existed, so every changed file shows
`LEGACY` and `--prune` removes nothing? If those files are unedited template
output, add `--legacy`: the apply records their current hashes as baselines,
and the next preview shows them as `STALE-MANAGED` or `OBSOLETE`. Review the
`OBSOLETE` list before you run `setup.sh --merge --prune`.

More: [existing-project guide](../guides/existing-projects.md) ·
[upgrade guide](../upgrade-guide.md).
