<script setup>
import { ref } from "vue";
import { FlareButton, FlareCommentThread } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const detail = ref(true);
const focusCommentId = ref();
const comments = [
  { id: "1", author: { id: "leo", name: "Leo Wang" }, text: "第三张构图绝了！" },
  { id: "2", author: { id: "ivy", name: "Ivy Chen" }, replyToName: "Leo Wang", text: "哈哈那张我也最喜欢" },
  { id: "3", author: { id: "mia", name: "Mia Zhou" }, text: "每一次回看都能发现不同的细节。\n".repeat(8) + "下次一起去😀" },
];
</script>
<template>
  <DemoStage>
    <div class="stage"><FlareButton size="sm" variant="secondary" :label="detail ? '切换信息流' : '切换详情'" @click="detail = !detail" /><FlareButton size="sm" variant="secondary" label="定位长评论" @click="focusCommentId = '3'" /><FlareCommentThread :focus-comment-id="focusCommentId" :comments="comments" :appearance="detail ? 'detail' : 'inline'" @select="() => {}" /></div>
  </DemoStage>
</template>
<style scoped>
.stage { max-width: 380px; margin: 0 auto; padding: 12px 16px; border-radius: 12px; background: var(--flare-color-bg-secondary); }
</style>
