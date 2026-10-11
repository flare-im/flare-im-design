<script setup>
import { computed, ref } from "vue";
import { FlareDescriptionList, FlareSegmentedControl, FlareTag } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 控制台消息详情：宿主把每个值格式化好，未知的留空，列表显示「未设置」；
// 标识符可复制，复制结果由宿主提示；不只是文字的行（类型、状态）用 item-<key> 插槽画成标签。
const items = [
  { key: "serverId", label: "消息 ID", value: "m_01HZX3K9Q2V7", monospace: true, copyable: true },
  { key: "conversation", label: "会话 ID", value: "c_8f2e41", monospace: true, copyable: true },
  { key: "seq", label: "会话序号", value: 1287 },
  { key: "sender", label: "发送者", value: "林悦（u_10086）" },
  { key: "kind", label: "消息类型", value: "image" },
  { key: "status", label: "状态", value: "recalled" },
  { key: "channel", label: "频道", value: null },
  { key: "createdAt", label: "发送时间", value: "2026-10-11 09:24:31" },
  { key: "attributes", label: "扩展属性", value: "x-trace=7f3a\nsource=web", span: 2 },
];
const placementIndex = ref(0);
const labelPlacement = computed(() => (placementIndex.value === 0 ? "start" : "top"));
const last = ref("还没有复制");
function onCopy(key, copied) {
  last.value = copied ? `已复制 ${key}` : `浏览器拒绝了复制 ${key}`;
}
</script>

<template>
  <DemoStage>
    <div class="description-demo">
      <FlareSegmentedControl v-model="placementIndex" :options="['标签在旁', '标签在上']" />
      <FlareDescriptionList label="消息详情" :items="items" :columns="2" :label-placement="labelPlacement" appearance="card" @copy="onCopy">
        <template #item-kind="{ value }"><FlareTag :label="String(value)" /></template>
        <template #item-status="{ value }"><FlareTag :label="value === 'recalled' ? '已撤回' : '正常'" :tone="value === 'recalled' ? 'warning' : 'success'" /></template>
      </FlareDescriptionList>
      <p class="description-demo__status" role="status">{{ last }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.description-demo {
  display: grid;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  max-width: 720px;
}
.description-demo__status {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
}
</style>
