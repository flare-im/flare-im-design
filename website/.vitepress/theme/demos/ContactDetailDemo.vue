<script setup>
import { ref } from "vue";
import { FlareContactDetail } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// Every intent is handled, so the full friend profile renders; a host omits the ones it cannot do.
const lastIntent = ref("");
const show = (name) => { lastIntent.value = name; };

const contact = {
  id: "flare_ivy",
  name: "Ivy Chen",
  signature: "设计即沟通 · 一套契约，四端原生实现",
  presence: "online",
  remark: "设计评审组 · Ivy",
  region: "上海 · 中国",
  phone: "138 **** 2048",
  tags: ["设计", "评审组", "常联系"],
};
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareContactDetail
        :contact="contact"
        starred
        description="设计评审组核心 · 响应快"
        @message="show('message')"
        @call="show('call')"
        @video="show('video')"
        @edit="show('edit')"
        @edit-description="show('editDescription')"
        @toggle-star="show('toggleStar')"
        @block="show('block')"
        @remove="show('remove')"
      />
      <p class="intent" role="status">{{ lastIntent }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 380px; }
.intent { min-height: 1.5em; margin: 8px 0 0; color: var(--flare-color-text-secondary); font-size: 13px; text-align: center; }
</style>
