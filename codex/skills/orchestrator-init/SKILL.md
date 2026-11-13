---
name: orchestrator-init
description: "Optional. Scaffold an orchestrator folder (bin/ scripts, state schema, plan template, inbox/outbox, AGENTS.md skeleton) and print the two T3 schedule prompts for the user to create by hand. Use when the user asks to set up, init or bootstrap an orchestrator. Never creates scheduled tasks and never writes to a tracker, chat tool or calendar."
---

# Orchestrator init

Optional. Renders the file skeleton of an orchestrator: a folder that plans work, dispatches T3 threads, records runs in YAML state files and reports progress. The project's own SDD workflow does not need it.

## What it creates

| Path | What it is |
| --- | --- |
| `AGENTS.md` | Orchestration rules skeleton: people, tracker projects, T3 project ids, cycle, threads, an empty model routing table (Trivial, Simple, Medium, Complex), progress check, config review. `<placeholders>` stay for the user to fill. |
| `bin/` | `state.py`, `render-progress.py`, `resource-check.py`, `tracker-comment.py`, `archive-evidence.py`, `_common.py`, `README.md`. Python with PEP 723 metadata, run through `uv` (PyYAML). Paths resolve from the scripts' own folder. |
| `state/SCHEMA.md`, `state/EXAMPLE.yaml` | Format of `state/<TASK-ID>.yaml`, and a fictional example to copy for each new task. |
| `plans/TEMPLATE.md` | Plan shape: current block, security invariants, epics and tasks, parallelism, review log. |
| `plans/launch-standing-orders.md` | The standing orders pasted at the end of every task-thread launch: `/slice` first, tests red then stop, no merge, push pending approval. |
| `inbox/`, `outbox/` | `README.md` with the request format, plus `done/`. |
| `learnings/`, `flakes/` | Empty, with `.gitkeep`. |
| `skills/VENDORED.md` | Header of the pinned-skills table. |
| `schedules/` | The two schedule prompts, kept with the folder so they can be re-created. |

## Steps

1. **Ask three questions** in one message and wait for the answers:
   1. Orchestrator folder path (default `./orchestrator`; an argument to `/orchestrator-init` answers this one).
   2. Project tracker name (for example Plane, Jira, Linear, GitHub Issues).
   3. Approver name: the person who approves plans, thread launches and pushes.
2. **Plan.** Run the renderer from this skill's folder, without `--write`:

   ```sh
   python3 -I <this skill's folder>/render.py --target <path> --tracker "<tracker>" --approver "<approver>"
   ```

   Show its output as it is: one line per file, `create`, `skip` or `conflict`. An existing file is always `skip`; the renderer never overwrites. A `conflict` (a file where a folder is needed) exits 2: tell the user which path to move, and do not ask to write.
3. **Confirm.** Ask: "Create these files? (yes/no)". Anything but a clear yes: stop, nothing is written.
4. **Write.** Run the same command with `--write`.
5. **Print the schedule prompts.** The renderer ends by printing `Orchestrator progress check` (every 45 min) and `Config review (bi-weekly)` (every 14 days). Repeat both blocks verbatim in your reply and tell the user to create each one by hand with T3 `schedule_task`, bound to the orchestrator thread, then record the schedule ids in `AGENTS.md`.
6. **Next steps** for the user, one line each: fill the `<placeholders>` in `AGENTS.md`; install `uv` if missing; `git init` the folder if it should be versioned.

If the renderer rejects a name, ask again for that answer only.

## Do not

- Call `schedule_task` or any other scheduler. The user creates both tasks.
- Write to a tracker, Slack, Teams, email or a calendar.
- Overwrite, move or delete an existing file. Re-running only adds what is missing.
- Copy anything from `~/.config` or put secrets, tokens or webhook URLs in any file.
- Commit or push.
