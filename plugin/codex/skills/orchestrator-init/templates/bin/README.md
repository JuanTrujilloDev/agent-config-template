# bin

Scripts that keep `state/*.yaml`, the rendered `PROGRESS.md` files and the {{tracker}} comments in step, and that gate local dispatches on this machine's resources. All are Python with PEP 723 inline metadata and run through `uv`: invoke them directly (`bin/state.py ...`) or as `uv run --script bin/state.py ...`. Each takes `--root` (the folder that holds this orchestrator folder, auto-detected from the script's location) and `--help`. Standard library plus PyYAML only. Shared helpers live in `_common.py`.

| Script | Purpose |
| --- | --- |
| `render-progress.py` | Generates `PROGRESS.md` (full) and `PROGRESS-digest.md` (short, for delegates) from the state files. `--check` exits 1 when they are stale. |
| `state.py` | Edits a state file: `run-add`, `run-set`, `set`, `task-set`, `check-tick`, `check-reset`, `validate`. Validates enums, sets `updated`, re-renders unless `--no-render`. Comments in the YAML are not preserved. |
| `tracker-comment.py` | Renders the {{tracker}} comment (Markdown or `--html`) from the state file. It never calls {{tracker}}; whoever posts it does so after {{approver}}'s yes. |
| `archive-evidence.py` | Moves a run's evidence folder to `~/orchestrator-artifacts/<task>/<run-id>/`, tars it, prints the SHA-256, writes `manifest.json`, and with `--state` records path and hash on the run. Never deletes; refuses git-tracked files unless `--allow-tracked`. |
| `resource-check.py` | Pre-dispatch check (macOS and Linux): free memory, load, heavy processes, local runs recorded as running. `--kind remote` always fits; `--kind local --need MB --project key` applies the policy (default 2500 MB free, no second local run for the same project, at most 2 local runs machine-wide). Exit 0 dispatch, 1 wait, 2 could not measure. |

## Standard sequence for one delegation

```sh
B=bin
$B/resource-check.py --kind local --need 2500 --project <project>        # exit 0 before a local dispatch
# dispatch with delegate_task / t3_thread_launch, then:
$B/state.py run-add --task ABC-123 --id abc-123-api-r1 --kind execute \
  --provider <provider> --model <model> --effort medium --task-id "<T3 task id>"
# on completion:
$B/state.py run-set --task ABC-123 --id abc-123-api-r1 state=completed result=delivered \
  report=plans/ABC-123/abc-123-api-r1.md finished=now
$B/archive-evidence.py --task ABC-123 --run abc-123-api-r1 --state /path/to/evidence-dir
$B/state.py set --task ABC-123 current.next_step="..." current.summary="..."
$B/tracker-comment.py --task ABC-123 --html   # post after {{approver}}'s yes, then: state.py set tracker.last_comment_id=<id>
$B/render-progress.py --check                                           # 0 when PROGRESS.md matches the state
```

Scheduled progress check: `state.py check-tick --task X` after a verified no-change check, `state.py check-reset --task X --reason "..."` when something moved.
