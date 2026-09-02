## Security review: mini-feature-grammar

- Input is local JSON/Markdown selected by repository glob or an explicit CLI
  path; parsing uses `json` and bounded regexes, with no evaluation or shelling.
- The validator is read-only. It reports paths and structural errors, not file
  contents or secrets.
- Malformed nested types return a controlled exit 1 instead of a traceback.

**Verdict:** approved; no blocker.
