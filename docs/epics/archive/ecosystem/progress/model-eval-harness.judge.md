# Judge: model-eval-harness (@s1..@s8)

## Spec fidelity

Result: pass

- @s1–@s8 map directly to the catalog validator, inert plan, four fake adapters,
  deterministic rubric checks, two write gates, temporary cwd, and manual CI.
- `verified_by_human` remains unchanged; automated results use separate JSON.

## Standards & health

Result: pass

- Table-driven argv is justified by four current CLI protocols; no class
  hierarchy, dependency, shell string, or judge model was added.
- Python compile, catalog validation, generated-tree check, focused smoke, and
  whitespace checks pass.

## Security review

Severity: no critical, high, or medium findings.

- Host argv is passed as a list with `shell=False`; fixture paths must resolve
  inside the repository and model cwd is always a temporary rendered project.
- Live calls require `--run`; workspace cases additionally require
  `--allow-writes`. Results omit prompts, responses, stderr, argv, and environment
  values. Authentication errors are reduced to a fixed message.
- Residual host-native permissions remain visible in the README: the temporary
  cwd protects the source target, while each installed CLI still enforces its
  own filesystem/network permissions.

## Verdict

APPROVED
