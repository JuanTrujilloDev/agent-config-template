# /audit

Run a comprehensive code-quality + security audit on the codebase or a specific scope.

## Usage

```
/audit                    # entire codebase
/audit <path>             # specific dir or file
/audit <branch>           # specific branch's diff against {{default_branch}}
```

## Steps

### Phase 1: Plan
1. Identify files in scope
2. Check repo size: total files, recently changed files
3. List the audit categories you'll cover

### Phase 2: Code review
Spawn `code-reviewer` against the scope. Capture findings.

### Phase 3: Security review
Spawn `security-reviewer` against the scope. Capture findings.

### Phase 4: Test health
- Run `{{test_cmd}}` — all green?
- Coverage at ≥{{test_coverage_target}}%?
- Identify untested critical paths

### Phase 5: Tooling health
- `{{format_cmd}}` clean?
- `{{lint_cmd}}` clean?
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
