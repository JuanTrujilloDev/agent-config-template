#!/bin/bash
# v0.9.2 MF3 Gate 2: preview exposes an unchanged lock-only managed file.

V092_MF3_TARGET="$WORK/v092-mf3-obsolete"
V092_MF3_ANS="$ROOT/examples/python-fastapi/answers.env"
V092_MF3_REL=".claude/rules/retired.md"

v092_mf3_record() {
  local target="$1" rel="$2" content="$3"
  mkdir -p "${target}/${rel%/*}"
  printf '%s' "$content" >"$target/$rel"
  python3 -c '
import hashlib, json, pathlib, sys

target = pathlib.Path(sys.argv[1])
rel = sys.argv[2]
lock_path = target / "agent-config.lock.json"
lock = json.loads(lock_path.read_text())
lock["files"][rel] = {
    "template_version": "0.9.1",
    "sha256": hashlib.sha256((target / rel).read_bytes()).hexdigest(),
}
lock_path.write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n")
' "$target" "$rel"
}

bash "$ROOT/setup.sh" --target "$V092_MF3_TARGET" --answers "$V092_MF3_ANS" >/dev/null 2>&1
v092_mf3_record "$V092_MF3_TARGET" "$V092_MF3_REL" 'retired managed rule'

V092_MF3_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF3_TARGET" --answers "$V092_MF3_ANS" 2>&1)
V092_MF3_RC=$?
check "v0.9.2 @s16 obsolete preview exits without applying" "1" "$V092_MF3_RC"
grep_case "v0.9.2 @s16 unchanged lock-only path is obsolete" \
  <(printf '%s\n' "$V092_MF3_OUT") 'OBSOLETE +\.claude/rules/retired\.md'

V092_MF3_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF3_TARGET" --answers "$V092_MF3_ANS" --merge 2>&1)
check "v0.9.2 @s18 ordinary merge retains unchanged obsolete path" \
  "retired managed rule" "$(cat "$V092_MF3_TARGET/$V092_MF3_REL")"
grep_case "v0.9.2 @s18 ordinary merge reports unchanged obsolete path" \
  <(printf '%s\n' "$V092_MF3_OUT") 'OBSOLETE +\.claude/rules/retired\.md'

printf 'user edit\n' >>"$V092_MF3_TARGET/$V092_MF3_REL"
V092_MF3_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF3_TARGET" --answers "$V092_MF3_ANS" 2>&1)
grep_case "v0.9.2 @s17 edited obsolete path is customized" \
  <(printf '%s\n' "$V092_MF3_OUT") 'CUSTOMIZED-OBSOLETE +\.claude/rules/retired\.md'

cp "$V092_MF3_TARGET/$V092_MF3_REL" "$WORK/v092-mf3-before-merge"
V092_MF3_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF3_TARGET" --answers "$V092_MF3_ANS" --merge 2>&1)
V092_MF3_RC=$?
check "v0.9.2 @s18 ordinary merge succeeds" "0" "$V092_MF3_RC"
check "v0.9.2 @s18 ordinary merge retains obsolete path" "0" \
  "$(cmp -s "$WORK/v092-mf3-before-merge" "$V092_MF3_TARGET/$V092_MF3_REL"; echo $?)"
grep_case "v0.9.2 @s18 ordinary merge reports retained obsolete path" \
  <(printf '%s\n' "$V092_MF3_OUT") 'CUSTOMIZED-OBSOLETE +\.claude/rules/retired\.md'

V092_MF3_INVALID="$WORK/v092-mf3-invalid-mode"
mkdir -p "$V092_MF3_INVALID"
printf 'precious\n' >"$V092_MF3_INVALID/precious.txt"
V092_MF3_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF3_INVALID" --answers "$V092_MF3_ANS" --prune 2>&1)
V092_MF3_RC=$?
check "v0.9.2 @s21 prune without merge fails" "1" "$V092_MF3_RC"
check "v0.9.2 @s21 misuse is one concise line" "1" \
  "$(printf '%s\n' "$V092_MF3_OUT" | grep -c .; true)"
