---
name: scope-page
description: "Deliver a scope, plan or design as a markdown companion plus a self-contained story-walkthrough page: user flows step by step on real screens, then (once the design is approved) the slices per flow and a Plan checklist the slice threads tick. Builds offline HTML with build.mjs, checks it in a browser with verify.mjs."
argument-hint: "<design folder>"
---

# scope-page

Every scoping, plan or design task delivers two things before any epic or code exists, both in a design folder outside the repository (never commit the built page or its captures):

1. **The markdown scope**: the technical companion (code read, decisions, estimates).
2. **The page** `scope/index.html`: one self-contained file that works offline, built from `_build/content.mjs`.

```
<design folder>/
  <feature>-scope.md       the markdown (Round N decisions on top)
  design.md                the approved design (architect)
  _build/content.mjs       stories, screens, build, plan, questions (data only)
  _build/captures/*.png    real captures with invented sample data
  _build/progress/*.json   one per slice, written by that slice's thread
  _build/round<N>/         earlier rounds, copied before each rebuild
  scope/                   the built page, plan-checklist.md, report.md, verification
```

## The order

1. **Flows.** The scope holds the user flows only: each story is a step-by-step walk, one screen per step, the last step showing the outcome. No slices yet.
2. The user approves the scope. Then `architect` designs it and the user approves the design.
3. **Plan.** Only now add `plan` to `content.mjs`: the design's slices, each naming the flow steps it builds. The page then shows "Built by" chips on each step, a flow → slices diagram per story and a Plan checklist with every slice `todo`. Then `/epic`.
4. **Progress.** Each slice's thread writes its own `_build/progress/<slice>.json` and rebuilds the page (`implement`). One writer per file, so parallel slice threads never collide; the user only reads the checklist.

## Screens

Every screen is a real capture or is marked: **Today** (a real capture, unchanged), **Approved design** (a capture of a design already approved) or **Proposed** (a capture with HTML overlays on the design tokens; every new element has a dashed outline). A drawn `kind: 'html'` screen says "drawn" in its title and legend. Capture from a local run or staging with invented sample data; never show real client data.

## content.mjs

Start from [example/content.mjs](example/content.mjs). Exports:

| Export | What |
| --- | --- |
| `meta` | `title`, `product`, `heading`, `intro`, `byline`, `codeRead`, `scopeMarkdown`; optional `tokens`: a CSS file of design tokens relative to `content.mjs` (default: this skill's `tokens.css`, same variable names) |
| `images` | captures: `path` relative to `content.mjs`, pixel `w`/`h`, `origin` |
| `screens` | `img`, `crop` `[x, y, w, h]`, `status` (`today`, `approved`, `proposed`), `title`, `overlays`; or `kind: 'html'` with `html` and `legend` |
| `stories` | `id`, `theme`, `actor`, `title`, `goal`, `steps` (`screen`, `action`, `text`), `outcome`, `related`, `questions` |
| `build` | optional `intro`, `diagrams`, `codemap`, `efforts`, `slices`, `order`, `followups` |
| `plan` | after design approval only: `slices: [{ id, layer, name, flows: { <story id>: [step numbers] }, hours }]`; `id` is the slice number `/epic` gives it (`slices/<n>.md`) |
| `decisions`, `assumptions`, `questions` | the Questions tab; every open question has `who`, `why` and a default `def` |
| `css` | optional classes for this scope only, on the design tokens |

A progress file (`_build/progress/<slice>.json`):

```json
{ "slice": "2", "layer": "be", "status": "review", "branch": "feature/EX-1-export-be", "mr": "!12", "head": "9f31c0a",
  "review": [{ "file": "app/exports/views/fund_export_views.py", "lines": "1-40", "why": "the endpoint and its permission" }],
  "dod": "format, lint, changed lines, slice tests 6 passed, suite green", "updated": "2026-11-20T11:05:00-05:00" }
```

`status` is one of `todo`, `tests approved`, `in progress`, `review`, `done`. `review` lists the files the user should read, from the slice's Placement rows, approved tests last.

## Build and verify

```bash
node .claude/skills/scope-page/build.mjs "<design folder>/_build/content.mjs"   # writes <design folder>/scope/
node .claude/skills/scope-page/verify.mjs "<design folder>/scope"               # needs Playwright
node --test .claude/skills/scope-page/build.test.mjs                           # the builder's own tests
```

`build.mjs` stops with a message naming the broken entry: a missing screen, image, crop, status, related story, question or diagram; a plan slice naming a missing flow or step; a progress file for an unknown slice or status. It writes `index.html`, `source-mapping.json` and, with a plan, `plan-checklist.md`. `verify.mjs` walks every story and step at 1440 px and 390 px (images decode, captions, outcomes, the checklist lists every slice, no console errors, no horizontal overflow) and saves a screenshot per tab and width. Look at the screenshots too. Then write `scope/report.md` by hand: what the page holds, where each screen came from, the verification result and its gaps, how to rebuild.

## Review rounds

Put the reviewer's answers in a dated `## Round N decisions (<who>, <date>)` block at the top of the markdown; it overrides older text below it. Copy the previous page, `content.mjs` and markdown to `_build/round<N>/`, then rebuild and verify again. Never record an approval the reviewer did not give.
