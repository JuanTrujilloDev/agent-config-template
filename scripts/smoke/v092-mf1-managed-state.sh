#!/bin/bash
# v0.9.2 MF1 Gate 2: fresh renders expose one deterministic managed-state file.

V092_MF1_TARGET="$WORK/v092-mf1-fresh"
rm -rf "$V092_MF1_TARGET"
mkdir -p "$V092_MF1_TARGET"
bash "$ROOT/setup.sh" \
  --target "$V092_MF1_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" >/dev/null 2>&1

V092_MF1_LOCK="$V092_MF1_TARGET/agent-config.lock.json"
V092_MF1_RC=0
python3 -c '
import hashlib, json, pathlib, re, sys

target = pathlib.Path(sys.argv[1])
lock = json.loads((target / "agent-config.lock.json").read_text())
assert lock["schema_version"] == 1
assert lock["template_version"] == "0.9.2"
assert lock["hosts"] == ["claude"]
assert list(lock["files"]) == sorted(lock["files"])
assert "CLAUDE.md" not in lock["files"]
assert ".claude/settings.json" not in lock["files"]
assert ".claude/CLAUDE.md" not in lock["files"]
assert "docs/CONTEXT.md" not in lock["files"]
assert not any(rel.startswith("docs/design-system/") for rel in lock["files"])
for rel, entry in lock["files"].items():
    assert entry["template_version"] == "0.9.2"
    assert re.fullmatch(r"[0-9a-f]{64}", entry["sha256"])
    assert hashlib.sha256((target / rel).read_bytes()).hexdigest() == entry["sha256"]
' "$V092_MF1_TARGET" || V092_MF1_RC=$?
check "v0.9.2 @s1 fresh render writes deterministic managed baseline" "0" "$V092_MF1_RC"

cp "$V092_MF1_LOCK" "$WORK/v092-mf1-lock-before.json"
bash "$ROOT/setup.sh" \
  --target "$V092_MF1_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" \
  --overwrite >/dev/null 2>&1
check "v0.9.2 @s1/@s5 overwrite keeps lock deterministic" "0" "$(cmp -s "$WORK/v092-mf1-lock-before.json" "$V092_MF1_LOCK"; echo $?)"

V092_MF1_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF1_TARGET" \
  --answers "$ROOT/examples/python-django/answers.env" 2>&1)
V092_MF1_PREVIEW_RC=$?
check "v0.9.2 @s2 stale preview exits without writing" "1" "$V092_MF1_PREVIEW_RC"
grep_case "v0.9.2 @s2 baseline match is stale" <(printf '%s\n' "$V092_MF1_OUT") 'STALE-MANAGED +\.claude/agents/backend-dev\.md'

V092_MF1_OLD_HASH=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["files"][".claude/agents/backend-dev.md"]["sha256"])' "$V092_MF1_LOCK")
printf '\nuser edit\n' >>"$V092_MF1_TARGET/.claude/agents/backend-dev.md"
V092_MF1_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF1_TARGET" \
  --answers "$ROOT/examples/python-django/answers.env" 2>&1)
grep_case "v0.9.2 @s3 edited baseline is customized-managed" <(printf '%s\n' "$V092_MF1_OUT") 'CUSTOMIZED-MANAGED +\.claude/agents/backend-dev\.md'
V092_MF1_LINE=$(printf '%s\n' "$V092_MF1_OUT" | grep -E -e '--merge --overwrite-files ' | tail -1)
check "v0.9.2 @s3 customized path absent from suggestion" "0" "$(printf '%s\n' "$V092_MF1_LINE" | grep -c '\.claude/agents/backend-dev\.md'; true)"

bash "$ROOT/setup.sh" \
  --target "$V092_MF1_TARGET" \
  --answers "$ROOT/examples/python-django/answers.env" \
  --merge >/dev/null 2>&1
check "v0.9.2 @s6 merge preserves customized baseline" "$V092_MF1_OLD_HASH" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["files"][".claude/agents/backend-dev.md"]["sha256"])' "$V092_MF1_LOCK")"
bash "$ROOT/setup.sh" \
  --target "$V092_MF1_TARGET" \
  --answers "$ROOT/examples/python-django/answers.env" \
  --merge --overwrite-files .claude/agents/backend-dev.md >/dev/null 2>&1
check "v0.9.2 @s6 explicit overwrite advances baseline" "0" "$(python3 -c 'import hashlib,json,sys; d=json.load(open(sys.argv[1])); print(0 if d["files"][".claude/agents/backend-dev.md"]["sha256"] == hashlib.sha256(open(sys.argv[2],"rb").read()).hexdigest() else 1)' "$V092_MF1_LOCK" "$V092_MF1_TARGET/.claude/agents/backend-dev.md")"

