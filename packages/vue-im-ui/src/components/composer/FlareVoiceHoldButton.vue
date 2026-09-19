<script setup lang="ts">
import { computed, ref } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = defineProps<{ label?: string; recordingLabel?: string }>();
const { t } = useFlareI18n();
const strings = computed(() => ({
  label: props.label ?? t("voiceHoldButton.label"),
  recordingLabel: props.recordingLabel ?? t("voiceHoldButton.recording"),
}));
const emit = defineEmits<{
  (e: "start"): void;
  (e: "end"): void;
  (e: "cancel"): void;
}>();

const pressing = ref(false);
function down() {
  pressing.value = true;
  emit("start");
}
function up() {
  if (!pressing.value) return;
  pressing.value = false;
  emit("end");
}
function cancel() {
  if (!pressing.value) return;
  pressing.value = false;
  emit("cancel");
}
</script>

<template>
  <button
    class="flare-voice"
    :class="{ pressing }"
    @pointerdown="down"
    @pointerup="up"
    @pointerleave="cancel"
    @pointercancel="cancel"
  >
    {{ pressing ? strings.recordingLabel : strings.label }}
  </button>
</template>

<style scoped>
.flare-voice {
  width: 100%;
  height: 40px;
  border: none;
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  user-select: none;
  touch-action: none;
  transition: background 0.12s, color 0.12s;
}
.flare-voice.pressing {
  background: var(--flare-color-primary);
  color: #fff;
}
</style>
