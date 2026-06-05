# Sync note — bundled template

`plugin/template/`, `plugin/setup.sh`, and `plugin/template.config.yaml` are
**byte-for-byte copies** of the canonical versions at the repo root. They're
bundled so the plugin is self-contained when installed via `/plugin install`
(Claude Code uses only the `plugin/` directory).

**Don't edit these copies by hand.** Edit the canonical files at the repo root,
then re-mirror:

```bash
scripts/sync-plugin.sh
```

CI runs `scripts/sync-plugin.sh --check` on every push/PR and fails if the copies
have drifted, so the mirror can't silently rot.

> Note: the plugin's own `agents/`, `commands/`, `hooks/`, and `skills/` are
> hand-authored, stack-agnostic variants — they are **not** mirrors of the
> canonical template and are not touched by the sync script.
