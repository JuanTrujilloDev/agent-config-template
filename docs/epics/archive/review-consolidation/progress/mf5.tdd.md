## TDD: agent-style-and-release (@s34..@s40)

### Public behavior seams

- Subagent-dispatch command coverage and evidence.
- README credit and upgrade instructions.
- Four public plugin manifest versions.

### Scenario → check

- @s34–@s36 → all eight dispatch commands pass the style handoff contract;
  only the two central orchestrators mention `agent_style` among agent files.
- @s37 → README credit includes source, MIT status, originality, and no affiliation.
- @s38 → all four manifests report 0.9.1.
- @s39 → upgrade guide covers the five compatibility points.
- @s40 → build/packaging version checks run in smoke; full release suite runs
  after implementation.

### Red

Focused MF5 smoke → exit 1 on 2026-09-02. All eight dispatch-command checks
already passed and only the two central orchestrators referenced `agent_style`;
credit, upgrade evidence, and four manifest bumps were still missing.

### Green

Focused MF5 smoke and the full 1,250-assertion smoke suite pass. All four
manifests report `0.9.1`; packaging reports no skew; README credit and the
upgrade guide satisfy @s37–@s39.

### Refactor

Kept `agent_style` centralized. No per-agent pointer, runtime dependency, or
new review framework was added. The historical v0.9.0 release smoke now checks
version consistency instead of freezing future manifests at `0.9.0`.
