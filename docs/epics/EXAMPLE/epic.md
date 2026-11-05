<!-- source=local; docs/epics/EXAMPLE/ is the source of truth; edit here, then run validate-epics.py -->
# EXAMPLE — Company SSO login

## Request
"Let issuer admins log in with their company Google Workspace instead of a password." (ask, 2026-10-28)

## Description
Issuer admins of a company with a verified domain authenticate through OIDC; passwords stay for everyone else. Revocation at the IdP logs the user out within one sweep.

## Capability groups
| Group | Tracker | Stories |
| --- | --- | --- |
| login | — | S1, S2 |
| revocation | — | S3 |

## User Stories
### login
- **S1** As an issuer admin, I want to sign in with my company Google account so that I do not keep a separate password.
- **S2** As an issuer admin with an unverified domain, I want a clear refusal so that I know to contact support.
### revocation
- **S3** As a company IT contact, I want a revoked Google account to lose access so that leavers are locked out.

## Acceptance Criteria
- **S1** A user of a verified domain lands on `/dashboard` after the IdP callback; no password form is shown.
- **S2** A user of an unverified domain sees `Your company is not enabled for SSO (code SSO-02)` and stays logged out.
- **S3** After the IdP reports the account revoked, the next request returns 302 to `/login?reason=revoked`.

## Test Scenarios
- **TS1** Given company `acme.com` is verified and `ana@acme.com` has no session, When the IdP callback returns `sub=ana-1`, Then the response is 302 to `/dashboard` and a session exists for `ana@acme.com`.
- **TS2** Given company `beta.io` is not verified, When `bo@beta.io` completes the callback, Then the response is 403 with body containing `SSO-02` and no session exists.
- **TS3** Given `ana@acme.com` has a session, When the revocation sweep finds `sub=ana-1` revoked, Then her next request is 302 to `/login?reason=revoked`.

## Technical tasks
| # | Layer | Name | Stories | Hours |
| --- | --- | --- | --- | --- |
| 1 | db | SSO company settings and identity link (models, serializers) | S1, S2, S3 | 4 |
| 2 | be | OIDC callback and revocation sweep (views, tasks) | S1, S2, S3 | 8 |
| 3 | fe | SSO button, refusal page, revoked banner | S1, S2, S3 | 5 |

## Estimate
17 h
