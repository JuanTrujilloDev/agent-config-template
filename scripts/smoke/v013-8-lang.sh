# v0.13.0 item 8 — lang-python, lang-javascript, lang-typescript, lang-css: loaded by path, short, no style overlap.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/v013-8-lang.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

for l in python javascript typescript css; do
  f="$ROOT/core/.claude/skills/lang-$l/SKILL.md"
  grep_case "v0.13 i8 lang-$l frontmatter name" "$f" "^name: lang-$l\$"
  grep_case "v0.13 i8 lang-$l loads by paths" "$f" '^paths: \["\*\*/\*\.'
  rows=$(grep -cE '^\| [^-]' "$f"); rows=$((rows - 1))
  check "v0.13 i8 lang-$l has 10–15 rules" "yes" "$([ "$rows" -ge 10 ] && [ "$rows" -le 15 ] && echo yes || echo "no ($rows)")"
  grep_case "v0.13 i8 lang-$l defers to the project" "$f" 'the project wins'
  check "v0.13 i8 plugin lang-$l mirrors core" "0" "$(diff -q "$f" "$ROOT/plugin/skills/lang-$l/SKILL.md" >/dev/null 2>&1; echo $?)"
  check "v0.13 i8 rendered lang-$l" "present" "$([ -f "$WORK/.claude/skills/lang-$l/SKILL.md" ] && echo present || echo absent)"
done
grep_case "v0.13 i8 lang-python globs .py" "$ROOT/core/.claude/skills/lang-python/SKILL.md" '^paths: \["\*\*/\*\.py"\]$'
grep_case "v0.13 i8 lang-typescript reads lang-javascript too" "$ROOT/core/.claude/skills/lang-typescript/SKILL.md" 'Read `lang-javascript` too'
grep_case "v0.13 i8 implement names the lang skills" "$ROOT/core/.claude/skills/implement/SKILL.md" '`lang-python`, `lang-javascript`, `lang-typescript`, `lang-css`'
grep_case "v0.13 i8 code-review reads the lang skill" "$ROOT/core/.claude/skills/code-review/SKILL.md" 'the `lang-\*` skill for each changed file'