rm "$V092_MF1_LOCK"
printf '\nlegacy edit\n' >>"$V092_MF1_TARGET/.claude/agents/backend-dev.md"
V092_MF1_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF1_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" 2>&1)
grep_case "v0.9.2 @s4/@s7 missing state is legacy" <(printf '%s\n' "$V092_MF1_OUT") 'LEGACY +\.claude/agents/backend-dev\.md'

for V092_MF1_BAD_STATE in \
  '{' \
  '{"schema_version":2,"template_version":"old","hosts":[],"files":{}}' \
  '{"schema_version":1,"template_version":"old","hosts":[],"files":{"../escape":{"template_version":"old","sha256":"0000000000000000000000000000000000000000000000000000000000000000"}}}' \
  '{"schema_version":1,"template_version":"old","hosts":[],"files":{"/escape":{"template_version":"old","sha256":"0000000000000000000000000000000000000000000000000000000000000000"}}}' \
  '{"schema_version":1,"template_version":"old","hosts":[],"files":{"README.md":{"template_version":"old","sha256":"0000000000000000000000000000000000000000000000000000000000000000"}}}' \
  '{"schema_version":1,"template_version":"old","hosts":[],"files":{".claude/agents/backend-dev.md":{"template_version":"old","sha256":"bad"}}}'
do
  printf '%s\n' "$V092_MF1_BAD_STATE" >"$V092_MF1_LOCK"
  V092_MF1_OUT=$(bash "$ROOT/setup.sh" \
    --target "$V092_MF1_TARGET" \
    --answers "$ROOT/examples/python-fastapi/answers.env" 2>&1)
  check "v0.9.2 @s8 invalid state warns once" "1" "$(printf '%s\n' "$V092_MF1_OUT" | grep -c 'Ignoring invalid agent-config.lock.json'; true)"
  grep_case "v0.9.2 @s8 invalid state cannot claim baseline" <(printf '%s\n' "$V092_MF1_OUT") 'LEGACY +\.claude/agents/backend-dev\.md'
done

V092_MF1_OUTSIDE="$WORK/v092-mf1-outside-lock"
printf 'precious\n' >"$V092_MF1_OUTSIDE"
rm -f "$V092_MF1_LOCK"
ln -s "$V092_MF1_OUTSIDE" "$V092_MF1_LOCK"
touch "$WORK/v092-mf1-marker"
sleep 1
V092_MF1_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF1_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" \
  --merge 2>&1)
V092_MF1_SYMLINK_RC=$?
check "v0.9.2 @s5/@s8 symlinked state refuses mutation" "1" "$V092_MF1_SYMLINK_RC"
check "v0.9.2 @s5/@s8 outside state target is unchanged" "precious" "$(cat "$V092_MF1_OUTSIDE")"
check "v0.9.2 @s5/@s8 refusal happens before target writes" "" "$(find "$V092_MF1_TARGET" -newer "$WORK/v092-mf1-marker" -type f -o -newer "$WORK/v092-mf1-marker" -type l)"

for V092_MF1_HOST in claude cursor codex grok; do
  V092_MF1_HOST_TARGET="$WORK/v092-mf1-$V092_MF1_HOST"
  bash "$ROOT/setup.sh" \
    --target "$V092_MF1_HOST_TARGET" \
    --answers "$ROOT/examples/python-fastapi/answers.env" \
    --host "$V092_MF1_HOST" >/dev/null 2>&1
  check "v0.9.2 @s9 $V092_MF1_HOST records canonical host" "$V092_MF1_HOST" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hosts"][0])' "$V092_MF1_HOST_TARGET/agent-config.lock.json")"
done

V092_MF1_BUNDLE_TARGET="$WORK/v092-mf1-bundle"
bash "$ROOT/plugin/setup.sh" \
  --target "$V092_MF1_BUNDLE_TARGET" \
  --answers "$ROOT/examples/python-fastapi/answers.env" >/dev/null 2>&1
check "v0.9.2 @s9 bundled setup writes equivalent state" "0" "$(python3 -c 'import json,sys; a=json.load(open(sys.argv[1])); b=json.load(open(sys.argv[2])); print(0 if a == b else 1)' "$WORK/v092-mf1-lock-before.json" "$V092_MF1_BUNDLE_TARGET/agent-config.lock.json")"
