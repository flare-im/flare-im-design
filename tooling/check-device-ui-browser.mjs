// Run against `site npm run dev`; uses the consuming workspace's Playwright install.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
const [site = 'http://127.0.0.1:5189', consumerPackage] = process.argv.slice(2);
assert(consumerPackage, 'Pass site URL and absolute path to a package.json with @playwright/test installed');
const { chromium, expect } = createRequire(resolve(consumerPackage))('@playwright/test');
const browser = await chromium.launch();
try {
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 3 });
  page.setDefaultTimeout(10000);
  await page.goto(`${site}/components/mention-picker`);
  const picker = page.locator('.flare-mention');
  await expect(picker).toBeVisible();
  await picker.locator('input').fill('ivy');
  await expect(picker.locator('button')).toHaveCount(1);
  await picker.locator('input').press('ArrowDown');
  await expect(picker.locator('button')).toBeFocused();
  await picker.locator('button').press('Enter');
  await expect(page.getByText('已选择：ivy', { exact: true })).toBeVisible();
  await picker.locator('button').press('Escape');
  await expect(page.getByText('选择器已关闭', { exact: true })).toBeVisible();
  await picker.locator('input').fill('');
  const box = await picker.boundingBox();
  assert(box.x >= 0 && box.x + box.width <= 390, 'mobile picker fits');
  for (const button of await picker.locator('button').all()) assert((await button.boundingBox()).height >= 48);
  await page.setViewportSize({ width: 1600, height: 1000 });
  await page.goto(`${site}/components/responsive-layout`);
  await page.getByRole('button', { name: '详情', exact: true }).click();
  await expect(page.locator('.flare-rl--single')).toBeVisible();
  await expect(page.locator('.flare-rl').getByText('会话详情')).toBeVisible();
  await page.locator('.flare-rl__back').click();
  await expect(page.locator('.flare-rl').getByText('聊天窗口')).toBeVisible();
  // Change the mounted component's containing element, without resizing the window.
  await page.locator('.stage').evaluate(e => { e.style.width = '1102px'; e.style.maxWidth = 'none'; });
  await expect(page.locator('.flare-rl__detail')).toBeVisible();
  await page.locator('.stage').evaluate(e => { e.style.width = '800px'; });
  await page.getByRole('button', { name: '详情', exact: true }).click();
  await expect(page.locator('.flare-rl__chat').getByText('会话详情')).toBeVisible();
  await page.locator('.controls select').selectOption('2');
  await expect(page.locator('.flare-rl--single')).toBeVisible();
  console.log('PASS: mobile mention search/keyboard/Escape/48px targets; container resize, details, large text');
} finally { await browser.close(); }
