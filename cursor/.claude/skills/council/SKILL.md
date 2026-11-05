---
name: council
description: "Opt-in, single round: three delegates from three providers review a security or architecture slice read-only and score it. Only when the user asks for it or the launch draft names it. Adapted from tstack council."
argument-hint: "[what to review]"
disable-model-invocation: true
---

# council

Opt-in. Run only when the user says "council" or the task's launch draft names it and states its price; it costs three extra high-effort reviews. Meant for slices that touch security or architecture, after `code-review` and its fix round, so the delegates see the fixed code.

## Members

One strong model per provider, high reasoning effort: Claude Opus 5.5, GPT Astra or Sol, Grok 4.7, unless the user names others. In T3 Code, call `orchestrator_capabilities` once to resolve the models, then `delegate_task` once per member, in parallel. Elsewhere, use the host's sub-agent tool. If a member or provider is unavailable, report it; **never substitute** another model.

## Single round

Give each delegate the slice file, its stories, the diff command against the slice's base (`git diff <base>...HEAD`), and the `code-review` report. Their work is read-only. Ask each for findings ranked by severity and a score out of 10.

Collect the three answers once. Summarize the useful findings, where the delegates disagree, and the recommended next steps. There is no second round: fix what you agree with in one pass, and fight scope creep; a finding outside the slice's stories becomes a follow-up, not a change.

## Report

Put the results in the final reply:

```markdown
## Council review

| Delegate | Score |
| --- | --- |
| Claude Opus 5.5 | 8/10 |
| GPT Sol | 7/10 |
| Grok 4.7 | no score |
```

Write `no score` when a delegate gives none; never invent one. Edit an open PR's description with this section only after the user confirms; never post it as a comment.
