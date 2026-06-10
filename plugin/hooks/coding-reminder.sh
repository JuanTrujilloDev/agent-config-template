#!/bin/bash
# Injects principles + workflow reminder on coding-related prompts.

set -uo pipefail
INPUT=$(cat)
PROMPT=$(echo "$INPUT" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get("prompt", "") or "")
except Exception:
    pass
' 2>/dev/null)
[ -z "$PROMPT" ] && exit 0

LOWER=$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Skip clearly non-coding prompts unless they reference code paths/keywords.
case "$LOWER" in
    "what is "*|"what's "*|"explain "*|"how does "*|"how do "*|"why does "*|"why is "*|"can you explain"*|"tell me about"*|"summarize"*|"summary of"*|"list "*|"show me"*)
        if ! printf '%s' "$LOWER" | grep -qE '(\.py|\.html|\.js|\.ts|\.tsx|\.css|implement|fix|refactor|add|create|update|change|build|migrate|hook|model|view|serializer|template|component|route|endpoint|api|test)'; then
            exit 0
        fi
        ;;
esac

if ! printf '%s' "$LOWER" | grep -qE '(implement|fix|refactor|add|create|update|change|build|write|migrate|optimize|debug|hotfix|feature|bug|new (model|view|serializer|template|component|endpoint|api)|\.py\b|\.html\b|\.js\b|\.ts\b|\.tsx\b|\.css\b|/feature\b|/audit\b|/commit\b|/pr\b|/plan\b|/design\b)'; then
    exit 0
fi

cat <<'HEREDOC'
[reminder — operating principles, see the principles skill]

Before any code edit:
  1. Restate the goal in ONE sentence + list 2–4 verifiable success criteria.
  2. Edits >50 lines or new defs/classes → spawn `backend-dev` or `frontend-dev`
     with Design First before implementing.
  3. Confirm the current branch matches the task type. NEVER code on the
     default branch. Use: feature/<slug>, fix/<slug>, hotfix/<slug>,
     refactor/<slug>, chore/<slug>, docs/<slug>.
  4. Apply the principles: Think · Simplicity · Surgical · Goal-Driven ·
     Read-Before-Write · Code Health (DRY, small units, why-comments) ·
     Micro-PR (≤12 files / <3,000 LOC) · Definition of Done · Conciseness ·
     Branch Discipline.
  5. Definition of Done before declaring complete: format → lint → tests →
     `judge` → `security-reviewer` (if relevant).
HEREDOC
exit 0
