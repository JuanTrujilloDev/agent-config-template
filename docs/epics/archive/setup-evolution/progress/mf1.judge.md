# Judge: config-scopes-workflow-mode  (@s1..@s6)

**Stats:** 15 files, 256 lines churn (7 hand-authored: setup.sh, template.config.yaml, core/feature.md, core/orchestrator.md, plugin/commands/setup-template.md, docs/sdd-workflow.md, features.json; 8 generated mirrors ride along per spec D10). Within max_files=8 / max_loc=400.

**Scenario → verification** (executed by judge, not taken on faith):

| Scenario | Check | Result |
|---|---|---|
| @s1 | Rendered with `workflow_mode=SDD+TDD`: feature.md → "TDD is on by default … Gate 2: you approve the tests … applied per mini-feature, skippable per mini-feature"; orchestrator.md step 3 → "TDD is on by default … STOP at Gate 2 … unless the human skips TDD for this mini-feature" | ✓ |
| @s2 | Rendered with `workflow_mode=SDD` and with key absent: feature.md → "TDD is off by default and available on request ('with TDD')". `diff -r` of the two renders: **byte-identical** (back-compat proven) | ✓ |
| @s3 | template.config.yaml defines `workflow_mode`, choices `[SDD, SDD+TDD]`, default `SDD`; header comments document all three scopes (committed answers.env / gitignored .claude/answers.local.env / session keywords) | ✓ |
| @s4 | setup-template.md step 5 gitignore block lists `.claude/answers.local.env`, no longer lists `answers.env`; explicit "`answers.env` is **committed** — never gitignore it". upgrade-guide.md already says `git add answers.env # the source of truth` (line 27) and contains no gitignore advice for it — consistent, no edit needed | ✓ |
| @s5 | setup.sh diff is exactly the 4-line synthesis (`if ANS.get("workflow_mode","").strip() == "SDD+TDD": ANS["workflow_tdd"] = "yes"`) at section 2a, directly mirroring the `ticket_tracker` flag_map pattern above it. Lives in the embedded Python — bash 3.2 not implicated. Two consecutive SDD+TDD renders: byte-identical | ✓ |
| @s6 | docs/sdd-workflow.md: one new paragraph after Gate 2 naming `workflow_mode` as the TDD-default source, "flow itself is identical either way; only the default flips" — no flow change | ✓ |

Diff isolation verified: only `feature.md` and `orchestrator.md` differ between SDD and SDD+TDD renders; no stray `{{#workflow_tdd}}` markers survive rendering; no blank-line artifacts at the removed sections. `build.sh` regenerated mirrors with zero new drift, `build.sh --check` exit 0, `validate-packaging.py` green (v0.8.0).

**Semantics check (@s1 wording vs sdd-workflow/CLAUDE.md):** the SDD+TDD variant preserves per-mini-feature application ("applied per mini-feature"), per-mini-feature skippability ("skip TDD" / "unless the human skips"), and Gate 2 as a human STOP. No contradiction with core/CLAUDE.md or the workflow doc.

### Blockers
- None.

### Major
- None.

### Minor
- `plugin/commands/setup-template.md:60` — the Config scopes table presents `.claude/answers.local.env` (`autonomy_mode`, `verbosity`, `companions`, "read at session time") as existing behavior; nothing reads that file until MF2/MF3 land. No "landing in MF2" marker exists anywhere in the diff, contrary to what the handoff claimed. Fine inside this release train, but **MF1 must not ship in a release without MF2** or the docs promise a mechanism that doesn't exist. Not a blocker: same-branch, same-release.
- `docs/specs/setup-evolution/features.json` — full compact→expanded JSON reformat (~110 lines of churn) when the only real change is `status: in_progress`. Drive-by reformat; keep diffs surgical next time (likely a JSON tool round-trip).

### Nits
- `setup.sh:536` — the post-render "Add to .gitignore" hint still lists only `settings.local.json` + `mcp.json`; could add `.claude/answers.local.env` for consistency with setup-template.md step 5. Not contract-required (@s4 names only the two docs).
- Config-scopes documentation now exists twice (template.config.yaml header + setup-template.md table). Two copies is under the rule of three and the table feeds MF3's @s16, so acceptable — watch it if a third copy appears.
- Rendered `feature.md` frontmatter description and CLAUDE.md still say "optional TDD" even under SDD+TDD. Literally true (skippable per mini-feature), so no contradiction — just slightly stale flavor.

### Adversarial findings
Diff >200 lines → three lenses run; overreach pruned in synthesis.
- **Skeptic:** lowercase/typo values (`workflow_mode=sdd+tdd`) silently fall back to SDD with no warning. Identical tolerance to the existing `ticket_tracker` pattern (contract mandates that pattern), and `.strip()` handles trailing whitespace. Downgraded to no-action: not a new failure mode, and the contract's Design notes forbid inventing validation machinery here (YAGNI).
- **Architect:** flag synthesis placed at section 2a between the ticket-tracker and project-type synthesis blocks — right shape, single call site, zero parser change, exactly the spec's Design notes. No findings.
- **Minimalist:** everything traces to a scenario except the features.json reformat (Minor above) and the setup-template scopes table (kept — feeds @s16). Nothing to prune.

### Verdict
- [x] APPROVED   - [ ] CHANGES REQUESTED

No security-relevant surface (no auth/permissions/external input) — security-reviewer not required. Approval is conditional only on the release-sequencing note: MF2 must land before v0.8.1 ships, which the ratified train already guarantees.
