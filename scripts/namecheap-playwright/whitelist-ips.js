// Add IPs to the Namecheap API whitelist using the saved Playwright session.
// IPs to add come from env: NAMECHEAP_WHITELIST_IPS="ip1,ip2,..." (comma-separated).

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const SESSION_FILE = path.join(__dirname, '.session.json');
const SHOTS_DIR = path.join(__dirname, 'shots');
const API_PAGE = 'https://ap.www.namecheap.com/settings/tools/apiaccess/';

// Format: NAMECHEAP_WHITELIST_IPS="name1=ip1,name2=ip2"
const IPS_RAW = process.env.NAMECHEAP_WHITELIST_IPS || '';
const IPS = IPS_RAW.split(',').map(s => {
  const [name, ip] = s.split('=').map(x => x.trim());
  return { name, ip };
}).filter(e => e.name && e.ip);
const PASS = process.env.NAMECHEAP_PASS;
if (!PASS) { console.error('NAMECHEAP_PASS env var required'); process.exit(1); }

function log(msg) { console.log(`[whitelist] ${msg}`); }
function fail(msg) { log(`FAIL: ${msg}`); process.exit(1); }

if (IPS.length === 0) fail('NAMECHEAP_WHITELIST_IPS env var is empty (format: name1=ip1,name2=ip2)');
if (!fs.existsSync(SESSION_FILE)) fail(`session file not found at ${SESSION_FILE} — run enable-api.js first`);

fs.mkdirSync(SHOTS_DIR, { recursive: true });
async function shot(page, name) {
  const file = path.join(SHOTS_DIR, `${Date.now()}-${name}.png`);
  try { await page.screenshot({ path: file, fullPage: true }); log(`shot: ${path.basename(file)}`); }
  catch (e) { log(`shot failed (${name}): ${e.message}`); }
}

