# Security review — adaptive-skills MF1: coding-reminder hook prefs banner

**Scope:** `git diff HEAD` on `core/.claude/hooks/coding-reminder.sh`,
`plugin/hooks/coding-reminder.sh` (identical block in
`plugin/template/.claude/hooks/coding-reminder.sh`). UserPromptSubmit hooks that
read user-writable `.claude/answers.local.env` and echo a derived banner into
model context.
**Stack:** Bash, invoked by Claude Code UserPromptSubmit; stdin JSON via python3.
**Result:** No exploitable findings. One low/doc-hygiene note.

## What the change does
Adds `output_style` alongside existing `autonomy_mode`. Both read with
`sed -n 's/^key=//p' "$PREFS" | head -1`. `output_style` passes a strict whitelist
(`concise|balanced|detailed|terse`, empty→`concise`, else→`""`). Banner chosen by
matching `"$AUTONOMY:$STYLE"` against fixed patterns, echoing fixed literals; the
only interpolated token is `$STYLE`, provably one of four whitelisted words.

## Prompt injection via file content — NOT PRESENT
Invariant ("file content never reaches output") holds under fuzzing.
- `autonomy_mode` is only ever matched, never echoed. Unrecognized values
  (`` `id` ``, `$(...)`, `INJECTED BANNER`) match no pattern → no banner line.
- `output_style` reaches stdout only as `$STYLE`; `case` collapses every
  non-whitelisted value (metachars, `$(touch …)`, 5 KB line, newlines) to `""`,
  routing to a style-less mode banner.
- `head -1` bounds multi-line files to one field; extra crafted lines never surface.
Fuzz (backticks, `$(touch /tmp/pwned)`, `rm -rf ~`, 5 KB line, embedded newlines):
only the fixed mode banner printed; no side-effect file created.

## Command injection — NOT PRESENT
No `eval`. Every expansion double-quoted (`"$PREFS"`, `"$AUTONOMY:$STYLE"`,
`"$STYLE"`), used only in `case` matching or `echo` args — never command position,
never word-split. Prefs value never executed (verified).

## Path handling of CLAUDE_PROJECT_DIR — SAFE
`"${CLAUDE_PROJECT_DIR:-.}/.claude/answers.local.env"` under `set -u`:
unset→`.` (no nounset abort); spaces→quoted OK; symlink/attacker path→`sed` reads
target but output still whitelisted (no escalation past hook uid's own read rights);
unreadable→`sed` errors to `2>/dev/null`, vars empty → default gated+concise,
exit 0, empty stderr (confirmed).

## Fail-open / never-block — CORRECT
No `set -e`; `set -uo pipefail` doesn't abort the `sed|head` pipe (status unchecked).
Every failure path (missing/unreadable file, bad values, empty prompt, non-JSON
stdin) falls through to final `exit 0`. Verified exit 0 + empty stderr on
unreadable-file case.

## stdin JSON read — NO REGRESSION
Unchanged by diff. `python3 json.load` in try/except with `2>/dev/null`;
empty/invalid → `exit 0`. Not touched by banner change.

## Note (low / doc hygiene, not a hook vuln)
Comment calls `.claude/answers.local.env` "gitignored", but the repo's only
`.gitignore` ignores `/answers.env`, not `.claude/answers.local.env`, and no
template `.gitignore` adds the pattern. File holds only `autonomy_mode` /
`output_style` (no secrets) → worst case is an accidental commit of a personal
preference, not a credential leak. If the "gitignored" contract matters, add
`.claude/answers.local.env` (or `*.local.env`) to the shipped `.gitignore`.
Additive; no runtime impact.
