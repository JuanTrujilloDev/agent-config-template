#!/bin/bash
# v0.9.2 MF4 Gate 2: parse quoted answers once before host selection.

V092_MF4_ANS="$WORK/v092-mf4-quoted.env"
V092_MF4_TARGET="$WORK/v092-mf4-quoted"
cp "$ROOT/examples/python-fastapi/answers.env" "$V092_MF4_ANS"
printf '%s\n' \
  'project_name="Quoted # Project"' \
  "project_description='Single # Project'" \
  'TARGET_HOSTS="Cursor,GROK"' >>"$V092_MF4_ANS"

V092_MF4_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF4_TARGET" --answers "$V092_MF4_ANS" 2>&1)
V092_MF4_RC=$?
check "v0.9.2 @s24 quoted answers render" "0" "$V092_MF4_RC"
check "v0.9.2 @s24 quoted hosts normalize canonically" "grok,cursor" \
  "$(python3 -c 'import json,sys; print(",".join(json.load(open(sys.argv[1]))["hosts"]))' "$V092_MF4_TARGET/agent-config.lock.json" 2>/dev/null)"
check "v0.9.2 @s24 quoted value renders without outer quotes" \
  "# Quoted # Project — Project Guidelines" \
  "$(head -1 "$V092_MF4_TARGET/CLAUDE.md" 2>/dev/null)"
grep_case "v0.9.2 @s24 single-quoted value renders without outer quotes" \
  "$V092_MF4_TARGET/CLAUDE.md" '^Single # Project$'

V092_MF4_HOSTS_ANS="$WORK/v092-mf4-hosts.env"
V092_MF4_HOSTS_TARGET="$WORK/v092-mf4-hosts"
cp "$ROOT/examples/python-fastapi/answers.env" "$V092_MF4_HOSTS_ANS"
printf '\nTARGET_HOSTS=CoDeX,claude,CURSOR,CLAUDE,gRoK,codex\n' >>"$V092_MF4_HOSTS_ANS"
bash "$ROOT/setup.sh" \
  --target "$V092_MF4_HOSTS_TARGET" --answers "$V092_MF4_HOSTS_ANS" >/dev/null 2>&1
check "v0.9.2 @s25 recorded hosts dedupe in canonical order" \
  "claude,grok,cursor,codex" \
  "$(python3 -c 'import json,sys; print(",".join(json.load(open(sys.argv[1]))["hosts"]))' "$V092_MF4_HOSTS_TARGET/agent-config.lock.json")"

V092_MF4_CLI_TARGET="$WORK/v092-mf4-cli-hosts"
printf '\nTARGET_HOSTS=windsurf\n' >>"$V092_MF4_HOSTS_ANS"
bash "$ROOT/setup.sh" \
  --target "$V092_MF4_CLI_TARGET" --answers "$V092_MF4_HOSTS_ANS" \
  --host CuRsOr,cursor,GROK >/dev/null 2>&1
check "v0.9.2 @s26 CLI hosts override and normalize" "grok,cursor" \
  "$(python3 -c 'import json,sys; print(",".join(json.load(open(sys.argv[1]))["hosts"]))' "$V092_MF4_CLI_TARGET/agent-config.lock.json")"

V092_MF4_COMPAT_ANS="$WORK/v092-mf4-compatible.env"
V092_MF4_COMPAT_TARGET="$WORK/v092-mf4-compatible"
cp "$ROOT/examples/python-fastapi/answers.env" "$V092_MF4_COMPAT_ANS"
printf '\nproject_description=Literal spaces # retained\nhas_frontend=yes\nfrontend_framework=\n' >>"$V092_MF4_COMPAT_ANS"
bash "$ROOT/setup.sh" \
  --target "$V092_MF4_COMPAT_TARGET" --answers "$V092_MF4_COMPAT_ANS" >/dev/null 2>&1
grep_case "v0.9.2 @s27 unquoted spaces and hash stay literal" \
  "$V092_MF4_COMPAT_TARGET/CLAUDE.md" '^Literal spaces # retained$'
grep_case "v0.9.2 @s27 empty values remain compatible" \
  "$V092_MF4_COMPAT_TARGET/CLAUDE.md" '^\| Frontend \|  \|$'

