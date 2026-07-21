<script setup>
import FlareIcon from "flare-core-vue-im-ui/components/general/FlareIcon.vue";
import FlareChatHeader from "flare-core-vue-im-ui/components/messages/ChatConversationHeader.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareChatHeader>
        <template #identity>
          <div class="idy">
            <strong>Ivy Chen</strong>
            <span class="sub">在线 · 设计评审组</span>
          </div>
        </template>
        <template #actions>
          <span class="act"><FlareIcon name="search" :size="18" /></span>
          <span class="act"><FlareIcon name="phone" :size="18" /></span>
          <span class="act"><FlareIcon name="more" :size="18" /></span>
        </template>
      </FlareChatHeader>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 480px; border: 1px solid var(--flare-color-border-secondary); border-radius: 12px; overflow: hidden; }
.idy { display: flex; flex-direction: column; }
.sub { font-size: 12px; color: var(--flare-color-text-tertiary); }
.act { font-size: 16px; opacity: 0.7; }
</style>
