# Judge: integrate-command (@s19..@s23)

**Stats:** 2 hand-authored command files, 116 lines total, plus workflow state. Limit: 6 files / 500 LOC. Five generated mirrors are excluded by D10. Branch: `feature/setup-evolution`.

| Scenario | Evidence | Status |
|---|---|---|
| @s19 canonical lookup, disclosed plan, confirmation stop | `integrate.md` research fields L14–25; plan L29–41 | ✓ |
| @s20 MCP JSON + CLAUDE line; tracker is a separate offer | apply flow L43–50; tracker gate L54–56 | ✓ |
| @s21 offline/failed lookup has no partial writes | failure path L27 | ✓ |
| @s22 decline changes nothing | explicit stop L41 | ✓ |
| @s23 all host variants generated and validated | seven source/generated paths found; build and packaging checks green | ✓ |

## Review

- Preflight parses existing JSON before installs or writes.
- Existing MCP entries and unrelated content are preserved.
- Secrets remain environment-variable placeholders.
- Remote shell pipelines, privileged installs, and global installs require separate confirmation.
- Ponytail: reused the current command-to-skill pipeline and MCP example; no registry, dependency, helper, or abstraction added.
- Security pass: official sources preferred, community sources labeled and checked, exact install command disclosed, zero automatic execution before approval.

## Checks

- `bash scripts/build.sh --check` — generated trees in sync.
- `python3 scripts/validate-packaging.py` — packaging valid at v0.8.0.
- `git diff --check` — clean.

## Verdict

- [x] APPROVED
- [ ] CHANGES REQUESTED
