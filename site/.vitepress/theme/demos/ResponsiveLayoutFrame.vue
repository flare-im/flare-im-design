<script setup>
// Full-bleed ResponsiveLayout: wide → triple (list + chat + detail), tablet →
// dual, phone → single pane with a back bar. Switches on viewport width.
import FlareResponsiveLayout from "@flare-im/vue-ui/components/layout/FlareResponsiveLayout.vue";
</script>

<template>
  <div class="frame">
    <FlareResponsiveLayout :has-detail="true" active-pane="chat">
      <template #list><div class="pane pane--list">会话列表</div></template>
      <template #chat><div class="pane pane--chat">聊天窗口</div></template>
      <template #detail><div class="pane pane--detail">会话详情</div></template>
    </FlareResponsiveLayout>
  </div>
</template>

<style scoped>
.frame { height: 100dvh; background: var(--flare-color-bg-primary, #fff); }
.pane {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  font-size: 14px;
  color: var(--flare-color-text-secondary);
}
.pane--list { background: var(--flare-color-bg-secondary, #f5f6f8); }
.pane--chat { background: var(--flare-color-bg-primary, #fff); }
.pane--detail { background: var(--flare-color-bg-secondary, #f5f6f8); }
</style>
