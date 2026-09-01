---
name: design
description: "Design workflow for a new UI feature — ui-designer wireframes and component specs before any code."
---

# /design

> **On Codex (no subagents):** you play every role yourself, switching hats
> explicitly and in sequence — `pmo` (spec/contract), the dev specialist
> (implement), `judge` (review), `security-reviewer` (when auth/permissions/
> data are touched). Same artifacts under `docs/specs/<slug>/`, same human
> gates (contract approval; failing tests under TDD), same Definition of Done.
> Announce each hat switch in one line.


Start the design workflow for a new UI feature.

## Usage

```
/design <feature description>
```

## Workflow

1. **Gather requirements**
  - What is the feature?
  - Who is the user?
  - What problem does it solve?
  - Constraints?

2. **Review existing patterns**
  - Check `docs/design-system/` for existing components
  - Identify reusable patterns

3. **Spawn `ui-designer`** to produce wireframes + component specs

4. **Pause for user approval** before handoff to `frontend-dev`

5. After approval, route to `frontend-dev` for implementation
