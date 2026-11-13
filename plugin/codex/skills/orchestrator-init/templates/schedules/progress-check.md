## Orchestrator progress check

Name: `Orchestrator progress check` · every 45 min · bound to the orchestrator thread

```text
Orchestrator progress check. Work in {{orchestrator_dir}} and follow its AGENTS.md. Read PROGRESS-digest.md for status, never whole state files.
1. Inbox: read new files in inbox/. Act only on files with approved_by: {{approver}}; move handled files to inbox/done/.
2. Runs: for every run recorded as running in state/*.yaml, check its delegated task or thread; also read every task thread past its last recorded run (t3_thread_read) and record {{approver}}'s own rounds there as runs. Record each finished one with bin/state.py run-set (state, result, report, finished=now) and move its evidence out with bin/archive-evidence.py.
3. Dispatch: start only the next ready step of a plan {{approver}} approved, after bin/resource-check.py says it fits for local work. Never select new tasks, never start unapproved work, never review a child's work in this turn.
4. Counters: bin/state.py check-tick for a task with no substantive change, check-reset with the reason when something moved. Paused tasks are not ticked.
5. Render: bin/render-progress.py, then bin/render-progress.py --check must exit 0.
6. {{tracker}}: draft a comment with bin/tracker-comment.py only when a task is delivered or done, an epic closes, or something needs {{approver}}. Post nothing without {{approver}}'s explicit yes.
7. Reply with one block per active task and nothing more:
   <project> <task id> — epics: E1 done | E2 current (2 of 5 done) | E3 waiting
   Needs you: <one decision, with options and a recommendation> | nothing
   List every pending push approval.
If every task has gone three checks without a change, or no approved step can proceed, say so and disable this schedule. Commit changes to state/, plans/ and learnings/ in this folder; never push.
```