V092_MF4_BAD_ANS="$WORK/v092-mf4-unmatched.env"
V092_MF4_BAD_TARGET="$WORK/v092-mf4-unmatched"
printf 'project_name="Broken\n' >"$V092_MF4_BAD_ANS"
V092_MF4_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF4_BAD_TARGET" --answers "$V092_MF4_BAD_ANS" 2>&1)
V092_MF4_RC=$?
check "v0.9.2 @s28 unmatched quote exits 1" "1" "$V092_MF4_RC"
grep_case "v0.9.2 @s28 unmatched quote names line" \
  <(printf '%s\n' "$V092_MF4_OUT") '^Error: answers line 1: malformed quoted value\.$'
check "v0.9.2 @s28 unmatched quote is concise" "1" \
  "$(printf '%s\n' "$V092_MF4_OUT" | grep -c .; true)"
check "v0.9.2 @s28 unmatched quote writes nothing" "absent" \
  "$([ -e "$V092_MF4_BAD_TARGET" ] && echo present || echo absent)"

V092_MF4_BAD_ANS="$WORK/v092-mf4-trailing.env"
V092_MF4_BAD_TARGET="$WORK/v092-mf4-trailing"
printf 'project_name="Closed" trailing\n' >"$V092_MF4_BAD_ANS"
V092_MF4_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF4_BAD_TARGET" --answers "$V092_MF4_BAD_ANS" 2>&1)
V092_MF4_RC=$?
check "v0.9.2 @s28 trailing quoted material exits 1" "1" "$V092_MF4_RC"
grep_case "v0.9.2 @s28 trailing quoted material names line" \
  <(printf '%s\n' "$V092_MF4_OUT") '^Error: answers line 1: malformed quoted value\.$'
check "v0.9.2 @s28 trailing quoted material writes nothing" "absent" \
  "$([ -e "$V092_MF4_BAD_TARGET" ] && echo present || echo absent)"

V092_MF4_IGNORE_TARGET="$WORK/v092-mf4-ignore-add"
mkdir -p "$V092_MF4_IGNORE_TARGET/.claude"
printf 'output_style=concise\n' >"$V092_MF4_IGNORE_TARGET/.claude/answers.local.env"
V092_MF4_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF4_IGNORE_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" 2>&1)
V092_MF4_RC=$?
check "v0.9.2 @s29 local answers render succeeds" "0" "$V092_MF4_RC"
check "v0.9.2 @s29 gitignore gets exact local answers rule" \
  ".claude/answers.local.env" \
  "$(cat "$V092_MF4_IGNORE_TARGET/.gitignore" 2>/dev/null)"
grep_case "v0.9.2 @s29 gitignore change is reported" \
  <(printf '%s\n' "$V092_MF4_OUT") \
  'Added \.claude/answers\.local\.env to \.gitignore'

V092_MF4_IGNORE_TARGET="$WORK/v092-mf4-ignore-existing"
mkdir -p "$V092_MF4_IGNORE_TARGET/.claude"
printf 'agent_style=terse\n' >"$V092_MF4_IGNORE_TARGET/.claude/answers.local.env"
printf 'node_modules/\n.claude/answers.local.env\n# keep\n' >"$V092_MF4_IGNORE_TARGET/.gitignore"
cp "$V092_MF4_IGNORE_TARGET/.gitignore" "$WORK/v092-mf4-ignore-before"
V092_MF4_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF4_IGNORE_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" 2>&1)
check "v0.9.2 @s30 existing gitignore rule stays byte-identical" "0" \
  "$(cmp -s "$WORK/v092-mf4-ignore-before" "$V092_MF4_IGNORE_TARGET/.gitignore"; echo $?)"
check "v0.9.2 @s30 existing gitignore rule stays unique" "1" \
  "$(grep -cxF '.claude/answers.local.env' "$V092_MF4_IGNORE_TARGET/.gitignore")"
check "v0.9.2 @s30 existing rule reports no change" "0" \
  "$(printf '%s\n' "$V092_MF4_OUT" | grep -c 'Added .*answers.local.env'; true)"

V092_MF4_NO_LOCAL_TARGET="$WORK/v092-mf4-no-local"
mkdir -p "$V092_MF4_NO_LOCAL_TARGET"
printf 'keep-without-newline' >"$V092_MF4_NO_LOCAL_TARGET/.gitignore"
cp "$V092_MF4_NO_LOCAL_TARGET/.gitignore" "$WORK/v092-mf4-no-local-before"
bash "$ROOT/setup.sh" \
  --target "$V092_MF4_NO_LOCAL_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" >/dev/null 2>&1
