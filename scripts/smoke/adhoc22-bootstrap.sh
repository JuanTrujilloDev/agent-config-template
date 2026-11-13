# ADHOC-22 S3 — bootstrap.sh (one-command install), setup.sh --abort/--legacy, migrate.py named headings.
# Sourced by scripts/smoke.sh; also runs standalone: bash scripts/smoke/adhoc22-bootstrap.sh
if [ -z "${ROOT:-}" ]; then
  ROOT=$(cd "$(dirname "$0")/../.." && pwd); WORK=$(mktemp -d); FAIL=0
  trap 'rm -rf "$WORK"' EXIT
  . "$ROOT/scripts/smoke/lib.sh"
fi

B_BOOT="$ROOT/bootstrap.sh"
B_GIT() { git -c user.name=smoke -c user.email=smoke@example.invalid -c commit.gpgsign=false -c tag.gpgsign=false "$@"; }
B_ABSENT() { [ -e "$1" ] && echo present || echo absent; }

check "adhoc22 bootstrap.sh exists" "present" "$(B_ABSENT "$B_BOOT")"
check "adhoc22 bootstrap.sh parses as POSIX sh" "0" "$(sh -n "$B_BOOT" 2>/dev/null; echo $?)"
check "adhoc22 bootstrap.sh has no bash-only [[" "0" "$(grep -c '\[\[' "$B_BOOT" 2>/dev/null; true)"

# Template source: a tagged git repo built from this working tree, so the clone path runs for real.
B_SRC="$WORK/b-src"; mkdir -p "$B_SRC"
(cd "$ROOT" && git ls-files -co --exclude-standard -z | xargs -0 tar cf - 2>/dev/null) | (cd "$B_SRC" && tar xf -)
(cd "$B_SRC" && git init -q && B_GIT add -A && B_GIT commit -qm src && B_GIT tag v-smoke)
B_NEW() { rm -rf "$1"; mkdir -p "$1"; (cd "$1" && git init -q && echo hi >README.md && B_GIT add -A && B_GIT commit -qm init); }
B_TMP="$WORK/b-tmp"; mkdir -p "$B_TMP"
B_RUN() { # DIR ANSWER ARGS... — runs bootstrap in DIR, the y/N answer read from a file instead of /dev/tty
  d=$1; printf '%s\n' "$2" >"$WORK/b-tty"; shift 2
  (cd "$d" && TMPDIR="$B_TMP" AGENT_CONFIG_TTY="$WORK/b-tty" sh "$B_BOOT" --source "file://$B_SRC" --ref v-smoke "$@" >"$WORK/b-out.txt" 2>&1; echo $?)
}

# 1. Refuses outside a git repo and on a dirty tree (unless --force).
mkdir -p "$WORK/b-nogit"
check "adhoc22 refuses outside a git repo" "1" "$(B_RUN "$WORK/b-nogit" y)"
check "adhoc22 nothing written outside a git repo" "0" "$(ls -A "$WORK/b-nogit" | wc -l | tr -d ' ')"
B_R="$WORK/b-repo"; B_NEW "$B_R"; echo dirty >>"$B_R/README.md"
check "adhoc22 refuses a dirty tree" "1" "$(B_RUN "$B_R" y)"
grep_case "adhoc22 dirty tree names --force" "$WORK/b-out.txt" '--force'
check "adhoc22 --force passes the dirty check, decline exits 0" "0" "$(B_RUN "$B_R" n --force)"

# 2. Preview, then decline: plan printed, nothing written, temp folder cleaned.
B_NEW "$B_R"
check "adhoc22 decline exits 0" "0" "$(B_RUN "$B_R" n)"
grep_case "adhoc22 preview lists files to add" "$WORK/b-out.txt" 'ADD +\.claude/rules/principles\.md'
grep_case "adhoc22 preview asks apply? (y/N)" "$WORK/b-out.txt" 'Apply\? \(y/N\)'
check "adhoc22 decline writes nothing" "" "$(cd "$B_R" && git status --porcelain)"
check "adhoc22 temp folder cleaned after decline" "0" "$(ls -A "$B_TMP" | wc -l | tr -d ' ')"
printf '' >"$WORK/b-tty-empty"
check "adhoc22 no answer means no" "0" "$(cd "$B_R" && TMPDIR="$B_TMP" AGENT_CONFIG_TTY="$WORK/b-tty-empty" sh "$B_BOOT" --source "file://$B_SRC" --ref v-smoke >/dev/null 2>&1; echo $?)"
check "adhoc22 no answer writes nothing" "" "$(cd "$B_R" && git status --porcelain)"