grep_case "v0.9.2 @s21 misuse names required merge mode" \
  <(printf '%s\n' "$V092_MF3_OUT") '--prune is only valid together with --merge'
check "v0.9.2 @s21 misuse writes nothing" "precious" \
  "$(cat "$V092_MF3_INVALID/precious.txt")"

V092_MF3_PRUNE_TARGET="$WORK/v092-mf3-prune"
V092_MF3_EMPTY_REL=".claude/rules/empty-retired/old.md"
V092_MF3_NONEMPTY_REL=".claude/rules/nonempty-retired/old.md"
bash "$ROOT/setup.sh" \
  --target "$V092_MF3_PRUNE_TARGET" --answers "$V092_MF3_ANS" >/dev/null 2>&1
v092_mf3_record "$V092_MF3_PRUNE_TARGET" "$V092_MF3_EMPTY_REL" 'old empty rule'
v092_mf3_record "$V092_MF3_PRUNE_TARGET" "$V092_MF3_NONEMPTY_REL" 'old kept-dir rule'
printf 'user file\n' >"$V092_MF3_PRUNE_TARGET/.claude/rules/nonempty-retired/keep.txt"

V092_MF3_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF3_PRUNE_TARGET" --answers "$V092_MF3_ANS" --merge --prune 2>&1)
V092_MF3_RC=$?
check "v0.9.2 @s19 prune succeeds" "0" "$V092_MF3_RC"
check "v0.9.2 @s19 prune deletes only proven obsolete files" "absent|absent|user file" \
  "$([ -e "$V092_MF3_PRUNE_TARGET/$V092_MF3_EMPTY_REL" ] && echo present || echo absent)|$([ -e "$V092_MF3_PRUNE_TARGET/$V092_MF3_NONEMPTY_REL" ] && echo present || echo absent)|$(cat "$V092_MF3_PRUNE_TARGET/.claude/rules/nonempty-retired/keep.txt")"
grep_case "v0.9.2 @s19 prune reports empty-dir deletion" \
  <(printf '%s\n' "$V092_MF3_OUT") "- $V092_MF3_EMPTY_REL"
grep_case "v0.9.2 @s19 prune reports nonempty-dir deletion" \
  <(printf '%s\n' "$V092_MF3_OUT") "- $V092_MF3_NONEMPTY_REL"
check "v0.9.2 @s22 removes empty managed dir, keeps non-empty dir" "absent|present" \
  "$([ -d "$V092_MF3_PRUNE_TARGET/.claude/rules/empty-retired" ] && echo present || echo absent)|$([ -d "$V092_MF3_PRUNE_TARGET/.claude/rules/nonempty-retired" ] && echo present || echo absent)"
V092_MF3_LOCK_RC=0
python3 -c '
import json, pathlib, sys

files = json.loads((pathlib.Path(sys.argv[1]) / "agent-config.lock.json").read_text())["files"]
assert sys.argv[2] not in files
assert sys.argv[3] not in files
' "$V092_MF3_PRUNE_TARGET" "$V092_MF3_EMPTY_REL" "$V092_MF3_NONEMPTY_REL" || V092_MF3_LOCK_RC=$?
check "v0.9.2 @s22 prune drops deleted lock entries" "0" "$V092_MF3_LOCK_RC"

cp -R "$V092_MF3_PRUNE_TARGET" "$WORK/v092-mf3-after-prune"
bash "$ROOT/setup.sh" \
  --target "$V092_MF3_PRUNE_TARGET" --answers "$V092_MF3_ANS" --merge --prune >/dev/null 2>&1
check "v0.9.2 @s22 repeated prune is a no-op" "0" \
  "$(diff -r "$WORK/v092-mf3-after-prune" "$V092_MF3_PRUNE_TARGET" >/dev/null 2>&1; echo $?)"

