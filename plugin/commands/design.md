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
   - Read `docs/design-system/MASTER.md` (and `docs/design-system/pages/<page>.md` if the page has an override). Every spec cites its tokens.
   - If MASTER.md is missing, create it from the template sections, in this order: Colors & semantic tokens, Typography, Spacing & layout, Radius, shadows & motion, Component conventions, Icon & image style, Voice & tone, Responsive rules, Accessibility & contrast, Anti-patterns. Leave `TODO:` where a value cannot be inferred from the codebase.
   - If the `ui-ux-pro-max` skill is installed you MAY delegate palette/typography generation to it, then normalize its output into the MASTER.md token table format above. `ui-ux-pro-max` is optional and never vendored into this template; without it, fill the sections by hand.
   - Identify reusable components under `docs/design-system/` and in the codebase

3. **Spawn `ui-designer`** to produce wireframes + component specs

4. **Pause for user approval** before handoff to `frontend-dev`

5. After approval, route to `frontend-dev` for implementation
