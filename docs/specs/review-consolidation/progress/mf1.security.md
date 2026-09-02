# Security review: MF1 verify-preflight

## Scope

User-supplied Git refs, diff/spec path discovery, and instruction smoke tests.

## Findings

No security findings.

- Ref validation uses `git rev-parse --verify --end-of-options`, preventing a
  dash-prefixed value from becoming an option.
- `merge-base` receives the validated full SHA, not the raw user value.
- Returned paths stay data-only; untracked contents use a path-safe file-read
  tool, and no path is evaluated or interpolated as a command.
- Invalid refs and empty scopes stop before reviewer dispatch.

## Verdict

APPROVED
