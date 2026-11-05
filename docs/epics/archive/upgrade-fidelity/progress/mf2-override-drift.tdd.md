# MF2 override-drift — TDD

## Public seams

- `python3 scripts/check-override-headings.py` checks all known whole-file
  source/override pairs.
- Passing two paths checks one fixture pair.
- Missing source H2 headings produce exit 1 and name the source, override, and
  exact heading.
- `<!-- override-ignore-h2: Exact heading -->` exempts only that heading.

## Red

- Scenario: `@s12` rejects a source heading missing from its override.
- Test: `scripts/smoke/v092-mf2-override-drift.sh`.
- Observed: exit 2; the checker does not exist, so no source/override/heading
  diagnostic is produced.

## Green

Implemented the stdlib checker, exact waivers, build gate, and @s10..@s15 focused tests; all passed with no further refactor needed.
