// Content validation in build.mjs. Run: node --test .claude/skills/scope-page/build.test.mjs
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { describe, test } from 'node:test';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const EXAMPLE = pathToFileURL(path.join(HERE, 'example/content.mjs')).href;
const CAPTURE = path.join(HERE, 'example/capture.svg');

// Builds the example content after applying `mutation` (JS source acting on C).
function build(mutation, progress) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'scope-page-'));
  const content = path.join(dir, 'content.mjs');
  fs.writeFileSync(content, `import * as ex from ${JSON.stringify(EXAMPLE)};
const C = structuredClone({ ...ex });
C.images.fund.path = ${JSON.stringify(CAPTURE)};
${mutation}
export const { meta, images, css, screens, stories, build, plan, decisions, assumptions, questions } = C;`);
  if (progress) {
    fs.mkdirSync(path.join(dir, 'progress'));
    fs.writeFileSync(path.join(dir, 'progress', 'x.json'), JSON.stringify(progress));
  }
  return spawnSync(process.execPath, [path.join(HERE, 'build.mjs'), content, path.join(dir, 'scope')], { encoding: 'utf8' });
}

describe('build.mjs content validation', () => {
  test('builds the example', () => {
    const result = build('');
    assert.equal(result.status, 0, result.stderr);
  });

  const broken = [
    ['step.screen → screens', "C.stories[0].steps[0].screen = 'nope';", 'Story export: missing screen nope'],
    ['story.questions → questions', "C.stories[0].questions = ['nope'];", 'Story export: missing question nope'],
    ['screen.img → images', "C.screens['fund-today'].img = 'nope';", 'Screen fund-today: missing image nope'],
    ['story.related → stories', "C.stories[0].related = ['nope'];", 'Story export: missing related story nope'],
    ['build.diagrams → screens', "C.build.diagrams = ['nope'];", 'Build: diagram nope is not an html screen'],
    ['screen crop', "delete C.screens['fund-today'].crop;", 'Screen fund-today: crop must be [x, y, w, h]'],
    ['screen status', "C.screens['fund-today'].status = 'nope';", 'Screen fund-today: unknown status nope'],
    ['plan flow → stories', "C.plan.slices[0].flows = { nope: [1] };", 'Plan: slice 1 names missing flow nope'],
    ['plan step → story steps', "C.plan.slices[0].flows = { export: [4] };", 'Plan: slice 1 names step 4 of flow export, which has 3'],
  ];
  for (const [name, mutation, message] of broken) {
    test(`fails on a broken ${name}`, () => {
      const result = build(mutation);
      assert.notEqual(result.status, 0);
      assert.match(result.stderr, new RegExp(message.replace(/[[\]]/g, '\\$&')));
    });
  }

  test('fails on a progress file for an unknown slice', () => {
    const result = build('', { slice: '9', status: 'done' });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Progress x.json: unknown slice 9/);
  });

  test('fails on an unknown progress status', () => {
    const result = build('', { slice: '1', status: 'shipped' });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Progress x.json: unknown status shipped/);
  });

  test('writes the plan checklist from progress files', () => {
    const result = build('', { slice: '1', status: 'done', mr: '!12', review: [{ file: 'a.py', why: 'the view' }] });
    assert.equal(result.status, 0, result.stderr);
    const out = result.stdout.match(/wrote (.*)index\.html/)[1];
    const md = fs.readFileSync(path.join(out, 'plan-checklist.md'), 'utf8');
    assert.match(md, /- \[x\] \*\*1 · be\*\* Export job and endpoint · done · !12/);
    assert.match(md, /- \[ \] \*\*2 · fe\*\* Button and notification · todo/);
    assert.match(md, /  - `a.py`: the view/);
  });
});
