// Builds a self-contained scope walkthrough page from a content module.
// Usage: node .claude/skills/scope-page/build.mjs <path/to/_build/content.mjs> [outDir]
// outDir defaults to ../scope next to the content file's folder. Progress files are read from
// <content folder>/progress/*.json (one per slice, written by the slice's own thread).
import fs from 'fs';
import path from 'path';
import { fileURLToPath, pathToFileURL } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const contentFile = process.argv[2];
if (!contentFile) throw new Error('Usage: node .claude/skills/scope-page/build.mjs <content.mjs> [outDir]');

const CONTENT = path.resolve(contentFile);
const CONTENT_DIR = path.dirname(CONTENT);
const OUT = path.resolve(process.argv[3] || path.join(CONTENT_DIR, '../scope'));
const C = await import(pathToFileURL(CONTENT).href);
const MIME = { '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp', '.svg': 'image/svg+xml' };
const STATUS = { today: 'Today', approved: 'Approved design', proposed: 'Proposed' };

const images = {};
for (const [key, img] of Object.entries(C.images || {})) {
  const file = path.resolve(CONTENT_DIR, img.path);
  const mime = MIME[path.extname(file).toLowerCase()];
  if (!mime) throw new Error(`Unsupported image type: ${file}`);
  images[key] = { src: `data:${mime};base64,` + fs.readFileSync(file).toString('base64'), w: img.w, h: img.h, origin: img.origin };
}

// Fail at build time on a broken reference; the page would otherwise throw while rendering.
for (const [id, sc] of Object.entries(C.screens)) {
  if (!STATUS[sc.status]) throw new Error(`Screen ${id}: unknown status ${sc.status} (use ${Object.keys(STATUS).join(', ')})`);
  if (sc.kind === 'html') continue;
  if (!images[sc.img]) throw new Error(`Screen ${id}: missing image ${sc.img}`);
  if (!Array.isArray(sc.crop) || sc.crop.length !== 4) throw new Error(`Screen ${id}: crop must be [x, y, w, h]`);
}
for (const s of C.stories) {
  for (const st of s.steps) {
    if (!C.screens[st.screen]) throw new Error(`Story ${s.id}: missing screen ${st.screen}`);
  }
}
const qids = new Set((C.questions || []).map(q => q.id));
for (const s of C.stories) {
  for (const q of s.questions || []) {
    if (!qids.has(q)) throw new Error(`Story ${s.id}: missing question ${q}`);
  }
}
const storyIds = new Set(C.stories.map(s => s.id));
for (const s of C.stories) {
  for (const r of s.related || []) {
    if (!storyIds.has(r)) throw new Error(`Story ${s.id}: missing related story ${r}`);
  }
}
for (const id of (C.build || {}).diagrams || []) {
  if (C.screens[id]?.kind !== 'html') throw new Error(`Build: diagram ${id} is not an html screen`);
}

// The plan exists once the design is approved: slices, each naming the flow steps it builds.
const SLICE_STATUS = ['todo', 'tests approved', 'in progress', 'review', 'done'];
const plan = C.plan || null;
const progress = {};
const storyById = Object.fromEntries(C.stories.map(s => [s.id, s]));
for (const sl of plan ? plan.slices : []) {
  if (!sl.flows || typeof sl.flows !== 'object') throw new Error(`Plan: slice ${sl.id} needs flows: { <story id>: [step numbers] }`);
  for (const [flow, steps] of Object.entries(sl.flows)) {
    if (!storyById[flow]) throw new Error(`Plan: slice ${sl.id} names missing flow ${flow}`);
    const n = storyById[flow].steps.length;
    for (const k of steps) if (!(Number.isInteger(k) && k >= 1 && k <= n)) throw new Error(`Plan: slice ${sl.id} names step ${JSON.stringify(k)} of flow ${flow}, which has steps 1 to ${n}`);
  }
}
const PROGRESS = path.join(CONTENT_DIR, 'progress');
function parseProgress(f) {
  const text = fs.readFileSync(path.join(PROGRESS, f), 'utf8');
  try {
    return JSON.parse(text);
  } catch (error) {
    throw new Error(`Progress ${f}: not valid JSON (${error.message})`);
  }
}
const sliceIds = new Set((plan ? plan.slices : []).map(sl => sl.id));
for (const f of plan && fs.existsSync(PROGRESS) ? fs.readdirSync(PROGRESS).filter(f => f.endsWith('.json')).sort() : []) {
  const p = parseProgress(f);
  if (!sliceIds.has(p.slice)) throw new Error(`Progress ${f}: unknown slice ${p.slice}`);
  if (!SLICE_STATUS.includes(p.status)) throw new Error(`Progress ${f}: unknown status ${p.status} (use ${SLICE_STATUS.join(', ')})`);
  progress[p.slice] = p;
}

