<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = defineProps<{ label?: string; recordingLabel?: string; cancelLabel?: string; disabled?: boolean; busy?: boolean; slideToCancel?: boolean }>();
const { t } = useFlareI18n();
const emit = defineEmits<{ start: []; end: []; cancel: [] }>();
const pressing = ref(false);
const cancelling = ref(false);
let pointer: number | undefined;
let startY = 0;
let captured: HTMLButtonElement | null = null;
const text = computed(() => cancelling.value ? props.cancelLabel ?? t("voiceHoldButton.cancel")
  : pressing.value ? props.recordingLabel ?? t("voiceHoldButton.recording") : props.label ?? t("voiceHoldButton.label"));
function begin() {
  if (props.disabled || pressing.value) return;
  pressing.value = true; cancelling.value = false; emit("start");
}
function releaseCapture() {
  const node = captured; captured = null;
  if (pointer !== undefined && node?.hasPointerCapture?.(pointer)) node.releasePointerCapture(pointer);
  pointer = undefined;
}
function cancel() {
  if (!pressing.value) return;
  pressing.value = false; cancelling.value = false; releaseCapture(); emit("cancel");
}
function finish() {
  if (!pressing.value) return;
  if (cancelling.value) { cancel(); return; }
  pressing.value = false; releaseCapture(); emit("end");
}
function down(event: PointerEvent) {
  if (props.disabled || pressing.value || (event.button != null && event.button !== 0) || event.isPrimary === false) return;
  pointer = event.pointerId; startY = event.clientY;
  const node = event.currentTarget as HTMLButtonElement;
  if (pointer !== undefined && node.setPointerCapture) {
    try { node.setPointerCapture(pointer); captured = node; } catch { captured = null; }
  }
  begin();
}
function move(event: PointerEvent) {
  if (!props.slideToCancel || !pressing.value || event.pointerId !== pointer) return;
  cancelling.value = startY - event.clientY >= 48;
}
function up(event: PointerEvent) { if (pointer === undefined || event.pointerId === pointer) finish(); }
function pointerCancel(event: PointerEvent) { if (pointer === undefined || event.pointerId === pointer) cancel(); }
function leave() { if (!props.slideToCancel || !captured) cancel(); }
function keydown(event: KeyboardEvent) {
  if (event.key === "Escape") { event.preventDefault(); cancel(); }
  else if ([" ", "Enter"].includes(event.key)) { event.preventDefault(); if (!event.repeat) begin(); }
}
function keyup(event: KeyboardEvent) {
  if ([" ", "Enter"].includes(event.key)) { event.preventDefault(); finish(); }
}
function assistiveClick(event: MouseEvent) { if (event.detail === 0) pressing.value ? finish() : begin(); }
watch(() => props.disabled, disabled => { if (disabled) cancel(); });
onMounted(() => window.addEventListener("blur", cancel));
onBeforeUnmount(() => { window.removeEventListener("blur", cancel); cancel(); });
</script>

<template>
  <button type="button" class="flare-voice" :class="{ pressing, 'is-cancelling': cancelling }"
    :disabled="disabled" :aria-pressed="pressing" :aria-busy="busy || undefined"
    @pointerdown="down" @pointermove="move" @pointerup="up" @pointerleave="leave"
    @pointercancel="pointerCancel" @lostpointercapture="pointerCancel" @keydown="keydown" @keyup="keyup" @blur="cancel" @click="assistiveClick">
    <span>{{ text }}</span><slot name="trailing" />
  </button>
</template>

<style scoped>
.flare-voice {
  position: relative; display: inline-flex; align-items: center; justify-content: center;
  gap: var(--flare-size-spacing-sm); width: 100%; box-sizing: border-box;
  height: var(--flare-size-layout-control-height-md); min-height: var(--flare-size-layout-control-height-md);
  padding-inline: var(--flare-size-spacing-md); border: 0; border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary); color: var(--flare-color-text-primary);
  font: inherit; font-size: var(--flare-size-font-size-md); font-weight: 500;
  cursor: pointer; user-select: none; touch-action: none;
  transition: background var(--flare-transition-fast), color var(--flare-transition-fast);
}
.flare-voice::after { content: ""; position: absolute; inset: 50% auto auto 50%; transform: translate(-50%, -50%); width: max(100%, var(--flare-size-layout-touch-target)); height: max(100%, var(--flare-size-layout-touch-target)); }
.flare-voice.pressing { background: var(--flare-color-bg-selected); color: var(--flare-color-primary-text); }
.flare-voice.is-cancelling { background: var(--flare-color-bg-secondary); color: var(--flare-color-error-text); }
.flare-voice:disabled { opacity: var(--flare-opacity-disabled); cursor: default; }
.flare-voice:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
@media (prefers-reduced-motion: reduce) { .flare-voice { transition: none; } }
</style>
