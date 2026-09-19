import {spawnSync} from 'node:child_process';
import {dirname,join} from 'node:path';
import {fileURLToPath} from 'node:url';
const directory=dirname(fileURLToPath(import.meta.url));
const args=process.argv.slice(2);
const failures=[];
for(const name of ['scene-panels','call-recovery','device-ui','transfer-ui','transfer-queue','search-panel','timeline-recovery']) {
  const result=spawnSync(process.execPath,[join(directory,`check-${name}-browser.mjs`),...args],{stdio:'inherit'});
  if(result.error||result.status!==0) failures.push(name);
}
if(failures.length){console.error('IM browser checks failed:',failures.join(', '));process.exitCode=1;}
else console.log('PASS: all 7 IM browser suites');
