#!/bin/bash
# v0.9.2 MF2: whole-file overrides cannot silently drop source H2 headings.

V092_MF2_SOURCE="$WORK/v092-mf2-source.md"
V092_MF2_OVERRIDE="$WORK/v092-mf2-override.md"

V092_MF2_OUT=$(python3 "$ROOT/scripts/check-override-headings.py" 2>&1)
V092_MF2_RC=$?
check "v0.9.2 @s10 known override map passes" "0|" "$V092_MF2_RC|$V092_MF2_OUT"

printf '# Source\n\n## Shared\n' >"$V092_MF2_SOURCE"
printf '# Override\n\n## Shared\n' >"$V092_MF2_OVERRIDE"
V092_MF2_OUT=$(python3 "$ROOT/scripts/check-override-headings.py" \
  "$V092_MF2_SOURCE" "$V092_MF2_OVERRIDE" 2>&1)
V092_MF2_RC=$?
check "v0.9.2 @s11 matching H2 is quiet" "0|" "$V092_MF2_RC|$V092_MF2_OUT"

printf '# Source\n\n## Shared\n\n## New contract\n' >"$V092_MF2_SOURCE"
printf '# Override\n\n## Shared\n' >"$V092_MF2_OVERRIDE"

V092_MF2_OUT=$(python3 "$ROOT/scripts/check-override-headings.py" \
  "$V092_MF2_SOURCE" "$V092_MF2_OVERRIDE" 2>&1)
V092_MF2_RC=$?
check "v0.9.2 @s12 missing source H2 fails" "1" "$V092_MF2_RC"
grep_case "v0.9.2 @s12 failure names source" <(printf '%s\n' "$V092_MF2_OUT") 'v092-mf2-source\.md'
grep_case "v0.9.2 @s12 failure names override" <(printf '%s\n' "$V092_MF2_OUT") 'v092-mf2-override\.md'
grep_case "v0.9.2 @s12 failure names heading" <(printf '%s\n' "$V092_MF2_OUT") 'New contract'

printf '# Override\n\n## Shared\n\n<!-- override-ignore-h2: New contract -->\n' >"$V092_MF2_OVERRIDE"
cp "$V092_MF2_SOURCE" "$WORK/v092-mf2-source.before"
cp "$V092_MF2_OVERRIDE" "$WORK/v092-mf2-override.before"
V092_MF2_OUT=$(python3 "$ROOT/scripts/check-override-headings.py" \
  "$V092_MF2_SOURCE" "$V092_MF2_OVERRIDE" 2>&1)
V092_MF2_RC=$?
check "v0.9.2 @s13 exact marker passes" "0|" "$V092_MF2_RC|$V092_MF2_OUT"
cmp -s "$V092_MF2_SOURCE" "$WORK/v092-mf2-source.before"; V092_MF2_SOURCE_RC=$?
cmp -s "$V092_MF2_OVERRIDE" "$WORK/v092-mf2-override.before"; V092_MF2_OVERRIDE_RC=$?
check "v0.9.2 @s15 checker does not write fixtures" "0|0" "$V092_MF2_SOURCE_RC|$V092_MF2_OVERRIDE_RC"

printf '# Override\n\n## Shared\n\n<!-- override-ignore-h2 New contract -->\n' >"$V092_MF2_OVERRIDE"
V092_MF2_OUT=$(python3 "$ROOT/scripts/check-override-headings.py" \
  "$V092_MF2_SOURCE" "$V092_MF2_OVERRIDE" 2>&1); V092_MF2_RC=$?
check "v0.9.2 @s14 malformed marker fails" "1" "$V092_MF2_RC"
grep_case "v0.9.2 @s14 malformed marker is clear" <(printf '%s\n' "$V092_MF2_OUT") 'malformed override-ignore-h2 marker'

printf '# Override\n\n## Shared\n\n<!-- override-ignore-h2: * -->\n' >"$V092_MF2_OVERRIDE"
V092_MF2_OUT=$(python3 "$ROOT/scripts/check-override-headings.py" \
  "$V092_MF2_SOURCE" "$V092_MF2_OVERRIDE" 2>&1); V092_MF2_RC=$?
check "v0.9.2 @s14 broad marker fails" "1" "$V092_MF2_RC"
grep_case "v0.9.2 @s14 broad marker is clear" <(printf '%s\n' "$V092_MF2_OUT") 'unknown source H2 "\*"'

printf '# Override\n\n## Shared\n\n<!-- override-ignore-h2: Ghost -->\n' >"$V092_MF2_OVERRIDE"
V092_MF2_OUT=$(python3 "$ROOT/scripts/check-override-headings.py" \
  "$V092_MF2_SOURCE" "$V092_MF2_OVERRIDE" 2>&1); V092_MF2_RC=$?
check "v0.9.2 @s14 unmatched marker fails" "1" "$V092_MF2_RC"
grep_case "v0.9.2 @s14 unmatched marker is clear" <(printf '%s\n' "$V092_MF2_OUT") 'unknown source H2 "Ghost"'

printf '# Override\n\n## Shared\n\n<!-- override-ignore-h2: Shared -->\n' >"$V092_MF2_OVERRIDE"
V092_MF2_OUT=$(python3 "$ROOT/scripts/check-override-headings.py" \
  "$V092_MF2_SOURCE" "$V092_MF2_OVERRIDE" 2>&1); V092_MF2_RC=$?
check "v0.9.2 @s14 stale marker fails" "1" "$V092_MF2_RC"
grep_case "v0.9.2 @s14 stale marker is clear" <(printf '%s\n' "$V092_MF2_OUT") 'stale marker for present H2 "Shared"'

before "v0.9.2 @s15 build gates before mode split" "$ROOT/scripts/build.sh" \
  '^python3 scripts/check-override-headings\.py$' '^if \[ "\$\{1:-\}" = "--check" \]; then$'
bash "$ROOT/scripts/build.sh" >/dev/null 2>&1; V092_MF2_BUILD_RC=$?
bash "$ROOT/scripts/build.sh" --check >/dev/null 2>&1; V092_MF2_CHECK_RC=$?
check "v0.9.2 @s15 normal and check builds pass gate" "0|0" "$V092_MF2_BUILD_RC|$V092_MF2_CHECK_RC"
