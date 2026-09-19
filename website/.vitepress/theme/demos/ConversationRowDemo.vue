<script setup>
import { computed } from "vue";
import { FlareConversationRow } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const props = defineProps({ previewState: { type: String, default: "default" } });
const item = computed(() => ({
  id: "u2",
  displayName: "Ivy Chen",
  lastMessagePreview: "好的，那我们明天上午同步一下 👍",
  timestampLabel: "14:02",
  mentioned: props.previewState === "mention",
  typing: props.previewState === "typing",
  failed: props.previewState === "failed",
  unreadCount: ["unread", "mention"].includes(props.previewState) ? 3 : 0,
  pinned: props.previewState === "pinned",
  muted: props.previewState === "muted",
}));
const draftPreview = computed(() => props.previewState === "draft" ? "Release checklist" : "");
</script>

<template>
  <DemoStage>
    <!-- 行是 listitem：它的文档用法就是活在一个 list 里，demo 也照这样摆。 -->
    <div class="row-stage" role="list">
      <FlareConversationRow :item="item" :active="previewState === 'selected'" :draft-preview="draftPreview" />
    </div>
  </DemoStage>
</template>

<style scoped>
.row-stage { width: 100%; max-width: 420px; }
</style>
