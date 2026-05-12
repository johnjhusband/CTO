// Namecheap API enablement via Playwright (headless).
//
// Credentials come from env vars NAMECHEAP_USER / NAMECHEAP_PASS — never
// hard-coded. 2FA code is read from a file (code.txt) that the operator
// writes when the email-based device-verification code arrives. After
// successful 2FA, the browser session state is saved to .session.json so
// future runs skip login + 2FA entirely.
//
// Flow:
//   1. If .session.json exists: try API page directly; skip login if valid
//   2. Otherwise: POST login form, then wait for 2FA code in code.txt
//   3. Navigate to API Access page, toggle ON, Save
//   4. Capture API Username + Key, write to namecheap-api.local.env
//   5. Persist session for next run

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const LOGIN_URL = 'https://www.namecheap.com/myaccount/login.aspx';
const API_PAGE = 'https://ap.www.namecheap.com/Profile/Tools/ApiAccess';
const OUT_FILE = path.join(__dirname, 'namecheap-api.local.env');
const SHOTS_DIR = path.join(__dirname, 'shots');
const SESSION_FILE = path.join(__dirname, '.session.json');
const CODE_FILE = path.join(__dirname, 'code.txt');

const STEP_TIMEOUT_MS = 60 * 1000;
const POLL_INTERVAL_MS = 1500;
const POST_LOGIN_WAIT_MS = 60 * 1000;
const CODE_WAIT_MS = 15 * 60 * 1000;

const USER = process.env.NAMECHEAP_USER;
const PASS = process.env.NAMECHEAP_PASS;

function log(msg) { console.log(`[namecheap] ${msg}`); }
function fail(msg, code = 1) { log(`FAIL: ${msg}`); process.exit(code); }

if (!USER || !PASS) {
  fail('NAMECHEAP_USER and NAMECHEAP_PASS env vars are required');
}

fs.mkdirSync(SHOTS_DIR, { recursive: true });

async function shot(page, name) {
  const file = path.join(SHOTS_DIR, `${Date.now()}-${name}.png`);
  try { await page.screenshot({ path: file, fullPage: true }); log(`shot: ${path.basename(file)}`); }
  catch (e) { log(`shot failed (${name}): ${e.message}`); }
}

async function pickVisible(locator, name, page) {
  const count = await locator.count();
  for (let i = 0; i < count; i++) {
    const el = locator.nth(i);
    if (await el.isVisible().catch(() => false)) return el;
  }
  await shot(page, `${name}-not-visible`);
  fail(`no visible ${name} input found (had ${count} candidates)`);
}

async function waitForCode() {
  if (fs.existsSync(CODE_FILE)) {
    try { fs.unlinkSync(CODE_FILE); } catch {}
  }
  log(`Waiting up to ${CODE_WAIT_MS / 60000} min for 2FA code in ${CODE_FILE}`);
  const start = Date.now();
  while (Date.now() - start < CODE_WAIT_MS) {
    if (fs.existsSync(CODE_FILE)) {
      const raw = fs.readFileSync(CODE_FILE, 'utf8').trim();
      try { fs.unlinkSync(CODE_FILE); } catch {}
      const cleaned = raw.replace(/[^A-Za-z0-9]/g, '');
      if (/^[A-Za-z0-9]{4,8}$/.test(cleaned)) return cleaned;
      log(`code file content "${raw}" is not a valid code; ignoring and waiting`);
    }
    await new Promise(r => setTimeout(r, 2000));
  }
  fail('timed out waiting for 2FA code');
}

