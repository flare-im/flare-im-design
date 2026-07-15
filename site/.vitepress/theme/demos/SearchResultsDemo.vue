<script setup>
import FlareSearchResults from "flare-core-vue-im-ui/components/general/FlareSearchResults.vue";
import DemoStage from "./DemoStage.vue";
const query = "设计";
const groups = [
  {
    kind: "contact",
    label: "联系人",
    items: [
      { id: "ivy", kind: "contact", title: "设计-Ivy Chen", subtitle: "一套契约，四端原生实现" },
      { id: "leo", kind: "contact", title: "Leo Wang", subtitle: "设计系统维护者" },
    ],
  },
  {
    kind: "group",
    label: "群聊",
    items: [{ id: "g1", kind: "group", title: "Flare 设计评审", subtitle: "12 名成员" }],
    total: 3,
  },
  {
    kind: "message",
    label: "聊天记录",
    items: [
      { id: "m1", kind: "message", title: "Ivy Chen", subtitle: "周五的设计评审带上组件清单", meta: "昨天" },
    ],
  },
];
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareSearchResults :groups="groups" :query="query" @open="() => {}" @view-all="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage {
  max-width: 380px; margin: 0 auto; padding: 8px; border-radius: 14px;
  background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-primary);
}
</style>
