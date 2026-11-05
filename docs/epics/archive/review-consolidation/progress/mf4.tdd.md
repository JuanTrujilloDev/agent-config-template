## TDD: tdd-quality-guardrails (@s26..@s33)

### Public behavior seams

- Shared TDD workflow policy.
- Feature/orchestrator implementer handoff.
- Gate 2 evidence contract.

### Scenario → check

- @s26–@s28 → public seams precede tests and unconfirmed internals stay private.
- @s29 → expected values come from independent sources, never production logic.
- @s30 → mocks stop at external boundaries.
- @s31 → one vertical red/green slice completes before the next.
- @s32–@s33 → every host route passes the shared guardrails plus `agent_style`,
  with no duplicated full policy in stack agents.

### Red

Focused MF4 smoke → exit 1 on 2026-09-02. Existing TDD guidance required a
failing test but did not define public seams, independent expectations, mock
boundaries, or vertical red/green slices.

### Green

`bash scripts/smoke.sh` → exit 0. All workflow sources define the four
guardrails, every feature/orchestrator route passes them with `agent_style`, and
no stack-agent copy was added.

### Refactor

Kept one policy block per host workflow and one short handoff pointer per route.
No new TDD skill, test framework, mock library, or stack-specific duplication.
