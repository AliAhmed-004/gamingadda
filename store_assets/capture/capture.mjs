// Captures phone-sized screenshots of the Flutter web build for Play Store listing.
// Usage: node capture.mjs [targetId ...]  (no args = all targets)
import { chromium } from 'playwright-core';
import { mkdirSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const BASE = 'http://localhost:8917';
const OUT = join(dirname(fileURLToPath(import.meta.url)), '..', 'raw');
mkdirSync(OUT, { recursive: true });

// Logical viewport 360x780 at 3x -> exactly 1080x2340 physical pixels.
const VIEWPORT = { width: 360, height: 780 };
const DSF = 3;

/** @type {{id: string, url: string, settleMs?: number, taps?: {x: number, y: number, delayMs?: number}[]}[]} */
const TARGETS = [
  { id: 'home', url: '/', settleMs: 9000 },
  { id: 'ludo', url: '/?game=ludo', settleMs: 9000 },
  { id: 'checkers', url: '/?game=checkers', settleMs: 9000 },
  { id: 'card_match', url: '/?game=casino', settleMs: 9000 },
  {
    id: 'tic_tac_toe',
    url: '/?game=tic_tac_toe',
    settleMs: 9000,
    // Play a few moves so the grid isn't empty (center, then corners).
    taps: [
      { x: 180, y: 390, delayMs: 1800 },
      { x: 90, y: 300, delayMs: 1800 },
      { x: 270, y: 480, delayMs: 1800 },
    ],
  },
  {
    id: 'stack',
    // demo=1 auto-builds a mid-game tower in-app (deterministic).
    url: '/?game=stack&demo=1',
    settleMs: 9000,
    afterMs: 6500,
  },
];

const wanted = process.argv.slice(2);
const targets = wanted.length
  ? TARGETS.filter((t) => wanted.includes(t.id))
  : TARGETS;

const browser = await chromium.launch({
  executablePath: '/usr/bin/google-chrome',
  headless: true,
});

for (const target of targets) {
  const viewport = target.landscape
    ? { width: VIEWPORT.height, height: VIEWPORT.width }
    : VIEWPORT;
  const context = await browser.newContext({
    viewport,
    deviceScaleFactor: DSF,
    isMobile: true,
    hasTouch: true,
  });
  const page = await context.newPage();
  console.log(`[${target.id}] loading ${target.url}`);
  await page.goto(BASE + target.url, { waitUntil: 'load', timeout: 60000 });
  await page.waitForTimeout(target.settleMs ?? 8000);

  for (const tap of target.taps ?? []) {
    await page.mouse.click(tap.x, tap.y);
    await page.waitForTimeout(tap.delayMs ?? 1000);
  }

  for (const stroke of target.keys ?? []) {
    await page.keyboard.press(stroke.key);
    await page.waitForTimeout(stroke.delayMs ?? 1000);
  }

  if (target.afterMs) await page.waitForTimeout(target.afterMs);

  const file = join(OUT, `${target.id}.png`);
  await page.screenshot({ path: file });
  console.log(`[${target.id}] saved ${file}`);
  await context.close();
}

await browser.close();
console.log('done');
