<!-- requires: has_ui -->
---
name: design
description: "Design workflow for a new UI feature — ui-designer wireframes and component specs before any code."
disable-model-invocation: true
---

# /design

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

4. **Pause for user approval** before handoff to the implementing dev agent

5. After approval, route to {{#has_frontend}}`frontend-dev`{{/has_frontend}}{{^has_frontend}}`{{primary_dev_agent}}`{{/has_frontend}} for implementation
