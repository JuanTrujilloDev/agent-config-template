---
name: code-review
description: "Review the diff since a fixed point along two separate axes: Standards (principles, the layer style skill, a Fowler smell baseline) and Spec (the slice file and its stories; approved tests unchanged). Runs both in parallel sub-agents, reports them side by side, one fix round. Adapted from mattpocock/skills code-review (MIT)."
argument-hint: "[fixed point]"
---

# code-review

Two-axis review of the diff between `HEAD` and a fixed point:

- **Standards**: does the code follow this project's documented standards?
- **Spec**: does the code do what the slice and its stories ask, and nothing else?

Both axes run as **parallel sub-agents** with fresh context, so neither pollutes the other. Hosts without sub-agents run the two axes one after the other in this thread, keeping the reports separate.

## 1. Pin the fixed point

Use the argument when given. Otherwise: the stacked base from the slice's `- Branch:` line (`stacked on …`) while that branch exists, else the default branch. Confirm it resolves (`git rev-parse <fixed-point>`) and that `git diff <fixed-point>...HEAD` (three dots: against the merge-base) is non-empty; a bad ref or empty diff stops here. Note `git log <fixed-point>..HEAD --oneline`.

## 2. Sources

- **Spec**: the slice file `docs/epics/<ID>/slices/<n>.md` for the current branch (its `- Branch:` line), plus the slice's stories, AC and TS lines in `docs/epics/<ID>/epic.md`. No slice file (a `/fix`, a refactor): the user's request or the issue they name; if there is none, skip the Spec axis and say "no spec available".
- **Standards**: `.claude/rules/principles.md`, the layer style skill (`backend-style` for db/be, `frontend-style` for fe, both when the diff spans both), the `patterns` skill, plus `CONTRIBUTING.md` or `CODING_STANDARDS.md` when present, plus the smell baseline below.
- **Design system** (UI diffs only): `docs/design-system/MASTER.md` (or a `pages/<page>.md` override), `docs/design-system/tokens.json` and `tokens.lock.json`. A hardcoded color, spacing, radius or font value not traceable to the token source is a finding, cited `file:line`. A missing theme target, a stale `source_sha256` / `target_sha256`, a raw brand value or an undocumented page-level token fork is a Blocker.

### Smell baseline (Fowler, *Refactoring* ch. 3)

The repo overrides: a documented standard wins where it endorses something flagged here. Each smell is a judgement call ("possible Feature Envy"), never a hard violation; skip anything tooling enforces.

- **Mysterious Name**: a name that doesn't reveal what it does or holds. → rename it.
- **Duplicated Code**: the same logic shape in more than one hunk or file. → extract the shared shape.
- **Feature Envy**: a method reaching into another object's data more than its own. → move it onto that data.
- **Data Clumps**: the same few fields or params travelling together. → bundle them into one type.
- **Primitive Obsession**: a primitive standing in for a domain concept. → give the concept a small type.
- **Repeated Switches**: the same `switch`/`if`-cascade on the same type recurs. → one map or polymorphism.
- **Shotgun Surgery**: one logical change forces scattered edits. → gather what changes together.
- **Divergent Change**: one module edited for several unrelated reasons. → split it.
- **Speculative Generality**: abstraction or parameters the slice does not need. → delete, inline back.
- **Message Chains**: long `a.b().c().d()` navigation. → hide the walk behind one method.
- **Middle Man**: a class or function that mostly delegates. → call the real target.
- **Refused Bequest**: an implementer ignoring most of what it inherits. → composition.

## 3. Approved-tests gate (before the sub-agents)

1. **The slice file is append-only.** Run `git diff $(git merge-base <fixed-point> HEAD) -- docs/epics/<ID>/slices/<n>.md` (commits and working tree). A removed or changed line under `## Approved tests`, or on the `- Branch:` line, is a **Spec blocker**: it would lift the lock or redirect this gate. Added lines are fine (a re-approval appends a new `Commit:` line).
2. **Approved tests are unchanged.** Read `## Approved tests`: the last `Commit: <sha>` line and every listed path. Run `git diff <sha> -- <paths>` (covers commits and the working tree). Non-empty output is a **Spec blocker** that fails the review regardless of everything else: approved tests or fixtures were changed after approval. Quote the diff stat.

## 4. Spawn both sub-agents in parallel

**Standards prompt**: the diff command, commit list, the standards files, and the smell baseline pasted in full. Brief: "Report per file/hunk (a) each violation of a documented standard, citing file and rule, and (b) any baseline smell, named, with the hunk quoted. Mark each finding Blocker or Judgement call; baseline smells are always judgement calls. Under 400 words."

**Spec prompt**: the diff command, commit list, the slice file and its stories/AC/TS pasted. Brief: "Report (a) stories or TS the slice covers that are missing or partial; (b) behaviour in the diff no story asks for (scope creep); (c) behaviour that looks implemented but wrong. Quote the story or TS line for each. Mark each Blocker or Judgement call. Under 400 words."

## 5. Aggregate

Present `## Standards` and `## Spec` verbatim or lightly cleaned, with the approved-tests gate result first under Spec. Do **not** merge or rerank findings across axes: code can follow every standard and build the wrong thing, or build the right thing against the conventions; separate reports stop one axis masking the other. End with one line: findings per axis and the worst issue within each.

## 6. One fix round

Fix every Blocker once, rerun the Definition of Done, and report what changed. Do not run a second review loop; remaining judgement calls go in the PR description. Then `/pr`.
