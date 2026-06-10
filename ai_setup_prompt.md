# Claude setup prompt — verbatim

The README's "Per-project: tell Claude" section is the casual version. This is the precise version, useful if you want to script the setup or feed it into an agent.

## The prompt

```
Set up Claude Code config from the template at <ABSOLUTE PATH TO TEMPLATE REPO>.

1. Inspect the project I'm currently in.
   Read package.json, pyproject.toml, Cargo.toml, go.mod, Gemfile,
   requirements.txt, manage.py, top-level README.md, and the source layout.
   From those, infer answers for every variable defined in
   <TEMPLATE PATH>/template.config.yaml — project_type (web-app, api-service,
   mobile-app, desktop-app, game, library-cli, data-ml, other), language,
   framework, src_dir, test/lint/format/build commands, default branch,
   has_frontend (web only), has_background_jobs, has_e2e, ticket_tracker, etc.

2. Draft an answers.env at the project root. One KEY=VALUE per line.
   For each value, classify your confidence:
     - HIGH    — derived directly from a config file (cite the file).
     - LOW     — best guess; show the alternative.
     - UNKNOWN — left blank, with a `# TODO: <what's missing>` line above.

3. Show me the answers.env grouped by confidence level. WAIT for my approval
   or edits.

4. After I approve, run:
     bash <TEMPLATE PATH>/setup.sh --target . --answers ./answers.env

5. Add to .gitignore (creating it if missing):
     .claude/settings.local.json
     .claude/mcp.json
     answers.env

6. Tell me Claude Code needs to be restarted to pick up the new hooks
   and slash commands.

Do not modify anything else. Do not invent placeholder values where the
project doesn't tell you. If a value is genuinely ambiguous, ask one
targeted clarifying question and stop.
```

## Why it's shaped this way

- **Confidence labels** keep you in the loop on real ambiguities. A value Claude gets wrong silently costs more than one it asks about.
- **Draft → approve → render** prevents Claude from writing 30+ files only to discover the test command was wrong.
- **Explicit `.gitignore` step** stops the local settings file and any MCP secrets from leaking.
- **"Do not invent values"** is the most important instruction — it's how you tell the difference between an inference and a hallucination.

## Variant: I trust Claude, just go

If you want the no-approval-gate version (use it on throwaway projects only):

```
Set up Claude Code config from <TEMPLATE PATH>. Read this project, infer
all answers from config files and source layout, write answers.env, run
setup.sh, update .gitignore. Don't ask me anything unless something is
genuinely ambiguous.
```

Faster, but you trade away the chance to catch a wrong inference before 30+ files are written.
