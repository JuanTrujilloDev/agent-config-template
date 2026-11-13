# {{project_name}} — Usage Guide

Read [the principles](rules/principles.md) first; everything below builds on them.

## What do I run when…?

| Situation | Run |
|---|---|
{{#ticket_tracker_plane}}
| Plane epic assigned | `/epic {{branch_prefix}}-<#>`: reads the card, drafts stories and slices |
{{/ticket_tracker_plane}}
{{#ticket_tracker_jira}}
| Jira epic assigned | `/epic {{branch_prefix}}-<#>`: reads the ticket, drafts stories and slices |
{{/ticket_tracker_jira}}
{{#ticket_tracker_linear}}
| Linear epic assigned | `/epic <ticket-id>`: reads the ticket, drafts stories and slices |
{{/ticket_tracker_linear}}
| New feature, no ticket | `/epic <ask>`: asks whether to put the epic on a tracker; if not, `docs/epics/<ID>/` is the source of truth |
| Epic approved, next piece of work | `/slice <ID> <n>` → `tests-first` → `implement` → `code-review` → `/pr` |
| Small fix with an obvious cause | `/fix <description>`: no epic, full Definition of Done |
| Prod is broken | `hotfix/<slug>` from `{{default_branch}}`, then `/fix`; `code-review` still runs |
| Refactor, no behaviour change | `refactor/<slug>`; existing tests must stay green and unchanged |
| Before calling anything done | `/verify`: re-read the request and the diff, run it, fix what you find |
| Auth, permissions, data exposure | `security-reviewer` before merge, always |
| Pre-merge or teammate PR | `/audit` (or "review PR #\<n\>") |
| Question or investigation | Ask; no branch, no code changes |

## The slice loop

```
/epic <ID or ask>                            → draft: groups, stories, AC, TS, slices    → you: "approve" or "change 3"
/slice <ID> 1                                → brief: stories, seams, fixtures, tests    → you: "yes"
/slice <ID> 1 cold-review                    → same, plus two fresh reviewers' findings (opt-in)
tests-first                                  → tests committed, red output pasted        → you read the tests: "yes"
implement                                    → code to green, Definition of Done pasted
code-review                                  → Standards + Spec axes, one fix round
/pr                                          → base = previous layer branch while open
```

One slice per PR, one layer per slice: `feature/<ID>-<group>-db` → `-be` → `-fe`. Aim for 200–400 non-test lines; the cap is {{max_files_per_pr}} files / {{max_loc_per_pr}} lines.

## Agents

{{#has_ui}}
- `ui-designer` — wireframes and component specs before UI code (`/design`).
{{/has_ui}}
- `security-reviewer` — read-only audit for auth, permissions, data and input boundaries.
{{#enforce_mutation_testing}}
- `mutation-tester` — checks that the slice's tests bite (opt-in).
{{/enforce_mutation_testing}}

Everything else runs in your thread; there is no coordinator or dev subagent.

## Where things live

| What | Where |
|---|---|
| Principles | `.claude/rules/principles.md` |
| Skills (epic, slice, tests-first, implement, code-review, style, patterns) | `.claude/skills/<name>/SKILL.md` |
| Epics and slices | `docs/epics/<ID>/epic.md`, `docs/epics/<ID>/slices/<n>.md` |
| Agents, commands, hooks | `.claude/agents/`, `.claude/commands/`, `.claude/hooks/` |

## Troubleshooting

**"BLOCKED: '{{default_branch}}' is a protected branch."** Check out a typed branch (principles, Branch Discipline) and retry.

**"BLOCKED: … is an approved test."** The slice's tests are locked once you approved them. Fix the code, not the test. If the test is wrong, agree the change, restart with `AGENT_CONFIG_UNLOCK_TESTS=1`, and approve the tests again.

{{#has_e2e}}
**"`mcp__playwright__*` tools aren't available."** Restart the host after editing the config and check `.claude/mcp.json` has the `playwright` entry.
{{/has_e2e}}
