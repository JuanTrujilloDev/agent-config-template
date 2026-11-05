## Security review: schema-version-and-migration

- Input is local JSON selected by the repository glob or explicit paths;
  parsing uses `json`, with no evaluation, network access, or shell execution.
- Every target is parsed and planned before writes. Missing or unknown schema
  versions fail before mutation, preventing partial migrations.
- Replacement is atomic and preserves the original file mode. Temporary files
  stay beside their target and are cleaned on failure.
- Diagnostics expose paths and structural errors, not file contents or secrets.

**Verdict:** approved; no blocker.
