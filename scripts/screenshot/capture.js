import puppeteer from 'puppeteer';

(async () => {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 800 });
  
  const url = process.argv[2];
  const outPath = process.argv[3];
  
  if (!url || !outPath) {
    console.error('Usage: node capture.js <url> <outPath>');
    process.exit(1);
  }
  
  console.log(`Navigating to ${url}...`);
  await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
  
  // Wait 4 seconds for full rendering (including animations/Riverpod syncs)
  await new Promise(r => setTimeout(r, 4000));
  
  console.log(`Saving screenshot to ${outPath}...`);
  await page.screenshot({ path: outPath, fullPage: false });
  
  await browser.close();
  console.log('Done!');
})().catch(err => {
  console.error(err);
  process.exit(1);
});
