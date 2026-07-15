<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import {
  CallOutline,
  CameraReverseOutline,
  MicOffOutline,
  MicOutline,
  PersonAddOutline,
  VideocamOffOutline,
  VideocamOutline,
  VolumeHighOutline,
  VolumeMuteOutline,
} from "@vicons/ionicons5";
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
const micIcon = computed(() => (props.muted ? MicOffOutline : MicOutline));
const camIcon = computed(() => (props.cameraOn ? VideocamOutline : VideocamOffOutline));
const speakerIcon = computed(() => (props.speakerOn ? VolumeHighOutline : VolumeMuteOutline));
</script>

<template>
  <div class="flare-call-controls">
    <button type="button" class="flare-call-controls__btn" :aria-pressed="muted" @click="emit('toggleMute')">
      <span class="ico" :class="{ 'ico--active': muted }"><n-icon :size="24" :component="micIcon" /></span>
      <span class="lbl">{{ t("call.microphone") }}</span>
    </button>

    <template v-if="mode === 'video'">
      <button type="button" class="flare-call-controls__btn" :aria-pressed="!cameraOn" @click="emit('toggleCamera')">
        <span class="ico" :class="{ 'ico--active': !cameraOn }"><n-icon :size="24" :component="camIcon" /></span>
        <span class="lbl">{{ t("call.camera") }}</span>
      </button>
      <button type="button" class="flare-call-controls__btn" @click="emit('switchCamera')">
        <span class="ico"><n-icon :size="24" :component="CameraReverseOutline" /></span>
        <span class="lbl">{{ t("call.flip") }}</span>
      </button>
    </template>

    <button v-else type="button" class="flare-call-controls__btn" :aria-pressed="speakerOn" @click="emit('toggleSpeaker')">
      <span class="ico" :class="{ 'ico--active': speakerOn }"><n-icon :size="24" :component="speakerIcon" /></span>
      <span class="lbl">{{ t("call.speaker") }}</span>
    </button>

    <button v-if="showAddMember" type="button" class="flare-call-controls__btn" @click="emit('addMember')">
      <span class="ico"><n-icon :size="24" :component="PersonAddOutline" /></span>
      <span class="lbl">{{ t("call.addMember") }}</span>
    </button>

    <button type="button" class="flare-call-controls__btn" @click="emit('hangup')">
      <span class="ico ico--end"><n-icon :size="26" :component="CallOutline" /></span>
      <span class="lbl">{{ t("call.hangUp") }}</span>
    </button>
  </div>
</template>

<style scoped>
.flare-call-controls {
  display: flex;
  gap: 20px;
}
.flare-call-controls__btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  border: none;
  background: none;
  cursor: pointer;
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
    transform var(--flare-transition-fast, 150ms ease),
    background var(--flare-transition-fast, 150ms ease),
    color var(--flare-transition-fast, 150ms ease);
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
  transform: rotate(135deg);
}
.ico--end :deep(svg) {
  transform: rotate(-135deg);
}
.flare-call-controls__btn:active .ico--end {
  transform: rotate(135deg) scale(0.92);
}
.lbl {
  font-size: 11px;
  color: rgba(255, 255, 255, 0.72);
  letter-spacing: 0.01em;
}
</style>
