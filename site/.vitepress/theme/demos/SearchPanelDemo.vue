<script setup>
import { ref } from 'vue';
import FlareSearchPanel from '@flare-im/vue-ui/components/general/FlareSearchPanel.vue';
import DemoStage from './DemoStage.vue';
const criteria = { query: '11', filterId: 'all' };
const groups = (filterId) => [{ kind: 'message', label: filterId === 'file' ? '文件' : '消息', items: [{ id: filterId, kind: 'message', title: filterId === 'file' ? '报告11.pdf' : '旧文本结果11', subtitle: 'İX · Unicode 高亮验证' }] }];
const snapshot = ref({ criteria, state: 'success', groups: groups('all') });
const ranges = [{ id: 'any', label: '不限时间' }, { id: 'before', label: '9 月 1 日前', toTime: 1788191999999 }, { id: 'after', label: '9 月 1 日起', fromTime: 1788192000000 }, { id: 'invalid', label: '无效范围', fromTime: 2, toTime: 1 }];
const pending = ref(null);
const count = ref(0);
function search(value) { pending.value = value; count.value++; }
function complete() { if (pending.value) snapshot.value = { criteria: { ...pending.value }, state: 'success', groups: groups(pending.value.filterId) }; }
function fail() { if (pending.value) snapshot.value = { criteria: { ...pending.value }, state: 'failure', groups: [], error: '连接中断，请重试' }; }
</script>
<template>
  <DemoStage><div class="search-demo">
    <FlareSearchPanel :snapshot="snapshot" :time-ranges="ranges" :filters="{ all: '全部', text: '文本', file: '文件', image: '图片', video: '视频', audio: '语音' }" @search="search" />
    <div class="controls"><button @click="complete">返回当前结果</button><button @click="fail">模拟失败</button></div>
    <p role="status">已提交 {{ count }} 次；待处理类型 {{ pending?.filterId || 'all' }}；时间 {{ pending?.fromTime ?? '不限' }} — {{ pending?.toTime ?? '不限' }}。此演示仅使用本地数据。</p>
  </div></DemoStage>
</template>
<style scoped>
.search-demo { display:grid; gap:16px; width:100%; min-width:0; }
.controls { display:flex; flex-wrap:wrap; gap:8px; }
.controls button { min-height:48px; padding:8px 12px; border:1px solid var(--flare-color-border-primary); border-radius:8px; }
p { font-size:13px; overflow-wrap:anywhere; }
</style>
