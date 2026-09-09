<script setup>
import {ref,computed,defineComponent,h} from 'vue';
import FlareMemberPanel from '@flare-im/vue-ui/components/scenes/FlareMemberPanel.vue';
import FlareDeviceSessions from '@flare-im/vue-ui/components/scenes/FlareDeviceSessions.vue';
import FlareMediaCenter from '@flare-im/vue-ui/components/scenes/FlareMediaCenter.vue';
import FlareNotificationPreferences from '@flare-im/vue-ui/components/scenes/FlareNotificationPreferences.vue';
import FlareCapabilityBoundary from '@flare-im/vue-ui/components/scenes/FlareCapabilityBoundary.vue';
import FlareDangerConfirm from '@flare-im/vue-ui/components/scenes/FlareDangerConfirm.vue';
import DemoStage from './DemoStage.vue';
const props=defineProps({mode:{type:String,default:'MemberPanel'}});
const state=ref('available'),busy=ref(false),error=ref(),last=ref('尚未操作'),open=ref(false),confirmed=ref(0),cancelled=ref(0),crash=ref(false),generation=ref(0);
const toggle=ref(true), partial=ref(false);
const members=computed(()=>state.value==='empty'?[]:[{id:'owner',title:'林川',badge:'群主',detail:'团队创建者',actions:[]},{id:'member',title:'超长成员名称与权限说明',badge:'成员',error:partial.value?'该成员操作失败，可单独重试':undefined,detail:'仅显示当前账号有权执行的操作',busy:busy.value,actions:[{id:'remove',label:'移出群聊',destructive:true}]}]);
const devices=computed(()=>[{id:'current',title:'本机',detail:'正在使用的会话',current:true,actions:[{id:'revoke',label:'退出登录',destructive:true}]},{id:'other',title:'另一台设备',detail:'最近活跃 · 由宿主提供',current:false,error:partial.value?'该设备退出失败，可单独重试':undefined,busy:busy.value,actions:[{id:'revoke',label:'退出登录',destructive:true}]}]);
const media=[{id:'expired',title:'项目交付设计.pdf',detail:'授权地址已过期，请重新获取',kind:'file',availability:'expired',actions:[{id:'open',label:'打开文件'},{id:'refresh',label:'重新获取'}]}];
const prefs=computed(()=>[{id:'preview',title:'显示消息预览',detail:'在通知中显示消息内容',value:toggle.value,enabled:true,busy:busy.value}]);
function action(v){last.value=v.id+'/'+v.action;if(v.action==='remove'||v.action==='revoke')open.value=true;}
function confirm(){confirmed.value++;busy.value=true;last.value='已提交确认 '+confirmed.value+' 次';}
function fail(){error.value='操作未完成，请重试';busy.value=false;}
const Plugin=defineComponent({setup(){return()=>{if(crash.value)throw Error('simulated plugin render failure');return h('div','可选插件内容');};}});
</script>
<template><DemoStage><div class="scene-demo" :data-mode="mode">
 <div class="controls"><label>状态 <select v-model="state" aria-label="场景状态"><option v-for="s in ['available','loading','unavailable','denied','failed','empty']" :key="s">{{ s }}</option></select></label><label><input v-model="busy" type="checkbox" /> 处理中</label><button @click="fail">模拟失败</button><button v-if="mode==='MemberPanel'||mode==='DeviceSessions'" @click="partial=!partial">部分操作失败</button></div>
 <FlareMemberPanel v-if="mode==='MemberPanel'" :items="members" :loading="state==='loading'" :error="error" @action="action" @reload="last='重新加载'" />
 <FlareDeviceSessions v-if="mode==='DeviceSessions'" :items="devices" :loading="state==='loading'" :error="error" @action="action" />
 <FlareMediaCenter v-if="mode==='MediaCenter'" :items="media" :error="error" @action="action" />
 <FlareNotificationPreferences v-if="mode==='NotificationPreferences'" :items="prefs" :permission="state==='empty'?'unavailable':state" permission-text="系统通知权限由宿主提供" permission-action-text="打开系统设置" @change="toggle=$event.value;last=$event.id+'/'+$event.value" @permission-action="last='打开系统设置'" />
 <template v-if="mode==='CapabilityBoundary'"><p>基础聊天始终可用</p><FlareCapabilityBoundary :state="state==='empty'?'unavailable':state" text="可选能力尚未就绪或发生错误" action-text="恢复能力" :reset-key="generation" @action="crash=false;generation++;state='available'" @error="last='插件错误已隔离'"><Plugin /></FlareCapabilityBoundary><button @click="crash=true">插件渲染失败</button></template>
 <button v-if="mode==='DangerConfirm'" @click="open=true">打开确认</button>
 <FlareDangerConfirm :open="open" title="确认移除？" description="此操作会移除目标的访问权限，请确认对象。" target="测试对象" :busy="busy" :error="error" confirm-text="确认移除" @confirm="confirm" @cancel="cancelled++;open=false;last='取消 '+cancelled+' 次'" />
 <p role="status">{{ last }}。本地演示，不修改账号、成员或文件。</p>
</div></DemoStage></template>
<style scoped>
.scene-demo{min-width:0;width:100%;display:grid;gap:12px}.controls{display:flex;flex-wrap:wrap;align-items:center;gap:8px}.controls label{display:flex;align-items:center;gap:8px;min-height:48px}button,select{min-height:48px;padding:8px 12px;border:1px solid var(--flare-color-border-primary);border-radius:8px}p{font-size:13px;overflow-wrap:anywhere}
</style>
