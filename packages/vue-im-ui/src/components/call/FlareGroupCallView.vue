<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareCallControls from "./FlareCallControls.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareCallMode, FlareCallParticipant, FlareCallState } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    participants: FlareCallParticipant[];
    mode: FlareCallMode;
    state: FlareCallState;
    title?: string;
    durationLabel?: string;
    muted?: boolean;
    cameraOn?: boolean;
    speakerOn?: boolean;
    encrypted?: boolean;
  }>(),
  { title: "", muted: false, cameraOn: true, speakerOn: false, encrypted: false },
);
const emit = defineEmits<{
  (e: "hangup"): void;
  (e: "toggleMute"): void;
  (e: "toggleCamera"): void;
  (e: "toggleSpeaker"): void;
  (e: "switchCamera"): void;
  (e: "addMember"): void;
  (e: "minimize"): void;
  (e: "selectParticipant", id: string): void;
}>();

const { t } = useFlareI18n();

// Grid columns grow with the head-count, capped so tiles stay legible.
const cols = computed(() => {
  const n = props.participants.length;
  if (n <= 1) return 1;
  if (n <= 4) return 2;
  if (n <= 9) return 3;
  return 4;
});
const statusText = computed(() => {
  if (props.state === "reconnecting") return t("call.reconnecting");
  if (props.state === "failed") return t("call.failed");
  if (props.state === "connected") return props.durationLabel ?? t("call.connected");
  if (props.state === "ringing") return t("call.ringing");
  return t("call.calling");
});
</script>

<template>
  <div class="flare-group-call">
    <header class="flare-group-call__bar">
      <button type="button" class="flare-group-call__minimize" :aria-label="t('call.minimize')" @click="emit('minimize')">
        <n-icon aria-hidden="true" :size="20" :component="flareIcons.collapse" />
      </button>
      <div class="flare-group-call__title">
        <div class="flare-group-call__name">{{ title || t("call.groupCall") }}</div>
        <div class="flare-group-call__meta">
          {{ t("call.participants", { count: participants.length }) }} · {{ statusText }}
        </div>
      </div>
      <div v-if="encrypted" class="flare-group-call__secure" :title="'End-to-end encrypted'">
        <n-icon aria-hidden="true" :size="14" :component="flareIcons.lock" />
      </div>
    </header>

    <div class="flare-group-call__grid" :style="{ gridTemplateColumns: `repeat(${cols}, 1fr)` }">
      <button
        v-for="p in participants"
        :key="p.id"
        type="button"
        class="flare-group-call__tile"
        :class="{ 'is-speaking': p.speaking, 'is-self': p.isSelf }"
        @click="emit('selectParticipant', p.id)"
      >
        <div class="flare-group-call__stream">
          <!-- Host injects each participant's video track here; falls back to the avatar. -->
          <slot name="tile" :participant="p">
            <FlareAvatar
              v-if="mode === 'audio' || p.cameraOff"
              :user-id="p.id"
              :display-name="p.name"
              :avatar-url="p.avatarUrl"
              :size="64"
            />
          </slot>
        </div>
        <div class="flare-group-call__tag">
          <span v-if="p.muted" class="flare-group-call__mic"><n-icon aria-hidden="true" :size="12" :component="flareIcons['mic-off']" /></span>
          <span v-else-if="p.cameraOff && mode === 'video'" class="flare-group-call__mic"><n-icon aria-hidden="true" :size="12" :component="flareIcons['camera-off']" /></span>
          <span class="flare-group-call__pname">{{ p.isSelf ? t("groupCallView.selfName", { name: p.name }) : p.name }}</span>
        </div>
      </button>
    </div>

    <div class="flare-group-call__controls">
      <FlareCallControls
        :muted="muted"
        :camera-on="cameraOn"
        :speaker-on="speakerOn"
        :mode="mode"
        show-add-member
        @toggle-mute="emit('toggleMute')"
        @toggle-camera="emit('toggleCamera')"
        @toggle-speaker="emit('toggleSpeaker')"
        @switch-camera="emit('switchCamera')"
        @add-member="emit('addMember')"
        @hangup="emit('hangup')"
      />
    </div>
  </div>
</template>

<style scoped>
.flare-group-call {
  position: relative;
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  min-height: 460px;
  color: #fff;
  overflow: hidden;
  background:
    linear-gradient(180deg, color-mix(in srgb, var(--flare-color-primary) 20%, #18181b), #101012 58%);
}
.flare-group-call__bar {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: var(--flare-size-spacing-2md) 16px;
}
.flare-group-call__minimize {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  flex: 0 0 auto;
  border: 0;
  border-radius: 50%;
  color: #fff;
  background: rgba(255, 255, 255, 0.12);
  cursor: pointer;
  transition: background var(--flare-transition-fast);
}
.flare-group-call__minimize:hover { background: rgba(255, 255, 255, 0.2); }
.flare-group-call__title { flex: 1 1 auto; min-width: 0; }
.flare-group-call__name {
  font-size: 16px;
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-group-call__meta {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.62);
}
.flare-group-call__secure {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  flex: 0 0 auto;
  border-radius: 50%;
  color: rgba(255, 255, 255, 0.7);
  background: rgba(255, 255, 255, 0.08);
}
.flare-group-call__grid {
  flex: 1 1 auto;
  min-height: 0;
  display: grid;
  gap: 8px;
  padding: 4px 12px 12px;
  overflow: auto;
}
.flare-group-call__tile {
  position: relative;
  display: grid;
  place-items: center;
  min-height: 116px;
  padding: 0;
  border: 2px solid transparent;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.06);
  cursor: pointer;
  overflow: hidden;
  transition: border-color var(--flare-transition-fast), transform var(--flare-transition-fast);
}
.flare-group-call__tile:active { transform: scale(0.99); }
.flare-group-call__tile.is-speaking {
  border-color: #34d17f;
  box-shadow: 0 0 0 3px rgba(52, 209, 127, 0.28);
}
.flare-group-call__tile.is-self { background: color-mix(in srgb, var(--flare-color-primary) 18%, transparent); }
.flare-group-call__stream {
  display: grid;
  place-items: center;
  width: 100%;
  height: 100%;
}
.flare-group-call__stream :deep(video),
.flare-group-call__stream :deep(img) {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.flare-group-call__tag {
  position: absolute;
  left: 8px;
  bottom: 8px;
  right: 8px;
  display: flex;
  align-items: center;
  gap: 5px;
  min-width: 0;
}
.flare-group-call__mic {
  display: grid;
  place-items: center;
  width: 20px;
  height: 20px;
  flex: 0 0 auto;
  border-radius: 6px;
  color: #fff;
  background: rgba(0, 0, 0, 0.42);
}
.flare-group-call__pname {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: 12px;
  color: #fff;
  background: rgba(0, 0, 0, 0.42);
}
.flare-group-call__controls {
  flex: 0 0 auto;
  display: flex;
  justify-content: center;
  padding: 16px 12px 40px;
}
</style>
