const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  const ctx = await b.newContext({
    userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
  });
  const page = await ctx.newPage();
  await page.goto('https://www.namecheap.com/myaccount/login.aspx', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2000);
  const html = await page.evaluate(() => {
    const inputs = Array.from(document.querySelectorAll('input'));
    return inputs.map(i => ({
      type: i.type, name: i.name, id: i.id, placeholder: i.placeholder, autocomplete: i.autocomplete,
    }));
  });
  console.log(JSON.stringify(html, null, 2));
  const buttons = await page.evaluate(() => {
    const btns = Array.from(document.querySelectorAll('button, input[type=submit]'));
    return btns.map(b => ({ tag: b.tagName, type: b.type, text: (b.innerText || b.value || '').slice(0, 50), id: b.id, name: b.name }));
  });
  console.log('BUTTONS:', JSON.stringify(buttons, null, 2));
  await b.close();
})();
