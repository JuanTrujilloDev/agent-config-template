# v0.10.0 MF1 model-eval-harness (@s1..@s8).
EVAL_RUN="$ROOT/scripts/evals/run.py"
EVAL_CATALOG="$ROOT/scripts/evals/cases.jsonl"
EVAL_TMP="$WORK/v010-evals"
mkdir -p "$EVAL_TMP/bin"

# @s1/@s2 — catalog validates and listing is inert.
python3 "$EVAL_RUN" validate --catalog "$EVAL_CATALOG" >"$EVAL_TMP/validate.out" 2>"$EVAL_TMP/validate.err"
check "v0.10.0 @s1 catalog validates" "0" "$?"
check "v0.10.0 @s1 six cases listed" "6" "$(python3 "$EVAL_RUN" list --catalog "$EVAL_CATALOG" | wc -l | tr -d ' ')"
for id in pattern-restraint pattern-force pattern-stuffing fix-needs-repro terse-review spec-feature-workflow; do
  grep_case "v0.10.0 @s1 catalog has $id" "$EVAL_CATALOG" "\"id\": *\"$id\""
done

cat >"$EVAL_TMP/bin/fake-host" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >>"$FAKE_ARGS_FILE"
printf '%s\n' "$PWD" >>"$FAKE_CWD_FILE"
case "${FAKE_MODE:-ok}" in
  auth) echo 'authentication required' >&2; exit 1 ;;
  fail) echo 'host failed' >&2; exit 9 ;;
  malformed) echo 'not json'; exit 0 ;;
  timeout) sleep 2; exit 0 ;;
esac
mkdir -p docs/specs/eval-smoke
printf 'spec\n' >docs/specs/eval-smoke/spec.md
printf 'contract\n' >docs/specs/eval-smoke/contract.md
printf 'feature\n' >eval-smoke.txt
if [ "${1:-}" = "exec" ]; then
  printf '%s\n' '{"type":"item.completed","item":{"type":"agent_message","text":"no pattern — single call site"}}'
  printf '%s\n' '{"type":"turn.completed","usage":{"input_tokens":1}}'
else
  printf '{"result":"no pattern — single call site"}\n'
fi
SH
chmod +x "$EVAL_TMP/bin/fake-host"
: >"$EVAL_TMP/args"
: >"$EVAL_TMP/cwds"

eval_env() {
  FAKE_ARGS_FILE="$EVAL_TMP/args" FAKE_CWD_FILE="$EVAL_TMP/cwds" \
  EVAL_CLAUDE_BIN="$EVAL_TMP/bin/fake-host" EVAL_CODEX_BIN="$EVAL_TMP/bin/fake-host" \
  EVAL_CURSOR_BIN="$EVAL_TMP/bin/fake-host" EVAL_GROK_BIN="$EVAL_TMP/bin/fake-host" \
  XAI_API_KEY='do-not-record-this' "$@"
}

# @s2/@s3 — plan calls nothing; four adapters use their documented entry points.
eval_env python3 "$EVAL_RUN" run --host claude --case pattern-restraint --catalog "$EVAL_CATALOG" >"$EVAL_TMP/plan"
check "v0.10.0 @s2 plan is inert" "0" "$(wc -l <"$EVAL_TMP/args" | tr -d ' ')"
for host in claude codex cursor grok; do
  eval_env python3 "$EVAL_RUN" run --host "$host" --case pattern-restraint --run \
    --catalog "$EVAL_CATALOG" --results "$EVAL_TMP/$host.json" >/dev/null
  check "v0.10.0 @s3 $host fake run passes" "0" "$?"
done
grep_case "v0.10.0 @s3 claude argv" "$EVAL_TMP/args" '^-p .*--output-format json'
grep_case "v0.10.0 @s3 codex argv" "$EVAL_TMP/args" '^exec .*--json.*--ephemeral'
grep_case "v0.10.0 @s3 cursor argv" "$EVAL_TMP/args" '^-p .*--output-format json'
grep_case "v0.10.0 @s3 grok argv" "$EVAL_TMP/args" '^--no-auto-update -p .*--output-format json'

# @s4/@s7 — skips/errors and deterministic rubric result.
EVAL_CLAUDE_BIN="$EVAL_TMP/missing" python3 "$EVAL_RUN" run --host claude --case pattern-restraint --run \
  --catalog "$EVAL_CATALOG" --results "$EVAL_TMP/missing.json" >/dev/null
check "v0.10.0 @s4 missing binary skips" "skip" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[0]["status"])' "$EVAL_TMP/missing.json")"
FAKE_MODE=auth eval_env python3 "$EVAL_RUN" run --host claude --case pattern-restraint --run \
  --catalog "$EVAL_CATALOG" --results "$EVAL_TMP/auth.json" >/dev/null
check "v0.10.0 @s4 auth failure skips" "skip" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[0]["status"])' "$EVAL_TMP/auth.json")"
FAKE_MODE=malformed eval_env python3 "$EVAL_RUN" run --host claude --case pattern-restraint --run \
  --catalog "$EVAL_CATALOG" --results "$EVAL_TMP/malformed.json" >/dev/null
check "v0.10.0 @s4 malformed output errors" "error" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[0]["status"])' "$EVAL_TMP/malformed.json")"
FAKE_MODE=timeout eval_env python3 "$EVAL_RUN" run --host claude --case pattern-restraint --run --timeout 1 \
  --catalog "$EVAL_CATALOG" --results "$EVAL_TMP/timeout.json" >/dev/null
check "v0.10.0 @s4 timeout errors" "error" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[0]["status"])' "$EVAL_TMP/timeout.json")"
grep_case "v0.10.0 @s7 result records pass" "$EVAL_TMP/claude.json" '"status": "pass"'
check "v0.10.0 @s8 secret omitted" "0" "$(grep -rl 'do-not-record-this' "$EVAL_TMP"/*.json 2>/dev/null | wc -l | tr -d ' ')"

# @s5/@s6 — write cases need both gates and always use disposable cwd.
eval_env python3 "$EVAL_RUN" run --host claude --case spec-feature-workflow --run \
  --catalog "$EVAL_CATALOG" --results "$EVAL_TMP/refused.json" >/dev/null 2>&1
check "v0.10.0 @s6 write case refuses one gate" "2" "$?"
eval_env python3 "$EVAL_RUN" run --host claude --case spec-feature-workflow --run --allow-writes \
  --catalog "$EVAL_CATALOG" --results "$EVAL_TMP/write.json" >/dev/null
check "v0.10.0 @s6 disposable write run passes" "0" "$?"
check "v0.10.0 @s6 source repo never host cwd" "0" "$(grep -cFx "$ROOT" "$EVAL_TMP/cwds" || true)"

# @s8 — live workflow is manual; ordinary CI validates only.
grep_case "v0.10.0 @s8 manual workflow" "$ROOT/.github/workflows/model-evals.yml" 'workflow_dispatch:'
grep_case "v0.10.0 @s8 ordinary CI validates" "$ROOT/.github/workflows/ci.yml" 'scripts/evals/run.py validate'
grep_case "v0.10.0 @s8 result dir ignored" "$ROOT/.gitignore" '^/eval-results/$'
