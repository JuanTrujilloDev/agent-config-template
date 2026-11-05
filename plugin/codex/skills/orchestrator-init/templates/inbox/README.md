# inbox — to the orchestrator

One file per request from a bot, a person or a task thread, `YYYY-MM-DDTHHMM-<from>-<kind>.md`:

```
---
from: <sender>
kind: spin-up | spin-down | message | status
task: ABC-0000
approved_by: {{approver}}
---
body
```

No `approved_by: {{approver}}`, no action: the orchestrator reads the file and asks for approval in its own thread. Handled files move to `done/`. A new file here counts as a change for the progress check.
