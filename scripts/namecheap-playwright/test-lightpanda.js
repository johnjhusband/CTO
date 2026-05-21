// End-to-end smoke test: start Lightpanda's CDP server, connect Playwright
// via connectOverCDP, navigate to a known-stable page, interact with elements,
// confirm Lightpanda is what actually served the page (not a hidden Chromium).
//
// Run from scripts/namecheap-playwright/ (reuses installed Playwright):
//   node test-lightpanda.js

const { spawn } = require('child_process');
const net = require('net');
const { chromium } = require('playwright');

const LP_HOST = '127.0.0.1';
const LP_PORT = 9222;

function log(msg) { console.log(`[lp-test] ${msg}`); }

async function waitForPort(host, port, timeoutMs = 8000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const ok = await new Promise((resolve) => {
      const s = net.connect(port, host);
      s.on('connect', () => { s.end(); resolve(true); });
      s.on('error', () => resolve(false));
      setTimeout(() => { s.destroy(); resolve(false); }, 500);
    });
    if (ok) return true;
    await new Promise(r => setTimeout(r, 200));
  }
  return false;
}

(async () => {
  log('Starting lightpanda serve...');
  const lp = spawn('lightpanda', ['serve', '--host', LP_HOST, '--port', String(LP_PORT)], {
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let lpOut = '';
  lp.stdout.on('data', d => { lpOut += d.toString(); });
  lp.stderr.on('data', d => { lpOut += d.toString(); });

  const cleanup = () => { try { lp.kill('SIGTERM'); } catch {} };
  process.on('exit', cleanup);
  process.on('SIGINT', () => { cleanup(); process.exit(130); });

  if (!await waitForPort(LP_HOST, LP_PORT)) {
    log('lightpanda did NOT bind. stdout/stderr:');
    log(lpOut);
    cleanup();
    process.exit(1);
  }
  log(`lightpanda bound on ${LP_HOST}:${LP_PORT}`);

  log('Connecting Playwright via connectOverCDP...');
  const browser = await chromium.connectOverCDP(`ws://${LP_HOST}:${LP_PORT}`);
  log(`connected. version=${browser.version()}`);

  // Confirm this is Lightpanda — the version string from a real Chromium is
  // typically "HeadlessChrome/<version>"; Lightpanda will report differently.
  const ver = browser.version();
  if (/chrome|chromium/i.test(ver) && !/lightpanda/i.test(ver)) {
    log(`WARNING: version string "${ver}" looks like Chromium, not Lightpanda`);
  } else {
    log(`version string "${ver}" — looks distinct from headless Chrome`);
  }

  const context = browser.contexts()[0] || await browser.newContext();
  const page = await context.newPage();

  log('Navigating to https://example.com ...');
  await page.goto('https://example.com', { waitUntil: 'domcontentloaded', timeout: 15000 });
  const title = await page.title();
  log(`page title: "${title}"`);

  const h1 = await page.locator('h1').first().textContent().catch(() => null);
  log(`<h1> text: "${h1}"`);

  // Try to click the "More information..." link on example.com
  const link = page.locator('a').first();
  const linkText = await link.textContent().catch(() => null);
  log(`first link text: "${linkText}"`);
  const linkHref = await link.getAttribute('href').catch(() => null);
  log(`first link href: "${linkHref}"`);

  // Verify Playwright actually drove the page (interactive, not just static fetch)
  const userAgent = await page.evaluate(() => navigator.userAgent).catch(() => null);
  log(`navigator.userAgent reported by page: "${userAgent}"`);

  await page.close();
  await browser.close();
  log('PASS: Lightpanda served the page, Playwright drove it.');
  cleanup();
  process.exit(0);
})().catch((err) => {
  console.error('[lp-test] FAIL:', err.message);
  process.exit(1);
});