const DATA = {
  meta: C.meta, images, screens: C.screens, stories: C.stories, build: C.build || {}, plan, progress,
  decisions: C.decisions || [], assumptions: C.assumptions || [], questions: C.questions || [],
};
const TOKENS = fs.readFileSync(C.meta.tokens ? path.resolve(CONTENT_DIR, C.meta.tokens) : path.join(HERE, 'tokens.css'), 'utf8');
// Page chrome and generic overlay primitives, all on design-system tokens. Scope-specific
// overlay classes go in the content module's `css` export.
const CSS = `
*{box-sizing:border-box}body{margin:0;background:var(--surface-subtle);color:var(--text-body);font:16px/1.55 var(--font-sans)}
button{font:inherit;cursor:pointer;border:1px solid var(--border-strong);background:var(--surface);color:var(--text-heading);padding:10px 16px;border-radius:var(--radius-pill)}
button:hover{background:var(--surface-tint)}button:disabled{opacity:.4;cursor:default}summary{cursor:pointer}
button:focus-visible,a:focus-visible,summary:focus-visible{outline:3px solid var(--focus);outline-offset:3px}
header{background:linear-gradient(115deg,var(--surface-tint),var(--surface-subtle) 60%,var(--surface-tint));padding:32px 5vw;border-bottom:1px solid var(--border)}
header p{margin-bottom:0;max-width:72ch}.brand{font-weight:800;font-size:22px;color:var(--text-heading)}
h1{font-size:clamp(30px,4vw,46px);line-height:1.12;letter-spacing:-1.2px;margin:22px 0 12px;color:var(--text-heading)}
h2{font-size:28px;line-height:1.2;margin:10px 0 18px;color:var(--text-heading)}h3{line-height:1.3;color:var(--text-heading)}small,.muted{color:var(--text-muted)}
nav{display:flex;gap:8px;padding:14px 5vw;background:var(--surface-subtle);position:sticky;top:0;z-index:5;border-bottom:1px solid var(--border);overflow-x:auto}
nav button{white-space:nowrap}nav button[aria-selected=true]{background:var(--text-heading);color:#fff;border-color:var(--text-heading)}
main{padding:28px 5vw 60px}.layout{display:grid;grid-template-columns:290px minmax(0,1fr);gap:28px}
.sidebar{align-self:start;max-height:84vh;overflow:auto;padding-right:6px;position:sticky;top:76px}
.theme{font-size:12px;text-transform:uppercase;letter-spacing:1.4px;margin:20px 0 8px;color:var(--text-muted);font-weight:700}.theme:first-child{margin-top:0}
.story{display:block;width:100%;text-align:left;margin-bottom:6px;font-size:14px;border-radius:var(--radius-lg);padding:9px 12px}
.story small{display:block;font-size:12px}.story[aria-pressed=true]{background:var(--surface-tint);border-color:var(--action);font-weight:700}
.card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-panel);padding:26px;margin-bottom:20px;box-shadow:var(--shadow-sm)}
.storyhead{max-width:80ch}.storyhead h2{margin-bottom:6px}
.pill{display:inline-block;font-size:12px;font-weight:600;background:var(--surface-tint);color:var(--action);padding:3px 10px;border-radius:var(--radius-pill);margin-right:6px}
.pill.Decided{background:var(--success-surface);color:var(--success-text)}.pill.Open{background:var(--warning-surface);color:var(--warning-text)}
.walk{display:grid;grid-template-columns:minmax(0,1fr);gap:20px;margin-top:18px}.below{display:grid;grid-template-columns:minmax(0,1.2fr) minmax(0,1fr);gap:24px;align-items:start}.below .controls{margin-top:0}
.frame{border:1px solid var(--border-strong);border-radius:14px;background:var(--surface);overflow:hidden;box-shadow:0 18px 35px rgba(16,26,44,.08)}
.chrome{display:flex;align-items:center;gap:10px;padding:8px 12px;border-bottom:1px solid var(--border);background:#F9FAFC;font-size:12px;color:var(--text-muted)}
.chrome i{width:9px;height:9px;border-radius:50%;background:#D7DCE4;display:inline-block}.chrome .st{margin-left:auto;font-weight:700;padding:2px 9px;border-radius:var(--radius-pill)}
.st.today{background:#EEF0F4;color:var(--text-muted)}.st.proposed{background:var(--surface-tint);color:var(--action)}.st.approved{background:var(--success-surface);color:var(--success-text)}
.viewport{max-height:72vh;overflow:auto;position:relative}.sizer{position:relative;overflow:hidden}
.layer{position:absolute;left:0;top:0;transform-origin:0 0}.layer img{display:block}
.legend{font-size:12px;margin-top:8px}.legend b{color:var(--action)}
.caption{background:var(--surface-tint);padding:22px;border-radius:14px}.caption h3{font-size:21px;margin:8px 0}.caption p{margin:0;font-size:15px}
.caption .note{display:block;margin-top:10px;font-size:13px;color:var(--warning-text)}
.controls{display:flex;gap:10px;margin:18px 0}.next{background:var(--action);color:#fff;border-color:var(--action);font-weight:700}.next:hover{background:var(--action-hover)}
.outcome{border-left:4px solid var(--success-text);padding:12px 16px;background:var(--success-surface);border-radius:0 10px 10px 0;font-size:15px}
.steps{display:flex;flex-wrap:wrap;gap:5px;margin-top:16px}.steps button{font-size:12px;padding:5px 10px;border-radius:var(--radius-md)}
.steps button[aria-current=step]{background:var(--text-heading);color:#fff}
details{border:1px solid var(--border);border-radius:var(--radius-lg);padding:12px 16px;margin:12px 0;background:var(--surface)}summary{font-weight:650;color:var(--text-heading)}
details p,details li{font-size:14px}.q{background:var(--surface-subtle)}.q .who{font-weight:700;color:var(--action)}
.rel button{font-size:13px;padding:6px 12px;margin:4px 6px 0 0}
table.t{width:100%;border-collapse:collapse;font-size:14px}table.t th,table.t td{text-align:left;padding:8px 10px;border-bottom:1px solid var(--border);vertical-align:top}
table.t th{font-size:12px;text-transform:uppercase;letter-spacing:.6px;color:var(--text-muted)}table.t td.n{text-align:right;white-space:nowrap}table.t code{font-size:12px;word-break:break-word}
.grid2{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px;margin-bottom:20px}.grid2 .card{margin:0}
.big{font-size:34px;font-weight:800;color:var(--text-heading);letter-spacing:-1px}.tablewrap{overflow-x:auto}
footer{padding:22px 5vw;border-top:1px solid var(--border);font-size:12px}a{color:var(--action)}[hidden]{display:none!important}
.dia{padding:26px;font-size:14px;background:var(--surface)}
/* overlays: drawn in the capture's own pixel units */
.ov{position:absolute;display:flex;align-items:center;font-family:var(--font-sans);color:var(--text-heading)}
.ov.new{outline:2px dashed var(--action);outline-offset:2px;border-radius:var(--radius-sm)}.ov.raw{display:block;background:none;z-index:3}
.ov-btn{background:var(--action);color:#fff;border-radius:var(--radius-pill);padding:9px 18px;font-size:14px;font-weight:600}
.ov-btn.ghost{background:var(--surface);color:var(--action);border:1px solid var(--border-strong)}
.ov-panel{width:100%;align-self:flex-start;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius-panel);box-shadow:var(--shadow-sm);padding:28px 32px}
.ov-info{border:1px solid var(--info-border);background:var(--info-surface);color:var(--action-hover);border-radius:var(--radius-lg);padding:12px 16px;font-size:14px}
.ov-note{border:1px solid var(--warning-border);background:var(--warning-surface);color:var(--warning-text);border-radius:var(--radius-lg);padding:12px 16px;font-size:14px}
.ov-chip{font-size:11px;font-weight:700;color:var(--warning-text);background:var(--warning-surface);border:1px solid var(--warning-border);border-radius:var(--radius-pill);padding:1px 7px}
.ov-tip{background:var(--text-heading);color:#fff;font-size:13px;line-height:1.45;padding:10px 12px;border-radius:var(--radius-md);box-shadow:0 8px 24px rgba(16,26,44,.25)}
.ov-modal{background:var(--surface);border-radius:var(--radius-panel);box-shadow:0 24px 60px rgba(16,26,44,.3);padding:26px 28px;font-size:14.5px}
/* plan: flow → slices and the checklist */
.builtby{margin-top:10px;font-size:13px}.chip{display:inline-block;font-size:12px;font-weight:650;border:1px solid var(--border-strong);border-radius:var(--radius-pill);padding:2px 9px;margin:2px 4px 0 0;background:var(--surface)}
.lay-db{border-color:#C9B6F2;background:#F4EFFD}.lay-be{border-color:var(--info-border);background:var(--info-surface)}.lay-fe{border-color:var(--success-border);background:var(--success-surface)}
.flowrow{display:grid;gap:8px;margin:6px 0}.flowrow .stp{border:1px solid var(--border-strong);border-radius:10px;padding:8px 10px;font-size:13px;background:var(--surface)}.flowrow .stp b{display:block;font-size:11px;color:var(--text-muted)}
.flowrow .bar{border:1px solid var(--border-strong);border-radius:10px;padding:7px 10px;font-size:13px;font-weight:600}.flowrow .bar small{display:block;font-weight:400}
ul.check{list-style:none;margin:0;padding:0}ul.check li.slice{padding:10px 0;border-bottom:1px solid var(--border)}ul.check .box{display:inline-block;width:16px;height:16px;border:1.5px solid var(--border-strong);border-radius:4px;vertical-align:-3px;margin-right:8px;text-align:center;font-size:11px;line-height:13px}
ul.check .box.on{background:var(--success-text);border-color:var(--success-text);color:#fff}ul.check ul{margin:6px 0 0 26px;padding:0;font-size:13px}ul.check code{font-size:12px;word-break:break-word}
.sst{display:inline-block;font-size:11px;font-weight:700;border-radius:var(--radius-pill);padding:1px 8px;background:var(--surface-subtle);color:var(--text-muted)}.sst.done{background:var(--success-surface);color:var(--success-text)}.sst.review{background:var(--warning-surface);color:var(--warning-text)}.sst.progress,.sst.tests{background:var(--info-surface);color:var(--action)}
@media(max-width:1100px){.layout{grid-template-columns:230px 1fr}.below{grid-template-columns:1fr}}
@media(max-width:700px){header{padding:24px 16px}main{padding:20px 16px}nav{padding:10px 16px;gap:6px}nav button{font-size:13px;padding:8px 12px}
.layout{display:block}.sidebar{position:static;max-height:260px;margin-bottom:18px;border-bottom:1px solid var(--border)}.card{padding:18px}
.grid2{grid-template-columns:1fr}h2{font-size:24px}.viewport{max-height:480px}.flowrow{grid-template-columns:1fr 1fr!important}.flowrow .bar{grid-column:1/-1!important}}
`;
const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);
const m = C.meta;
const footerLinks = [['source-mapping.json', 'Story source mapping'], ['report.md', 'Review report']];
if (m.scopeMarkdown) footerLinks.push([m.scopeMarkdown, 'Technical scope (markdown)']);

