// Example scope content. Copy this file to <design folder>/_build/content.mjs and replace it.
// `plan` is added only after the user approves the design (architect); until then leave it out.
// Image paths are relative to this file. Overlay x/y/w/h are in the capture's own pixels.

export const meta = {
  title: 'Example Scope',
  product: 'Example scope',
  heading: 'One change, walked through on the real screens.',
  intro: 'Pick a story and step through it. Dashed outlines mark what is new.',
  byline: 'Scope review · EXAMPLE-1 · Code read on staging <sha> · Round 1',
  codeRead: 'staging <sha>',
  scopeMarkdown: '../example-scope.md',
};

export const images = {
  fund: { path: 'capture.svg', w: 1280, h: 640, origin: 'Stand-in capture with invented data.' },
};

// Extra overlay classes for this scope only (use design-system tokens).
export const css = '.ov-cell{width:100%;padding-left:10px;font-size:14px}';

export const screens = {
  'fund-today': { img: 'fund', crop: [0, 0, 1280, 640], status: 'today', title: 'Fund page today' },
  'fund-proposed': {
    img: 'fund', crop: [0, 0, 1280, 640], status: 'proposed', title: 'Fund page with an export button',
    overlays: [
      { x: 1080, y: 50, w: 140, h: 40, isNew: true, html: '<span class="ov-btn">Export CSV</span>' },
    ],
  },
  'flow-diagram': {
    kind: 'html', status: 'proposed', title: 'How the export runs',
    html: '<div class="dia"><p><b>Click</b> → background job → <b>download link</b> in the notification.</p></div>',
  },
};

export const stories = [
  {
    id: 'export', theme: 'Fund page', actor: 'Issuer', title: 'Export my fund holdings',
    goal: 'Get the holdings into a spreadsheet without asking support.',
    steps: [
      { screen: 'fund-today', action: 'Today: open the fund page', text: 'There is no way to export the holdings.' },
      { screen: 'fund-proposed', action: 'Click Export CSV', text: 'A new button next to the title starts the export.' },
      { screen: 'flow-diagram', action: 'Download the file', text: 'The export runs in the background and the link arrives as a notification.' },
    ],
    outcome: 'The issuer has the holdings as CSV in two clicks.',
    related: [], questions: ['q-columns'],
  },
];

export const build = {
  intro: 'Where the change lands, effort and slices.',
  diagrams: ['flow-diagram'],
  codemap: [['Fund page', 'No export', 'apps/etf/views.py', 'Add an export action']],
  efforts: [{ item: 'Export CSV', rows: [['be', 'Export job and endpoint', 6], ['fe', 'Button and notification', 4], ['qa', 'Walk and review', 2]] }],
  effortNote: 'One developer, tests included.',
  slices: [['EXAMPLE-1', '1', 'be', 6], ['EXAMPLE-1', '2', 'fe', 4]],
  order: ['Backend slice, then the button.'],
  followups: [['XLSX format', 'Nobody asked yet', 3]],
};

// Defined once the design is approved. Each slice names the steps it builds, per flow (story id).
export const plan = {
  slices: [
    { id: '1', layer: 'be', name: 'Export job and endpoint', flows: { export: [2, 3] }, hours: 6 },
    { id: '2', layer: 'fe', name: 'Button and notification', flows: { export: [2, 3] }, hours: 4 },
  ],
};

export const decisions = [['Format', 'CSV only', 'Reviewer, 2026-11-20']];
export const assumptions = ['Columns match the holdings table.'];
export const questions = [
  { id: 'q-columns', who: 'Product', text: 'Should the export include cost basis?', why: 'It changes the job query.', def: 'No; add later.' },
];
