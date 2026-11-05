## TDD: two-axis-verdicts (@s8..@s16)

### Public behavior seams

- Judge report headings, axis results, finding labels, and final verdict.
- Security report severity, finding labels, and final verdict.
- Adversarial-review trigger and placement rules.

### Scenario → check

- @s8 → judge has two exact axes and one allowed result per axis.
- @s9 → every finding has one class and axes are never cross-ranked.
- @s10 → judgment-call-only reports approve.
- @s11 → hard violations request changes.
- @s12 → security keeps severity and exposes the same exact verdict contract.
- @s13–@s15 → adversarial review uses only size/risk triggers and stays in axes.
- @s16 → source/plugin/rendered reviewers and three workflow surfaces agree.

### Red

Focused MF2 smoke → exit 1 on 2026-09-02. Existing reviewers lack the two axes,
finding classes, exact verdict, proportional adversarial trigger, and shared
workflow contract. Existing security severity headings remain present.

### Green

`bash scripts/smoke.sh` → exit 0. All @s8–@s16 checks pass across source,
plugin, rendered, and shared-workflow surfaces. Older pattern/principles smoke
assertions were updated from `Blocker` to the new `hard-violation` term.

### Refactor

Reused the existing report templates and adversarial lenses. No new reviewer,
command, parser, or severity scheme was introduced.
