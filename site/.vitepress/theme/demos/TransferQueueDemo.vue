<script setup>
import { ref } from 'vue';
import FlareTransferQueue from '@flare-im/vue-ui/components/media/FlareTransferQueue.vue';
import DemoStage from './DemoStage.vue';
const labels={retry:'重试',cancel:'取消',pause:'暂停',resume:'继续',open:'打开'};
const initial=()=>[
 {id:'a',name:'产品设计交付说明.pdf',state:'failed',statusText:'网络中断，可以重试',actionLabels:labels,progress:0.3},
 {id:'b',name:'会议录音.m4a',state:'failed',statusText:'连接恢复后可以重试',actionLabels:labels},
 {id:'c',name:'已取消的附件.zip',state:'cancelled',statusText:'已取消，保留记录',actionLabels:labels},
 {id:'d',name:'头像.png',state:'completed',statusText:'已完成',actionLabels:labels},
];
const items=ref(initial()), loading=ref(false), error=ref(), last=ref('尚未操作');
function retry(ids){last.value='批量重试：'+ids.join(',');items.value=items.value.map(i=>ids.includes(i.id)?{...i,busy:true,statusText:'重试处理中'}:i);}
function settle(){items.value=items.value.map(i=>i.busy?{...i,busy:false,state:i.id==='a'?'completed':'failed',statusText:i.id==='a'?'已完成':'仍无法连接，请稍后重试'}:i);}
function reset(){items.value=initial();error.value=undefined;loading.value=false;last.value='尚未操作';}
</script>
<template><DemoStage><div class="queue-demo">
 <FlareTransferQueue :items="items" :loading="loading" :error="error" @retry-failed="retry" @action="last = `任务操作：${$event.id}/${$event.action}`" @reload="loading=true" />
 <div class="controls"><button @click="settle">返回部分失败</button><button @click="error='队列刷新失败，已有任务保留';loading=false">模拟刷新失败</button><button @click="items=[];error=undefined;loading=false">空队列</button><button @click="reset">重置演示</button></div>
 <p role="status">{{ last }}。本地模拟，不上传或删除文件。</p>
</div></DemoStage></template>
<style scoped>
.queue-demo {width:100%;min-width:0;display:grid;gap:16px;}
.controls {display:flex;flex-wrap:wrap;gap:8px;}
.controls button {min-height:48px;padding:8px 12px;border:1px solid var(--flare-color-border-primary);border-radius:8px;}
p {font-size:13px;overflow-wrap:anywhere;}
</style>
