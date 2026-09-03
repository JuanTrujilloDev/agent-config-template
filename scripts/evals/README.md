# Model behavior evaluations

Validation is local, deterministic, and makes no model calls:

```bash
python3 scripts/evals/run.py validate
python3 scripts/evals/run.py list
```

Preview or explicitly run one host:

```bash
python3 scripts/evals/run.py run --host cursor --case pattern-restraint
python3 scripts/evals/run.py run --host cursor --case pattern-restraint --run
```

Workspace cases additionally require `--allow-writes`. They run in a temporary
rendered project that is deleted afterward; the source repository is never the
host working directory. The host CLI still controls its own filesystem and
network permissions, so use an OS/container sandbox for untrusted case prompts.

Executable overrides for tests/custom installs are `EVAL_CLAUDE_BIN`,
`EVAL_CODEX_BIN`, `EVAL_CURSOR_BIN`, and `EVAL_GROK_BIN`. Optional model
overrides use `EVAL_<HOST>_MODEL`. Results contain status metadata only and
default to the gitignored `eval-results/results.json`.
