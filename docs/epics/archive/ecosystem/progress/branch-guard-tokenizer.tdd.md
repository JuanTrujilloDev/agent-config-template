# TDD: branch-guard-tokenizer (@s23..@s28)

## Public seam

Cursor `beforeShellExecution` hook JSON: actual commit/push commands on protected
branches return `permission=deny`; everything else returns `permission=allow`.

## Scenario to test

- @s23: direct, path-qualified, global-option, and assignment forms.
- @s24–@s25: shell `-c`, chains, newlines, and quoted separators.
- @s26–@s27: literals, searches, read-only git, malformed input, feature branch.
- @s28: Bash syntax, rendered parity, and accurate guardrail docs.

## Red

`scripts/smoke/v010-mf4-branch-tokenizer.sh` exited 1 on 2026-09-02. The word
scan blocked quoted literals/searches and missed a newline-separated command;
tokenized docs were also absent.

## Green

Focused smoke passes @s23–@s28 against both source and marketplace hooks:
direct/path/options/assignment, shell wrappers, chains, newlines, quoted
separators, literals, searches, read-only git, malformed input, branch policy,
syntax, rendered parity, and docs.

## Refactor

Kept the existing Bash hook boundary and embedded one stdlib tokenizer. No shell
AST dependency or attempt at complete shell interpretation was added.
