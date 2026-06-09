# Sync note — bundled template

`plugin/template/`, `plugin/setup.sh`, and `plugin/template.config.yaml` are
**generated copies** of the canonical source at the repo root:

- `plugin/template/` ← `core/`
- `plugin/setup.sh` ← `setup.sh`
- `plugin/template.config.yaml` ← `template.config.yaml`

They're bundled so the plugin is self-contained when installed via `/plugin install`
(Claude Code uses only the `plugin/` directory).

**Don't edit these copies by hand.** Edit the canonical files (`core/`, `setup.sh`,
`template.config.yaml`) and regenerate:

```bash
scripts/build.sh
```

CI runs `scripts/build.sh --check` on every push/PR and fails on drift, so the
copies can't silently rot. (`scripts/sync-plugin.sh` is a deprecated shim that
forwards to `build.sh`.)

> The plugin's own `agents/`, `commands/`, `hooks/`, and `skills/` are
> hand-authored, stack-agnostic variants — not mirrors of `core/`, and not
> touched by the build.
