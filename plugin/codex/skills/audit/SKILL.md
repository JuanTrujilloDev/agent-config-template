---
name: audit
description: "Code-quality + security audit of the codebase, a path, or a branch diff (code-review Standards axis + security-reviewer)."
---

# /audit

> **On Codex (no subagents):** run every step in this thread, in sequence.
> `code-review` runs its Standards axis, then its Spec axis, and reports them
> separately; `security-reviewer` becomes a read-only pass you announce in one
> line. Same files under `docs/epics/<ID>/`, same user gates (epic draft, slice
> brief, approved tests), same Definition of Done.


Run a comprehensive code-quality + security audit on the codebase or a specific scope.

## Usage

```
/audit                    # entire codebase
/audit <path>             # specific dir or file
/audit <branch>           # specific branch's diff against main
```

## Steps

### Phase 1: Plan
1. Identify files in scope
2. Check repo size: total files, recently changed files
3. List the audit categories you'll cover

### Phase 2: Code review
Run the `code-review` Standards axis against the scope. Capture findings.

### Phase 3: Security review
Spawn `security-reviewer` against the scope. Capture findings.

### Phase 4: Test health
- Run `your project's test command` — all green?
- Coverage at ≥80%?
- Identify untested critical paths

### Phase 5: Tooling health
- `your project's format command` clean?
- `your project's lint command` clean?
- Dependency security: any known CVEs?

## Output
```markdown
# Audit Report: <scope> — <date>

## Summary
- Critical: <n>
- High: <n>
- Medium: <n>
- Low: <n>

## Findings (grouped by severity)
...

## Recommended actions
1. ...
```
