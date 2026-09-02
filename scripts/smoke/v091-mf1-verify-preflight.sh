# v0.9.1 MF1 verify preflight (@s1..@s7).
V091_VERIFY_SRC="$ROOT/core/.claude/commands/verify.md"
V091_VERIFY_PLUGIN="$ROOT/plugin/commands/verify.md"

for f in "$V091_VERIFY_SRC" "$V091_VERIFY_PLUGIN" "$VERIFY"; do
  label=$(basename "$f")
  grep_case "v0.9.1 @s1 $label captures HEAD" "$f" 'VERIFY_BASE_SHA=.*git rev-parse HEAD'
  grep_case "v0.9.1 @s1 $label keeps immutable base" "$f" '[Ii]mmutable.*VERIFY_BASE_SHA|VERIFY_BASE_SHA.*[Ii]mmutable'
  grep_case "v0.9.1 @s2 $label captures merge-base" "$f" 'VERIFY_BASE_SHA=.*git merge-base.*HEAD'
  grep_case "v0.9.1 @s3 $label validates explicit ref" "$f" 'git rev-parse --verify'
  grep_case "v0.9.1 @s3 $label refuses invalid ref" "$f" '[Ii]nvalid.*ref.*([Rr]efuse|STOP)|([Rr]efuse|STOP).*[Ii]nvalid.*ref'
  grep_case "v0.9.1 @s4 $label exact empty refusal" "$f" 'Nothing to verify\.'
  grep_case "v0.9.1 @s5 $label includes untracked" "$f" 'git ls-files --others --exclude-standard'
  grep_case "v0.9.1 @s5 $label reads untracked content" "$f" '[Rr]ead every recorded untracked path'
  grep_case "v0.9.1 @s5 $label treats paths as data" "$f" '[Pp]aths.*as data|never.*(execute|interpolate).*path'
  grep_case "v0.9.1 @s6 $label changed spec tier" "$f" '[Cc]hanged.*docs/specs/<slug>'
  grep_case "v0.9.1 @s6 $label commit branch tier" "$f" '[Cc]ommit.*branch.*(reference|slug)'
  grep_case "v0.9.1 @s6 $label active ledger tier" "$f" '[Ss]ingle active ledger'
  before "v0.9.1 @s6 $label changed before commit" "$f" '[Cc]hanged.*docs/specs/<slug>' '[Cc]ommit.*branch.*(reference|slug)'
  before "v0.9.1 @s6 $label commit before ledger" "$f" '[Cc]ommit.*branch.*(reference|slug)' '[Ss]ingle active ledger'
  grep_case "v0.9.1 @s6 $label reports ambiguity" "$f" '[Aa]mbigu'
  grep_case "v0.9.1 @s7 $label honest fallback" "$f" '[Nn]o unique originating spec.*user request'

  moving=$(grep -E 'git (diff|log)' "$f" 2>/dev/null | grep -vc 'VERIFY_BASE_SHA' || true)
  check "v0.9.1 @s1 $label no moving git diff/log" "0" "$moving"
done

parity "v0.9.1 @s7 verify base parity" 'VERIFY_BASE_SHA' "$V091_VERIFY_SRC" "$V091_VERIFY_PLUGIN"
parity "v0.9.1 @s7 verify empty parity" 'Nothing to verify\.' "$V091_VERIFY_SRC" "$V091_VERIFY_PLUGIN"
parity "v0.9.1 @s7 verify discovery parity" '[Nn]o unique originating spec' "$V091_VERIFY_SRC" "$V091_VERIFY_PLUGIN"
