<script setup>
import { computed } from "vue";
import { FlareComposer } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const props = defineProps({ previewState: { type: String, default: "idle" } });
const composerProps = computed(() => ({
  targetName: "Ivy Chen",
  replySender: props.previewState === "replying" ? "Ivy Chen" : "",
  replyPreview: props.previewState === "replying" ? "Review the mobile state too." : "",
  editing: props.previewState === "editing",
  editPreview: props.previewState === "editing" ? "Updated release note" : "",
  readOnly: props.previewState === "readOnly",
  sendBlocked: ["offline", "sendBlocked"].includes(props.previewState),
  statusHint: props.previewState === "offline" ? "Offline. Draft saved locally." : props.previewState === "sendBlocked" ? "Sending is temporarily unavailable." : "",
}));
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareComposer v-bind="composerProps" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 520px; }
</style>
