---
description: "Optional: scaffold an orchestrator folder and print the two T3 schedule prompts for you to create by hand. Asks three questions, shows the plan, writes only after your yes, never overwrites."
argument-hint: "[orchestrator folder path]"
---

# /orchestrator-init

Follow the `orchestrator-init` skill step by step. An argument is the answer to its first question (the orchestrator folder path); still ask the other two.

The skill never creates scheduled tasks and never writes to a tracker, chat tool or calendar. It prints the two schedule prompts; you create them in T3.
