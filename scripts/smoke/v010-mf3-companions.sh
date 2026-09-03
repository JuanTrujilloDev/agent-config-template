# v0.10.0 MF3 companion-lifecycle (@s16..@s22).
LOCK="$ROOT/plugin/companions.lock.json"
SC="$ROOT/plugin/commands/setup-companions.md"
X_SC="$ROOT/hosts/codex/skills/setup-companions/SKILL.md"

# @s16 — one valid, deterministic metadata source.
check "v0.10.0 @s16 lock parses" "0" "$(python3 -m json.tool "$LOCK" >/dev/null 2>&1; echo $?)"
check "v0.10.0 @s16 lock schema and tools" "0" "$(python3 - "$LOCK" <<'PY'
import json,re,sys
d=json.load(open(sys.argv[1]))
assert d['schema_version']==1
assert list(d['companions'])==sorted(d['companions'])==['graphify','ponytail','ui-ux-pro-max']
for name,item in d['companions'].items():
    assert re.fullmatch(r'\d+\.\d+\.\d+',item['version'])
    assert item['source'] and item['install_method'] and item['probe']
p=d['companions']['ponytail']['direct_download']
assert re.fullmatch(r'[0-9a-f]{64}',p['sha256']) and '/v4.9.0/' in p['url']
PY
echo $?)"

# @s17 — commands point at the lock; generated Codex copy is exact.
grep_case "v0.10.0 @s17 plugin command locates lock" "$SC" 'companions\.lock\.json'
grep_case "v0.10.0 @s17 codex skill locates adjacent lock" "$X_SC" 'companions\.lock\.json'
check "v0.10.0 @s17 codex generated lock exact" "0" "$(diff -q "$LOCK" "$ROOT/codex/skills/setup-companions/companions.lock.json" >/dev/null 2>&1; echo $?)"
check "v0.10.0 @s17 bundled codex lock exact" "0" "$(diff -q "$LOCK" "$ROOT/plugin/codex/skills/setup-companions/companions.lock.json" >/dev/null 2>&1; echo $?)"

# @s18–@s21 — lifecycle, offline states, digest, and immediate confirmations.
for file in "$SC" "$X_SC"; do
  for action in plan doctor install update uninstall; do
    grep_case "v0.10.0 @s18 $(basename "$file") action $action" "$file" "\b$action\b"
  done
  grep_case "v0.10.0 @s18 $(basename "$file") plan offline" "$file" '[Pp]lan.*offline|offline.*plan'
  grep_case "v0.10.0 @s18 $(basename "$file") doctor offline" "$file" '[Dd]octor.*offline|offline.*doctor'
  for state in missing healthy outdated unverifiable; do
    grep_case "v0.10.0 @s18 $(basename "$file") state $state" "$file" "$state"
  done
  grep_case "v0.10.0 @s19 $(basename "$file") install confirmation" "$file" '[Cc]onfirm.*immediately.*install|install.*[Cc]onfirm.*immediately'
  grep_case "v0.10.0 @s19 $(basename "$file") update confirmation" "$file" '[Cc]onfirm.*immediately.*update|update.*[Cc]onfirm.*immediately'
  grep_case "v0.10.0 @s20 $(basename "$file") sha before replace" "$file" 'SHA-256.*before.*replac|before.*replac.*SHA-256'
  grep_case "v0.10.0 @s21 $(basename "$file") uninstall confirmation" "$file" '[Cc]onfirm.*immediately.*(remov|uninstall)|uninstall.*[Cc]onfirm.*immediately'
  grep_case "v0.10.0 @s21 $(basename "$file") preserves unrelated config" "$file" '[Uu]nrelated.*([Pp]reserv|untouch)|[Pp]reserv.*[Uu]nrelated'
done

# @s22 — validator owns drift checks; a seeded lock mismatch fails and restores.
check "v0.10.0 @s22 packaging accepts lock" "0" "$(cd "$ROOT" && python3 scripts/validate-packaging.py >/dev/null 2>&1; echo $?)"
cp "$LOCK" "$WORK/companions.lock.bak"
python3 - "$LOCK" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['companions']['graphify']['version']='latest'
open(p,'w').write(json.dumps(d,indent=2,sort_keys=True)+'\n')
PY
rc=$(cd "$ROOT" && python3 scripts/validate-packaging.py >/dev/null 2>&1; echo $?)
mv "$WORK/companions.lock.bak" "$LOCK"
check "v0.10.0 @s22 invalid pin fails packaging" "1" "$rc"
grep_case "v0.10.0 @s22 guide shows lifecycle" "$ROOT/docs/guides/existing-projects.md" '/setup-companions (plan|doctor|install|update|uninstall)'
