<script setup lang="ts">
// The call control bar (docs/plugin-experience.md §3.3): round keys of component.callControlSize on the call stage,
// device keys as switches, hangup last. On a phone with more than 4 device keys hangup takes its own row at
// component.callHangupSize. Pointer devices with a keyboard get M (mic), V (camera) and Ctrl/⌘+Shift+H (hang up).
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { NPopover, NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import { useCallPhone } from "./useCallPhone";

const props = withDefaults(
  defineProps<{
    muted?: boolean;
    cameraOn?: boolean;
    speakerOn?: boolean;
    speakerPicker?: boolean;
    mode?: "audio" | "video";
    /** Show the "add participant" button (group calls). */
    showAddMember?: boolean;
    /** Show the "switch to video" button in an audio call; it emits `startVideo` and the host turns the call into video. */
    canStartVideo?: boolean;
    /** Media controls are unavailable; ending the call remains possible. */
    disabled?: boolean;
  }>(),
  { muted: false, cameraOn: true, speakerOn: false, speakerPicker: false, mode: "video", showAddMember: false, canStartVideo: false, disabled: false },
);
const emit = defineEmits<{
  (e: "toggleMute"): void;
  (e: "toggleCamera"): void;
  (e: "toggleSpeaker"): void;
  (e: "switchCamera"): void;
  (e: "addMember"): void;
  (e: "startVideo"): void;
  (e: "hangup"): void;
}>();

const { t } = useFlareI18n();
const platform = useFlarePlatformSafe();
const devicePickerOpen = ref(false);
watch(() => props.disabled, disabled => { if (disabled) devicePickerOpen.value = false; });
const deviceTrigger = ref<HTMLButtonElement | null>(null);
function closeDevicePicker(event: KeyboardEvent) {
  if (!devicePickerOpen.value) return;
  event.preventDefault();
  event.stopPropagation();
  devicePickerOpen.value = false;
  deviceTrigger.value?.focus();
}
const micIcon = computed(() => (props.muted ? flareIcons["mic-off"] : flareIcons.mic));
const camIcon = computed(() => (props.cameraOn ? flareIcons.video : flareIcons["camera-off"]));
const speakerIcon = computed(() => (props.speakerPicker || props.speakerOn ? flareIcons.speaker : flareIcons["speaker-off"]));
// §3.3: flip (switch-camera) only in a phone's video call, as the Flutter kit.
const phone = useCallPhone();
/** Keys before hangup. */
const toggleCount = computed(() => 2 + (props.mode === "video" ? (phone.value ? 2 : 1) : props.canStartVideo ? 1 : 0) + Number(props.showAddMember));

// ── PC shortcuts: only with a keyboard, never while the viewer types somewhere ──
const keys = computed(() => platform.capabilities.value.keyboardShortcut);
const hint = (label: string, key: string) => (keys.value ? `${label} (${key})` : label);
function typing(target: EventTarget | null): boolean {
  const el = target as HTMLElement | null;
  return Boolean(el?.closest?.("input, textarea, select, [contenteditable='true'], [contenteditable='']"));
}
function shortcut(event: KeyboardEvent): void {
  if (!keys.value || event.repeat || event.defaultPrevented || typing(event.target)) return;
  const key = event.key.toLowerCase();
  if (key === "h" && event.shiftKey && (event.ctrlKey || event.metaKey) && !event.altKey) {
    event.preventDefault();
    emit("hangup");
    return;
  }
  if (props.disabled || event.ctrlKey || event.metaKey || event.altKey || event.shiftKey) return;
  if (key === "m") emit("toggleMute");
  else if (key === "v" && props.mode === "video") emit("toggleCamera");
}
onMounted(() => window.addEventListener("keydown", shortcut));
onBeforeUnmount(() => window.removeEventListener("keydown", shortcut));
</script>

<template>
  <div
    class="flare-call-controls"
    :class="{ 'has-hangup-row': toggleCount > 4 }"
    :style="{ '--flare-call-row-keys': toggleCount > 4 ? toggleCount : toggleCount + 1 }"
    @keydown.esc="closeDevicePicker"
  >
    <button type="button" class="flare-call-controls__btn" :disabled="disabled" role="switch" :aria-checked="!muted" :title="hint(t('call.microphone'), 'M')" @click="emit('toggleMute')">
      <span class="ico" :class="{ 'ico--active': muted }"><n-icon aria-hidden="true" size="var(--flare-size-icon-size-lg)" :component="micIcon" /></span>
      <span class="lbl">{{ t("call.microphone") }}</span>
    </button>

    <NPopover
      v-if="$slots.devices"
      v-model:show="devicePickerOpen"
      :disabled="disabled"
      trigger="click"
      placement="top"
      :show-arrow="false"
      style="width: var(--flare-size-component-call-device-panel-width)"
      :to="false"
      :theme-overrides="{ color: 'var(--flare-color-call-popover)', textColor: 'var(--flare-color-call-on-stage)', borderRadius: 'var(--flare-size-radius-card)', padding: 'var(--flare-size-spacing-md)' }"
    >
      <template #trigger>
        <button ref="deviceTrigger" type="button" class="flare-call-controls__btn" :disabled="disabled" :role="speakerPicker ? 'button' : 'switch'" :aria-checked="speakerPicker ? undefined : speakerOn" :aria-haspopup="speakerPicker ? 'dialog' : undefined" @click="emit('toggleSpeaker')">
          <span class="ico" :class="{ 'ico--active': !speakerPicker && speakerOn }"><n-icon aria-hidden="true" size="var(--flare-size-icon-size-lg)" :component="speakerIcon" /></span>
          <span class="lbl">{{ t("call.speaker") }}</span>
        </button>
      </template>
      <slot name="devices" />
    </NPopover>
    <button v-else ref="deviceTrigger" type="button" class="flare-call-controls__btn" :disabled="disabled" :role="speakerPicker ? 'button' : 'switch'" :aria-checked="speakerPicker ? undefined : speakerOn" :aria-haspopup="speakerPicker ? 'dialog' : undefined" @click="emit('toggleSpeaker')">
      <span class="ico" :class="{ 'ico--active': !speakerPicker && speakerOn }"><n-icon aria-hidden="true" size="var(--flare-size-icon-size-lg)" :component="speakerIcon" /></span>
      <span class="lbl">{{ t("call.speaker") }}</span>
    </button>

    <!-- Spec §3.3 order: mic, speaker/device, camera, flip, switch to video, add member, hang up. -->
    <template v-if="mode === 'video'">
      <button type="button" class="flare-call-controls__btn" :disabled="disabled" role="switch" :aria-checked="cameraOn" :title="hint(t('call.camera'), 'V')" @click="emit('toggleCamera')">
        <span class="ico" :class="{ 'ico--active': !cameraOn }"><n-icon aria-hidden="true" size="var(--flare-size-icon-size-lg)" :component="camIcon" /></span>
        <span class="lbl">{{ t("call.camera") }}</span>
      </button>
      <button v-if="phone" type="button" class="flare-call-controls__btn" :disabled="disabled" @click="emit('switchCamera')">
        <span class="ico"><n-icon aria-hidden="true" size="var(--flare-size-icon-size-lg)" :component="flareIcons['switch-camera']" /></span>
        <span class="lbl">{{ t("call.flip") }}</span>
      </button>
    </template>

    <button v-if="mode === 'audio' && canStartVideo" type="button" class="flare-call-controls__btn" :disabled="disabled" @click="emit('startVideo')">
      <span class="ico"><n-icon aria-hidden="true" size="var(--flare-size-icon-size-lg)" :component="flareIcons.video" /></span>
      <span class="lbl">{{ t("call.switchToVideo") }}</span>
    </button>

    <button v-if="showAddMember" type="button" class="flare-call-controls__btn" :disabled="disabled" @click="emit('addMember')">
      <span class="ico"><n-icon aria-hidden="true" size="var(--flare-size-icon-size-lg)" :component="flareIcons['person-add']" /></span>
      <span class="lbl">{{ t("call.addMember") }}</span>
    </button>

    <button type="button" class="flare-call-controls__btn flare-call-controls__hangup" :title="hint(t('call.hangUp'), 'Ctrl/⌘+Shift+H')" @click="emit('hangup')">
      <span class="ico ico--end"><n-icon aria-hidden="true" size="var(--flare-size-icon-size-lg)" :component="flareIcons['end-call']" /></span>
      <span class="lbl">{{ t("call.hangUp") }}</span>
    </button>
  </div>
</template>

<style scoped>
.flare-call-controls {
  --flare-call-key: var(--flare-size-component-call-control-size);
  display: flex;
  justify-content: center;
  align-items: flex-start;
  gap: var(--flare-size-spacing-2xl);
  max-width: 100%;
  min-width: 0;
}
/* PC: one row, with an extra gap before hangup. */
.flare-call-controls__hangup { margin-inline-start: var(--flare-size-spacing-2xl); }
.flare-call-controls__btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  min-width: var(--flare-call-key);
  max-width: 100%;
  padding: 0;
  border: none;
  background: none;
  color: inherit;
  font: inherit;
  cursor: pointer;
}
/* The focus ring follows the round key, not a square around key and label. */
.flare-call-controls__btn:focus-visible { outline: none; }
.flare-call-controls__btn:focus-visible .ico {
  outline: var(--flare-size-component-focus-ring-width) solid var(--flare-color-border-selected);
  outline-offset: var(--flare-size-component-focus-ring-offset);
}
.ico {
  display: flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  width: var(--flare-call-key);
  height: var(--flare-call-key);
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-color-call-on-stage);
  background: var(--flare-color-call-control);
  transition:
    transform var(--flare-transition-fast),
    background var(--flare-transition-fast),
    color var(--flare-transition-fast);
}
@media (hover: hover) {
  .flare-call-controls__btn:not(:disabled):hover .ico:not(.ico--active):not(.ico--end) { background: var(--flare-color-call-control-hover); }
}
/* Pressed: the hover fill on touch too, and the 0.98 press (colour only under reduced motion, below). */
.flare-call-controls__btn:not(:disabled):active .ico { transform: scale(var(--flare-size-component-press-scale)); }
.flare-call-controls__btn:not(:disabled):active .ico:not(.ico--active):not(.ico--end) { background: var(--flare-color-call-control-hover); }
/* "off/on" state: filled, so a muted mic / a camera that is off reads at a glance. */
.ico--active {
  color: var(--flare-color-call-on-control-active);
  background: var(--flare-color-call-control-active);
}
.ico--end {
  color: var(--flare-color-call-on-stage);
  background: var(--flare-color-call-hangup);
}
.flare-call-controls__btn:active .ico--end { background: var(--flare-color-call-hangup-pressed); }
.lbl {
  font-size: var(--flare-size-font-size-sm);
  overflow-wrap: anywhere;
  color: var(--flare-color-call-on-stage-secondary);
}
.flare-call-controls__btn:disabled { opacity: var(--flare-opacity-disabled); cursor: not-allowed; }
@media (prefers-reduced-motion: reduce) {
  .flare-call-controls__btn:not(:disabled):active .ico { transform: none; }
}
/* Phones: tighter keys; with more than 4 device keys, hangup gets its own centred row at the larger size. */
@media (max-width: 599px) {
  /* The row takes the stage's width: the gap below is a share of it, and a shrink-to-fit row (the call view centres it)
     left that share at ~0, so at 390 three keys touched and hangup wrapped to its own row (§3.3: spacing.lg apart). */
  .flare-call-controls { width: 100%; flex-wrap: wrap; gap: var(--flare-size-spacing-lg); row-gap: var(--flare-size-spacing-lg); }
  .flare-call-controls__hangup { margin-inline-start: 0; }
  .flare-call-controls.has-hangup-row .flare-call-controls__hangup { flex-basis: 100%; }
  /* §3.4: a row's keys stay in one row (the device keys, or all of them with hangup); at 320 the gap gives way first. */
  .flare-call-controls { column-gap: clamp(0px, calc((100% - var(--flare-call-row-keys) * var(--flare-call-key)) / (var(--flare-call-row-keys) - 1)), var(--flare-size-spacing-lg)); }
  .flare-call-controls.has-hangup-row .ico--end {
    width: var(--flare-size-component-call-hangup-size);
    height: var(--flare-size-component-call-hangup-size);
  }
}
</style>
