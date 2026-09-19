<script setup>
import { computed } from "vue";
import { FlareMessageMeta } from "@flare-im/vue-ui";
import DemoStage from "./DemoStage.vue";

const props = defineProps({ previewState: { type: String, default: "edited" } });
const status = computed(() => ["pending", "sending", "sent", "delivered", "read", "failed", "retrying"].includes(props.previewState) ? props.previewState : "read");
</script>

<template>
  <DemoStage>
    <div class="message-meta-demo">
      <p>Cross-platform component coverage is ready for review.</p>
      <FlareMessageMeta timestamp="23:59" :edited="previewState === 'edited'" :status="status" tone="onOutgoing" />
    </div>
  </DemoStage>
</template>

<style scoped>
.message-meta-demo { width: min(100%, 360px); margin-inline-start: auto; padding: 12px 14px 8px; border-radius: var(--flare-size-radius-lg); color: var(--flare-color-message-outgoing-foreground); background: var(--flare-color-message-outgoing-background); }
.message-meta-demo p { margin: 0 0 5px; color: inherit; font-size: 14px; line-height: 1.45; }
</style>
