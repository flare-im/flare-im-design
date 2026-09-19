<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    muted?: boolean;
    cameraOn?: boolean;
    speakerOn?: boolean;
    mode?: "audio" | "video";
    /** Show the "add participant" button (group calls). */
    showAddMember?: boolean;
  }>(),
  { muted: false, cameraOn: true, speakerOn: false, mode: "video", showAddMember: false },
);
const emit = defineEmits<{
  (e: "toggleMute"): void;
  (e: "toggleCamera"): void;
  (e: "toggleSpeaker"): void;
  (e: "switchCamera"): void;
  (e: "addMember"): void;
  (e: "hangup"): void;
}>();

const { t } = useFlareI18n();
const micIcon = computed(() => (props.muted ? flareIcons["mic-off"] : flareIcons.mic));
const camIcon = computed(() => (props.cameraOn ? flareIcons.video : flareIcons["camera-off"]));
const speakerIcon = computed(() => (props.speakerOn ? flareIcons.speaker : flareIcons["speaker-off"]));
</script>

<template>
  <div class="flare-call-controls">
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

    <button v-else type="button" class="flare-call-controls__btn" role="switch" :aria-checked="speakerOn" @click="emit('toggleSpeaker')">
      <span class="ico" :class="{ 'ico--active': speakerOn }"><n-icon aria-hidden="true" :size="24" :component="speakerIcon" /></span>
      <span class="lbl">{{ t("call.speaker") }}</span>
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
  outline: 2px solid white;
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
  color: #fff;
  background: rgba(255, 255, 255, 0.14);
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
  color: #17131c;
  background: #fff;
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
  color: rgba(255, 255, 255, 0.72);
  letter-spacing: 0.01em;
}
</style>