async function doLogin(page) {
  log('Loading login page.');
  await page.goto(LOGIN_URL, { waitUntil: 'domcontentloaded' });
  await shot(page, 'login-page');

  const userCandidates = page.locator('input[name="LoginUserName"]');
  const passCandidates = page.locator('input[name="LoginPassword"], input[type="password"]');
  await userCandidates.first().waitFor({ state: 'attached', timeout: STEP_TIMEOUT_MS }).catch(() => {});
  const userInput = await pickVisible(userCandidates, 'username', page);
  const passInput = await pickVisible(passCandidates, 'password', page);

  await userInput.fill(USER);
  await passInput.fill(PASS);
  const filledUser = await userInput.inputValue();
  const filledPassLen = (await passInput.inputValue()).length;
  log(`filled username=${filledUser}  password length=${filledPassLen}`);
  await shot(page, 'login-filled');

  log(`URL before submit: ${page.url()}`);
  await passInput.press('Enter');
  await page.waitForLoadState('domcontentloaded').catch(() => {});
  await page.waitForTimeout(4000);
  log(`URL after submit: ${page.url()}`);
  await shot(page, 'after-submit');

  // Wrong-creds check: look for visible validation error in the page
  const errCount = await page.locator(
    '.field-validation-error:visible, [class*="error"]:visible:has-text("incorrect"), ' +
    '[class*="error"]:visible:has-text("invalid"), [class*="error"]:visible:has-text("does not match")'
  ).count().catch(() => 0);
  if (errCount > 0) {
    await shot(page, 'login-rejected');
    fail('login rejected (incorrect credentials) — see screenshot');
  }

  // 2FA handling
  if (/\/twofa\//i.test(page.url())) {
    await handle2FA(page);
  }

  // CAPTCHA check
  const captcha = await page.locator('iframe[src*="recaptcha"], iframe[title*="recaptcha" i]').count();
  if (captcha > 0) {
    await shot(page, 'captcha-required');
    fail('CAPTCHA challenge presented');
  }

  // Final post-login URL check
  log(`Waiting for post-login app URL...`);
  try {
    await page.waitForURL((url) => {
      const u = url.toString();
      if (/\/login|\/twofa/i.test(u)) return false;
      return /ap\.www\.namecheap\.com|\/dashboard|\/myaccount\/(?!login)/i.test(u);
    }, { timeout: POST_LOGIN_WAIT_MS });
  } catch {
    await shot(page, 'post-login-timeout');
    fail(`post-login redirect did not happen; landed at ${page.url()}`);
  }
  log(`Logged in. Current URL: ${page.url()}`);
  await shot(page, 'logged-in');
}

async function handle2FA(page) {
  log(`2FA challenge at ${page.url()}`);
  await shot(page, '2fa-prompt');

  // Dump every input attribute on the 2FA page so future failures show what to match.
  try {
    const inputs = await page.evaluate(() => {
      return Array.from(document.querySelectorAll('input, textarea')).map(i => ({
        tag: i.tagName, type: i.type, name: i.name, id: i.id,
        placeholder: i.placeholder, autocomplete: i.autocomplete, maxLength: i.maxLength,
        visible: !!(i.offsetWidth || i.offsetHeight),
      }));
    });
    log(`2FA page inputs: ${JSON.stringify(inputs)}`);
  } catch {}

  const code = await waitForCode();
  log(`Got code (${code.length} chars). Filling in.`);

  // Try several locator strategies. Pick the first visible match.
  const candidates = [
    page.getByPlaceholder(/verification/i),
    page.getByPlaceholder(/enter the code/i),
    page.getByLabel(/verification\s*code/i),
    page.locator('input[name*="verification" i]'),
    page.locator('input[name*="code" i]'),
    page.locator('input[name*="otp" i]'),
    page.locator('input[autocomplete="one-time-code"]'),
    page.locator('input[type="tel"]'),
    page.locator('input[maxlength="6"], input[maxlength="7"], input[maxlength="8"]'),
    // Last-resort: any visible text input that isn't disabled/readonly
    page.locator('input[type="text"]:not([disabled]):not([readonly])'),
  ];
  let codeInput = null;
  for (const cand of candidates) {
    const count = await cand.count();
    for (let i = 0; i < count; i++) {
      const el = cand.nth(i);
      if (await el.isVisible().catch(() => false)) {
        const isReadonly = await el.evaluate(e => e.readOnly || e.disabled).catch(() => true);
        if (!isReadonly) { codeInput = el; break; }
      }
    }
    if (codeInput) break;
  }
  if (!codeInput) {
    await shot(page, '2fa-no-input-found');
    fail('could not find a visible verification-code input on the 2FA page');
  }
  await codeInput.fill(code);
  await shot(page, '2fa-filled');

  const submit = page.locator('button:has-text("Submit"), button[type=submit], input[type=submit]').first();
  if (await submit.count() > 0 && await submit.isVisible().catch(() => false)) {
    await submit.click().catch(async () => { await codeInput.press('Enter'); });
  } else {
    await codeInput.press('Enter');
  }
  await page.waitForLoadState('domcontentloaded').catch(() => {});
  await page.waitForTimeout(4000);
  await shot(page, 'after-2fa');
  log(`URL after 2FA: ${page.url()}`);
  if (/\/twofa\//i.test(page.url()) || /\/login/i.test(page.url())) {
    fail('still on 2FA/login page after submitting code — code wrong/expired');
  }
}

