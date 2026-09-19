import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { mkdirSync, writeFileSync } from 'node:fs';
const [site = 'http://127.0.0.1:5189', consumerPackage, outputDir] = process.argv.slice(2);
assert(consumerPackage, 'Pass site URL and package.json with @playwright/test');
const { chromium, expect } = createRequire(resolve(consumerPackage))('@playwright/test');
const browser = await chromium.launch();
const records = [];
try {
  for (const width of [320, 390, 1280]) for (const colorScheme of ['light', 'dark']) {
    const page = await browser.newPage({ viewport: { width, height: 1000 }, colorScheme, reducedMotion: 'reduce' });
    page.setDefaultTimeout(15000);
    await page.goto(`${site}/components/transfer-progress`);
    const card = page.locator('.flare-transfer');
    await expect(card).toBeVisible();
    const actions = { queued: ['取消'], transferring: ['暂停', '取消'], paused: ['继续传输', '取消'], failed: ['重新尝试'], completed: ['打开文件'], cancelled: ['重新尝试'] };
    for (const [state, labels] of Object.entries(actions)) {
      await page.getByLabel('传输状态').selectOption(state);
      await expect(card.locator('button')).toHaveText(labels);
      for (const button of await card.locator('button').all()) {
        assert((await button.boundingBox()).height >= 48, 'minimum touch area');
        await button.click();
        await expect(page.locator('.result')).toHaveText(`收到操作：${await button.innerText()}`);
      }
      const box = await card.boundingBox();
      assert(box.x >= 0 && box.x + box.width <= width, `${state} overflow at ${width}`);
    }
    await page.getByLabel('传输状态').selectOption('transferring');
    await page.getByLabel('未知进度').check();
    await expect(card.locator('progress')).not.toHaveAttribute('value');
    await page.getByLabel('未知进度').uncheck();
    await expect(card.locator('progress')).toHaveAttribute('value', '0.37');
    await page.getByLabel('传输状态').selectOption('failed');
    await page.getByLabel('操作处理中').check();
    await expect(card.locator('button')).toBeDisabled();
    const before = await page.locator('.result').innerText();
    await card.locator('button').dispatchEvent('click');
    await expect(page.locator('.result')).toHaveText(before);
    await page.getByLabel('操作处理中').uncheck();
    const bannerAction = page.locator('.flare-status-banner__action');
    assert((await bannerAction.boundingBox()).height >= 48);
    await bannerAction.click();
    await expect(page.locator('.result')).toHaveText('收到操作：检查连接');
    if (outputDir) {
      mkdirSync(outputDir, { recursive: true });
      await page.locator('.transfer-demo').screenshot({ path: resolve(outputDir, `transfer-${width}-${colorScheme}.png`) });
    }
    records.push({ width, colorScheme, states: Object.keys(actions), result: 'passed' });
    await page.close();
  }
  if (outputDir) writeFileSync(resolve(outputDir, 'transfer-browser-check.json'), JSON.stringify(records, null, 2));
  console.log(JSON.stringify(records, null, 2));
} finally { await browser.close(); }