# 3. Accept: renders, writes the lock and a generated answers.env; temp folder cleaned.
check "adhoc22 accept exits 0" "0" "$(B_RUN "$B_R" y)"
check "adhoc22 accept writes the lock file" "present" "$(B_ABSENT "$B_R/agent-config.lock.json")"
check "adhoc22 accept renders principles" "present" "$(B_ABSENT "$B_R/.claude/rules/principles.md")"
grep_case "adhoc22 generated answers.env records the host" "$B_R/answers.env" '^TARGET_HOSTS=claude$'
grep_case "adhoc22 generated answers.env names the repo" "$B_R/answers.env" '^project_name=b-repo$'
grep_case "adhoc22 generated answers.env uses template defaults" "$B_R/answers.env" '^default_branch=main$'
check "adhoc22 generated answers.env skips Plane-only keys" "0" "$(grep -c '^mcp_plane' "$B_R/answers.env")"
grep_case "adhoc22 generated answers.env says how to calibrate" "$B_R/answers.env" '^# .*setup-template'
check "adhoc22 temp folder cleaned after accept" "0" "$(ls -A "$B_TMP" | wc -l | tr -d ' ')"

# 4. Re-run on the rendered repo uses its answers.env and previews against the lock; --host codex works.
(cd "$B_R" && B_GIT add -A && B_GIT commit -qm render)
check "adhoc22 re-run on a rendered repo exits 0" "0" "$(B_RUN "$B_R" n)"
grep_case "adhoc22 re-run reads the repo answers.env" "$WORK/b-out.txt" 'answers: answers\.env'
B_NEW "$WORK/b-codex"
check "adhoc22 --host codex accept exits 0" "0" "$(B_RUN "$WORK/b-codex" y --host codex)"
check "adhoc22 --host codex renders .agents/skills" "present" "$(B_ABSENT "$WORK/b-codex/.agents/skills")"
check "adhoc22 unknown option exits 1" "1" "$(B_RUN "$B_R" n --bogus)"

# 5. setup.sh --abort on a fresh target prints the plan and writes nothing.
B_ANS="$ROOT/examples/python-fastapi/answers.env"
check "adhoc22 --abort on a fresh target exits 0" "0" "$(bash "$ROOT/setup.sh" --target "$WORK/b-fresh" --answers "$B_ANS" --abort >"$WORK/b-abort.txt" 2>&1; echo $?)"
grep_case "adhoc22 --abort on a fresh target prints ADD rows" "$WORK/b-abort.txt" '^  ADD '
check "adhoc22 --abort on a fresh target writes nothing" "0" "$(find "$WORK/b-fresh" -type f 2>/dev/null | wc -l | tr -d ' ')"

