// Renders post.html to a 1080x1080 Instagram PNG. Usage: node shoot.mjs
import { chromium } from '../capture/node_modules/playwright-core/index.mjs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const here = dirname(fileURLToPath(import.meta.url));
const browser = await chromium.launch({ executablePath: '/usr/bin/chromium', headless: true });
const page = await browser.newPage({ viewport: { width: 1080, height: 1080 }, deviceScaleFactor: 1 });
await page.goto('file://' + join(here, 'post.html'), { waitUntil: 'networkidle', timeout: 60000 });
await page.waitForTimeout(1500); // let webfonts settle
const out = join(here, 'gaming_adda_instagram.png');
await page.screenshot({ path: out, clip: { x: 0, y: 0, width: 1080, height: 1080 } });
console.log('saved ' + out);
await browser.close();
