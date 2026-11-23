// Worked example: the EXAMPLE epic (company SSO login) after its design was approved.
// Build: node core/.claude/skills/scope-page/build.mjs docs/epics/EXAMPLE/design/_build/content.mjs
// The app does not exist, so every screen is drawn HTML and says so. All data is invented.

export const meta = {
  title: 'Company SSO Login',
  product: 'Example app · Company SSO login',
  heading: 'Issuer admins sign in with their company Google account.',
  intro: 'Worked example of the v0.13 flow: the flows were approved first, then the design, then the plan. Pick a flow and step through it; the Build tab shows which slice builds each step and the checklist the slice threads tick.',
  byline: 'Worked example · EXAMPLE · design approved 2026-10-30 · invented data',
  codeRead: 'main 4f2c9e1 (invented)',
  scopeMarkdown: '../design.md',
};

export const images = {};

export const css = `
.dw{padding:24px;font-size:14px;background:var(--surface)}.dw h4{margin:0 0 12px;color:var(--text-heading)}
.dw .form{max-width:340px;margin:0 auto;display:grid;gap:10px}.dw .in{border:1px solid var(--border-strong);border-radius:var(--radius-md);padding:9px 12px;color:var(--text-muted)}
.dw .btn{border-radius:var(--radius-pill);padding:9px 14px;text-align:center;font-weight:600;background:var(--action);color:#fff}
.dw .btn.alt{background:var(--surface);color:var(--text-heading);border:1px solid var(--border-strong)}
.dw .new{outline:2px dashed var(--action);outline-offset:3px;border-radius:var(--radius-md)}
.dw .msg{border:1px solid var(--warning-border);background:var(--warning-surface);color:var(--warning-text);border-radius:var(--radius-lg);padding:12px 14px}
.dw .ok{border:1px solid var(--success-border);background:var(--success-surface);color:var(--success-text);border-radius:var(--radius-lg);padding:12px 14px}
.dw .acct{border:1px solid var(--border);border-radius:var(--radius-lg);padding:10px 12px}.dw .muted{color:var(--text-muted)}
`;

const DRAWN = 'Drawn for this example, not a capture. Dashed outline = new.';
const login = (extra = '') => `<div class="dw"><div class="form"><h4>Sign in</h4>${extra}<div class="in">Email</div><div class="in">Password</div><div class="btn">Sign in</div></div></div>`;

export const screens = {
  'login-today': { kind: 'html', status: 'today', title: 'Login page today (drawn)', legend: 'Drawn from the current page: email and password only.', html: login() },
  'login-sso': { kind: 'html', status: 'proposed', title: 'Login with the SSO button (drawn)', legend: DRAWN, html: login('<div class="btn alt new">Sign in with Google</div><p class="muted" style="text-align:center;margin:0">or</p>') },
  'google-pick': { kind: 'html', status: 'proposed', title: 'Google account picker (drawn)', legend: 'Drawn stand-in for the IdP screen; the IdP owns it.', html: '<div class="dw"><div class="form"><h4>Choose an account</h4><div class="acct">ana@acme.com<br><span class="muted">Acme Corp</span></div></div></div>' },
  'dashboard': { kind: 'html', status: 'proposed', title: 'Dashboard after the callback (drawn)', legend: DRAWN, html: '<div class="dw"><h4>Dashboard</h4><div class="ok new">Signed in as ana@acme.com through Google.</div></div>' },
  'refused': { kind: 'html', status: 'proposed', title: 'Refusal page (drawn)', legend: DRAWN, html: '<div class="dw"><div class="form"><h4>Sign in</h4><div class="msg new">Your company is not enabled for SSO (code SSO-02). <u>Contact support</u></div></div></div>' },
  'revoke-dia': { kind: 'html', status: 'proposed', title: 'How a revocation reaches the app (diagram)', html: '<div class="dw"><p><b>IT revokes the Google account</b> → every 15 minutes the sweep asks the IdP about each linked account → the identity is marked revoked → the next request is sent to login.</p></div>' },
  'revoked': { kind: 'html', status: 'proposed', title: 'Login with the revoked banner (drawn)', legend: DRAWN, html: login('<div class="msg new">Your company revoked this account. Ask your IT contact.</div>') },
};

