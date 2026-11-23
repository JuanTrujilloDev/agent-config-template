// Live browser checks for a built scope page.
// Usage: node .claude/skills/scope-page/verify.mjs <scopeDir>
// Needs Playwright where you run it (`npm i -D playwright && npx playwright install chromium`),
// or PLAYWRIGHT_MODULE=<path to playwright or playwright-core>; CHROMIUM_PATH picks the browser binary.
import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';

if (!process.argv[2]) throw new Error('Usage: node .claude/skills/scope-page/verify.mjs <scopeDir>');
const require = createRequire(path.join(process.cwd(), 'verify.cjs'));
const found = name => require.resolve.paths(name).some(dir => fs.existsSync(path.join(dir, name, 'package.json')));
const playwright = process.env.PLAYWRIGHT_MODULE || ['playwright', '@playwright/test', 'playwright-core'].find(found);
if (!playwright) throw new Error('verify.mjs needs Playwright: run `npm i -D playwright && npx playwright install chromium` here, or set PLAYWRIGHT_MODULE.');
const { chromium } = require(playwright);

const SCOPE = path.resolve(process.argv[2]);
const URL = 'file://' + path.join(SCOPE, 'index.html');
const VIEWPORTS = [{ name: 'desktop', width: 1440, height: 900 }, { name: 'phone', width: 390, height: 844 }];

const results = [];
const failures = [];
let checks = 0;
function ok(cond, msg) {
  checks++;
  if (!cond) failures.push(msg);
}

async function walkStory(page, vp, id) {
  await page.click(`.story[data-story="${id}"]`);
  const n = await page.$$eval('#steps button', b => b.length);
  ok(await page.isDisabled('#prev'), `${vp.name} ${id}: previous enabled on step 1`);
  for (let i = 0; i < n; i++) {
    if (i > 0) await page.click('#next');
    const cur = await page.$eval('#steps [aria-current=step]', b => +b.dataset.step);
    ok(cur === i, `${vp.name} ${id}: step ${i + 1} not current`);
    const img = await page.$('#sizer img');
    if (img) {
      ok(await img.evaluate(el => el.complete && el.naturalWidth > 0), `${vp.name} ${id}: step ${i + 1} image not decoded`);
      const h = await page.$eval('#sizer', el => el.getBoundingClientRect().height);
      ok(h > 50, `${vp.name} ${id}: step ${i + 1} frame height ${h}`);
    } else {
      ok(await page.$eval('#sizer', el => el.children.length > 0), `${vp.name} ${id}: step ${i + 1} has no screen`);
    }
    ok((await page.textContent('#caption')).includes(`Step ${i + 1} of ${n}`), `${vp.name} ${id}: step ${i + 1} caption count`);
  }
  ok(await page.isDisabled('#next'), `${vp.name} ${id}: next enabled on last step`);
  ok((await page.textContent('#outcome')).includes('Outcome'), `${vp.name} ${id}: no outcome on last step`);
  results.push([vp.name, id, n]);
}

const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
const browserVersion = browser.version();
for (const vp of VIEWPORTS) {
  const page = await browser.newPage({ viewport: { width: vp.width, height: vp.height } });
  page.setDefaultTimeout(15000);
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  await page.goto(URL);
  await page.waitForSelector('.story');
  const stories = await page.$$eval('.story', bs => bs.map(b => b.dataset.story));
  for (const id of stories) await walkStory(page, vp, id);
  const planned = await page.evaluate(() => (D.plan ? D.plan.slices.length : 0));
  if (planned) {
    await page.click('#tab-build');
    ok(await page.$$eval('#plancheck li.slice', li => li.length) === planned, `${vp.name}: Plan checklist does not list every slice`);
    ok(await page.$$eval('#planflows .bar', b => b.length) >= planned, `${vp.name}: flow → slices diagram misses a slice`);
    await page.click('#tab-stories');
  }
  for (const tab of ['build', 'questions', 'stories']) {
    await page.click(`#tab-${tab}`);
    ok(await page.isVisible(`#${tab}`), `${vp.name}: tab ${tab} not visible`);
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth + 1);
    ok(!overflow, `${vp.name}: horizontal page overflow on ${tab}`);
    await page.screenshot({ path: path.join(SCOPE, `verification-${vp.name}-${tab}.png`) });
  }
  ok(errors.length === 0, `${vp.name}: console errors ${errors.join(' | ')}`);
  await page.close();
}
await browser.close();

const report = { browser: `Chromium ${browserVersion}`, checks, failures, results };
fs.writeFileSync(path.join(SCOPE, 'verification-browser.json'), JSON.stringify(report, null, 2));
console.log(`checks ${checks}, failures ${failures.length}`);
failures.forEach(f => console.log(' -', f));
process.exitCode = failures.length ? 1 : 0;
