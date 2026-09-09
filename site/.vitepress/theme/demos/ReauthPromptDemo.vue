<script setup>
import { ref } from 'vue';
import FlareReauthPrompt from '@flare-im/vue-ui/components/general/FlareReauthPrompt.vue';
import DemoStage from './DemoStage.vue';
const reasons=[['sessionExpired','会话过期'],['kicked','被踢下线'],['credentialInvalid','凭证失效'],['accountDisabled','账号停用']];
const reason=ref('kicked'), busy=ref(false), error=ref(), last=ref('尚未操作'), fail=ref(true);
let timer;
function reauthenticate(){
  if(busy.value) return;
  busy.value=true; last.value='已派发 reauthenticate；busy 由宿主同步置位';
  clearTimeout(timer);
  timer=setTimeout(()=>{ busy.value=false; error.value=fail.value?'服务器暂时不可用，请稍后重试':undefined; last.value=fail.value?'重新登录失败，原因保留在面板中':'重新登录成功（宿主此时应关闭容器）'; },1200);
}
function logout(){ last.value='已派发 logout；退出与切换账号由宿主执行'; }
function reset(){ clearTimeout(timer); busy.value=false; error.value=undefined; last.value='尚未操作'; }
</script>
<template><DemoStage><div class="reauth-demo">
 <FlareReauthPrompt :reason="reason" :busy="busy" :error="error" account-label="hugo@flare.im"
   :detail="reason==='kicked' ? 'iPad · 今天 10:24' : undefined" @reauthenticate="reauthenticate" @logout="logout" />
 <div class="controls" role="group" aria-label="演示控制">
  <button v-for="[value,label] in reasons" :key="value" :aria-pressed="reason===value" @click="reason=value;reset()">{{ label }}</button>
  <label><input v-model="fail" type="checkbox" /> 模拟重新登录失败</label>
  <button @click="reset">重置演示</button>
 </div>
 <p role="status">{{ last }}。本地模拟，不发起真实登录。</p>
</div></DemoStage></template>
<style scoped>
.reauth-demo {width:100%;min-width:0;display:grid;gap:16px;justify-items:center;}
.controls {display:flex;flex-wrap:wrap;gap:8px;align-items:center;justify-content:center;}
.controls button {min-height:48px;padding:8px 12px;border:1px solid var(--flare-color-border-primary);border-radius:8px;}
.controls button[aria-pressed="true"] {border-color:var(--flare-color-primary);color:var(--flare-color-primary);}
.controls label {display:inline-flex;align-items:center;gap:6px;min-height:48px;font-size:13px;}
p {font-size:13px;overflow-wrap:anywhere;}
</style>
