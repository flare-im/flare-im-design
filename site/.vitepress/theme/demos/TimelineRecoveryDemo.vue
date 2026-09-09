<script setup>
import { ref } from 'vue';
import MessageList from '@flare-im/vue-ui/components/messages/MessageList.vue';
import DemoStage from './DemoStage.vue';
const rows = ref(Array.from({ length: 40 }, (_, i) => message(i + 20)));
const loading = ref(false), error = ref(''), requests = ref(0), conv = ref('A');
function message(id) { return { serverId: String(id), clientMsgId: String(id), timelineKey: String(id), timelineSortTs: id * 1000, conversationSeq: id, senderId: 'other', senderDisplayName: 'Ivy', createdAt: id * 1000, content: { contentType: 'text', text: { text: `消息 ${id} — ${'用于验证历史阅读位置。'.repeat(id % 3 + 1)}` } }, status: 2 }; }
function load() { requests.value++; loading.value = true; error.value = ''; }
function complete() { const first = Number(rows.value[0].timelineKey); rows.value = [...Array.from({ length: 10 }, (_, i) => message(first - 10 + i)), ...rows.value, message(Number(rows.value.at(-1).timelineKey) + 1)]; loading.value = false; }
function fail() { loading.value = false; error.value = '历史加载失败，请重试'; }
function switchConversation() { conv.value = conv.value === 'A' ? 'B' : 'A'; loading.value = false; error.value = ''; rows.value = Array.from({length: 20}, (_, i) => message(i + (conv.value === 'A' ? 20 : 200))); }
</script>
<template><DemoStage><div class="recovery-demo">
  <div class="controls"><button @click="complete">前插历史并追加新消息</button><button @click="fail">返回失败</button><button @click="switchConversation">切换会话</button><span role="status">请求次数：{{ requests }}</span></div>
  <div class="timeline-frame"><MessageList :conversation-id="conv" :messages="rows" current-user-id="me" :has-older="true" :loading-older="loading" :older-error="error" load-older-text="加载历史" @load-older="load" /></div>
</div></DemoStage></template>
<style scoped>
.recovery-demo { min-width: 0; width: 100%; }
.controls { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 12px; }
.controls button { min-height: 48px; padding: 8px; border: 1px solid var(--flare-color-border-primary); border-radius: 8px; }
.timeline-frame { height: 420px; min-width: 0; border: 1px solid var(--flare-color-border-primary); }
</style>
