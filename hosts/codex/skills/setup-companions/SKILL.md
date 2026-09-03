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

Read `companions.lock.json` beside this `SKILL.md` before doing anything. It owns
source, version, method, probe, package and direct-download SHA-256. If missing or
invalid, stop; do not reconstruct it or search for a newer release. The active
host is Codex.

## Lifecycle

1. **Detect local state.**
   - graphify: executable, version, and Codex integration.
   - ponytail: Codex plugin registration and version.
   - ui-ux-pro-max: `.agents/skills/ui-ux-pro-max/`; source `github.com/nextlevelbuilder/ui-ux-pro-max-skill`.
2. **Show the plan and STOP for confirmation.** `plan` is offline and read-only.
   Print the source, pinned version, exact install command, and what each writes.
   Install nothing without an explicit yes.
3. **Doctor (offline, read-only).** Use only local executable, version, plugin,
   path and SHA-256 probes. Report each tool as `missing`, `healthy`, `outdated`,
   or `unverifiable`; do not repair it.
4. **Install.** Skip `healthy`. Show exact command and paths, then confirm immediately before each install mutation. An explicit yes covers that tool
   only. Verify afterward; a repeated healthy install changes nothing.
5. **Update.** Act only on `outdated`. Show old and pinned versions plus exact
   command/paths, then confirm immediately before each update mutation. Never
   select latest or enable auto-update. Verify afterward.
6. **Uninstall.** List only the named companion-owned package/plugin/files, then
   confirm immediately before removal. Preserve unrelated user configuration and
   never recursively delete a parent skill directory.

One tool failing does not trigger retries or block the remaining selected tools.
Report the failing command and manual recovery.

## Pinned command reference

Always verify these values against `companions.lock.json` before use; packaging
validation rejects drift.

### Install graphify

```bash
uv tool install graphifyy==0.9.38 || pipx install graphifyy==0.9.38 || python3 -m pip install --user graphifyy==0.9.38
graphify install --platform codex
```

Use the detected installer with the same pin for update; use its named
`graphifyy` removal command for uninstall.

### Install ponytail

```bash
codex plugin marketplace add DietrichGebert/ponytail
codex plugin add ponytail@ponytail
```

Open `/hooks`, review and trust the two lifecycle hooks. The direct-download
entry is for Cursor only: if ever used, download to `mktemp` and verify SHA-256 before replacing its exact target. Never download from `main`.

### **Install ui-ux-pro-max**

Only when requested or the project has a UI:

```bash
npm install -g ui-ux-pro-max-cli@2.15.0
uipro init --ai codex
```

Uninstall removes the named npm package and only
`.agents/skills/ui-ux-pro-max/` after listing it. Never touch neighboring skills.

## After a successful action

Report local probes: `graphify --version`, `codex plugin list`, and the selected
skill path. Restart Codex when plugin/skill state changed. `/graphify .` remains
explicit opt-in; pure code extraction is local, while semantic document
extraction may use a configured LLM backend.
