# Orchestrator state files

One YAML file per {{tracker}} task at `state/<TASK-ID>.yaml`. These files are the source of truth for `PROGRESS.md` and `PROGRESS-digest.md`, which `bin/render-progress.py` generates. Edit the YAML with `bin/state.py` (preferred) or by hand, then re-render. The tools skip this file and any `EXAMPLE.yaml`.

## Top level

| Field | Required | Meaning |
| --- | --- | --- |
| `task` | yes | {{tracker}} identifier, e.g. `ABC-123`. Also the file name. |
| `title` | yes | Card title. |
| `project` | yes | Key into `learnings/<project>.md` and `flakes/<project>.md`. |
| `repo` | no | Absolute path of the project checkout. Present means runs may be local workloads (see `resource-check.py`). |
| `tracker` | yes | {{tracker}} coordinates, below. |
| `plan` | yes | Path of the plan file, e.g. `plans/ABC-123/plan.md`. |
| `status` | yes | `draft`, `approved`, `executing`, `reviewing`, `done`, `paused`, `cancelled`. |
| `updated` | yes | ISO-8601 local time with offset. The tools set it on every change. |
| `unchanged_checks` | yes | Consecutive scheduled checks with no substantive change. `state.py check-tick` / `check-reset`. |
| `orchestrator_thread` | no | Name of the T3 thread that owns the task. |
| `current` | yes | The live block, below. |
| `epics` | no | Epics and tasks, below. |
| `runs` | no | Append-only ledger of delegations, newest last, below. |
| `sync_notes` | no | Dated strings. Mismatches with {{tracker}} that could not be fixed, failed syncs, counter resets. |

## `tracker`

| Field | Meaning |
| --- | --- |
| `workspace` | Workspace slug. |
| `project_id` | {{tracker}} project id (listed in `AGENTS.md`). |
| `work_item_id` | Card id. |
| `state` | Column name as recorded by the orchestrator: `Backlog`, `ToDo`, `In progress`, `In review`, `Done`, `Closed`, `Cancelled`, `Archive`. Edit the `tracker.state` list in `bin/_common.py` to match your board. Only {{approver}} moves a card to a closed column. `state.py set` also accepts the legacy spelling `plane.<field>` for `tracker.<field>`. |
| `last_comment_id` | Last comment posted (rendered by `tracker-comment.py`). |

## `current`

| Field | Meaning |
| --- | --- |
| `summary` | One paragraph of plain prose describing what is true now. Replaced, not appended. History lives in `runs` and in the plan's history file. |
| `next_step` | The single next ready step, or `none`. |
| `blockers` | List of strings. |
| `approvals_pending` | List of strings: decisions {{approver}} must make. The progress check reports these verbatim. |
| `model_switches` | List of strings recording fallback routing, e.g. `<date> <model> unavailable, used <fallback> for planning`. |

## `epics[]`

| Field | Meaning |
| --- | --- |
| `id` | String, e.g. `"3"` or `"3b"`. |
| `name` | Epic name. |
| `state` | `queued`, `executing`, `in review`, `done`, `cancelled`. |
| `tasks[]` | Tasks, below. |

### `epics[].tasks[]`

| Field | Meaning |
| --- | --- |
| `id` | String, e.g. `"3.4"`. |
| `name` | Task name. |
| `owner` | Owner model and effort as in the plan. |
| `state` | `queued`, `executing`, `in review`, `blocked`, `done`, `cancelled`. |
| `branch`, `worktree` | Where the work lives when running. |
| `thread` | T3 session name (`ABC-123 / 3.4`) or task id. |
| `notes` | Short free text. |

## `runs[]`

Append-only. One entry per delegation, preflight, review, fix round or sync. Never rewrite an entry's `id`.

| Field | Meaning |
| --- | --- |
| `id` | Run id, e.g. `abc-123-34-api-r1`. Unique within the file. |
| `kind` | `execute`, `review`, `fix`, `preflight`, `research`, `design`, `learnings`, `closeout`, `publication`, `sync`, `diagnosis`, `tests` (a slice's tests-first round: tests written, pushed red, stopped for {{approver}}). |
| `provider`, `model`, `effort` | As resolved from `orchestrator_capabilities` at dispatch. |
| `skills` | List of skill names the brief required. |
| `state` | `queued`, `running`, `completed`, `failed`, `cancelled`, `blocked`. |
| `local` | Optional boolean, default true. `false` marks a run that only reads code and calls a hosted model, so `resource-check.py` does not count it as a local workload. |
| `task_id` | T3 delegated task id. |
| `started`, `finished` | ISO-8601 local time with offset. `state.py run-set` fills `finished` when a run reaches a terminal state. |
| `range` | Git range reviewed or produced, `base..head`. |
| `result` | `clean`, `changes_requested`, `blocked`, `inconclusive`, `delivered`, `n/a`. |
| `report` | Path of the report. |
| `evidence` | `path` (artifact store folder), `sha256` (of its tar), optional `tar`. Filled by `archive-evidence.py --state`. |
| `notes` | Short free text, for example test counts with provenance. |

## Rules the tools enforce

- Enum values above are validated on every write; an invalid value aborts the write.
- Duplicate run ids are rejected.
- Rendering is deterministic: the same state files always produce the same `PROGRESS.md`, so `render-progress.py --check` can run in a pre-commit step.
