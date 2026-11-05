# Judge: packaging-validation-ci  (@s19..@s21)

**Stats:** 6 files, 82(+)/8(−) lines — validate-packaging.py (+64), ci.yml (+10),
3 manifest version one-liners, features.json ledger flip.
**Scenario → test:** @s19 → validator clean run exit 0 ✓ (re-ran) ;
@s20 → seeded unquoted-colon `.mdc` AND invalid `hooks.json`, both exit 1 naming
the exact file ✓ (verified on BOTH parser paths — pyyaml and the no-yaml
heuristic fallback) ; @s21 → ci.yml cursor render-smoke steps executed locally
against node-nextjs, all green ✓ ; version-skew seeded (codex 0.7.9) →
exit 1 naming all three manifests ✓.

## Verified by execution

- `bash scripts/build.sh && bash scripts/build.sh --check &&
  python3 scripts/validate-packaging.py` — all green; build leaves only the
  6 diff files modified (no hidden drift).
- ci.yml parses as YAML; the new cursor steps live inside the existing
  `render-smoke` run block that ends in `exit $fail` — wired, not dead config.
- Validator integrity: extensions reuse `parse_frontmatter` /
  `walk_components` (parameterized, no parallel parser); imports remain
  stdlib-only (`json, os, re, sys`; yaml stays the optional in-function
  fallback). `disable-model-invocation` check handles both bool-True (yaml)
  and string "true" (fallback).
- Version sweep: `grep -rn 0.7.1` outside docs/specs history → nothing left;
  plugin.json, marketplace.json, codex plugin.json all 0.8.0; skew check now
  covers codex (per @s21).

### Blockers
- `scripts/validate-packaging.py:184-185` — **the mustache-strip mcp.json check
  passes a genuinely broken template.** Empirically verified: seeding an
  unconditional trailing comma after the playwright entry in
  `core/.claude/mcp.json.example` (replacing the conditional
  `{{#ticket_tracker_*}},{{/...}}` seams), rebuilding, and running the
  validator → **exit 0**. The two truthy sets (`{}` and
  `{has_e2e, ticket_tracker_plane}`) never exercise the
  *has_e2e-without-MCP-tracker* render — which is the **default
  configuration** (`ticket_tracker` defaults to `GitHub`; 4 of 6 examples use
  it). CI render-smoke doesn't back-stop it either: the cursor render uses
  node-nextjs (Linear → comma valid). A validator whose stated job is "the
  rendered form must parse" that green-lights a broken render of the default
  config fails the tests-bite bar. **One-line fix:**
  `check_mustache_json("cursor/.cursor/mcp.json", truthy={"has_e2e"})`.

### Minors
- Micro-PR budget ruling (asked explicitly): ledger says `max_files: 4`;
  substantive diff is 5 files (+ features.json status flip = 6 modified).
  **Ruling: overage waived, honestly.** @s21 and spec Q2 mandate the 0.8.0
  agreement across exactly three manifests, and the bump was scheduled into
  this final MF by the spec itself — three one-line bumps in three files is
  the irreducible minimum; validator + ci.yml are the other two contract
  surfaces. The minimum possible file count for this contract was 5, so the
  budget was mis-set at planning time, not busted by scope creep. Well inside
  global micro-PR caps (≤12 files, <3000 LOC; actual 6 files / ~90 LOC).
  Correct `max_files` to 6 when flipping MF7 to done.

### Nits
- `.github/workflows/ci.yml:51` — cursor render-smoke covers one example
  (node-nextjs/Linear). Fine per @s21 ("one example answers file"), but once
  the Blocker fix lands the validator covers the seams, so no CI change needed.

### Whole-release closing check (final MF)
- `build.sh` / `build.sh --check` / `validate-packaging.py`: all green.
- features.json: MF1–6 `done`, MF7 `in_progress` ✓; version field 0.8.0 ✓.
- Scenario ledger @s1–@s24: every scenario traces to shipped work —
  mf1–mf6 judge files all APPROVED; spot-checks re-verified live:
  @s5 (no Claude-as-actor idioms in core/), @s10 (no Claude hooks block under
  cursor/), @s11 (hooks.json registers only `beforeShellExecution` /
  `afterFileEdit`), @s15 (`--host opencode` exits 1 pointing at port-config),
  @s16–@s18 (cursor.md, grok.md, host-capability-matrix.md present),
  @s19–@s21 (this MF, above). No orphan scenario.

### Verdict
- [ ] APPROVED   - [x] CHANGES REQUESTED

One one-line Blocker in validate-packaging.py (add the `{"has_e2e"}` truthy
pass); everything else — including the file-budget overage — is approved as-is.
Re-run `python3 scripts/validate-packaging.py` after the fix and flip MF7 to
done.