# 6. Pre-lock repo: --merge --legacy records baselines, so the next plan says STALE/OBSOLETE and --prune works.
B_L="$WORK/b-legacy"; bash "$ROOT/setup.sh" --target "$B_L" --answers "$B_ANS" >/dev/null 2>&1
rm -f "$B_L/agent-config.lock.json"
printf 'old line\n' >>"$B_L/.claude/agents/security-reviewer.md"
printf '#!/bin/bash\necho reminder\n' >"$B_L/.claude/hooks/coding-reminder.sh"
mkdir -p "$B_L/tools"; printf 'mine\n' >"$B_L/tools/own.py"; printf 'mine\n' >"$B_L/AGENTS.md"
B_PLAN() { bash "$ROOT/setup.sh" --target "$B_L" --answers "$B_ANS" "$@" 2>&1; }
grep_case "adhoc22 pre-lock plan shows LEGACY" <(B_PLAN) 'LEGACY +\.claude/agents/security-reviewer\.md'
check "adhoc22 --legacy needs --merge" "1" "$(B_PLAN --legacy >/dev/null; echo $?)"
grep_case "adhoc22 --merge --legacy reports adopted paths" <(B_PLAN --merge --legacy) 'adopted 2 unrecorded managed file'
B_LOCKED() { python3 -c 'import json,sys; print("yes" if sys.argv[2] in json.load(open(sys.argv[1]))["files"] else "no")' "$B_L/agent-config.lock.json" "$1"; }
check "adhoc22 lock records the legacy file" "yes" "$(B_LOCKED .claude/agents/security-reviewer.md)"
check "adhoc22 lock records the retired file" "yes" "$(B_LOCKED .claude/hooks/coding-reminder.sh)"
check "adhoc22 lock skips tools/ files the template does not emit" "no" "$(B_LOCKED tools/own.py)"
check "adhoc22 lock skips a user AGENTS.md" "no" "$(B_LOCKED AGENTS.md)"
grep_case "adhoc22 legacy entries are marked" "$B_L/agent-config.lock.json" '"template_version": "legacy"' 2
B_P2=$(B_PLAN)
grep_case "adhoc22 after --legacy the old file is STALE-MANAGED" <(printf '%s\n' "$B_P2") 'STALE-MANAGED +\.claude/agents/security-reviewer\.md'
grep_case "adhoc22 after --legacy the retired file is OBSOLETE" <(printf '%s\n' "$B_P2") '^  OBSOLETE +\.claude/hooks/coding-reminder\.sh'
B_PLAN --merge --prune >/dev/null
check "adhoc22 --prune removes the retired file" "absent" "$(B_ABSENT "$B_L/.claude/hooks/coding-reminder.sh")"
check "adhoc22 --prune keeps tools/own.py" "present" "$(B_ABSENT "$B_L/tools/own.py")"

# 7. migrate.py: scenarios under a heading it cannot map are an ERROR row, never dropped silently.
B_M="$WORK/b-mig"; mkdir -p "$B_M/docs/specs/named"
printf '# Named — Spec\n\n## Problem\nx\n\n## Goal\ny\n' >"$B_M/docs/specs/named/spec.md"
printf '# Contract\n\n## MF1 — first\n- @s1 Given a When b Then c\n\n## Export CSV\n- @s2 Given d When e Then f\n' >"$B_M/docs/specs/named/contract.md"
printf '{"mini_features":[{"id":1,"name":"first","status":"todo"}]}\n' >"$B_M/docs/specs/named/features.json"
check "adhoc22 migrate.py exits 1 on an unmapped heading" "1" "$(python3 "$ROOT/core/.claude/skills/update-config/migrate.py" --root "$B_M" >"$WORK/b-mig.txt" 2>&1; echo $?)"
grep_case "adhoc22 migrate.py names the unmapped scenario" "$WORK/b-mig.txt" 'ERROR .*@s2.*Export CSV'

# 8. Docs: one install page leads with the command; README leads its install block with it.
B_INST="$ROOT/docs/install/README.md"
before "adhoc22 install page: command before the plugin path" "$B_INST" 'bootstrap\.sh \| sh' '/plugin marketplace add'
before "adhoc22 install page: plugin path before existing-repo update" "$B_INST" '/plugin marketplace add' '^## Update an existing repo'
grep_case "adhoc22 install page does not claim a Cursor listing" "$B_INST" 'not yet verified'
before "adhoc22 README install block leads with the command" "$ROOT/README.md" 'bootstrap\.sh \| sh' '/plugin marketplace add'
grep_case "adhoc22 README marks the sha256 as a release step" "$ROOT/README.md" 'RELEASE STEP.*sha256'
grep_case "adhoc22 CHANGELOG has an Unreleased entry" "$ROOT/docs/upgrade-guide.md" '^## Unreleased'
