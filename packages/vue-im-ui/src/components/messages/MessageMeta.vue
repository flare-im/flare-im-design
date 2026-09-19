<script setup lang="ts">
import { computed } from "vue";
import type {
  MessageEphemeralState,
  MessageLifecycle,
  MessageStatusState,
} from "../../shared/contracts/message-lifecycle";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import MessageStatus from "./MessageStatus.vue";

const props = withDefaults(defineProps<{
  timestamp?: string;
  edited?: boolean;
  status?: MessageStatusState;
  lifecycle?: MessageLifecycle;
  ephemeral?: MessageEphemeralState;
  density?: "compact" | "normal";
  tone?: "default" | "onOutgoing";
  overlay?: boolean;
}>(), {
  timestamp: "",
  edited: false,
  ephemeral: "none",
  density: "compact",
  tone: "default",
  overlay: false,
});

const emit = defineEmits<{ (event: "resend"): void }>();
const { t } = useFlareI18n();
const toneClass = computed(() => props.tone === "onOutgoing" ? "on-outgoing" : "default");
const resolvedEphemeral = computed(() => props.lifecycle?.ephemeral ?? props.ephemeral);
const ephemeralLabel = computed(() => {
  if (resolvedEphemeral.value === "readOnce") return t("message.readOnce");
  if (resolvedEphemeral.value === "burnAfterRead") return t("message.burned");
  if (resolvedEphemeral.value === "expired") return t("message.expired");
  return "";
});
</script>

<template>
  <footer
    class="message-meta-row"
    :class="[`message-meta-row--${density}`, `message-meta-row--${toneClass}`, { 'message-meta-row--overlay': overlay }]"
  >
    <span v-if="timestamp" class="message-meta-row__text">{{ timestamp }}</span>
    <span v-if="edited" class="message-meta-row__text">{{ t("message.edited") }}</span>
    <span v-if="ephemeralLabel" class="message-meta-row__text">{{ ephemeralLabel }}</span>
    <MessageStatus
      v-if="status !== undefined || lifecycle"
      :status="status ?? 'sent'"
      :lifecycle="lifecycle"
      :tone="tone"
      variant="inline"
      @resend="emit('resend')"
    />
  </footer>
</template>

<style scoped>
.message-meta-row {
  display: flex;
  width: fit-content;
  max-width: 100%;
  margin-inline-start: auto;
  align-items: center;
  justify-content: flex-end;
  align-self: flex-end;
  min-height: var(--flare-size-icon-size-sm);
  gap: var(--flare-size-spacing-xs);
  color: var(--flare-color-text-tertiary);
  white-space: nowrap;
}

.message-meta-row--normal { gap: var(--flare-size-spacing-2xs); }
.message-meta-row--on-outgoing { color: var(--flare-color-message-status-on-outgoing); }
.message-meta-row--overlay {
  position: absolute;
  inset-inline-end: var(--flare-size-spacing-xs);
  bottom: var(--flare-size-spacing-xs);
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-full);
  background: rgba(0, 0, 0, 0.48);
  color: var(--flare-color-message-status-on-outgoing);
}

.message-meta-row__text {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  font-size: var(--flare-size-font-size-xs);
  line-height: var(--flare-size-line-height-tight);
  color: currentColor;
}

.message-meta-row__text + .message-meta-row__text::before {
  content: "·";
  margin-inline-end: var(--flare-size-spacing-xs);
}
</style>
