<script setup>
import { computed, ref } from "vue";
import { FlareActionMenu, FlareIconButton, flareIcons } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const showMuted = ref(true);
const last = ref("");
const items = computed(() => [
  { id: "create-group", label: "创建群聊", icon: "people" },
  { id: "add-friend", label: "添加好友", icon: "person-add" },
  { id: "show-muted", label: "显示免打扰会话", icon: "mute", pressed: showMuted.value },
  { id: "export", label: "导出聊天记录", icon: "download", enabled: false, disabledReason: "仅桌面端可用" },
  { id: "blocked", label: "黑名单", icon: "block", group: "danger", danger: true },
]);

function select(id) {
  if (id === "show-muted") showMuted.value = !showMuted.value;
  last.value = items.value.find((item) => item.id === id)?.label ?? id;
}
</script>

<template>
  <DemoStage>
    <div class="action-menu-demo">
      <FlareActionMenu :items="items" label="新建" @select="select">
        <FlareIconButton :icon="flareIcons.add" aria-label="新建" variant="tinted" />
      </FlareActionMenu>
      <p role="status" class="action-menu-demo__status">{{ last ? `已选择：${last}` : "点击加号打开菜单" }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.action-menu-demo { display: flex; align-items: center; gap: var(--flare-size-spacing-md); min-height: 240px; align-content: start; }
.action-menu-demo__status { margin: 0; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-md); }
</style>
