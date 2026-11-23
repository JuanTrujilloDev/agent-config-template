---
name: architect
description: "Design an approved scope on three providers before the epic: each model writes a full low-level design (screens, backend, security, complexity, slices with a file per piece), this thread consolidates them once, interrogates every claim with something that runs, and hands one design to the user. Once per epic. Adapted from cursor/plugins pstack architect, arena and interrogate (MIT)."
argument-hint: "<design folder>"
disable-model-invocation: true
---

# architect

> **On Codex (no subagents):** run every step in this thread, in sequence.
> `code-review` runs its Standards axis, then its Spec axis, and reports them
> separately; `security-reviewer` becomes a read-only pass you announce in one
> line. Same files under `docs/epics/<ID>/`, same user gates (epic draft, slice
> brief, approved tests), same Definition of Done.


Once per epic, after the user approves the scope (flows only, `scope-page` skill) and before `/epic`. Not for `/fix`. Output: `<design folder>/design.md`, approved by the user.

Inputs every model gets, and nothing from this conversation: the approved scope markdown with its `Round N decisions`, `.claude/rules/architecture-map.md`, the `code-query` findings for what the scope touches, and [design-template.md](design-template.md).

## 1. Brief three models: same inputs, a full design each

Each model writes the whole design: screens, backend, security, complexity and the slices per flow, with a Placement row for every piece. Each brief stresses the model's lead area:

| Model | Lead area | Stressed in the brief |
| --- | --- | --- |
| Claude (the user's pick) | Frontend and design | templates, partials, components, state, tokens, every screen state |
| Codex (the user's pick) | Backend | the file for each piece from the map, signatures, query plan, migrations, Complexity; two shapes, keep one |
| Cursor (the user's pick) | Security | who reads and writes each endpoint and field, validation, what must not leak; give it the project's security scan output (`ruff --select S`, `npm audit` or the stack's equivalent) |

Ask the user to pick one model per provider before any brief: list the models each provider offers, with their efforts and one recommendation each, and wait for the answer (for example "Claude 1, Codex 2, Cursor 1"). Skip the question only when the user already picked them, for example with the scope approval. In T3 Code: call `orchestrator_capabilities` once (it lists the models for the question), then one read-only `delegate_task` per model, in parallel, each writing `<design folder>/designs/<provider>.md`. Elsewhere, use the host's sub-agents for the providers it has. A provider or model that is unavailable is reported in step 4; **never substitute** another one. Cost: about 0.85 to 1.6 M tokens per epic for the three designs, the consolidation and the interrogation (an estimate).

## 2. Consolidate: this thread, once

- Read all three designs end to end before choosing anything.
- Per section, start from the lead model's version: Screens from Claude; Backend and Complexity from Codex; Security from Cursor. Slices start from the slicing with the fewest slices that still keep one layer per slice.
- Graft from the other two only what the base misses (a check, a file, an edge case, a cheaper query), by hand, so the result reads as one design. Record it in `## Consolidation`: section, base, what was grafted from whom.
- Where the designs disagree on the same element, write one `## Disagreements` row: element, what each said, the pick, one line of reason. The lead model wins by default; a pick against it needs a reason step 3 can check, and the row goes to the user.
- When the three slice the epic in very different ways, the scope was unclear: make it an open question with a default instead of picking.

## 3. Interrogate before the user sees it

Every claim in `design.md` is checked by something that runs: a file or function exists (read or grep), a query count or an O(n) (run it at two sizes; the framework's query capture), a memory claim on a large set (a memory trace), a permission (a request as the wrong user), a map row (`tools/verify_changed.py` on a stub). A finding counts only when a run proves it. Put `## Interrogation` at the top of the design:

- Checked: how many claims, against which commit.
- Failed and fixed: each with the run that proved it, fixed in the design before step 4.
- Could not check: why (code not built yet), and when it will be (the slice test that will).
- Dropped: findings no run supports ("consider caching" with no slow path shown).

## 4. Hand back

Reply in the thread: the path to `design.md`; slices per flow; each disagreement with the pick taken; the interrogation counts; any provider that did not run; the open questions, each with a default. End with: "Once you approve, I define the plan: slices per flow and the checklist (`scope-page`), then `/epic`." Stop for the user's yes.

Record the user's answers as a dated `## Round N decisions (<who>, <date>)` block at the top of `design.md`, in their words. Never write an approval the user did not give.
