# {{project_name}} — Claude Code Usage Guide

Practical guide to working with Claude in this project. **Read [Core Operating Principles](rules/principles.md) first** — they're the foundation of everything below.

---

## TL;DR — What do I do when…?

| Situation | What to do |
|---|---|
{{#ticket_tracker_plane}}
| **Plane task assigned** | `/feature {{branch_prefix}}-<#>` → Claude pulls ticket, runs full flow |
{{/ticket_tracker_plane}}
{{#ticket_tracker_jira}}
| **Jira task assigned** | `/feature {{branch_prefix}}-<#>` → Claude pulls ticket, runs full flow |
{{/ticket_tracker_jira}}
{{#ticket_tracker_linear}}
| **Linear task assigned** | `/feature <ticket-id>` → Claude pulls ticket, runs full flow |
{{/ticket_tracker_linear}}
| **Spec a feature first** | `/spec <description>` → `pmo` writes spec + Given/When/Then contract + mini-features; you approve |
| **New feature, no ticket** | `/feature <description>` → full spec-driven flow, orchestrated and gated |
| **Small scoped fix (obvious cause)** | `/fix <description>` → skips spec + Design First, keeps the full Definition of Done |
| **Before you call it done** | `/verify` → re-read the request, read the diff, run it, fix what you find |
| **Hotfix (prod broken)** | *"Hotfix: \<symptom\>. Branch from `{{default_branch}}` as `hotfix/\<slug\>`. Spawn the right dev agent directly, single small PR."* — `orchestrator`/`pmo` skipped; `judge` still runs |
| **Bug fix (non-urgent)** | Reproduce → minimal fix → tests → standard agent flow on a `fix/<slug>` branch |
| **Refactor (no behavior change)** | `judge` first to baseline → `*-dev` agent on `refactor/<slug>` → single PR ≤{{max_files_per_pr}} files |
| **Tiny change** (typo, comment, single-value config; ≤50 lines, ≤1 new def) | Edit directly, or `/fix`. The hook is advisory. |
| **Question / investigation** | Use `Explore` agent — no code changes, no branch needed |
| **Pre-merge check** | `/audit` or invoke `judge` + `security-reviewer` manually |
| **Touching auth, permissions, data exposure** | `security-reviewer` is **mandatory** before merge |
| **Reviewing teammate's PR** | *"Review PR #\<n\>"* → Claude fetches via `gh`, runs `judge` (+ `security-reviewer` if relevant) |

---

## The agent map

| Agent | Spawn it when… | Output |
|---|---|---|
| `pmo` | You need a spec: idea/SOW → Given/When/Then contract + PR-sized mini-features | `docs/specs/<slug>/{spec,contract,features}` |
| `orchestrator` | You want the full spec-driven flow run and gated for a feature | coordinates; never edits code |
{{#has_frontend}}
| `ui-designer` | A non-trivial UI change is needed | Wireframes, mockups, flow descriptions |
{{/has_frontend}}
| `backend-dev` | API-layer work | Code + tests {{#enforce_layer_split}}on `*-be` branch{{/enforce_layer_split}} |
{{#has_frontend}}
| `frontend-dev` | UI work | Code + tests {{#enforce_layer_split}}on `*-fe` branch (after BE merged){{/enforce_layer_split}} |
{{/has_frontend}}
| `judge` | Before any commit/PR — and on teammate PRs | Findings report (read-only) |
| `security-reviewer` | Change touches auth/permissions/data | Findings report (read-only) |
{{#enforce_mutation_testing}}
| `mutation-tester` | Validate the tests bite before a mini-feature closes | Mutation score (read-only) |
{{/enforce_mutation_testing}}

---

## The "Definition of Done" checklist

A task is **NOT** done until all pass, in order:

1. **Format** — `{{format_cmd}}`
2. **Lint** — `{{lint_cmd}}`
3. **Unit tests** — `{{test_cmd}}` (≥{{test_coverage_target}}% coverage)
4. **Review** — `judge` agent (code + tests vs the contract); address all blockers
5. **Security review** — `security-reviewer` if change touches auth/permissions/data
{{#has_e2e}}
6. **Live browser verification** — for FE-touching changes OR big changes (>5 files / 500 lines): walk through smoke flows + the task's success criteria via `mcp__playwright__*`
{{/has_e2e}}

The agent that did the work runs the checklist and reports results before declaring done.

---

## Branch cheat sheet

**Never code on `{{default_branch}}`.**

| Type | Pattern |
|---|---|
{{#branch_prefix}}
| Feature | `feature/{{branch_prefix}}-<#>-<slug>`{{#enforce_layer_split}} (split: `-be` / `-fe`){{/enforce_layer_split}} |
| Fix | `fix/[{{branch_prefix}}-<#>-]<slug>` |
{{/branch_prefix}}
{{^branch_prefix}}
| Feature | `feature/<slug>`{{#enforce_layer_split}} (split: `-be` / `-fe`){{/enforce_layer_split}} |
| Fix | `fix/<slug>` |
{{/branch_prefix}}
| Hotfix | `hotfix/<slug>` (branches from `{{default_branch}}`) |
| Refactor | `refactor/<slug>` |
| Chore | `chore/<slug>` |
| Docs | `docs/<slug>` |

---

## Worked example — feature flow

```
You:    /feature {{#branch_prefix}}{{branch_prefix}}-87{{/branch_prefix}}{{^branch_prefix}}add CSV export to holdings list{{/branch_prefix}}

Claude: [pulls ticket / drafts brief]
        Spawning pmo...
[brief produced]
        Brief ready. Goal: <one sentence>.
        Success criteria: 1) ... 2) ... 3) ...
        Approve brief? (yes/edit)

You:    yes

Claude: Contract approved. Spawning orchestrator...
[plan produced]
        Plan: BE-1 (... files, ... LOC), FE-1 (... files, ... LOC).
        {{#enforce_layer_split}}BE ships first.{{/enforce_layer_split}} Approve? (yes/edit)

You:    yes

Claude: Checking out branch... Spawning {{#enforce_layer_split}}backend-dev{{/enforce_layer_split}}{{^enforce_layer_split}}*-dev{{/enforce_layer_split}}.
        Design First: <design artifact>. Approve? (yes/edit)

You:    yes

[implements + runs DoD: format, lint, tests, judge, security-reviewer{{#has_e2e}}, playwright{{/has_e2e}}]
        PR opened. DoD: ✓✓✓✓✓.
```

---

## Quick reference

### Spawning agents manually
- *"spawn backend-dev to add ..."*
- *"have judge check the last 3 commits"*

### Bypassing the enforcement hook (rare)
- *"This is a minor copy tweak, just edit directly."*
- The hook still warns; CLAUDE.md flags it as a deliberate override.
- Don't make this a habit.

### Where things live
| What | Where |
|---|---|
| Principles | `.claude/rules/principles.md` |
| Style guides | `.claude/rules/{backend{{#has_frontend}},frontend{{/has_frontend}}}-style.md` |
| Agents | `.claude/agents/*.md` |
| Commands | `.claude/commands/*.md` |
| Hooks | `.claude/hooks/*.sh` |
| Briefs / SOWs | `docs/specs/` |
| Implementation plans | `docs/plans/` |
| Specs + contracts | `docs/specs/<slug>/` |
| SDD/TDD workflow | `docs/sdd-workflow.md` |

---

## Troubleshooting

**"The hook blocked my edit but I just want to fix one line."**
The threshold (50 lines or new def/class) is intentional. To bypass, say *"edit directly, skip the agent"* — but don't make it a habit.

**"Claude didn't spawn an agent."**
Reference `CLAUDE.md` Agent Usage Rules. If it happens repeatedly, the `coding-reminder.sh` hook may not be firing — check `.claude/settings.json`.

{{#has_e2e}}
**"`mcp__playwright__*` tools aren't available."**
Restart Claude Code after editing config. Verify `.claude/mcp.json` has the `playwright` server entry.
{{/has_e2e}}
