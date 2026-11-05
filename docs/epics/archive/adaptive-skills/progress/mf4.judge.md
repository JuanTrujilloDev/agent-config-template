## Judge: mf4 brand-system  (@s25..@s32)

**Stats:** 8 hand-authored files (core agents x4, core/commands/design.md, core/docs/design-system/MASTER.md, scripts/build.sh, scripts/smoke.sh); 29 files incl. build outputs; +183/-33 tracked + 159-line MASTER.md. Budget ≤12 met; <3000 lines.
**Scenario → test:** @s25 → smoke "@s25 line 1 / ten H2 in order / page overrides note / only when deviate" ✓ ; @s26 → smoke node-nextjs/flutter-mobile/unity-game rendered+H2+zero `{{`+TODO, python-fastapi absent ✓ ; @s27 → smoke cursor render ✓ ; @s28 → smoke reads/pages/cites + `before` ordering x3 + inline-styles gotcha ✓ ; @s29 → smoke judge line (frontend_dir, color/spacing/radius/font, file:line, rendered resolved) ✓ ; @s30 → smoke step-2 awk slice: reads, creates-when-missing, ten sections, delegate, normalize, optional/never vendored ✓ ; @s31 → smoke parity x4 agents + design.md, zero `{{` ✓ ; @s32 → smoke build --check + cmp cursor==core ✓

**Verified:** smoke.sh 236 PASS / 0 FAIL. `build.sh --check` exit 0. Double build: tree identical (status hash unchanged across two builds). `validate-packaging.py` green @ v0.8.1. Renders: node-nextjs MASTER present (0 `{{`, 26 TODO, Stack line filled); flutter-mobile + unity-game present (0 `{{`, 26 TODO); python-fastapi absent (no `docs/` at all). Parity: core == plugin/template == cursor == plugin/cursor byte-identical for 4 agents + design; codex/plugin codex identical; docs trees identical across cursor/, plugin/cursor/, plugin/template/.

**Originality vs ui-ux-pro-max (`scripts/design_system.py` `format_master_md` / `format_page_override_md`, fetched from main):** schema adapted (MASTER + `pages/<page>.md` override, override wins), wording original. Upstream headings: Global Rules / Color Palette / Spacing Variables / Shadow Depths / Component Specs / Style Guidelines / Anti-Patterns (Do NOT Use) / Pre-Delivery Checklist; header is a `> LOGIC:` blockquote. Ours: ten different H2s, "Rules of use" paragraph, token tables. Only overlaps are WCAG facts (4.5:1, 44px targets, `prefers-reduced-motion`, visible focus) phrased differently; breakpoint test list differs (320/768/1024/1440 vs 375/768/1024/1440). No lifted sentences. Optional/never-vendored honored: no upstream code or data in repo.

**Content review:** usable, not padding. Semantic color table with light/dark TODO cells and role column; type scale with concrete size/line-height/weight defaults; 4px spacing scale; radius/shadow/motion tokens with durations + reduced-motion rule; component states incl. empty/loading/error; contrast minimums (AA floor, 4.5:1 / 3:1 large & UI, focus ring 2px/2px); breakpoints; anti-patterns phrased as judge-decidable findings with examples. Stack-agnostic enough: Rules of use shows `var(--x)` / `$space-4` / `theme.radius.md` forms so Flutter/Unity can map tokens; px defaults read as logical px. Web-leaning bits (breakpoint table, ARIA, `outline: none`) are harmless for mobile/game and stated alongside "platform-native controls first".

**Wiring:** ui-designer: read-before line above Responsibilities + step 2 of workflow; frontend-dev/mobile-dev: `## Brand system (read before coding)` between design artifact and Design notes & TDD — sensible. Judge line: "hardcoded color, spacing, radius, or font values not traceable to a MASTER.md token (or pages override) ... cite file:line", scoped `under {{frontend_dir}}` when has_frontend — decidable and scoped. design.md: "you MAY delegate ... `ui-ux-pro-max` is optional and never vendored into this template; without it, fill the sections by hand" — optionality unmistakable.

### Blockers
- none

### Ruling on implementer's skipped item (judge UI line not gated on `has_ui`)
- **Minor, non-gating.** @s29/@s31 never asked for the gate, and in the python-fastapi render the line is inert noise, not a wrong instruction. But it dangles a reference to a file the render does not contain and breaks the template's own convention (ui-designer is dropped for API-only). Fix is two standalone lines (`{{#has_ui}}` / `{{/has_ui}}` on their own lines; STANDALONE_RE strips them cleanly) plus one smoke check on the fastapi render. Recommend folding into this commit; not required to merge.

### Nits
- core/docs/design-system/MASTER.md:5 — inline `{{#has_frontend}}Stack: …{{/has_frontend}}` leaves a blank line in flutter/unity renders (double blank after the intro sentence). Put the section tags on their own lines.
- core/docs/design-system/MASTER.md Responsive rules — table is web-only; for mobile/game renders a `TODO:` hint ("map to device classes / UI canvas scaler") would make it fillable rather than skipped. Optional.
- scripts/smoke.sh:302 `first_line` — `sed 's/^$/0/'` never fires (sed sees zero lines on no match); `${a:-0}` in `before` already covers it. Dead, remove.
- scripts/smoke.sh at 374 lines — approaching the ~400 guideline; MF5+ will cross it. Consider one file per MF (`smoke.d/`) before the next mini-feature, not in this one.
- frontend-dev.md / mobile-dev.md — identical "Brand system" paragraph (2 copies; rule of three not hit). Watch if a third dev agent gets it.

### Verdict
- [x] APPROVED   - [ ] CHANGES REQUESTED

Security-reviewer: not required (no auth, permissions, or external input touched).