const HTML = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(m.title)}</title><style>${TOKENS}${CSS}${C.css || ''}</style></head><body>
<header><div class="brand">${esc(m.product)}</div>
<h1>${esc(m.heading)}</h1><p>${esc(m.intro)}</p><small>${esc(m.byline)}</small></header>
<nav role="tablist" aria-label="Scope sections">
<button role="tab" id="tab-stories" data-tab="stories" aria-selected="true" aria-controls="stories">User stories</button>
<button role="tab" id="tab-build" data-tab="build" aria-selected="false" aria-controls="build" tabindex="-1">How it works &amp; build</button>
<button role="tab" id="tab-questions" data-tab="questions" aria-selected="false" aria-controls="questions" tabindex="-1">Questions &amp; next steps</button></nav>
<main>
<section id="stories" role="tabpanel" aria-labelledby="tab-stories"><div class="layout"><aside><div class="sidebar" id="storylist"></div></aside>
<div><article class="card"><div class="storyhead" id="storyhead"></div>
<div class="walk"><div><div class="frame"><div class="chrome"><i></i><i></i><i></i><span id="screentitle"></span><span class="st" id="screenstatus"></span></div>
<div class="viewport" id="viewport"><div class="sizer" id="sizer"></div></div></div>
<p class="legend muted" id="legend"></p></div>
<div class="below"><div class="caption" aria-live="polite" id="caption"></div>
<div><div class="controls"><button id="prev">← Previous</button><button id="next" class="next">Next →</button></div>
<div id="outcome"></div><div id="steps" class="steps" aria-label="Walkthrough steps"></div></div></div></div>
<div id="related" class="rel"></div>
<details id="storyq"><summary>Questions for this story</summary><div id="storyquestions"></div></details>
<details><summary>Screen source</summary><p class="muted" id="source"></p></details></article></div></div></section>
<section id="build" role="tabpanel" aria-labelledby="tab-build" hidden></section>
<section id="questions" role="tabpanel" aria-labelledby="tab-questions" hidden></section>
</main>
<footer>Works offline. ${footerLinks.map(([href, label]) => `<a href="${esc(href)}">${label}</a>`).join(' · ')}</footer>
<script>const D=${JSON.stringify(DATA).replace(/</g, '\\u003c')};</script>
<script>${fs.readFileSync(path.join(HERE, 'page.js'), 'utf8')}</script></body></html>`;

fs.mkdirSync(OUT, { recursive: true });
fs.writeFileSync(path.join(OUT, 'index.html'), HTML);

const mapping = {
  generated_from: path.basename(CONTENT), code_read: m.codeRead || null,
  images: Object.fromEntries(Object.entries(C.images || {}).map(([k, v]) => [k, { file: v.path, size: [v.w, v.h], origin: v.origin }])),
  stories: C.stories.map(s => ({
    id: s.id, theme: s.theme, actor: s.actor, title: s.title, tag: s.tag || null,
    steps: s.steps.map(st => {
      const sc = C.screens[st.screen];
      return { screen: st.screen, status: sc.status, image: sc.img || null, crop: sc.crop || null, action: st.action };
    }),
    questions: s.questions || [], related: s.related || [],
  })),
  questions: (C.questions || []).map(({ id, who, text }) => ({ id, who, text })),
};
fs.writeFileSync(path.join(OUT, 'source-mapping.json'), JSON.stringify(mapping, null, 2));

// The same checklist as markdown, for reading in a terminal or pasting into a PR.
if (plan) {
  const lines = ['# Plan checklist', '', `Generated from ${path.basename(CONTENT)} and progress/*.json. Slice threads update it; nobody edits it.`, ''];
  for (const sl of plan.slices) {
    const p = progress[sl.id] || { status: 'todo' };
    lines.push(`- [${p.status === 'done' ? 'x' : ' '}] **${sl.id} · ${sl.layer}** ${sl.name} · ${p.status}${p.mr ? ' · ' + p.mr : ''}`);
    for (const r of p.review || []) lines.push(`  - \`${r.file}\`${r.lines ? ' ' + r.lines : ''}: ${r.why}`);
  }
  fs.writeFileSync(path.join(OUT, 'plan-checklist.md'), lines.join('\n') + '\n');
}
console.log('wrote', path.join(OUT, 'index.html'), (fs.statSync(path.join(OUT, 'index.html')).size / 1e6).toFixed(2) + ' MB');