check "v0.9.2 @s30 no local answers leaves gitignore untouched" "0" \
  "$(cmp -s "$WORK/v092-mf4-no-local-before" "$V092_MF4_NO_LOCAL_TARGET/.gitignore"; echo $?)"

V092_MF4_GATED_TARGET="$WORK/v092-mf4-gated-ignore"
bash "$ROOT/setup.sh" \
  --target "$V092_MF4_GATED_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" >/dev/null 2>&1
printf 'autonomy_mode=gated\n' >"$V092_MF4_GATED_TARGET/.claude/answers.local.env"
printf 'keep\n' >"$V092_MF4_GATED_TARGET/.gitignore"
cp "$V092_MF4_GATED_TARGET/.gitignore" "$WORK/v092-mf4-gated-before"

V092_MF4_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF4_GATED_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" 2>&1)
check "v0.9.2 @s31 preview exits 1" "1" "$?"
check "v0.9.2 @s31 preview leaves gitignore untouched" "0" \
  "$(cmp -s "$WORK/v092-mf4-gated-before" "$V092_MF4_GATED_TARGET/.gitignore"; echo $?)"

bash "$ROOT/setup.sh" \
  --target "$V092_MF4_GATED_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" --abort >/dev/null 2>&1
check "v0.9.2 @s31 abort leaves gitignore untouched" "0" \
  "$(cmp -s "$WORK/v092-mf4-gated-before" "$V092_MF4_GATED_TARGET/.gitignore"; echo $?)"

V092_MF4_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF4_GATED_TARGET" --answers "$V092_MF4_BAD_ANS" 2>&1)
check "v0.9.2 @s31 parse failure leaves gitignore untouched" "0" \
  "$(cmp -s "$WORK/v092-mf4-gated-before" "$V092_MF4_GATED_TARGET/.gitignore"; echo $?)"

V092_MF4_OUTSIDE_IGNORE="$WORK/v092-mf4-outside-gitignore"
printf 'outside\n' >"$V092_MF4_OUTSIDE_IGNORE"
rm "$V092_MF4_GATED_TARGET/.gitignore"
ln -s "$V092_MF4_OUTSIDE_IGNORE" "$V092_MF4_GATED_TARGET/.gitignore"
V092_MF4_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF4_GATED_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" --merge 2>&1)
V092_MF4_RC=$?
check "v0.9.2 @s31 escaping gitignore symlink exits 1" "1" "$V092_MF4_RC"
check "v0.9.2 @s31 escaping gitignore symlink is retained" "link" \
  "$([ -L "$V092_MF4_GATED_TARGET/.gitignore" ] && echo link || echo changed)"
check "v0.9.2 @s31 escaping gitignore referent is untouched" "outside" \
  "$(cat "$V092_MF4_OUTSIDE_IGNORE")"

for V092_MF4_MANIFEST in \
  plugin/.claude-plugin/plugin.json \
  .claude-plugin/marketplace.json \
  .cursor-plugin/plugin.json \
  codex/.codex-plugin/plugin.json
do
  grep_case "v0.9.2 @s32 $V092_MF4_MANIFEST version" \
    "$ROOT/$V092_MF4_MANIFEST" '"version": "0\.9\.2"'
done

V092_MF4_README="$ROOT/README.md"
for V092_MF4_TERM in \
  'agent-config\.lock\.json' \
  'STALE-MANAGED' \
  'CUSTOMIZED-MANAGED' \
  'LEGACY' \
  'OBSOLETE' \
  'CUSTOMIZED-OBSOLETE' \
  '--merge --prune' \
  'quoted.*answers|answers.*quoted'
do
  grep_case "v0.9.2 @s32 README explains $V092_MF4_TERM" \
    "$V092_MF4_README" "$V092_MF4_TERM"
done

section "$ROOT/docs/upgrade-guide.md" '^## Upgrading to v0\.9\.2' >"$WORK/v092-mf4-upgrade.md"
for V092_MF4_TERM in \
  'agent-config\.lock\.json' \
  'STALE-MANAGED' \
  'CUSTOMIZED-MANAGED' \
  'LEGACY' \
  'OBSOLETE' \
  'CUSTOMIZED-OBSOLETE' \
  '--merge --prune' \
  'first.*upgrade|upgrade.*first' \
  'quoted' \
  '\.claude/answers\.local\.env'
