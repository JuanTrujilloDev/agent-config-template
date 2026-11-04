# outbox — from the orchestrator

One file per request to a bot or a person, `YYYY-MM-DDTHHMM-<to>-<kind>.md`:

```
---
to: <recipient>
kind: spin-up | spin-down | message | status
task: ABC-0000
approved_by: {{approver}}
---
body
```

No `approved_by: {{approver}}`, no action. Handled files move to `done/`.
