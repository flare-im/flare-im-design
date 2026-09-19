import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {resolve} from 'node:path';
import {mkdir,writeFile} from 'node:fs/promises';
const [site='http://127.0.0.1:5189',pkg]=process.argv.slice(2);
const {chromium,expect}=createRequire(resolve(pkg))('@playwright/test');
// Preview startup is asynchronous in CI; bound readiness instead of a fixed sleep.
let ready=false;
for(let attempt=0;attempt<60;attempt++){
 try{const response=await fetch(site,{signal:AbortSignal.timeout(1000)});if(response.ok){ready=true;break;}}catch{}
 await new Promise(resolve=>setTimeout(resolve,500));
}
assert(ready,`Documentation preview did not become ready: ${site}`);
const browser=await chromium.launch();const out=resolve('docs/ui-review-20260909/scenes');await mkdir(out,{recursive:true});const checks=[];
try{for(const width of [320,1280])for(const theme of ['light','dark'])for(const slug of ['member-panel','device-sessions','media-center','notification-preferences','capability-boundary','danger-confirm']){
 const page=await browser.newPage({viewport:{width,height:1000},colorScheme:theme});const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(`${site}/components/${slug}`);await page.evaluate(v=>document.documentElement.classList.toggle('dark',v),theme==='dark');const demo=page.locator('.scene-demo');await expect(demo).toBeVisible();
 if(slug==='device-sessions'){await expect(demo.getByRole('button',{name:'退出登录',exact:true})).toHaveCount(1);await demo.getByRole('button',{name:'退出登录',exact:true}).click();await expect(page.getByRole('dialog')).toBeVisible();await page.getByRole('button',{name:'取消',exact:true}).click();await expect(demo.getByText(/取消 1 次/)).toBeVisible();}
 if(slug==='member-panel'||slug==='device-sessions'){await demo.getByRole('button',{name:'部分操作失败',exact:true}).click();await expect(demo.getByRole('alert')).toContainText('可单独重试');}
 if(slug==='media-center'){await expect(demo.getByRole('button',{name:'打开文件'})).toHaveCount(0);await demo.getByRole('button',{name:'重新获取',exact:true}).click();await expect(demo.getByText(/expired\/refresh/)).toBeVisible();}
 if(slug==='notification-preferences'){await demo.getByLabel('场景状态').selectOption('denied');await expect(demo.getByRole('switch')).toBeDisabled();await demo.getByLabel('场景状态').selectOption('available');await demo.getByRole('switch').uncheck();await expect(demo.getByText(/preview\/false/)).toBeVisible();}
 if(slug==='capability-boundary'){await demo.getByRole('button',{name:'插件渲染失败'}).click();await expect(demo.getByText(/插件错误已隔离/)).toBeVisible();await expect(demo.getByText('基础聊天始终可用')).toBeVisible();await expect(demo.getByText('可选插件内容')).toHaveCount(0);await demo.getByRole('button',{name:'恢复能力'}).click();await expect(demo.getByText('可选插件内容')).toBeVisible();}
 if(slug==='danger-confirm'){await demo.getByRole('button',{name:'打开确认'}).click();const dialog=page.getByRole('dialog');await expect(dialog).toBeVisible();await page.getByRole('button',{name:'确认移除',exact:true}).click();await expect(page.getByRole('button',{name:'取消',exact:true})).toBeDisabled();await page.keyboard.press('Escape');await expect(dialog).toBeVisible();await expect(page.getByRole('button',{name:'确认移除',exact:true})).toBeDisabled();await dialog.screenshot({path:resolve(out,`${slug}-${width}-${theme}.png`)});}
 else await demo.screenshot({style:'.VPNav,.VPLocalNav{visibility:hidden!important}',path:resolve(out,`${slug}-${width}-${theme}.png`)});
 const overflow=await demo.evaluate(el=>el.scrollWidth>el.clientWidth+1);assert(!overflow,slug+' overflow');assert.deepEqual(errors,[]);checks.push({slug,width,theme,passed:true});await page.close();
}await writeFile(resolve(out,'checks.json'),JSON.stringify(checks,null,2));console.log('PASS: 24 scene viewport/theme checks, current session guard, expired media recovery, permission gate, plugin exception isolation, busy confirmation');}finally{await browser.close();}
