<script setup>
import FlareCommentThread from "flare-core-vue-im-ui/components/moments/FlareCommentThread.vue";
import DemoStage from "./DemoStage.vue";
const comments = [
  { id: "1", author: { id: "leo", name: "Leo Wang" }, text: "第三张构图绝了！" },
  { id: "2", author: { id: "ivy", name: "Ivy Chen" }, replyToName: "Leo Wang", text: "哈哈那张我也最喜欢" },
  { id: "3", author: { id: "mia", name: "Mia Zhou" }, text: "求同款滤镜～" },
];
</script>
<template>
  <DemoStage>
    <div class="stage"><FlareCommentThread :comments="comments" @select="() => {}" /></div>
  </DemoStage>
</template>
<style scoped>
.stage { max-width: 380px; margin: 0 auto; padding: 12px 16px; border-radius: 12px; background: var(--flare-color-bg-secondary); }
</style>