(async () => {
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 900 },
    userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    storageState: SESSION_FILE,
  });
  const page = await context.newPage();

  log(`Loading ${API_PAGE} ...`);
  await page.goto(API_PAGE, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(3000);
  await shot(page, 'api-page');

  if (/\/login|\/twofa/i.test(page.url())) {
    fail(`session expired — landed at ${page.url()}; re-run enable-api.js to refresh .session.json`);
  }

  // Find currently-whitelisted IPs and the add control.
  const existing = await page.evaluate(() => {
    // Heuristic: IP-like text on the page
    const ipRe = /\b(\d{1,3}\.){3}\d{1,3}\b/g;
    const text = document.body.innerText;
    const found = [];
    let m;
    while ((m = ipRe.exec(text)) !== null) found.push(m[0]);
    return [...new Set(found)];
  });
  log(`IPs already visible on page: ${JSON.stringify(existing)}`);

  // Probe inputs to find the whitelist add field.
  const inputs = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('input,textarea')).map(i => ({
      tag: i.tagName, type: i.type || '', name: i.name, id: i.id,
      placeholder: i.placeholder || '', visible: !!(i.offsetWidth || i.offsetHeight),
    }));
  });
  log(`inputs on page: ${JSON.stringify(inputs).slice(0, 800)}`);

  // Find buttons too
  const buttons = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('button, input[type=submit], a[role=button]'))
      .filter(b => b.offsetWidth || b.offsetHeight)
      .map(b => ({ text: (b.innerText || b.value || '').trim().slice(0, 60), cls: b.className.slice(0, 60) }));
  });
  log(`visible buttons: ${JSON.stringify(buttons).slice(0, 800)}`);

  // Click the EDIT control next to "Whitelisted IPs" — Namecheap renders it
  // as a small button/link element, not always a <button>. Use text match.
  const editBtn = page.getByText(/^edit$/i).first();
  if (await editBtn.count() > 0) {
    log('Clicking EDIT to open whitelist editor');
    await editBtn.click({ force: true }).catch(() => {});
    await page.waitForTimeout(2500);
    await shot(page, 'after-edit-click');
  } else {
    log('No EDIT control found near whitelist — see screenshots');
  }

  // The editor page has an "ADD IP" button that pops a modal with 3 fields:
  // IP Name (label), IP Address, Namecheap Password. Then Save Changes.
  for (const { name, ip } of IPS) {
    const tag = `${name}_${ip.replace(/\./g, '_')}`;
    log(`Adding ${name}=${ip}`);
    const addIpBtn = page.getByText(/^add ip$/i).first();
    if (await addIpBtn.count() === 0) {
      await shot(page, `no-add-ip-btn-${tag}`);
      log(`ADD IP button not found`);
      break;
    }
    await addIpBtn.click({ force: true });
    await page.waitForTimeout(1500);
    await shot(page, `modal-open-${tag}`);

    // Field 1: IP Name (label). Try by label text first, fall back to first visible text input
    const nameInput = page.getByLabel(/IP\s*Name/i).first();
    let nameTarget = null;
    if (await nameInput.count() > 0 && await nameInput.isVisible().catch(() => false)) {
      nameTarget = nameInput;
    } else {
      // First visible text input in the modal
      const ti = page.locator('input[type="text"]:visible').first();
      if (await ti.count() > 0) nameTarget = ti;
    }
    if (!nameTarget) { await shot(page, `no-name-${tag}`); log('no IP Name input'); break; }
    await nameTarget.fill(name);

    // Field 2: IP Address
    const ipInput = page.getByLabel(/IP\s*Address/i).first();
    let ipTarget = null;
    if (await ipInput.count() > 0 && await ipInput.isVisible().catch(() => false)) {
      ipTarget = ipInput;
    } else {
      // Second visible text input
      const inputs = await page.locator('input[type="text"]:visible').all();
      if (inputs.length >= 2) ipTarget = inputs[1];
    }
    if (!ipTarget) { await shot(page, `no-ip-${tag}`); log('no IP Address input'); break; }
    await ipTarget.fill(ip);

    // Field 3: Namecheap Password
    const pwInput = page.locator('input[type="password"]:visible').first();
    if (await pwInput.count() === 0) { await shot(page, `no-pw-${tag}`); log('no password input'); break; }
    await pwInput.fill(PASS);

    await shot(page, `modal-filled-${tag}`);

    // Click Save Changes
    const saveBtn = page.locator('button:has-text("Save Changes")').filter({ visible: true }).first();
    if (await saveBtn.count() === 0) { await shot(page, `no-save-${tag}`); log('no Save Changes button'); break; }
    await saveBtn.click({ force: true });
    await page.waitForTimeout(4000);
    await shot(page, `after-add-${tag}`);

    // Check for validation error / persistence
    const err = await page.locator('[class*="error"]:visible, [class*="alert"]:visible').count().catch(() => 0);
    if (err > 0) {
      const errText = await page.locator('[class*="error"]:visible, [class*="alert"]:visible').first().textContent().catch(() => '');
      log(`possible error after save: "${errText.trim().slice(0, 200)}"`);
    }
  }

  // Click Done to exit the editor
  const doneBtn = page.locator('button:has-text("Done")').filter({ visible: true }).first();
  if (await doneBtn.count() > 0) {
    log('Clicking Done');
    await doneBtn.click({ force: true }).catch(() => {});
    await page.waitForTimeout(2000);
    await shot(page, 'after-done');
  }

  // Refresh and report what's there now
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2500);
  const after = await page.evaluate(() => {
    const ipRe = /\b(\d{1,3}\.){3}\d{1,3}\b/g;
    const text = document.body.innerText;
    const found = [];
    let m;
    while ((m = ipRe.exec(text)) !== null) found.push(m[0]);
    return [...new Set(found)];
  });
  log(`IPs visible after save: ${JSON.stringify(after)}`);

  await context.storageState({ path: SESSION_FILE });
  await browser.close();
  log('Done.');
})().catch(err => { console.error('[whitelist]', err); process.exit(1); });
