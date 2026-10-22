<script setup>
import { computed } from "vue";
import { FlareMessageMeta } from "@flare-im/vue-ui";
import DemoStage from "./DemoStage.vue";

// Inside an outgoing bubble (bubbleFooter, onOutgoing palette) and below a card (below, default palette: the
// failure is the "Failed to send. Retry" key). In a group the read summary replaces the ticks.
const props = defineProps({ previewState: { type: String, default: "edited" } });
const status = computed(() => (props.previewState === "failed" ? "failed" : "read"));
const summary = computed(() => (props.previewState === "readSummary" ? { readCount: 2, unreadCount: 3, total: 5 } : undefined));
</script>

<template>
  <DemoStage>
    <div class="message-meta-demo">
      <p>Cross-platform component coverage is ready for review.</p>
      <FlareMessageMeta
        timestamp="23:59"
        :edited="previewState === 'edited'"
        :ephemeral="previewState === 'ephemeral' ? 'readOnce' : 'none'"
        :status="summary ? 'sent' : status"
        :read-summary="summary"
        tone="onOutgoing"
        placement="bubbleFooter"
        @read-receipt-open="() => {}"
      />
    </div>
    <div class="message-meta-demo__card">
      <div class="message-meta-demo__shell">卡片</div>
      <FlareMessageMeta timestamp="23:59" :status="status" placement="below" @resend="() => {}" />
    </div>
  </DemoStage>
</template>

<style scoped>
.message-meta-demo { width: min(100%, 360px); margin-inline-start: auto; padding: 12px 14px 8px; border-radius: var(--flare-size-radius-lg); color: var(--flare-color-message-outgoing-foreground); background: var(--flare-color-message-outgoing-background); }
.message-meta-demo p { margin: 0 0 5px; color: inherit; font-size: 14px; line-height: 1.45; }
.message-meta-demo__card { display: grid; justify-items: end; gap: var(--flare-size-spacing-xs); width: min(100%, 280px); margin: 16px 0 0 auto; }
.message-meta-demo__shell { width: 100%; padding: var(--flare-size-spacing-md); border: 1px solid var(--flare-color-border-secondary); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); font-size: 14px; }
</style>
