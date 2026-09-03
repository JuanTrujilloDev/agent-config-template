---
name: setup-companions
description: "Plan, inspect, install, update, or uninstall the optional graphify, ponytail, and UI UX Pro Max companions from one pinned lock."
---

# /setup-companions

Manages **optional** companions. The core workflow works without them.

## Usage

```text
/setup-companions [graphify,ponytail,ui-ux-pro-max]
/setup-companions <plan|doctor|install|update|uninstall> [graphify,ponytail,ui-ux-pro-max]
```

No action means `install`. No list means graphify + ponytail. ui-ux-pro-max is
for UI projects only and only when requested or `has_ui`. A list selects exactly
those tools.

## Lock and host

Read metadata before doing anything:

- Claude: `${CLAUDE_PLUGIN_ROOT}/companions.lock.json`
- Cursor/Grok: `${CURSOR_PLUGIN_ROOT}/plugin/companions.lock.json`

The lock owns source, version, method, probe, package and direct-download
SHA-256. If it is missing or invalid, stop; do not reconstruct it from this file
or search for a newer release. Detect the active host and existing tool paths.

## Lifecycle

1. **Detect local state.**
   - graphify: executable, version, and host integration.
   - ponytail: host plugin or `.cursor/rules/ponytail.mdc` plus its SHA-256.
   - ui-ux-pro-max: `.claude/skills/ui-ux-pro-max/`; source `github.com/nextlevelbuilder/ui-ux-pro-max-skill`.
2. **Show the plan and STOP for confirmation.** `plan` is offline and read-only.
   Print the source, pinned version, exact install command, and what each writes.
   Install nothing without an explicit yes.
3. **Doctor (offline, read-only).** Use only local executable, version, plugin,
   path and SHA-256 probes. Report each tool as `missing`, `healthy`, `outdated`,
   or `unverifiable`; do not repair it.
4. **Install.** Skip `healthy`. Show the exact command and paths, then confirm immediately before each install mutation. An explicit yes covers that tool
   only. Verify after it finishes; a repeated healthy install changes nothing.
5. **Update.** Act only on `outdated`. Show old and pinned versions plus exact
   command/paths, then confirm immediately before each update mutation. Never
   select latest or enable auto-update. Verify afterward.
6. **Uninstall.** List only the named companion-owned package/plugin/files, then
   confirm immediately before removal. Preserve unrelated user configuration and
   never recursively delete a parent skill/rules directory.

One tool failing does not trigger retries or block the remaining selected tools.
Report the failing command and manual recovery.

## Pinned command reference

Always verify the values below against `companions.lock.json` before showing or
running them; packaging validation rejects drift.

### Install graphify

First available installer wins:

```bash
uv tool install graphifyy==0.9.38 || pipx install graphifyy==0.9.38 || python3 -m pip install --user graphifyy==0.9.38
graphify cursor install   # Cursor/Grok
graphify install          # Claude
```

For update, use the detected installer with the same exact package pin. For
uninstall, use that installer's named `graphifyy` removal command.

### Install ponytail

Claude:

```bash
claude plugin marketplace add DietrichGebert/ponytail
claude plugin install ponytail@ponytail
```

Cursor/Grok uses the lock's version-pinned URL. Download to `mktemp`, verify its
SHA-256 before replacing `.cursor/rules/ponytail.mdc`, then install mode `0644`.
Never download from `main`. Uninstall removes only the plugin registration or
that exact project rule after the lifecycle confirmation.

### **Install ui-ux-pro-max**

Only when requested or `has_ui`:

```bash
npm install -g ui-ux-pro-max-cli@2.15.0
uipro init --ai cursor              # Cursor/Grok
uipro init --ai claude              # Claude
```

Uninstall removes the named npm package and only the selected host's generated
project skill directory after listing it. Never touch neighboring skills.

## After a successful action

Report the local probe result. Reload Cursor/Grok or restart Claude Code when a
rule/plugin changed. For graphify, `/graphify .` remains an explicit opt-in; pure
code extraction is local, while semantic document extraction may use a configured
LLM backend.
