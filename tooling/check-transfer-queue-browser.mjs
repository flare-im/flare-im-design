import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {resolve} from 'node:path';
import {mkdir,writeFile} from 'node:fs/promises';
const [site='http://127.0.0.1:5189',pkg]=process.argv.slice(2);
const {chromium,expect}=createRequire(resolve(pkg))('@playwright/test');
const browser=await chromium.launch();
const out=resolve('docs/ui-review-20260909/queue');await mkdir(out,{recursive:true});const checks=[];
try {
 for(const width of [320,390,1280]) for(const theme of ['light','dark']) {
  const page=await browser.newPage({viewport:{width,height:1000},colorScheme:theme});
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto(`${site}/components/transfer-queue`);
  await page.evaluate(v=>document.documentElement.classList.toggle('dark',v),theme==='dark');
  const demo=page.locator('.queue-demo'),queue=demo.locator('.flare-transfer-queue');
  await expect(queue).toBeVisible();
  await queue.getByRole('button',{name:'重试失败任务 (2)',exact:true}).click();
  await expect(demo.getByText(/批量重试：a,b/)).toBeVisible();
  await expect(queue.getByRole('button',{name:/重试失败任务/})).toHaveCount(0);
  await expect(queue.getByRole('button',{name:'重试',exact:true}).first()).toBeDisabled();
  await demo.getByRole('button',{name:'返回部分失败'}).click();
  await expect(queue.getByRole('button',{name:'重试失败任务 (1)',exact:true})).toBeVisible();
  await expect(queue.getByText('仍无法连接，请稍后重试')).toBeVisible();
  await expect(queue.getByText('已取消，保留记录')).toHaveCount(1);
  await demo.getByRole('button',{name:'模拟刷新失败'}).click();
  await expect(queue.getByText('队列刷新失败，已有任务保留')).toBeVisible();
  await expect(queue.getByText('产品设计交付说明.pdf')).toHaveCount(1);
  const geometry=await queue.evaluate(el=>({width:el.clientWidth,scroll:el.scrollWidth,heights:[...el.querySelectorAll('button')].map(b=>b.getBoundingClientRect().height)}));
  assert(geometry.scroll<=geometry.width+1);assert(geometry.heights.every(h=>h>=48));assert.deepEqual(errors,[]);
  await queue.screenshot({style:'.VPNav,.VPLocalNav { visibility:hidden!important; }',path:resolve(out,`${width}-${theme}.png`)});
  await demo.getByRole('button',{name:'空队列',exact:true}).click();
  await expect(queue.getByText('暂无传输任务')).toBeVisible();
  checks.push({width,theme,geometry,passed:true});await page.close();
 }
 await writeFile(resolve(out,'checks.json'),JSON.stringify(checks,null,2));
 console.log('PASS: six viewports/themes; capability-gated batch, busy lock, partial failure, cached refresh failure, empty queue, touch targets');
} finally {await browser.close();}
