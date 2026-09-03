# v0.10.0 MF5 release-0-10-0 (@s29..@s33).
V010_VERSION=0.10.0

# @s29 — four active manifests move together.
for manifest in plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json .cursor-plugin/plugin.json codex/.codex-plugin/plugin.json; do
  grep_case "v0.10.0 @s29 $manifest version" "$ROOT/$manifest" '"version": *"0\.10\.0"'
done

# @s30 — public and upgrade docs cover each shipped boundary.
for doc in "$ROOT/README.md" "$ROOT/docs/upgrade-guide.md"; do
  for term in 'scripts/evals/run\.py' '--run' '--allow-writes' 'tokens\.json' 'tokens\.lock\.json' 'plan\|doctor\|install\|update\|uninstall' '[Tt]okeniz' '0\.9\.2.*0\.10\.0|0\.10\.0.*0\.9\.2'; do
    grep_case "v0.10.0 @s30 $(basename "$doc") explains $term" "$doc" "$term"
  done
done
grep_case "v0.10.0 @s30 plugin README lifecycle" "$ROOT/plugin/README.md" 'plan\|doctor\|install\|update\|uninstall'

# @s31 — static release gates.
check "v0.10.0 @s31 spec ledgers validate" "0" "$(cd "$ROOT" && python3 scripts/validate-specs.py >/dev/null 2>&1; echo $?)"
check "v0.10.0 @s31 build check" "0" "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
PACKAGING=$(cd "$ROOT" && python3 scripts/validate-packaging.py 2>&1); PACKAGING_RC=$?
check "v0.10.0 @s31 packaging validates" "0" "$PACKAGING_RC"
grep_case "v0.10.0 @s31 packaging reports version" <(printf '%s\n' "$PACKAGING") 'packaging valid @ v0\.10\.0'
check "v0.10.0 @s31 shell syntax" "0" "$(bash -n "$ROOT/setup.sh" "$ROOT/plugin/setup.sh" "$ROOT/hosts/cursor/hooks/branch-guard.sh" "$ROOT/plugin/.cursor-plugin/hooks/branch-guard.sh"; echo $?)"
check "v0.10.0 @s31 JSON manifests" "0" "$(python3 -c 'import json,sys; [json.load(open(p)) for p in sys.argv[1:]]' "$ROOT/plugin/.claude-plugin/plugin.json" "$ROOT/.claude-plugin/marketplace.json" "$ROOT/.cursor-plugin/plugin.json" "$ROOT/codex/.codex-plugin/plugin.json" "$ROOT/plugin/companions.lock.json"; echo $?)"

v010_digest() {
  python3 -c '
import hashlib,pathlib,sys
root=pathlib.Path(sys.argv[1]); digest=hashlib.sha256()
for rel in sys.argv[2:]:
    path=root/rel
    for item in ([path] if path.is_file() else sorted(path.rglob("*"))):
        if item.is_file():
            digest.update(item.relative_to(root).as_posix().encode()); digest.update(item.read_bytes())
print(digest.hexdigest())
' "$ROOT" plugin/template plugin/setup.sh plugin/template.config.yaml plugin/examples codex/skills cursor plugin/cursor plugin/codex/skills
}
(cd "$ROOT" && bash scripts/build.sh >/dev/null)
BUILD_ONE=$(v010_digest)
(cd "$ROOT" && bash scripts/build.sh >/dev/null)
BUILD_TWO=$(v010_digest)
check "v0.10.0 @s32 double build deterministic" "$BUILD_ONE" "$BUILD_TWO"

# @s32 — six examples × four hosts.
RENDER_COUNT=0
for answers in "$ROOT"/examples/*/answers.env; do
  example=$(basename "$(dirname "$answers")")
  for host in claude cursor codex grok; do
    RENDER_COUNT=$((RENDER_COUNT + 1))
    target="$WORK/v010-$example-$host"
    bash "$ROOT/setup.sh" --target "$target" --answers "$answers" --host "$host" >/dev/null 2>&1
    check "v0.10.0 @s32 $example/$host renders" "0" "$?"
    check "v0.10.0 @s32 $example/$host placeholders" "0" "$(grep -R -cE '\{\{[#^/]?[a-z_]+\}\}' "$target" 2>/dev/null | awk -F: '{n+=$2} END{print n+0}')"
  done
done
check "v0.10.0 @s32 render matrix count" "24" "$RENDER_COUNT"

# @s33 — catalog validation is inert and the ledger is complete.
FAKE_HOST="$WORK/v010-paid-host"
printf '#!/bin/sh\ntouch "%s"\n' "$WORK/v010-paid-called" >"$FAKE_HOST"; chmod +x "$FAKE_HOST"
EVAL_CLAUDE_BIN="$FAKE_HOST" python3 "$ROOT/scripts/evals/run.py" validate >/dev/null
check "v0.10.0 @s33 catalog validation calls no host" "absent" "$([ -e "$WORK/v010-paid-called" ] && echo present || echo absent)"
check "v0.10.0 @s33 all mini-features done" "5" "$(python3 -c 'import json,sys; print(sum(x["status"]=="done" for x in json.load(open(sys.argv[1]))["mini_features"]))' "$ROOT/docs/specs/ecosystem/features.json")"
