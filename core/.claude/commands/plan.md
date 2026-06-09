# /plan

Decompose a feature into a sequenced ticket plan via the `pm` agent.

## Usage

```
/plan <feature description>
```

## Steps

1. Spawn `pm` agent
2. `pm` asks clarifying questions if scope is ambiguous
3. `pm` produces `docs/plans/<slug>-plan.md` with:
   - Goal + success criteria
   - {{#enforce_layer_split}}BE + FE tickets in sequence{{/enforce_layer_split}}{{^enforce_layer_split}}Sequential tickets{{/enforce_layer_split}}, each ≤{{max_files_per_pr}} files / <{{max_loc_per_pr}} LOC
   - Branch names for each ticket
   - Test scenarios per ticket
4. **Pause for user approval.**
5. After approval, route the first ticket to the appropriate `*-dev` agent.
