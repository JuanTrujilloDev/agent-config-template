(function () {
  'use strict';
  const $ = id => document.getElementById(id);
  const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);
  const STATUS = { today: 'Today', proposed: 'Proposed', approved: 'Approved design' };
  const LEGEND = {
    today: 'Real screen, unchanged.',
    approved: 'From an approved design.',
    proposed: '<b>Dashed outline</b> = proposed. Everything else is the real screen.',
  };
  const qById = Object.fromEntries(D.questions.map(q => [q.id, q]));
  const storyById = Object.fromEntries(D.stories.map(s => [s.id, s]));
  const B = D.build;
  const P = D.plan;
  const progress = D.progress || {};
  const STATUS_CLASS = { todo: '', 'tests approved': 'tests', 'in progress': 'progress', review: 'review', done: 'done' };
  let story = D.stories[0];
  let step = 0;

  function chip(sl) {
    return `<span class="chip lay-${esc(sl.layer)}">${esc(sl.id)} · ${esc(sl.layer)}</span>`;
  }

  function builtBy(storyId, stepNumber) {
    return P ? P.slices.filter(sl => (sl.flows[storyId] || []).includes(stepNumber)) : [];
  }

  function statusOf(sl) {
    return (progress[sl.id] || {}).status || 'todo';
  }

  function tagPill(tag) {
    if (!tag) return '';
    return `<span class="pill ${esc(tag.split(' ')[0])}">${esc(tag)}</span>`;
  }

  // ---------- story list ----------
  function renderList() {
    const themes = [...new Set(D.stories.map(s => s.theme))];
    $('storylist').innerHTML = themes.map(theme => `<p class="theme">${esc(theme)}</p>` +
      D.stories.filter(s => s.theme === theme).map(s =>
        `<button class="story" data-story="${esc(s.id)}" aria-pressed="false">${esc(s.title)}<small>${esc(s.actor)} · ${s.steps.length} step${s.steps.length > 1 ? 's' : ''}${s.tag ? ' · ' + esc(s.tag) : ''}</small></button>`).join('')).join('');
    $('storylist').addEventListener('click', e => {
      const b = e.target.closest('[data-story]');
      if (b) selectStory(b.dataset.story, 0, true);
    });
  }

  function selectStory(id, at, push) {
    story = storyById[id] || D.stories[0];
    step = Math.min(Math.max(at || 0, 0), story.steps.length - 1);
    document.querySelectorAll('.story').forEach(b => b.setAttribute('aria-pressed', String(b.dataset.story === story.id)));
    $('storyhead').innerHTML = `${tagPill(story.tag)}<span class="pill">${esc(story.actor)}</span>
      <h2>${esc(story.title)}</h2><p class="muted">${esc(story.goal)}</p>`;
    const related = story.related || [];
    $('related').innerHTML = related.length ? '<small>Related: </small>' + related.map(r =>
      `<button data-rel="${esc(r)}">${esc(storyById[r].title)}</button>`).join('') : '';
    const qs = (story.questions || []).map(q => qById[q]);
    $('storyq').hidden = !qs.length;
    $('storyquestions').innerHTML = qs.map(questionHtml).join('');
    if (push) {
      try { history.replaceState(null, '', '#' + story.id); } catch (e) { /* some browsers refuse on file:// */ }
    }
    renderStep();
  }

  // ---------- one step ----------
  function renderStep() {
    const st = story.steps[step];
    const sc = D.screens[st.screen];
    const last = step === story.steps.length - 1;
    $('screentitle').textContent = sc.title;
    $('screenstatus').textContent = STATUS[sc.status];
    $('screenstatus').className = 'st ' + sc.status;
    $('caption').innerHTML = `<small>Step ${step + 1} of ${story.steps.length}</small><h3>${esc(st.action)}</h3><p>${esc(st.text)}</p>` +
      (sc.note ? `<span class="note">${esc(sc.note)}</span>` : '') +
      (builtBy(story.id, step + 1).length ? `<div class="builtby">Built by ${builtBy(story.id, step + 1).map(chip).join('')}</div>` : '');
    $('prev').disabled = step === 0;
    $('next').disabled = last;
    $('outcome').innerHTML = last ? `<div class="outcome"><b>Outcome.</b> ${esc(story.outcome)}</div>` : '';
    $('steps').innerHTML = story.steps.map((s, i) =>
      `<button data-step="${i}" ${i === step ? 'aria-current="step"' : ''} aria-label="Step ${i + 1}: ${esc(s.action)}">${i + 1}. ${esc(s.action)}</button>`).join('');
    $('legend').innerHTML = sc.legend ? esc(sc.legend) : LEGEND[sc.status];
    const img = sc.img ? D.images[sc.img] : null;
    $('source').textContent = img ? `${img.origin} Region ${sc.crop.join(', ')} (x, y, w, h). Overlays are HTML drawn for this scope.` : 'Diagram drawn for this scope.';
    drawScreen(sc);
  }

  function drawScreen(sc) {
    const sizer = $('sizer');
    $('viewport').scrollTop = 0;
    if (sc.kind === 'html') {
      sizer.style.height = 'auto';
      sizer.innerHTML = sc.html;
      return;
    }
    const img = D.images[sc.img];
    const [x, y, w, h] = sc.crop;
    const overlays = (sc.overlays || []).map(o => {
      const cls = 'ov' + (o.isNew ? ' new' : '') + (o.raw ? ' raw' : '');
      const style = `left:${o.x}px;top:${o.y}px;width:${o.w}px;${o.h ? `height:${o.h}px;` : ''}${o.bg ? `background:${o.bg};` : ''}`;
      return `<div class="${cls}" style="${style}">${o.html}</div>`;
    }).join('');
    sizer.innerHTML = `<div class="layer" data-w="${w}" data-h="${h}" data-x="${x}" data-y="${y}" style="width:${img.w}px;height:${img.h}px">
      <img src="${img.src}" width="${img.w}" height="${img.h}" alt="${esc(sc.title)}">${overlays}</div>`;
    fit();
  }

  function fit() {
    const layer = document.querySelector('#sizer .layer');
    if (!layer) return;
    const w = +layer.dataset.w, h = +layer.dataset.h, x = +layer.dataset.x, y = +layer.dataset.y;
    const s = $('viewport').clientWidth / w;
    $('sizer').style.height = Math.round(h * s) + 'px';
    layer.style.transform = `scale(${s}) translate(${-x}px, ${-y}px)`;
  }

  // ---------- build tab ----------
  function hours(rows) { return rows.reduce((n, r) => n + (Number(r[2]) || 0), 0); }

  function table(head, rows, cell) {
    const th = head ? `<thead><tr>${head.map(h => `<th>${esc(h)}</th>`).join('')}</tr></thead>` : '';
    return `<div class="tablewrap"><table class="t">${th}<tbody>${rows.map(r => `<tr>${r.map(cell).join('')}</tr>`).join('')}</tbody></table></div>`;
  }

  function planFlows() {
    const flows = D.stories.filter(s => P.slices.some(sl => sl.flows[s.id]));
    return `<div class="card" id="planflows"><h3>Flows and the slices that build them</h3>` + flows.map(s => {
      const n = s.steps.length;
      const steps = s.steps.map((st, i) => `<div class="stp"><b>Step ${i + 1}</b>${esc(st.action)}</div>`).join('');
      const bars = P.slices.filter(sl => sl.flows[s.id]).map(sl => {
        const k = sl.flows[s.id];
        return `<div class="bar lay-${esc(sl.layer)}" style="grid-column:${Math.min(...k)} / ${Math.max(...k) + 1}">${esc(sl.id)} · ${esc(sl.layer)} · ${esc(sl.name)}<small>steps ${k.join(', ')} · ${esc(sl.hours)} h · ${esc(statusOf(sl))}</small></div>`;
      }).join('');
      return `<p class="theme">${esc(s.title)}</p><div class="flowrow" style="grid-template-columns:repeat(${n},minmax(0,1fr))">${steps}${bars}</div>`;
    }).join('') + '</div>';
  }

  function planChecklist() {
    const items = P.slices.map(sl => {
      const p = progress[sl.id] || {};
      const st = statusOf(sl);
      const review = (p.review || []).map(r => `<li><code>${esc(r.file)}</code>${r.lines ? ' ' + esc(r.lines) : ''}: ${esc(r.why)}</li>`).join('');
      return `<li class="slice"><span class="box${st === 'done' ? ' on' : ''}">${st === 'done' ? '✓' : ''}</span><b>${esc(sl.id)} · ${esc(sl.layer)}</b> ${esc(sl.name)}` +
        `${p.mr ? ' · ' + esc(p.mr) : ''} · <span class="sst ${STATUS_CLASS[st]}">${esc(st)}</span>${p.updated ? ` <small>${esc(p.updated)}</small>` : ''}` +
        `${review ? `<ul>${review}</ul>` : ''}</li>`;
    }).join('');
    const done = P.slices.filter(sl => statusOf(sl) === 'done').length;
    return `<div class="card" id="plancheck"><h3>Plan checklist · ${done} of ${P.slices.length} done</h3><p class="muted">Each slice's own thread writes its progress file; this list only reads them. Files to review come from the slice's Placement rows.</p><ul class="check">${items}</ul></div>`;
  }

  function renderBuild() {
    const efforts = B.efforts || [];
    const total = efforts.reduce((n, e) => n + hours(e.rows), 0);
    const parts = [`<h2>How it works &amp; build</h2>${B.intro ? `<p>${esc(B.intro)}</p>` : ''}`];
    if (P) parts.push(planChecklist(), planFlows());
    (B.diagrams || []).forEach(id => parts.push(`<div class="card"><h3>${esc(D.screens[id].title)}</h3>${D.screens[id].html}</div>`));
    if (B.codemap) parts.push(`<div class="card"><h3>Today → change, by code location</h3>${table(['Area', 'Today', 'Where', 'Change'], B.codemap,
      (c, i) => i === 2 ? `<td><code>${esc(c)}</code></td>` : `<td>${esc(c)}</td>`)}</div>`);
    if (efforts.length) {
      const summary = efforts.map(e => [e.item, `${hours(e.rows)} h`]);
      const detail = efforts.map(e => `<details><summary>${esc(e.item)} · ${hours(e.rows)} h</summary>${table(null, e.rows,
        (c, i) => i === 2 ? `<td class="n">${c} h</td>` : `<td>${esc(c)}</td>`)}</details>`).join('');
      parts.push(`<div class="card"><h3>Effort</h3><p class="big">${total} h</p>${B.effortNote ? `<p class="muted">${esc(B.effortNote)}</p>` : ''}
        ${table(null, summary, (c, i) => i === 1 ? `<td class="n">${esc(c)}</td>` : `<td><b>${esc(c)}</b></td>`)}${detail}</div>`);
    }
    if (B.slices) parts.push(`<div class="card"><h3>Epics and slices</h3>${B.slicesNote ? `<p class="muted">${esc(B.slicesNote)}</p>` : ''}
      ${table(['Epic', 'Slice', 'Layer', 'Hours'], B.slices, (c, i) => i === 3 ? `<td class="n">${c} h</td>` : `<td>${esc(c)}</td>`)}</div>`);
    if (B.order) parts.push(`<div class="card"><h3>Build order</h3><ol>${B.order.map(x => `<li>${esc(x)}</li>`).join('')}</ol></div>`);
    if (B.followups) parts.push(`<div class="card"><h3>Follow-ups, not in this scope</h3>${table(null, B.followups,
      (c, i) => i === 2 ? `<td class="n">${c} h</td>` : `<td>${esc(c)}</td>`)}</div>`);
    $('build').innerHTML = parts.join('');
  }

  // ---------- questions tab ----------
  function questionHtml(q) {
    return `<details class="q"><summary><span class="who">${esc(q.who)}</span> · ${esc(q.text)}</summary>
      <p><b>Why it matters:</b> ${esc(q.why)}</p><p><b>Default if no answer:</b> ${esc(q.def)}</p></details>`;
  }

  function renderQuestions() {
    const open = D.questions.length ? D.questions.map(questionHtml).join('') : '<p>None. Every question is answered and listed under Decided.</p>';
    $('questions').innerHTML = `<h2>Questions &amp; next steps</h2><p>Decisions already made are separate from what's still open. Each open question has a default, so work can start.</p>
      <div class="card"><h3>Decided</h3>${table(null, D.decisions, (c, i) => i === 2 ? `<td class="muted">${esc(c)}</td>` : `<td>${i ? esc(c) : `<b>${esc(c)}</b>`}</td>`)}</div>
      <div class="card"><h3>Assumed unless you say otherwise</h3><ul>${D.assumptions.map(x => `<li>${esc(x)}</li>`).join('')}</ul></div>
      <div class="card" id="openquestions"><h3>Open questions</h3>${open}</div>`;
  }

  // ---------- tabs ----------
  function selectTab(name) {
    document.querySelectorAll('[role=tab]').forEach(t => {
      const on = t.dataset.tab === name;
      t.setAttribute('aria-selected', String(on));
      t.tabIndex = on ? 0 : -1;
      $(t.dataset.tab).hidden = !on;
    });
    if (name === 'stories') fit();
  }

  document.querySelector('nav').addEventListener('click', e => { const t = e.target.closest('[role=tab]'); if (t) selectTab(t.dataset.tab); });
  document.querySelector('nav').addEventListener('keydown', e => {
    if (!['ArrowLeft', 'ArrowRight'].includes(e.key)) return;
    const tabs = [...document.querySelectorAll('[role=tab]')];
    const i = tabs.indexOf(document.activeElement);
    const n = tabs[(i + (e.key === 'ArrowRight' ? 1 : tabs.length - 1)) % tabs.length];
    n.focus();
    selectTab(n.dataset.tab);
  });
  $('prev').addEventListener('click', () => { if (step > 0) { step--; renderStep(); } });
  $('next').addEventListener('click', () => { if (step < story.steps.length - 1) { step++; renderStep(); } });
  $('steps').addEventListener('click', e => { const b = e.target.closest('[data-step]'); if (b) { step = +b.dataset.step; renderStep(); } });
  $('related').addEventListener('click', e => { const b = e.target.closest('[data-rel]'); if (b) { selectStory(b.dataset.rel, 0, true); $('storyhead').scrollIntoView({ block: 'start' }); } });
  new ResizeObserver(fit).observe($('viewport'));

  renderList();
  renderBuild();
  renderQuestions();
  selectStory(location.hash.slice(1), 0, false);
})();
