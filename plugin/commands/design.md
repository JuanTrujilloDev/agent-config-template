---
description: Design workflow for a new UI feature — ui-designer wireframes and component specs before any code.
argument-hint: "<feature description>"
---

# /design

Start the design workflow for a new UI feature.

## Usage

```
/design <feature description>
```

## Workflow

Read `agent_style` from `.claude/answers.local.env` once before spawning (absent, empty, or unrecognized = `terse`). Add `agent_style: <terse|descriptive> — return per "Report format" in the principles skill` to every subagent prompt this command spawns. Persisted artifacts stay prose.

1. **Gather requirements**
  - What is the feature?
  - Who is the user?
  - What problem does it solve?
  - Constraints?

2. **Load the brand system**
   - Read `docs/design-system/MASTER.md`, its machine-readable value source `docs/design-system/tokens.json`, and `docs/design-system/pages/<page>.md` if the page has an override. Every spec cites semantic tokens.
   - If the files are missing, create them from the template sections and token groups. Leave `TODO:` where a value cannot be inferred from the codebase; resolve every TODO used by this feature before implementation.
   - Keep all ten sections: Colors & semantic tokens, Typography, Spacing & layout, Radius, shadows & motion, Component conventions, Icon & image style, Voice & tone, Responsive rules, Accessibility & contrast, Anti-patterns.
   - If the `ui-ux-pro-max` skill is installed you MAY delegate palette/typography generation to it, then normalize its output into the MASTER.md token table format above. `ui-ux-pro-max` is optional and never vendored into this template; without it, fill the sections by hand.
   - Identify reusable components under `docs/design-system/` and in the codebase

3. **Synchronize exactly one code target**
   - Reuse the theme mechanism already present. Default mapping: web → CSS custom properties (including Tailwind projects); Flutter → `ThemeExtension` or `ThemeData`; Unity → `ScriptableObject`; desktop → its native theme facility; unknown UI stack → JSON-only.
   - Do not generate adapters the project does not use. The target contains semantic names from `tokens.json`, not a second palette.
   - Write `docs/design-system/tokens.lock.json` with `schema_version`, `adapter`, `source`, `source_sha256`, `target`, and `target_sha256`. Hash exact file bytes with SHA-256; `source` and `target` are repository-relative paths, never absolute machine paths. For JSON-only, source and target are both `docs/design-system/tokens.json`.

4. **Spawn `ui-designer`** to produce wireframes + component specs

5. **Pause for user approval** before handoff to `frontend-dev`

6. After approval, route to `frontend-dev` for implementation
