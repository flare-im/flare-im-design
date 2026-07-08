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
      <div class="sheet-title">Start conversation</div>
      <n-input v-model:value="peerUserId" round clearable placeholder="Enter a real user ID" />
      <n-button block type="primary" :loading="busy" @click="emit('open-peer')">
        Open direct chat
      </n-button>
    </div>

    <div class="sheet-section">
      <div class="sheet-title">Conversation ops</div>
      <n-input v-model:value="query" round clearable placeholder="Search by name, ID, or recent message" />
      <div class="sheet-actions">
        <n-button secondary :loading="busy" @click="emit('query')">Query</n-button>
        <n-button secondary :loading="busy" @click="emit('mark-all-read')">Mark all read</n-button>
      </div>
    </div>
  </section>
</template>