V092_MF3_LINK_TARGET="$WORK/v092-mf3-link"
V092_MF3_LINK_REL=".claude/rules/retired-link.md"
V092_MF3_OUTSIDE="$WORK/v092-mf3-outside"
bash "$ROOT/setup.sh" \
  --target "$V092_MF3_LINK_TARGET" --answers "$V092_MF3_ANS" >/dev/null 2>&1
v092_mf3_record "$V092_MF3_LINK_TARGET" "$V092_MF3_LINK_REL" 'recorded link rule'
printf 'outside\n' >"$V092_MF3_OUTSIDE"
rm "$V092_MF3_LINK_TARGET/$V092_MF3_LINK_REL"
ln -s "$V092_MF3_OUTSIDE" "$V092_MF3_LINK_TARGET/$V092_MF3_LINK_REL"
V092_MF3_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF3_LINK_TARGET" --answers "$V092_MF3_ANS" 2>&1)
grep_case "v0.9.2 @s17 obsolete symlink is customized" \
  <(printf '%s\n' "$V092_MF3_OUT") 'CUSTOMIZED-OBSOLETE +\.claude/rules/retired-link\.md'
bash "$ROOT/setup.sh" \
  --target "$V092_MF3_LINK_TARGET" --answers "$V092_MF3_ANS" --merge --prune >/dev/null 2>&1
check "v0.9.2 @s17 obsolete symlink and referent are kept" "link|outside" \
  "$([ -L "$V092_MF3_LINK_TARGET/$V092_MF3_LINK_REL" ] && echo link || echo missing)|$(cat "$V092_MF3_OUTSIDE")"

V092_MF3_ESCAPE_REL=".claude/rules/retired-dir/old.md"
v092_mf3_record "$V092_MF3_LINK_TARGET" "$V092_MF3_ESCAPE_REL" 'recorded outside rule'
mv "$V092_MF3_LINK_TARGET/.claude/rules/retired-dir" "$WORK/v092-mf3-outside-dir"
ln -s "$WORK/v092-mf3-outside-dir" "$V092_MF3_LINK_TARGET/.claude/rules/retired-dir"
V092_MF3_OUT=$(bash "$ROOT/setup.sh" \
  --target "$V092_MF3_LINK_TARGET" --answers "$V092_MF3_ANS" --merge --prune 2>&1)
grep_case "v0.9.2 @s17 escaping parent symlink is customized" \
  <(printf '%s\n' "$V092_MF3_OUT") 'CUSTOMIZED-OBSOLETE +\.claude/rules/retired-dir/old\.md'
check "v0.9.2 @s17 escaping parent symlink cannot prune outside file" \
  "recorded outside rule" "$(cat "$WORK/v092-mf3-outside-dir/old.md")"

V092_MF3_UNRECORDED_TARGET="$WORK/v092-mf3-unrecorded"
V092_MF3_UNRECORDED_REL=".claude/rules/unrecorded.md"
bash "$ROOT/setup.sh" \
  --target "$V092_MF3_UNRECORDED_TARGET" --answers "$V092_MF3_ANS" >/dev/null 2>&1
printf 'unrecorded\n' >"$V092_MF3_UNRECORDED_TARGET/$V092_MF3_UNRECORDED_REL"
cp "$V092_MF3_UNRECORDED_TARGET/CLAUDE.md" "$WORK/v092-mf3-user-owned-before"
rm "$V092_MF3_UNRECORDED_TARGET/agent-config.lock.json"
bash "$ROOT/setup.sh" \
  --target "$V092_MF3_UNRECORDED_TARGET" --answers "$V092_MF3_ANS" --merge --prune >/dev/null 2>&1
check "v0.9.2 @s20 missing state keeps unrecorded and user-owned files" "unrecorded|0" \
  "$(cat "$V092_MF3_UNRECORDED_TARGET/$V092_MF3_UNRECORDED_REL")|$(cmp -s "$WORK/v092-mf3-user-owned-before" "$V092_MF3_UNRECORDED_TARGET/CLAUDE.md"; echo $?)"

