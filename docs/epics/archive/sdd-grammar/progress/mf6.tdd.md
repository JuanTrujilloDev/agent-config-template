## TDD: brownfield-readme-release (@s34..@s41)

### Scenario → check

- @s34/@s35 → existing-project guide assertions cover survey, preview, safe
  merge, conflicts, host choice, contract/checks/rollback, optional trackers,
  and opt-in companions.
- @s36–@s39 → README assertions cover the first-80 quick starts, line budget,
  one workflow diagram/table, grammar, retained paths, and Spec Kit credit.
- @s40 → all release manifests and upgrade notes report v0.9.0 with no skew;
  Cursor's root manifest resolves every native component path.
- @s41 → final repository, deterministic-build, and four-host checks are
  recorded after the focused release assertions pass.

### Red

Focused smoke → exit 1 before implementation: the brownfield guide, v0.9
grammar/credit markers, synchronized manifests, and release notes were absent.

### Green

Focused and full smoke → exit 0. README is 223 lines; 31 local links resolve;
all manifests report 0.9.0; Cursor plugin JSON, component paths, command
frontmatter, and hook behavior validate; 24 example/host renders have zero
placeholders and valid shell/JSON; five generated trees are byte-stable.

### Refactor

README is a 223-line landing page with one workflow diagram and one command
table. Detail moved to existing guides plus one 73-line brownfield guide.
