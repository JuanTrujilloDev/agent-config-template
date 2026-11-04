## Config review (bi-weekly)

Name: `Config review (bi-weekly)` · every 14 days · bound to the orchestrator thread

```text
Config review (bi-weekly). Work in {{orchestrator_dir}} and follow its AGENTS.md.
1. Review this orchestrator: AGENTS.md, learnings/, flakes/, and the runs recorded in state/*.yaml since the last file in plans/config-reviews/. Note repeated failures, stalled runs, model fallbacks and rules nobody followed.
2. Models: compare the model routing table in AGENTS.md with the live catalog from orchestrator_capabilities and a web check (cite each source). Flag retired models and better candidates per tier.
3. Vendored skills: for each row in skills/VENDORED.md, diff the pinned copy against upstream (git ls-remote plus a shallow clone in an isolated download folder). Install nothing.
4. Project repos: read the agent config of each repo listed in AGENTS.md (AGENTS.md, CLAUDE.md, .claude/, .cursor/, .codex/) and note drift from this orchestrator's rules.
5. Write plans/config-reviews/<YYYY-MM-DD>.md: findings, then a numbered proposal, one change per number with the file it touches and the reason.
Apply nothing. Write nothing to {{tracker}}, chat tools or calendars. Reply with the file path and the numbered list; {{approver}} picks the numbers.
```
