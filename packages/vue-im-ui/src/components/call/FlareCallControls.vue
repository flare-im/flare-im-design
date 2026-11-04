<script setup lang="ts">
import { computed, ref } from "vue";
import { NPopover, NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

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
  }>(),
  { muted: false, cameraOn: true, speakerOn: false, speakerPicker: false, mode: "video", showAddMember: false, canStartVideo: false },
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
const devicePickerOpen = ref(false);
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
</script>

<template>
  <div class="flare-call-controls" @keydown.esc="closeDevicePicker">
    <button type="button" class="flare-call-controls__btn" role="switch" :aria-checked="!muted" @click="emit('toggleMute')">
      <span class="ico" :class="{ 'ico--active': muted }"><n-icon aria-hidden="true" :size="24" :component="micIcon" /></span>
      <span class="lbl">{{ t("call.microphone") }}</span>
    </button>

    <template v-if="mode === 'video'">
      <button type="button" class="flare-call-controls__btn" role="switch" :aria-checked="cameraOn" @click="emit('toggleCamera')">
        <span class="ico" :class="{ 'ico--active': !cameraOn }"><n-icon aria-hidden="true" :size="24" :component="camIcon" /></span>
        <span class="lbl">{{ t("call.camera") }}</span>
      </button>
      <button type="button" class="flare-call-controls__btn" @click="emit('switchCamera')">
        <span class="ico"><n-icon aria-hidden="true" :size="24" :component="flareIcons['switch-camera']" /></span>
        <span class="lbl">{{ t("call.flip") }}</span>
      </button>
    </template>

      <NPopover v-if="$slots.devices" v-model:show="devicePickerOpen" trigger="click" placement="top" :show-arrow="false" :width="280" :to="false" :theme-overrides="{color: '#22232b', textColor: '#f4f4f5', borderRadius: '12px', padding: '12px'}">
        <template #trigger>      <button ref="deviceTrigger" type="button" class="flare-call-controls__btn" :role="speakerPicker ? 'button' : 'switch'" :aria-checked="speakerPicker ? undefined : speakerOn" :aria-haspopup="speakerPicker ? 'dialog' : undefined" @click="emit('toggleSpeaker')">
        <span class="ico" :class="{ 'ico--active': !speakerPicker && speakerOn }"><n-icon aria-hidden="true" :size="24" :component="speakerIcon" /></span>
        <span class="lbl">{{ t("call.speaker") }}</span>
      </button>
</template><slot name="devices" />
      </NPopover><template v-else>      <button ref="deviceTrigger" type="button" class="flare-call-controls__btn" :role="speakerPicker ? 'button' : 'switch'" :aria-checked="speakerPicker ? undefined : speakerOn" :aria-haspopup="speakerPicker ? 'dialog' : undefined" @click="emit('toggleSpeaker')">
        <span class="ico" :class="{ 'ico--active': !speakerPicker && speakerOn }"><n-icon aria-hidden="true" :size="24" :component="speakerIcon" /></span>
        <span class="lbl">{{ t("call.speaker") }}</span>
      </button>
</template>
      <button v-if="mode === 'audio' && canStartVideo" type="button" class="flare-call-controls__btn" @click="emit('startVideo')">
        <span class="ico"><n-icon aria-hidden="true" :size="24" :component="flareIcons.video" /></span>
        <span class="lbl">{{ t("call.switchToVideo") }}</span>
      </button>

    <button v-if="showAddMember" type="button" class="flare-call-controls__btn" @click="emit('addMember')">
      <span class="ico"><n-icon aria-hidden="true" :size="24" :component="flareIcons['person-add']" /></span>
      <span class="lbl">{{ t("call.addMember") }}</span>
    </button>

    <button type="button" class="flare-call-controls__btn" @click="emit('hangup')">
      <span class="ico ico--end"><n-icon aria-hidden="true" :size="26" :component="flareIcons['end-call']" /></span>
      <span class="lbl">{{ t("call.hangUp") }}</span>
    </button>
  </div>
</template>

<style scoped>
.flare-call-controls {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  align-items: flex-start;
  gap: 20px;
  max-width: 100%;
}
.flare-call-controls__btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  border: none;
  background: none;
  cursor: pointer;
  min-width: 56px;
  max-width: 112px;
  padding: 0;
}
.flare-call-controls__btn:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 4px;
  border-radius: 8px;
}
.ico {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 56px;
  height: 56px;
  border-radius: 50%;
  color: var(--flare-call-control-foreground, #fff);
  background: var(--flare-call-control-background, rgba(255, 255, 255, 0.14));
  border: 1px solid rgba(255, 255, 255, 0.14);
  backdrop-filter: blur(8px);
  transition:
    transform var(--flare-transition-fast),
    background var(--flare-transition-fast),
    color var(--flare-transition-fast);
}
.flare-call-controls__btn:hover .ico {
  background: rgba(255, 255, 255, 0.22);
}
.flare-call-controls__btn:active .ico {
  transform: scale(0.92);
}
/* "off/on" active state — filled, so a muted mic / disabled camera reads at a glance. */
.ico--active {
  color: var(--flare-call-control-active-foreground, #17131c);
  background: var(--flare-call-control-active-background, #fff);
  border-color: #fff;
}
.ico--end {
  color: #fff;
  background: linear-gradient(160deg, #ff5a5f, #e2373c);
  border-color: transparent;
  box-shadow: 0 8px 22px rgba(226, 55, 60, 0.42);
}
.flare-call-controls__btn:active .ico--end {
  transform: scale(0.92);
}
.lbl {
  font-size: 0.75rem;
  overflow-wrap: anywhere;
  color: var(--flare-call-control-label, rgba(255, 255, 255, 0.72));
  letter-spacing: 0.01em;
}
</style>