async function captureCredentials(page) {
  log('Navigating to API Access page.');
  await page.goto(API_PAGE, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(3000);
  await shot(page, 'api-access-page');

  const apiBody = await page.evaluate(() => document.body.innerText).catch(() => '');
  if (/not\s+eligible|do\s+not\s+qualify|insufficient/i.test(apiBody)) {
    await shot(page, 'eligibility-blocked');
    fail('API access eligibility check failed — account does not qualify');
  }

  // Toggle API on if it isn't already
  const toggle = page.locator(
    'input[type="checkbox"][name*="API" i], input[type="checkbox"][id*="api" i], ' +
    'button[role="switch"], label:has-text("API Access") input, label:has-text("Enabled") input'
  ).first();
  let toggleClicked = false;
  try {
    await toggle.waitFor({ state: 'attached', timeout: 8000 });
    const isChecked = await toggle.isChecked().catch(() => null);
    const ariaChecked = await toggle.getAttribute('aria-checked').catch(() => null);
    log(`toggle state: checked=${isChecked} aria-checked=${ariaChecked}`);
    if (isChecked === false || ariaChecked === 'false') {
      log('Toggling API ON.');
      await toggle.click({ force: true });
      toggleClicked = true;
      await page.waitForTimeout(1500);
      await shot(page, 'after-toggle');
    }
  } catch (e) {
    log(`could not find toggle (page may already show key): ${e.message}`);
  }

  // After toggle click, Namecheap pops a "Turn ON API Access" modal that
  // requires re-entering the account password. We scope all modal interactions
  // to elements inside the modal container so we don't accidentally re-click
  // the toggle (which is also a checkbox elsewhere on the page).
  if (toggleClicked) {
    const modalPwd = page.locator('input[type="password"]').filter({ visible: true }).first();
    const modalVisible = await modalPwd.count() > 0 && await modalPwd.isVisible().catch(() => false);
    if (modalVisible) {
      log('Confirmation modal appeared — filling password.');

      // Dump modal DOM for diagnostics
      try {
        const modalInfo = await modalPwd.evaluate((pwd) => {
          // Walk up to find the modal container
          let modal = pwd;
          while (modal && modal.tagName !== 'BODY') {
            if (/modal|dialog|popup/i.test(modal.className || '')
                || modal.getAttribute('role') === 'dialog') break;
            modal = modal.parentElement;
          }
          if (!modal || modal.tagName === 'BODY') modal = pwd.parentElement.parentElement.parentElement;
          const buttons = Array.from(modal.querySelectorAll('button, input[type=submit], a[role=button]')).map(b => ({
            tag: b.tagName, type: b.type, text: (b.innerText || b.value || '').trim().slice(0, 80),
            cls: b.className.slice(0, 80),
          }));
          const checkboxes = Array.from(modal.querySelectorAll('input[type=checkbox]')).map(c => ({
            name: c.name, id: c.id, checked: c.checked, visible: !!(c.offsetWidth || c.offsetHeight),
          }));
          return { containerClass: modal.className.slice(0, 100), buttons, checkboxes };
        });
        log(`modal container class: ${modalInfo.containerClass}`);
        log(`modal buttons: ${JSON.stringify(modalInfo.buttons)}`);
        log(`modal checkboxes: ${JSON.stringify(modalInfo.checkboxes)}`);
      } catch (e) { log(`modal probe failed: ${e.message}`); }

      await modalPwd.fill(PASS);
      await shot(page, 'modal-filled');

      // Resolve a modal-scoped Confirm button. Walk up from the password
      // field to the modal container, then search inside it only.
      const confirmClicked = await modalPwd.evaluate((pwd) => {
        let modal = pwd;
        while (modal && modal.tagName !== 'BODY') {
          if (/modal|dialog|popup/i.test(modal.className || '')
              || modal.getAttribute('role') === 'dialog') break;
          modal = modal.parentElement;
        }
        if (!modal || modal.tagName === 'BODY') modal = pwd.parentElement.parentElement.parentElement;
        const buttons = Array.from(modal.querySelectorAll('button, input[type=submit], a[role=button]'));
        for (const b of buttons) {
          const t = (b.innerText || b.value || '').trim().toLowerCase();
          if (/^(confirm|turn on|enable|ok|submit|yes)\b/.test(t) && !/cancel|close/.test(t)) {
            b.click();
            return t;
          }
        }
        return null;
      });
      if (confirmClicked) {
        log(`Clicked modal button: "${confirmClicked}"`);
      } else {
        log('No Confirm-equivalent button found in modal; pressing Enter on password.');
        await modalPwd.press('Enter').catch(() => {});
      }
      await page.waitForTimeout(5000);
      await shot(page, 'after-confirm');

      // Check for modal errors (wrong password etc.)
      const modalErr = await page.locator(
        '[class*="error"]:visible:has-text("incorrect"), ' +
        '[class*="error"]:visible:has-text("invalid"), ' +
        '[class*="error"]:visible:has-text("password")'
      ).count().catch(() => 0);
      if (modalErr > 0) {
        await shot(page, 'modal-rejected');
        fail('confirmation modal rejected the password — see screenshot');
      }
    } else {
      log('No confirmation modal detected after toggle.');
    }
  }

  const saveBtn = page.locator(
    'button:has-text("Save Changes"), button:has-text("Save"), button:has-text("Apply")'
  ).first();
  if (await saveBtn.count() > 0 && await saveBtn.isVisible().catch(() => false)) {
    log('Clicking Save.');
    await saveBtn.click().catch(() => {});
    await page.waitForTimeout(2500);
    await shot(page, 'after-save');
  }

  log('Polling for API Key on the page (username = account login).');
  const startTime = Date.now();
  let apiUser = null;
  let apiKey = null;

  while (Date.now() - startTime < 30 * 1000) {
    const bodyText = await page.evaluate(() => document.body.innerText).catch(() => '');
    const userMatch = bodyText.match(/API\s+Username[\s:\n]+([A-Za-z0-9_-]{3,})/i);
    // Broaden to mixed-case alphanumeric (Namecheap may use it)
    const keyMatch = bodyText.match(/API\s+Key[\s:\n]+([A-Za-z0-9]{20,})/);
    if (userMatch) apiUser = userMatch[1];
    if (keyMatch) apiKey = keyMatch[1];

    // Search ALL text-ish inputs for a long alphanumeric value (the key
    // is often rendered in a disabled/readonly input).
    if (!apiKey) {
      const inputs = await page.locator('input').all();
      for (const inp of inputs) {
        const v = await inp.inputValue().catch(() => '');
        if (/^[A-Za-z0-9]{28,64}$/.test(v) && !/\s/.test(v)) {
          // Skip if it looks like our user's password or other known values
          if (v === PASS || v === USER) continue;
          apiKey = v;
          break;
        }
      }
    }
    if (apiKey) break;
    await page.waitForTimeout(POLL_INTERVAL_MS);
  }

  if (!apiKey) {
    await shot(page, 'no-credentials-found');
    // Dump what's on the page so we have data for the next iteration
    try {
      const dump = await page.evaluate(() => {
        const allInputs = Array.from(document.querySelectorAll('input')).map(i => ({
          type: i.type, name: i.name, id: i.id,
          value: i.value ? i.value.slice(0, 50) : '',
          readonly: i.readOnly, disabled: i.disabled,
          visible: !!(i.offsetWidth || i.offsetHeight),
        }));
        const headers = Array.from(document.querySelectorAll('h1,h2,h3,h4,label,strong,b'))
          .map(h => (h.innerText || '').trim()).filter(t => t && t.length < 60);
        return { inputs: allInputs, headers };
      });
      log(`page inputs after-confirm: ${JSON.stringify(dump.inputs)}`);
      log(`page headers: ${JSON.stringify(dump.headers)}`);
    } catch (e) { log(`dump failed: ${e.message}`); }
    fail('could not extract API credentials from page — see screenshots');
  }
  if (!apiUser) {
    apiUser = USER;
    log(`username not extracted, falling back to login username: ${apiUser}`);
  }

  const masked = apiKey.slice(0, 4) + '*'.repeat(Math.max(0, apiKey.length - 8)) + apiKey.slice(-4);
  log(`Captured: username=${apiUser}  key=${masked}`);

  let laptopIp = null;
  try {
    const resp = await page.goto('https://api.ipify.org', { timeout: 10000 });
    if (resp && resp.ok()) laptopIp = (await resp.text()).trim();
  } catch {}
  log(`Laptop public IP (for whitelist): ${laptopIp || 'unknown'}`);

  fs.writeFileSync(OUT_FILE,
    `# Namecheap API credentials — captured ${new Date().toISOString()}\n` +
    `# DO NOT COMMIT — gitignored by *.env\n` +
    `NAMECHEAP_API_USER="${apiUser}"\n` +
    `NAMECHEAP_API_KEY="${apiKey}"\n` +
    (laptopIp ? `LAPTOP_IP="${laptopIp}"\n` : '') +
    `# CTO_V1_IP="46.224.81.84"\n`
  );
  fs.chmodSync(OUT_FILE, 0o600);
  log(`Saved to ${OUT_FILE} (mode 600).`);
}

async function persistSession(context) {
  await context.storageState({ path: SESSION_FILE });
  fs.chmodSync(SESSION_FILE, 0o600);
  log(`Session persisted to ${SESSION_FILE} (mode 600).`);
}

(async () => {
  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-blink-features=AutomationControlled'],
  });

  const ctxOpts = {
    viewport: { width: 1280, height: 900 },
    userAgent:
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 ' +
      '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
  };
  let usingSession = false;
  if (fs.existsSync(SESSION_FILE)) {
    ctxOpts.storageState = SESSION_FILE;
    usingSession = true;
    log(`Using saved session from ${SESSION_FILE}`);
  }
  const context = await browser.newContext(ctxOpts);
  const page = await context.newPage();

  let needLogin = true;
  if (usingSession) {
    await page.goto(API_PAGE, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(2500);
    const url = page.url();
    log(`API page URL with saved session: ${url}`);
    if (!/\/login|\/twofa/i.test(url) && /namecheap\.com/i.test(url)) {
      log('Saved session is valid — skipping login.');
      needLogin = false;
    } else {
      log('Saved session expired — falling back to login flow.');
    }
  }

  if (needLogin) {
    await doLogin(page);
    // Persist session immediately after login+2FA succeed, BEFORE attempting
    // credential capture — so a downstream failure doesn't cost us another
    // 2FA round-trip on re-run.
    await persistSession(context);
  }

  await captureCredentials(page);
  // Re-persist after credential capture in case the toggle action added new cookies.
  await persistSession(context);
  await browser.close();
  log('Done.');
})().catch((err) => {
  console.error('[namecheap] Unhandled error:', err);
  process.exit(1);
});
