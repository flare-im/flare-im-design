#!/usr/bin/env node
// Build a real tarball in a standalone consumer with no IM SDK installed.
import {execFileSync} from 'node:child_process';
import {mkdtempSync,writeFileSync,readdirSync,existsSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname,join} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=join(dirname(fileURLToPath(import.meta.url)),'..');
const stage=mkdtempSync(join(tmpdir(),'flare-no-sdk-'));
const run=(cmd,args)=>execFileSync(cmd,args,{cwd:stage,stdio:'inherit'});
try {
  execFileSync('npm',['pack','--pack-destination',stage],{cwd:join(root,'vue-im-ui'),stdio:['ignore','pipe','pipe']});
  const tarball=readdirSync(stage).find(f=>f.endsWith('.tgz'));
  writeFileSync(join(stage,'package.json'),JSON.stringify({private:true,type:'module',dependencies:{
    '@flare-im/vue-ui':`file:./${tarball}`,vue:'^3.5.13','naive-ui':'^2.44.1','vue-router':'^4.6.0',
    vite:'^6.4.3','@vitejs/plugin-vue':'^6.0.7',
  }}));
  run('npm',['install','--no-audit','--no-fund']);
  if(existsSync(join(stage,'node_modules/@flare-im/sdk')))throw Error('SDK was unexpectedly installed');
  writeFileSync(join(stage,'index.html'),'<div id="app"></div><script type="module" src="/main.ts"></script>');
  writeFileSync(join(stage,'main.ts'),`import {createApp,h} from 'vue';
import {FlareMemberPanel,FlareMediaCenter,FlareDangerConfirm,FlareCapabilityBoundary} from '@flare-im/vue-ui';
createApp({render:()=>h('main',[h(FlareMemberPanel,{items:[]}),h(FlareMediaCenter,{items:[]}),h(FlareDangerConfirm,{open:false,title:'Delete',description:'Confirm',target:'Test'}),h(FlareCapabilityBoundary,{state:'unavailable',text:'Optional'})])}).mount('#app');`);
  writeFileSync(join(stage,'vite.config.mjs'),`import vue from '@vitejs/plugin-vue'; export default {plugins:[vue()]};`);
  run(join(stage,'node_modules/.bin/vite'),['build']);
  console.log('PASS: standalone tarball consumer built without @flare-im/sdk or workspace aliases');
}finally{rmSync(stage,{recursive:true,force:true});}
