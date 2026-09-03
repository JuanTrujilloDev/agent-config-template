# Judge: companion-lifecycle (@s16..@s22)

## Spec fidelity

Result: pass

- @s16–@s22 map to the lock validator, generated Codex copy, lifecycle text,
  explicit gates, digest check, scoped removal, mutation fixture, and guide.
- Companions remain optional; no automatic install, update, or network action was
  introduced.

## Standards & health

Result: pass

- The manifest pattern matches the approved force: three host surfaces consume
  one pin source. Existing command/override seams are reused; no manager class,
  runtime dependency, or general package abstraction was added.
- Build, packaging, focused smoke, JSON, and whitespace checks pass.

## Security review

Severity: no critical, high, or medium findings.

- Install/update/uninstall require per-tool confirmation immediately before the
  mutation. Doctor and plan prohibit network and writes. Uninstall targets are
  named and parent-directory recursion is forbidden.
- Cursor Ponytail downloads from the immutable v4.9.0 URL and verifies SHA-256
  before replacement. The remote artifact was fetched on 2026-09-02 and matched
  `e5b63124834c65e73208e8349e6cfd90b56757646c576a393932a01adc63940f`.

## Verdict

APPROVED
