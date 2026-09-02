# Add the workflow to an existing project

Use this path when the repository already has agent rules, code, or both.

## 1. Survey before writing

Read the project structure, current agent files, build/test commands, protected
branches, and existing conventions. Treat root `CLAUDE.md` or `AGENTS.md` as a
possible project source of truth; do not replace it blindly.

Ask: **What tracker or development tool do you already use?** Trackers are optional.
Keep the answer in the workflow only when the user wants an
integration; never require Plane, Jira, Linear, GitHub, or another service.

## 2. Choose the host

Select `claude`, `cursor`, `grok`, or `codex` and prepare `answers.env` from the
closest example. Set the real language, framework, directories, commands,
default branch, and project type.

## 3. Preview

Run without an apply mode first; this prints the plan and writes nothing:

```bash
./setup.sh --target . --answers ./answers.env --host cursor
```

Read every `STALE-MANAGED`, `CUSTOMIZED`, `OBSOLETE`,
`CUSTOMIZED-OBSOLETE`, and `SYMLINK-CONFLICT` line.

## 4. Resolve source-of-truth conflicts

Keep project-specific conventions in the root file. If `.claude/CLAUDE.md`
conflicts, fold useful content into root `CLAUDE.md`, then let the template use
its `../CLAUDE.md` symlink. Do not overwrite a customized file just because it
differs from the template.

## 5. Merge safely

```bash
./setup.sh --target . --answers ./answers.env --host cursor --merge
```

`--merge` adds missing managed files, preserves customized files, and
union-merges settings. Use the printed `--overwrite-files <paths>` list only for
stale managed files you reviewed and intentionally want to refresh.

To remove files retired by a newer template, approve each `OBSOLETE` path from
the preview, then run:

```bash
./setup.sh --target . --answers ./answers.env --host cursor --merge --prune
```

Prune deletes only unchanged managed files with recorded baselines.
`CUSTOMIZED-OBSOLETE`, legacy, unrecorded, user-owned, and unsafe paths remain.

## 6. Start one contract

Run `/spec <feature>`. Review `spec.md`, `contract.md`, and `features.json`.
Gate 1 stays closed until you approve the contract and all
`NEEDS CLARIFICATION:` markers are resolved. Then run `/feature <feature>`.

## 7. Run checks and inspect

Run the project's format, lint, test, and build checks. Review the generated
diff. Accept the optional browser, simulator, CLI, or artifact check when it
adds useful confidence.

## 8. Commit or rollback

Commit the template upgrade as its own `chore:` change. To rollback before a
commit, restore only the files listed by the preview from your VCS or discard
the isolated upgrade branch; never delete the whole agent directory blindly.

## Optional companions

- `graphify`: graph-first codebase queries.
- `ponytail`: minimal-code/YAGNI enforcement.
- `ui-ux-pro-max`: UI design help only when `has_ui` is enabled.

Run `/setup-companions [list]` to see an install plan. Nothing installs without
approval. Use `/integrate <tool>` for a tracker or MCP the user already chose.
