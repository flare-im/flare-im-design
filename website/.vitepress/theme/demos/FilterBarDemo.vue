<script setup>
import { computed, ref } from "vue";
import { FlareButton, FlareFilterBar, FlareFormField, FlareInput, FlareSelect } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 消息检索的查询栏：值全在宿主（这个 demo）里，查询栏只上报「查询」与「重置」。
// 不常用的条件收进「更多条件」；收起时键上写出其中几项已填，被收起的条件不会让人意外。
const empty = () => ({ conversationId: "", messageId: "", senderId: "", channelId: "", recalled: "any" });
const query = ref({ ...empty(), conversationId: "c_8f2e41" });
const moreOpen = ref(false);
const pending = ref(false);
const last = ref("还没有查询");
const recalledOptions = [
  { value: "any", label: "不限" },
  { value: "yes", label: "已撤回" },
  { value: "no", label: "未撤回" },
];
const moreActiveCount = computed(() => [query.value.senderId, query.value.channelId, query.value.recalled !== "any"].filter(Boolean).length);

function runSearch() {
  pending.value = true;
  last.value = `查询：${Object.entries(query.value).filter(([, value]) => value && value !== "any").map(([key, value]) => `${key}=${value}`).join("，") || "无条件"}`;
  setTimeout(() => { pending.value = false; }, 600);
}
function resetQuery() {
  query.value = empty();
  last.value = "已重置";
}
</script>

<template>
  <DemoStage>
    <div class="filter-bar-demo">
      <FlareFilterBar
        hint="至少填写会话、消息 ID 或发送者之一。"
        :loading="pending"
        :more-active-count="moreActiveCount"
        v-model:expanded="moreOpen"
        @search="runSearch"
        @reset="resetQuery"
      >
        <FlareFormField label="会话 ID"><FlareInput v-model="query.conversationId" monospace clearable placeholder="c_…" /></FlareFormField>
        <FlareFormField label="消息 ID"><FlareInput v-model="query.messageId" monospace clearable placeholder="m_…" /></FlareFormField>
        <template #more>
          <FlareFormField label="发送者"><FlareInput v-model="query.senderId" monospace clearable placeholder="u_…" /></FlareFormField>
          <FlareFormField label="频道"><FlareInput v-model="query.channelId" monospace clearable /></FlareFormField>
          <FlareFormField label="撤回状态"><FlareSelect v-model="query.recalled" :options="recalledOptions" title="撤回状态" /></FlareFormField>
        </template>
        <template #actions><FlareButton variant="ghost" label="导出" @click="last = '导出当前条件（本地模拟）'" /></template>
      </FlareFilterBar>
      <p class="filter-bar-demo__status" role="status">{{ last }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.filter-bar-demo {
  display: grid;
  gap: var(--flare-size-spacing-md);
  width: 100%;
}
.filter-bar-demo__status {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
}
</style>
