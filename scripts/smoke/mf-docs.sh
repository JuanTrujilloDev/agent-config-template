# v0.8.3 MF2 documentation catch-up (@s10..@s14).
MAP="$ROOT/docs/what-each-file-does.md"
README="$ROOT/README.md"
MATRIX="$ROOT/docs/install/host-capability-matrix.md"
CURSOR_DOC="$ROOT/docs/install/cursor.md"
CURSOR_AGENTS="$ROOT/hosts/cursor/AGENTS.md"

for term in 'hosts/' 'cursor/' 'codex/' 'scripts/smoke/' 'docs/design-system/' 'docs/CONTEXT\.md' '\.claude/answers\.local\.env' '/integrate' 'patterns\.md' '--overwrite-files'; do
  grep_case "v0.8.3 @s10 file map names $term" "$MAP" "$term"
done

for term in 'MASTER\.md' 'CONTEXT\.md' 'output_style' 'agent_style' '--overwrite-files'; do
  grep_case "v0.8.3 @s11 README names $term" "$README" "$term"
done
check "v0.8.3 @s11 README does not require companions" "0" "$(grep -ciE 'companions?.*(required|mandatory)|(required|mandatory).*companions?' "$README"; true)"

grep_case "v0.8.3 @s12 matrix autonomy/output banner row" "$MATRIX" '^\| Autonomy / output banner \|'
grep_case "v0.8.3 @s12 matrix brand MASTER row" "$MATRIX" '^\| Brand MASTER\.md \|'
grep_case "v0.8.3 @s12 banner row covers all four hosts" "$MATRIX" '^\| Autonomy / output banner \|[^|]+\|[^|]+\|[^|]+\|[^|]+\|'
grep_case "v0.8.3 @s12 brand row covers all four hosts" "$MATRIX" '^\| Brand MASTER\.md \|[^|]+\|[^|]+\|[^|]+\|[^|]+\|'

grep_case "v0.8.3 @s13 Cursor skills are stack-dependent" "$CURSOR_DOC" '[Ss]tack-dependent|depend(s|ing) on.*stack'
grep_case "v0.8.3 @s13 Cursor guide names requires directive" "$CURSOR_DOC" 'requires:'
check "v0.8.3 @s13 Cursor guide no longer says every slash command" "0" "$(grep -ci 'every slash command' "$CURSOR_DOC"; true)"

grep_case "v0.8.3 @s14 Cursor AGENTS points to skills" "$CURSOR_AGENTS" '\.claude/skills/'
grep_case "v0.8.3 @s14 Cursor AGENTS says skills are native" "$CURSOR_AGENTS" '[Cc]ursor.*reads.*skills.*natively|skills.*read.*natively.*[Cc]ursor'
