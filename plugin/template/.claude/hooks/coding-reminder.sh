#!/bin/bash
# UserPromptSubmit hook — injects principles + workflow reminder on coding prompts.

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

if [ -z "$PROMPT" ]; then
    exit 0
fi

LOWER=$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')

# Skip clearly non-coding prompts unless they reference code paths/keywords.
case "$LOWER" in
    "what is "*|"what's "*|"explain "*|"how does "*|"how do "*|"why does "*|"why is "*|"can you explain"*|"tell me about"*|"summarize"*|"summary of"*|"list "*|"show me"*)
        if ! printf '%s' "$LOWER" | grep -qE '({{src_dir}}/|\.py|\.html|\.js|\.ts|\.tsx|\.css|implement|fix|refactor|add|create|update|change|build|migrate|hook|model|view|serializer|template|component|route|endpoint|api|test)'; then
            exit 0
        fi
        ;;
esac

# Trigger reminder only if a coding keyword is present.
if ! printf '%s' "$LOWER" | grep -qE '(implement|fix|refactor|add|create|update|change|build|write|migrate|optimize|debug|hotfix|feature|bug|new (model|view|serializer|template|component|endpoint|api)|{{src_dir}}/|\.py\b|\.html\b|\.js\b|\.ts\b|\.tsx\b|\.css\b|/feature\b|/audit\b|/commit\b|/pr\b|/design\b)'; then
    exit 0
fi

# Mode + output-style banner — personal prefs from the gitignored local prefs
# file (see .claude/rules/principles.md, "Autonomy Mode" / "Output style"). Defensive:
# absent file/key = gated + concise; unrecognized output_style = the mode-only
# banner; unrecognized autonomy_mode = no banner. Only whitelisted fixed strings
# are echoed — file content never reaches the output; never blocks the prompt.
PREFS="${CLAUDE_PROJECT_DIR:-.}/.claude/answers.local.env"
AUTONOMY=$(sed -n 's/^autonomy_mode=//p' "$PREFS" 2>/dev/null | head -1 | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
STYLE=$(sed -n 's/^output_style=//p' "$PREFS" 2>/dev/null | head -1 | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
case "$STYLE" in
    "")                              STYLE=concise ;;
    concise|balanced|detailed|terse) ;;
    *)                               STYLE="" ;;
esac
case "$AUTONOMY:$STYLE" in
    autonomous:)  echo "mode: autonomous — say 'gate me' to switch" ;;
    autonomous:*) echo "mode: autonomous | output: $STYLE — say \"gate me\" or \"be brief\" to override this session" ;;
    gated:|:)     echo "mode: gated — say 'just go' for autonomous" ;;
    gated:*|:*)   echo "mode: gated | output: $STYLE — say \"just go\" or \"explain more\" to override this session" ;;
esac

cat <<'HEREDOC'
[reminder — operating principles, see .claude/rules/principles.md]

Before any code edit:
  1. Restate the goal in ONE sentence + list 2–4 verifiable success criteria.
{{#enforce_layer_split}}
  2. If task touches BOTH backend AND frontend → spawn `pmo` first to split into
     BE + FE mini-features (BE ships first, FE consumes the merged API).
  3. Edits >50 lines or new defs/classes in {{src_dir}} → spawn `{{primary_dev_agent}}`
     or `frontend-dev`. Both run Design First before implementing.
{{/enforce_layer_split}}
{{^enforce_layer_split}}
  2. Edits >50 lines or new defs/classes in {{src_dir}} → spawn `{{primary_dev_agent}}`
     {{#has_frontend}}or `frontend-dev` {{/has_frontend}}with Design First before implementing.
{{/enforce_layer_split}}
  - Confirm the current branch matches the task type. NEVER code on `{{default_branch}}`.
     Use: feature/{{#branch_prefix}}{{branch_prefix}}-<#>-{{/branch_prefix}}<slug>{{#enforce_layer_split}}[-be|-fe]{{/enforce_layer_split}}, fix/..., hotfix/..., refactor/..., chore/..., docs/...
  - Apply the principles: Think · Simplicity · Surgical · Goal-Driven · Read-Before-Write ·
     Code Health (DRY, small units, why-comments){{#enforce_layer_split}} · BE/FE Split{{/enforce_layer_split}} · Micro-PR (≤{{max_files_per_pr}} files / <{{max_loc_per_pr}} LOC) ·
     Definition of Done · Conciseness (be brief, no filler/recaps) · Branch Discipline.
  - Definition of Done before declaring complete: format → lint → tests →
     `judge` → `security-reviewer` (if relevant){{#has_e2e}} → live `mcp__playwright__*`
     verification (auto for FE-touching or big changes >5 files / 500 LOC){{/has_e2e}}.

If the prompt looks like a brand-new feature, prefer `/feature <{{#branch_prefix}}{{branch_prefix}}-#-or-{{/branch_prefix}}desc>`.
HEREDOC

exit 0
