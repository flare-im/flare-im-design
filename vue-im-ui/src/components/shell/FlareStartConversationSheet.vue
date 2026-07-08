<script setup lang="ts">
import { NButton, NInput } from "naive-ui";

const peerUserId = defineModel<string>("peerUserId", { default: "" });
const query = defineModel<string>("query", { default: "" });

defineProps<{
  busy?: boolean;
}>();

const emit = defineEmits<{
  (event: "open-peer"): void;
  (event: "query"): void;
  (event: "mark-all-read"): void;
}>();
</script>

<template>
  <section class="start-sheet">
    <div class="sheet-section">
      <div class="sheet-title">发起会话</div>
      <n-input v-model:value="peerUserId" round clearable placeholder="输入真实用户 ID" />
      <n-button block type="primary" :loading="busy" @click="emit('open-peer')">
        打开单聊
      </n-button>
    </div>

    <div class="sheet-section">
      <div class="sheet-title">会话运维</div>
      <n-input v-model:value="query" round clearable placeholder="按名称、ID 或最近消息查询" />
      <div class="sheet-actions">
        <n-button secondary :loading="busy" @click="emit('query')">查询</n-button>
        <n-button secondary :loading="busy" @click="emit('mark-all-read')">全部已读</n-button>
      </div>
    </div>
  </section>
</template>
