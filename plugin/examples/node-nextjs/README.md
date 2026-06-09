# node-nextjs example

Next.js 14 full-stack (App Router). Uses Linear for ticket tracking, Playwright for E2E. Layer split is OFF because Next.js conflates BE/FE in a single codebase — splitting PRs by API route vs. component is rarely worth the friction.

```bash
~/code/agent-config-template/setup.sh \
  --target . \
  --answers ./examples/node-nextjs/answers.env
```

If your team prefers stricter PR limits (Next.js components can balloon quickly), drop `max_files_per_pr` to `10`.
