# MF7 merge-reporting + release (@s48..@s57) — the `--merge` plan labels DIFFERS files
# (STALE-MANAGED / CUSTOMIZED / SYMLINK-CONFLICT) and prints one copy-pasteable
# `--merge --overwrite-files a,b` line; the flag overwrites only what is listed.
# Fixture replicates the read-only portfolio evidence in mktemp: render examples/python-django,
# then (a) old-style hand-written agent, (b) project paragraph appended to a rule,
# (c) `.claude/CLAUDE.md` symlink replaced by a differing regular file, (d) everything else identical.
SETUP="$ROOT/setup.sh"; DJ="$ROOT/examples/python-django/answers.env"
CLEAN="$WORK/mf7-clean"; FIX="$WORK/mf7-fixture"
bash "$SETUP" --target "$CLEAN" --answers "$DJ" >/dev/null 2>&1 || { echo "FAIL @s48 render python-django"; FAIL=1; }
BD=.claude/agents/backend-dev.md; BS=.claude/rules/backend-style.md; DCM=.claude/CLAUDE.md; SL=.claude/settings.local.json
cp -R "$CLEAN" "$FIX"
printf '# backend-dev\n\nYou write Django code. Follow PEP 8.\n' >"$FIX/$BD"                 # (a) stale managed
printf '\n## Project-specific\n\nAll money columns use DecimalField(19,4).\n' >>"$FIX/$BS"    # (b) customized rule
printf '\n## Team conventions\n\nWe deploy on Fridays. Really.\n' >>"$FIX/CLAUDE.md"           # root CLAUDE.md differs
MASTER=docs/design-system/MASTER.md; printf '\n## Colors\n\nprimary: #0044cc\n' >>"$FIX/$MASTER"  # D13 user-filled brand file
rm "$FIX/$DCM"; printf '# Old .claude/CLAUDE.md\n\nJan-2026 render.\n' >"$FIX/$DCM"           # (c) symlink conflict
printf '{"permissions":{"allow":["Bash(make:*)"]}}\n' >"$FIX/$SL"
md5f() { md5 -q "$1" 2>/dev/null || md5sum "$1" | cut -d' ' -f1; }
SL_MD5=$(md5f "$FIX/$SL"); ROOT_MD5=$(md5f "$FIX/CLAUDE.md"); BS_MD5=$(md5f "$FIX/$BS"); DCM_MD5=$(md5f "$FIX/$DCM")
# fresh_fix — resets $F to a pristine copy of the fixture with a mtime marker one second old.
fresh_fix() { F="$WORK/mf7-run"; rm -rf "$F"; cp -R "$FIX" "$F"; touch "$WORK/mf7-marker"; sleep 1; }
# run_setup ARGS... — sets OUT (stdout+stderr), RC, NEWER (files in $F newer than marker).
run_setup() { OUT=$(bash "$SETUP" --target "$F" --answers "$DJ" "$@" 2>&1); RC=$?; NEWER=$(find "$F" -newer "$WORK/mf7-marker" -type f -o -newer "$WORK/mf7-marker" -type l); }
untouched() { # NAME — asserts the three untouchable files in $F are byte-identical to the fixture
  check "$1 settings.local.json untouched" "$SL_MD5" "$(md5f "$F/$SL")"
  check "$1 root CLAUDE.md untouched" "$ROOT_MD5" "$(md5f "$F/CLAUDE.md")"
}