do
  grep_case "v0.9.2 @s32 upgrade guide explains $V092_MF4_TERM" \
    "$WORK/v092-mf4-upgrade.md" "$V092_MF4_TERM"
done

check "v0.9.2 @s33 spec ledger validates" "0" \
  "$(cd "$ROOT" && python3 scripts/validate-specs.py docs/specs/upgrade-fidelity/features.json >/dev/null 2>&1; echo $?)"
check "v0.9.2 @s33 build check passes" "0" \
  "$(cd "$ROOT" && bash scripts/build.sh --check >/dev/null 2>&1; echo $?)"
V092_MF4_PACKAGING=$(cd "$ROOT" && python3 scripts/validate-packaging.py 2>&1)
check "v0.9.2 @s33 packaging validates" "0" "$?"
grep_case "v0.9.2 @s33 packaging reports v0.9.2" \
  <(printf '%s\n' "$V092_MF4_PACKAGING") 'packaging valid @ v0\.9\.2'
check "v0.9.2 @s33 setup scripts parse" "0" \
  "$(bash -n "$ROOT/setup.sh" "$ROOT/plugin/setup.sh"; echo $?)"
check "v0.9.2 @s33 manifests parse as JSON" "0" \
  "$(python3 -c 'import json,sys; [json.load(open(path)) for path in sys.argv[1:]]' \
    "$ROOT/plugin/.claude-plugin/plugin.json" \
    "$ROOT/.claude-plugin/marketplace.json" \
    "$ROOT/.cursor-plugin/plugin.json" \
    "$ROOT/codex/.codex-plugin/plugin.json"; echo $?)"

v092_mf4_generated_digest() {
  python3 -c '
import hashlib, pathlib, sys

root = pathlib.Path(sys.argv[1])
digest = hashlib.sha256()
for rel in sys.argv[2:]:
    path = root / rel
    items = [path] if path.is_file() else sorted(path.rglob("*"))
    for item in items:
        if item.is_file():
            digest.update(item.relative_to(root).as_posix().encode())
            digest.update(item.read_bytes())
print(digest.hexdigest())
' "$ROOT" \
    plugin/template plugin/setup.sh plugin/template.config.yaml plugin/examples \
    codex/skills cursor plugin/cursor plugin/codex/skills
}

(cd "$ROOT" && bash scripts/build.sh >/dev/null)
V092_MF4_BUILD_ONE=$(v092_mf4_generated_digest)
(cd "$ROOT" && bash scripts/build.sh >/dev/null)
V092_MF4_BUILD_TWO=$(v092_mf4_generated_digest)
check "v0.9.2 @s33 double build is deterministic" \
  "$V092_MF4_BUILD_ONE" "$V092_MF4_BUILD_TWO"

V092_MF4_RENDER_COUNT=0
for V092_MF4_EXAMPLE in "$ROOT"/examples/*/answers.env; do
  for V092_MF4_HOST in claude cursor codex grok; do
    V092_MF4_RENDER_COUNT=$((V092_MF4_RENDER_COUNT + 1))
    V092_MF4_RENDER_TARGET="$WORK/v092-mf4-render-$(basename "$(dirname "$V092_MF4_EXAMPLE")")-$V092_MF4_HOST"
    bash "$ROOT/setup.sh" \
      --target "$V092_MF4_RENDER_TARGET" --answers "$V092_MF4_EXAMPLE" \
      --host "$V092_MF4_HOST" >/dev/null 2>&1
    check "v0.9.2 @s33 $(basename "$(dirname "$V092_MF4_EXAMPLE")")/$V092_MF4_HOST renders" \
      "0" "$?"
    check "v0.9.2 @s33 $(basename "$(dirname "$V092_MF4_EXAMPLE")")/$V092_MF4_HOST has no placeholders" \
      "0" "$(grep -R -cE '\{\{[#^/]?[a-z_]+\}\}' "$V092_MF4_RENDER_TARGET" 2>/dev/null | awk -F: '{n += $2} END {print n + 0}')"
  done
done
check "v0.9.2 @s33 render matrix covers 24 example/host pairs" \
  "24" "$V092_MF4_RENDER_COUNT"
