<!-- requires: has_frontend -->
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

4. **Pause for user approval** before handoff to `frontend-dev`

5. After approval, route to `frontend-dev` for implementation