# @s48 — plan (no mode): three labels, exit 1, nothing written
fresh_fix; run_setup
check "@s48 plan exits 1" "1" "$RC"
grep_case "@s48 STALE-MANAGED backend-dev.md" <(printf '%s\n' "$OUT") "STALE-MANAGED +$BD"
grep_case "@s48 STALE-MANAGED backend-style.md (rules/ is template-managed)" <(printf '%s\n' "$OUT") "STALE-MANAGED +$BS"
grep_case "@s48 SYMLINK-CONFLICT .claude/CLAUDE.md" <(printf '%s\n' "$OUT") "SYMLINK-CONFLICT +$DCM"
grep_case "@s48 CUSTOMIZED CLAUDE.md with keep hint" <(printf '%s\n' "$OUT") 'CUSTOMIZED +CLAUDE\.md.*keep'
check "@s48 CUSTOMIZED never applied to managed files" "0" "$(printf '%s\n' "$OUT" | grep -c "CUSTOMIZED.*\.claude/"; true)"
grep_case "@s48 D13: edited MASTER.md is CUSTOMIZED, not STALE-MANAGED" <(printf '%s\n' "$OUT") "CUSTOMIZED +$MASTER"
check "@s48 D13: MASTER.md never STALE-MANAGED" "0" "$(printf '%s\n' "$OUT" | grep -c "STALE-MANAGED.*$MASTER"; true)"
check "@s48 plan writes nothing (find -newer marker empty)" "" "$NEWER"
check "@s48 identical file (pmo.md) not listed" "0" "$(printf '%s\n' "$OUT" | grep -c 'agents/pmo\.md'; true)"
# @s49 — one copy-pasteable line: every STALE-MANAGED path, no CUSTOMIZED / SYMLINK-CONFLICT path
LINE=$(printf '%s\n' "$OUT" | grep -E -e '--merge --overwrite-files ' | tail -1)
check "@s49 exactly one --overwrite-files line" "1" "$(printf '%s\n' "$OUT" | grep -cE -e '--merge --overwrite-files '; true)"
grep_case "@s49 line is copy-pasteable (setup.sh --target … --answers … --merge --overwrite-files …)" <(printf '%s\n' "$LINE") "setup\.sh --target .* --answers .* --merge --overwrite-files [^ ]+$"
LIST=$(printf '%s\n' "$LINE" | sed -E 's/.*--overwrite-files ([^ ]+).*/\1/' | tr ',' '\n' | sort | paste -sd, -)
check "@s49 list = exactly the STALE-MANAGED files, no CUSTOMIZED path (MASTER.md absent)" "$BD,$BS" "$LIST"
# v0.8.3 @s3 — stdin plans keep `-` but explain that replay needs the same pipe.
fresh_fix
OUT=$(bash "$SETUP" --target "$F" --answers - <"$DJ" 2>&1); RC=$?
check "v0.8.3 @s3 stdin plan exits 1" "1" "$RC"
grep_case "v0.8.3 @s3 stdin plan keeps --answers -" <(printf '%s\n' "$OUT") '--answers - --merge --overwrite-files'
grep_case "v0.8.3 @s3 stdin plan explains replay" <(printf '%s\n' "$OUT") '[Pp]ipe.*same answers|same answers.*[Pp]ipe'
# @s50 — --merge alone keeps every differing file
fresh_fix; run_setup --merge
check "@s50 --merge alone exits 0" "0" "$RC"
check "@s50 --merge alone keeps stale backend-dev.md" "$(md5f "$FIX/$BD")" "$(md5f "$F/$BD")"
check "@s50 --merge alone keeps customized rule" "$BS_MD5" "$(md5f "$F/$BS")"
check "@s50 --merge alone keeps regular .claude/CLAUDE.md" "regular|$DCM_MD5" "$([ -L "$F/$DCM" ] && echo link || echo regular)|$(md5f "$F/$DCM")"
grep_case "@s50 --merge alone summary counts 0 overwritten" <(printf '%s\n' "$OUT") '0 overwritten'
untouched "@s50 --merge alone"
# @s50 — --merge --overwrite-files <one file> overwrites only that file
fresh_fix; run_setup --merge --overwrite-files "$BD"
check "@s50 overwrite-files exits 0" "0" "$RC"
check "@s50 backend-dev.md equals staged render" "$(md5f "$CLEAN/$BD")" "$(md5f "$F/$BD")"
check "@s50 customized rule byte-unchanged" "$BS_MD5" "$(md5f "$F/$BS")"
check "@s50 unlisted .claude/CLAUDE.md stays a regular file" "regular|$DCM_MD5" "$([ -L "$F/$DCM" ] && echo link || echo regular)|$(md5f "$F/$DCM")"
grep_case "@s50 prints what it overwrote" <(printf '%s\n' "$OUT") "(overwr|~).*$BD|$BD.*(overwr)"
grep_case "@s50 summary counts 1 overwritten" <(printf '%s\n' "$OUT") '1 overwritten'
untouched "@s50 overwrite-files"
# @s51 — listing .claude/CLAUDE.md relinks the symlink, root untouched
fresh_fix; run_setup --merge --overwrite-files "$DCM"
check "@s51 exits 0" "0" "$RC"
check "@s51 .claude/CLAUDE.md is a symlink to ../CLAUDE.md" "../CLAUDE.md" "$(readlink "$F/$DCM")"
check "@s51 stale backend-dev.md not touched when unlisted" "$(md5f "$FIX/$BD")" "$(md5f "$F/$BD")"
untouched "@s51"
# @s52 — misuse: unknown path / no mode / --overwrite → non-zero, one line, nothing written
fresh_fix; run_setup --merge --overwrite-files .claude/agents/nope.md
check "@s52 unknown path exits non-zero" "1" "$([ "$RC" -ne 0 ] && echo 1 || echo 0)"
check "@s52 unknown path: one-line error" "1" "$(printf '%s\n' "$OUT" | grep -c .; true)"
check "@s52 unknown path: nothing written" "" "$NEWER"
fresh_fix; run_setup --overwrite-files "$BD"
check "@s52 --overwrite-files without --merge exits 1" "1" "$RC"
check "@s52 without --merge: one-line error" "1" "$(printf '%s\n' "$OUT" | grep -c .; true)"
check "@s52 without --merge: nothing written" "" "$NEWER"
fresh_fix; run_setup --overwrite --overwrite-files "$BD"
check "@s52 with --overwrite exits non-zero" "1" "$([ "$RC" -ne 0 ] && echo 1 || echo 0)"
check "@s52 with --overwrite: one-line error" "1" "$(printf '%s\n' "$OUT" | grep -c .; true)"
check "@s52 with --overwrite: nothing written" "" "$NEWER"
fresh_fix; run_setup --merge --overwrite-files .claude/settings.json
check "@s52 .claude/settings.json is merge-managed: exits non-zero" "1" "$([ "$RC" -ne 0 ] && echo 1 || echo 0)"
check "@s52 settings.json listed: one-line error" "1" "$(printf '%s\n' "$OUT" | grep -c .; true)"
check "@s52 settings.json listed: nothing written" "" "$NEWER"
# security M2 — .claude/CLAUDE.md listed with no regular root CLAUDE.md → error, user text kept
fresh_fix; rm "$F/CLAUDE.md"; run_setup --merge --overwrite-files "$DCM"
check "@s52 M2 no root CLAUDE.md: exits non-zero" "1" "$([ "$RC" -ne 0 ] && echo 1 || echo 0)"
check "@s52 M2 no root CLAUDE.md: one-line error" "1" "$(printf '%s\n' "$OUT" | grep -c .; true)"
check "@s52 M2 no root CLAUDE.md: .claude/CLAUDE.md kept, nothing written" "regular|$DCM_MD5|" "$([ -L "$F/$DCM" ] && echo link || echo regular)|$(md5f "$F/$DCM")|$NEWER"
# security M1 — a listed path that is a symlink out of the target is refused before any write
PD=.claude/patterns/desktop.md; OUTSIDE="$WORK/mf7-outside"; printf 'precious\n' >"$OUTSIDE"
fresh_fix; rm "$F/$PD"; ln -s "$OUTSIDE" "$F/$PD"; touch "$WORK/mf7-marker"; sleep 1; run_setup --merge --overwrite-files "$PD"
check "@s52 M1 symlink out of target: exits non-zero" "1" "$([ "$RC" -ne 0 ] && echo 1 || echo 0)"
check "@s52 M1 symlink out of target: one-line error" "1" "$(printf '%s\n' "$OUT" | grep -c .; true)"
check "@s52 M1 outside file unchanged" "precious" "$(cat "$OUTSIDE")"
check "@s52 M1 nothing written in target" "" "$NEWER"
fresh_fix; rm -rf "$F/.claude/patterns"; mkdir "$WORK/mf7-outdir"; ln -s "$WORK/mf7-outdir" "$F/.claude/patterns"; run_setup --merge --overwrite-files "$PD"
check "@s52 M1 symlinked intermediate dir: exits non-zero" "1" "$([ "$RC" -ne 0 ] && echo 1 || echo 0)"
check "@s52 M1 symlinked intermediate dir: outside dir still empty" "" "$(ls "$WORK/mf7-outdir")"
# @s53 — bash 3.2 + python block still parse
check "@s53 bash -n setup.sh" "0" "$(bash -n "$SETUP" 2>/dev/null; echo $?)"
check "@s53 no declare -A" "0" "$(grep -c 'declare -A' "$SETUP"; true)"
# contract says split('PYEOF')[1]; the opener line is `<<'PYEOF' || PY_RC=$?`, so split on the whole opener.
check "@s53 python block parses" "0" "$(python3 -c "import ast,re; ast.parse(re.split(r\"<<'PYEOF'[^\\n]*\\n\", open('$SETUP').read())[1].split('\\nPYEOF')[0])" 2>/dev/null; echo $?)"
check "@s53 plugin/setup.sh parity (generated copy)" "0" "$(cmp -s "$SETUP" "$ROOT/plugin/setup.sh"; echo $?)"
# @s54 — upgrade guide: "Upgrading to v0.8.2" section + portfolio resolution
UPG="$ROOT/docs/upgrade-guide.md"; section "$UPG" '^## Upgrading to v0\.8\.2' >"$WORK/upg082.md"
grep_case "@s54 section exists" "$WORK/upg082.md" '^## Upgrading to v0\.8\.2'
grep_case "@s54 output_style four values, literal" "$WORK/upg082.md" 'output_style=concise\|balanced\|detailed\|terse'
grep_case "@s54 output_style default concise" "$WORK/upg082.md" 'output_style=concise\|balanced\|detailed\|terse.*default `concise`'
grep_case "@s54 keys live in .claude/answers.local.env" "$WORK/upg082.md" '`\.claude/answers\.local\.env`'
grep_case "@s54 terse caveat" "$WORK/upg082.md" '`terse`.*(caveat|readab|not for|lossy|beginner|ask)'
grep_case "@s54 agent_style two values, literal, default terse" "$WORK/upg082.md" 'agent_style=terse\|descriptive.*default `terse`'
check "@s54 no stale value lists (default|full, 'same four values')" "0" "$(grep -cE 'output_style=default|full\|terse|same four values' "$WORK/upg082.md"; true)"
grep_case "@s54 agent_style boundary rule" "$WORK/upg082.md" 'agent_style.*(boundary|return message|hand.?back|orchestrator)|(boundary|return message).*agent_style'
grep_case "@s54 companions list grammar" "$WORK/upg082.md" 'companions=(yes\|not_now\|never\|<comma list>|graphify,ponytail)'
for lbl in STALE-MANAGED CUSTOMIZED SYMLINK-CONFLICT; do grep_case "@s54 label $lbl" "$WORK/upg082.md" "$lbl"; done
grep_case "@s54 --overwrite-files documented" "$WORK/upg082.md" '--overwrite-files'
grep_case "@s54 portfolio: keep root CLAUDE.md conventions" "$WORK/upg082.md" '[Kk]eep.*root `?CLAUDE\.md`?|root `?CLAUDE\.md`?.*keep'
grep_case "@s54 portfolio: regenerate STALE-MANAGED via printed line" "$WORK/upg082.md" 'STALE-MANAGED.*(printed|copy-past|--overwrite-files)|(printed|copy-past).*STALE-MANAGED'
grep_case "@s54 portfolio: diff then convert .claude/CLAUDE.md to symlink" "$WORK/upg082.md" '[Dd]iff.*`?\.claude/CLAUDE\.md`?.*symlink|`?\.claude/CLAUDE\.md`?.*[Dd]iff.*symlink'
grep_case "@s54 portfolio: tooling upgrade as its own chore: commit" "$WORK/upg082.md" '`?chore:?`?.*commit|commit.*`?chore:'
# @s55 — CI render-smoke covers grok + codex and runs the smoke harness
CI="$ROOT/.github/workflows/ci.yml"
grep_case "@s55 ci renders --host grok" "$CI" '--host grok'
grep_case "@s55 ci renders --host codex" "$CI" '--host codex'
grep_case "@s55 ci still renders --host cursor" "$CI" '--host cursor'
grep_case "@s55 ci runs bash scripts/smoke.sh" "$CI" 'bash scripts/smoke\.sh'
# @s56 — --help documents the flag
grep_case "@s56 --help documents --overwrite-files" <(bash "$SETUP" --help 2>&1) '--overwrite-files'
grep_case "@s56 header usage line lists --overwrite-files" "$SETUP" 'setup\.sh --target <dir> --answers <file>.*--overwrite-files'
# @s57 — release: three manifests at 0.8.2, validator agrees
for m in plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json codex/.codex-plugin/plugin.json; do
  grep_case "@s57 $m version 0.8.2" "$ROOT/$m" '"version": *"0\.8\.2"'
done
check "@s57 validate-packaging reports v0.8.2" "1" "$(cd "$ROOT" && python3 scripts/validate-packaging.py 2>&1 | grep -c 'packaging valid @ v0\.8\.2'; true)"
# MANUAL: run the plan against the real portfolio checkout (read-only), confirm the three labels match
# MANUAL: the human diffs .claude/CLAUDE.md vs root CLAUDE.md before relinking; the smoke cannot judge which content wins