export const stories = [
  {
    id: 'sso-login', theme: 'Sign in', actor: 'Issuer admin', title: 'Sign in with my company Google account',
    goal: 'Get to the dashboard without a separate password.',
    steps: [
      { screen: 'login-today', action: 'Today: email and password', text: 'Every issuer admin keeps a password for this app.' },
      { screen: 'login-sso', action: 'Click "Sign in with Google"', text: 'A new button above the form starts the SSO flow. Staff accounts do not see it.' },
      { screen: 'google-pick', action: 'Pick the company account', text: 'Google asks which account to use and sends the user back to the callback.' },
      { screen: 'dashboard', action: 'Land on the dashboard', text: 'The callback resolves the verified company by email domain and creates the session.' },
    ],
    outcome: 'Ana reaches the dashboard with her Google account and no password.',
    related: ['sso-refused'], questions: [],
  },
  {
    id: 'sso-refused', theme: 'Sign in', actor: 'Issuer admin, unverified company', title: 'Be refused clearly when my company is not enabled',
    goal: 'Know what went wrong and who to ask.',
    steps: [
      { screen: 'login-sso', action: 'Click "Sign in with Google"', text: 'Same button, same flow.' },
      { screen: 'refused', action: 'See the refusal', text: 'The company is not verified, so the callback returns 403 with code SSO-02 and no session.' },
    ],
    outcome: 'Bo sees code SSO-02 and a support link, and stays logged out.',
    related: ['sso-login'], questions: [],
  },
  {
    id: 'sso-revoked', theme: 'Access', actor: 'Company IT contact', title: 'Lock out a leaver by revoking their Google account',
    goal: 'A revoked account loses access without anyone touching this app.',
    steps: [
      { screen: 'revoke-dia', action: 'Revoke the account at Google', text: 'The sweep runs every 15 minutes and marks revoked identities.' },
      { screen: 'revoked', action: 'The next request goes to login', text: 'The leaver is redirected to /login?reason=revoked and sees why.' },
    ],
    outcome: 'Within one sweep, the leaver is out and told why.',
    related: [], questions: [],
  },
];

export const plan = {
  slices: [
    { id: '1', layer: 'db', name: 'SSO company settings and identity link', flows: { 'sso-login': [4], 'sso-refused': [2], 'sso-revoked': [2] }, hours: 4 },
    { id: '2', layer: 'be', name: 'OIDC callback and revocation sweep', flows: { 'sso-login': [2, 3, 4], 'sso-refused': [2], 'sso-revoked': [1, 2] }, hours: 8 },
    { id: '3', layer: 'fe', name: 'SSO button, refusal page, revoked banner', flows: { 'sso-login': [2], 'sso-refused': [2], 'sso-revoked': [2] }, hours: 5 },
  ],
};

export const build = {
  intro: 'Three slices, one layer each, from the approved design (design.md). Effort and order come from its Slices table.',
  efforts: [{ item: 'EXAMPLE', rows: [['db', 'SSO company settings and identity link', 4], ['be', 'OIDC callback and revocation sweep', 8], ['fe', 'SSO button, refusal page, revoked banner', 5]] }],
  effortNote: 'Invented figures for the example.',
  order: ['db, then be (stacked), then fe (stacked), as the slices table says.'],
};

export const decisions = [
  ['Sweep interval', '15 minutes.', 'The reviewer, round 1, 2026-10-30'],
  ['Last-resort try in the sweep', 'Approved: one IdP timeout must not stop the sweep for every other company.', 'The reviewer, round 1, 2026-10-30'],
  ['Design', 'Approved; plan defined.', 'The reviewer, round 1, 2026-10-30'],
];
export const assumptions = ['Staff accounts keep passwords.', 'Google Workspace is the only IdP for now.'];
export const questions = [];
