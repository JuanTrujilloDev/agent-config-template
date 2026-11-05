---
name: epic
description: "Draft an epic once from a tracker card or a pasted ask: capability groups, one-case user stories, acceptance criteria, Given/When/Then test scenarios and layered slices. `/epic render <ID>` writes the repo copy and validates it."
argument-hint: "<ticket ID | ask> | render <ID>"
disable-model-invocation: true
---

# /epic

Turn a tracker card or a pasted ask into one epic draft the user approves by number. Do not interview; synthesize from the card, the conversation and the code, then ask only what blocks the draft.

Files (grammar in `docs/epics/EXAMPLE/` when this repo ships it, else the template below):

- `docs/epics/<ID>/epic.md`: ≤120 lines.
- `docs/epics/<ID>/slices/<n>.md`: one per slice, ≤60 lines, ≤5 stories (written by `/slice`).

## 1. Read the input

- A ticket id (`ABC-12`): read the card through the tracker MCP named in `CLAUDE.md` (MCP Servers): title, body, comments, sub-issues. If no tracker MCP is configured, ask for the card text.
- Free text: that text is the Request, quoted verbatim.
- Read `docs/CONTEXT.md` when it exists and use its terms.

## 2. Survey the code

Use the `code-query` skill (graph first, grep second) to find what the epic touches, what already exists to reuse, and the highest test seam per capability. Prefer existing seams; propose a new one only where none fits.

## 3. Draft once

Write the whole draft in the reply, using exactly these sections:

```markdown
# <ID> — <title>
## Request          the ask, verbatim, with its source and date
## Description      2–4 sentences: who, what changes, what stays the same
## Capability groups
| Group | Tracker | Stories |       one row per group; Tracker = module or `cap:<name>` label, or —
## User Stories
### <group>
- **S1** As a <actor>, I want <one behaviour> so that <benefit>.
## Acceptance Criteria
- **S1** One observable outcome with literal values.
## Test Scenarios
- **TS1** Given <state with literal values>, When <one action>, Then <observable result>.
## Technical tasks
| # | Layer | Name | Stories | Hours |   layers: db, be, fe (or the project's own layers)
## Estimate
<sum> h
```

Rules:

- One case per story: one When per TS, literal values (ids, emails, status codes, messages), no "etc.". Two Whens means two stories.
- Exactly one AC and one TS per story; `TSn` tests `Sn`. TS ≤5 lines.
- Story ids `S<n>` are global per epic and never renumbered once approved.
- Technical tasks are the slices: one row per layer per capability group, in `db → be → fe` order. No file paths, no MR links.

End the draft with a numbered list of open questions (only real blockers) and: `Reply "approve", or "change <n>: …" per section or story.`

## 4. Where it lives

After approval, ask once: **Do you want this epic and its slices as cards on a tracker? (default: no)** Create cards only on an explicit yes; no answer, or anything else, means no.

- **Yes**: create the epic card (label `epic`) with the approved body, then one sub-issue per Technical task (labels `slice` + layer), through the tracker MCP; when you cannot create cards, give the user the bodies to paste. Then run `/epic render <ID>` with the card id. The cards are the source of truth.
- **No** (the default): create no cards; pick the ID (the user's, else a short uppercase slug) and write the draft to `docs/epics/<ID>/epic.md` with this first line, then run the validator. These files are the source of truth.

```
<!-- source=local; docs/epics/<ID>/ is the source of truth; edit here, then run validate-epics.py -->
```

## `/epic render <ID>`

Read the epic card and its slice sub-issues and overwrite `docs/epics/<ID>/epic.md` and `slices/<n>.md` (sub-issue order = `n`). First line of each file:

```
<!-- generated from <tracker> <ID> at <ISO time>; source=<tracker>; edit the card, then `/epic render <ID>` -->
```

Never hand-edit a rendered file; change the card and render again. Keep each slice's `- Branch:` and `## Approved tests` lines when re-rendering: the test lock keys on them.

## Validate

Always finish with:

```bash
python3 .claude/skills/epic/validate-epics.py docs/epics/<ID>
```

ERROR lines (unknown story, missing section, missing `- Layer:` / `- Stories covered:`) must be fixed. WARN lines are size guidance; mention them, do not block on them. Next step: `/slice <ID> 1`.