v092_mf3_invalid_lock() {
  local target="$1" rel="$2" source="$3"
  python3 -c '
import hashlib, json, pathlib, sys

target, rel, source = pathlib.Path(sys.argv[1]), sys.argv[2], pathlib.Path(sys.argv[3])
lock = {
    "schema_version": 1,
    "template_version": "0.9.1",
    "hosts": ["claude"],
    "files": {rel: {"template_version": "0.9.1", "sha256": hashlib.sha256(source.read_bytes()).hexdigest()}},
}
(target / "agent-config.lock.json").write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n")
' "$target" "$rel" "$source"
}

V092_MF3_PRECIOUS="$WORK/v092-mf3-precious"
printf 'precious\n' >"$V092_MF3_PRECIOUS"
for V092_MF3_BAD_REL in "../v092-mf3-precious" "$V092_MF3_PRECIOUS" "CLAUDE.md"; do
  if [ "$V092_MF3_BAD_REL" = "CLAUDE.md" ]; then
    V092_MF3_BAD_SOURCE="$V092_MF3_UNRECORDED_TARGET/CLAUDE.md"
  else
    V092_MF3_BAD_SOURCE="$V092_MF3_PRECIOUS"
  fi
  v092_mf3_invalid_lock "$V092_MF3_UNRECORDED_TARGET" "$V092_MF3_BAD_REL" "$V092_MF3_BAD_SOURCE"
  V092_MF3_OUT=$(bash "$ROOT/setup.sh" \
    --target "$V092_MF3_UNRECORDED_TARGET" --answers "$V092_MF3_ANS" --merge --prune 2>&1)
  check "v0.9.2 @s20 invalid $V092_MF3_BAD_REL state warns once" "1" \
    "$(printf '%s\n' "$V092_MF3_OUT" | grep -c 'Ignoring invalid agent-config.lock.json'; true)"
  check "v0.9.2 @s20 invalid state deletes nothing" "precious|unrecorded|0" \
    "$(cat "$V092_MF3_PRECIOUS")|$(cat "$V092_MF3_UNRECORDED_TARGET/$V092_MF3_UNRECORDED_REL")|$(cmp -s "$WORK/v092-mf3-user-owned-before" "$V092_MF3_UNRECORDED_TARGET/CLAUDE.md"; echo $?)"
done

V092_MF3_BUNDLE_TARGET="$WORK/v092-mf3-bundle"
V092_MF3_BUNDLE_REL=".claude/rules/bundle-retired.md"
bash "$ROOT/plugin/setup.sh" \
  --target "$V092_MF3_BUNDLE_TARGET" --answers "$V092_MF3_ANS" >/dev/null 2>&1
v092_mf3_record "$V092_MF3_BUNDLE_TARGET" "$V092_MF3_BUNDLE_REL" 'old bundle rule'
V092_MF3_OUT=$(bash "$ROOT/plugin/setup.sh" \
  --target "$V092_MF3_BUNDLE_TARGET" --answers "$V092_MF3_ANS" --merge --prune 2>&1)
V092_MF3_RC=$?
check "v0.9.2 @s23 bundled prune succeeds" "0" "$V092_MF3_RC"
check "v0.9.2 @s23 bundled prune matches source behavior" "absent" \
  "$([ -e "$V092_MF3_BUNDLE_TARGET/$V092_MF3_BUNDLE_REL" ] && echo present || echo absent)"
grep_case "v0.9.2 @s23 help documents prune" <(bash "$ROOT/setup.sh" --help 2>&1) '--prune'
for V092_MF3_DOC in "$ROOT/plugin/commands/setup-template.md" "$ROOT/docs/guides/existing-projects.md"; do
  grep_case "v0.9.2 @s23 $(basename "$V092_MF3_DOC") documents prune command" \
    "$V092_MF3_DOC" '--merge --prune'
  grep_case "v0.9.2 @s23 $(basename "$V092_MF3_DOC") protects customized obsolete paths" \
    "$V092_MF3_DOC" 'CUSTOMIZED-OBSOLETE'
done
