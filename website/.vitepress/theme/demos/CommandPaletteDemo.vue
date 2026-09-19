<script setup lang="ts">
import { ref } from "vue";
import { FlareButton } from "@flare-im/vue-ui/components";
import { FlareCommandPalette } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const open = ref(false);
const query = ref("");
const selectedId = ref("new-message");
const lastAction = ref("尚未执行命令");
const groups = [{
  id: "workspace",
  label: "工作区",
  commands: [
    { id: "new-message", label: "发起新会话", description: "选择联系人或群组", shortcut: "⌘N", keywords: ["create"] },
    { id: "search", label: "搜索消息", description: "在当前工作区中查找", shortcut: "⌘F", keywords: ["find"] },
    { id: "settings", label: "打开设置", shortcut: "⌘," },
  ],
}];
</script>

<template>
  <DemoStage>
    <div class="command-palette-demo">
      <FlareButton @click="open = true">打开命令面板</FlareButton>
      <span aria-live="polite">{{ lastAction }}</span>
      <FlareCommandPalette
        :open="open"
        :query="query"
        :groups="groups"
        label="工作区命令"
        placeholder="搜索命令"
        empty-text="没有匹配的命令"
        :selected-id="selectedId"
        @query-change="query = $event"
        @selected-id-change="selectedId = $event"
        @invoke="lastAction = `已执行：${$event.label}`; open = false"
        @close="open = false"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.command-palette-demo { display: flex; align-items: center; gap: var(--flare-size-spacing-md); flex-wrap: wrap; }
.command-palette-demo span { color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
</style>
