# EXAMPLE — design

- Scope: `sso-scope.md`, approved 2026-10-29
- Author: consolidated from `designs/claude.md`, `designs/codex.md`, `designs/cursor.md`
- Code read at: main 4f2c9e1

> Worked example with invented code and figures. It shows what `architect` hands back and what the
> reviewer approves; nothing here describes a real project.

## Round 1 decisions (the reviewer, 2026-10-30)

| # | Question | Answer |
| --- | --- | --- |
| 1 | Sweep interval | 15 minutes, as proposed. |
| 2 | The one last-resort try in the sweep | Approved: one IdP timeout must not stop the sweep for every other company. |
| — | Design | Approved. Define the plan. |

## Interrogation

- Checked: 23 claims against main 4f2c9e1.
- Failed and fixed (3):
  - `Company` already has `domain`; two designs added a second `sso_domain` field; the design reuses `domain`. Run: `grep -n "domain" apps/accounts/models/company.py`.
  - The callback looked up the company per request with two queries; one `select_related` makes it one. Run: the callback at 1 and 50 companies, 3 queries both times.
  - The sweep loaded every identity into a list; it now iterates in batches of 500. Run: memory trace at 10 000 identities, peak 4 MB instead of 61 MB.
- Could not check (1): the refusal page's swap target; the template is built in slice 3, and `test_S2_refusal_page_shows_code` will check it.
- Dropped (2): "cache the IdP discovery document" (no run shows a slow path); "rate-limit the callback" (already limited by the login rate limit, run: 11th request in a minute returns 429).

## Consolidation

| Section | Base | Grafted |
| --- | --- | --- |
| Screens | Claude | Codex: the refusal reuses the existing error partial |
| Backend | Codex | Cursor: `revoked_at` is set only by the sweep, never by a request |
| Security | Cursor | Claude: the button is hidden for staff accounts, which keep passwords |
| Complexity | Codex | Claude: the sweep iterates in batches instead of loading all identities |
| Slices | Codex (3 slices, one layer each) | none |

## Disagreements

| Element | What each said | Pick | Reason |
| --- | --- | --- | --- |
| Where the IdP call lives | Claude: inside the view. Codex and Cursor: a client module | Client module | the map row "Outside client" puts every outside call in `clients/`; the sweep reuses it |

## Screens

- **Login** (`accounts/login.html`): "Sign in with Google" above the password form, hidden for staff. States: default; loading while redirecting.
- **Refusal** (`accounts/sso_refused.html`): `Your company is not enabled for SSO (code SSO-02)` and a support link. Reuses the error partial.
- **Revoked banner** (`components/accounts/_revoked_banner.html`): on `/login?reason=revoked`.

## Backend

- `SsoIdentity` (`apps/accounts/models/sso_identity.py`, Model): user, `sub`, `revoked_at`.
- `company_for_email(email) -> Company | None` (`apps/accounts/methods/sso_methods.py`, Business rule).
- `SsoCallbackView` (`apps/accounts/views/sso_callback_views.py`, API view): exchanges the code, resolves the company, refuses with 403 `SSO-02`, creates the session.
- `exchange_code(code) -> Claims` (`apps/accounts/clients/oidc_client.py`, Outside client).
- `sweep_revoked_sso` (`apps/accounts/tasks/sso_tasks.py`, Task): every 15 minutes.
- Migration: `SsoIdentity`; `Company.sso_verified`.

## Security

| Endpoint or field | Read | Write | Validation | Must not leak |
| --- | --- | --- | --- | --- |
| `GET /auth/sso/callback` | anyone with a valid `state` | creates a session | `state` matches the session; `iss`, `aud`, `exp` checked | whether a domain exists in our records |
| `SsoIdentity.revoked_at` | the auth middleware | the sweep only | — | — |

## Complexity

| Piece | n is | Time | DB queries | Memory | Outside calls | Checked by |
| --- | --- | --- | --- | --- | --- | --- |
| `SsoCallbackView.get` | companies | O(1) | 3, constant in n | one row | 1 token exchange | `test_S1_callback_query_count_constant` at 1 and 50 companies |
| `sweep_revoked_sso` | linked identities | O(n) | 1 per batch of 500 + 1 update per batch | one batch | 1 per identity | `test_S3_sweep_queries_grow_per_batch` at 10 and 1 000 identities |

## Last-resort error handling

| File | Function | Why no handler covers it |
| --- | --- | --- |
| `apps/accounts/tasks/sso_tasks.py` | `sweep_revoked_sso` | one IdP timeout must not stop the sweep for every other company; the task logs it and moves on |

## Slices

| # | Layer | Name | Flow steps it builds | Placement rows | Hours |
| --- | --- | --- | --- | --- | --- |
| 1 | db | SSO company settings and identity link | sso-login 4; sso-refused 2; sso-revoked 2 | 3 | 4 |
| 2 | be | OIDC callback and revocation sweep | sso-login 2–4; sso-refused 2; sso-revoked 1–2 | 3 | 8 |
| 3 | fe | SSO button, refusal page, revoked banner | sso-login 2; sso-refused 2; sso-revoked 2 | 3 | 5 |

## Open questions

None left; round 1 answered them.
