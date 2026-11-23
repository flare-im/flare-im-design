<script setup lang="ts">
import { flareCallAvatar } from "./callSizes";
// A group call (docs/plugin-experience.md §3.4, §12.16) on the call stage: 1 full, 2 side by side, 3 as two over one
// centred, 4 as 2×2, 5–6 as 3×2 (2×3 on phones), 7–9 as 3×3, 10–12 as 4×3 (3×4 on phones). The header counts the people
// who joined, not those still being called. Failed calls say the host's reason as their status and trade the control
// bar for close + call again. Add member shows only while the host listens to addMember.
// Tapping a tile makes it the main view with the others in a bottom strip (tiles 96 high); tapping it again restores
// the grid. The kit keeps that focus itself (and still emits selectParticipant); it ends when the person leaves.
import { computed, getCurrentInstance, ref, watch } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareCallControls from "./FlareCallControls.vue";
import CallFailedKeys from "./CallFailedKeys.vue";
import CallBarKey from "./CallBarKey.vue";
import { useCallWindow } from "./useCallWindow";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useCallPhone } from "./useCallPhone";
import type { FlareCallMode, FlareCallParticipant, FlareCallState } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    participants: FlareCallParticipant[];
    mode: FlareCallMode;
    state: FlareCallState;
    title?: string;
    durationLabel?: string;
    statusDetail?: string;
    /** The call-again key's label in the failed state (call.redial when absent); the key shows while the host listens to recover. */
    recoveryText?: string;
    muted?: boolean;
    cameraOn?: boolean;
    speakerOn?: boolean;
    speakerPicker?: boolean;
    /** The host has not yet created a media session; hangup remains available. */
    controlsDisabled?: boolean;
    encrypted?: boolean;
    /** Show the "switch to video" control in an audio call; it emits `startVideo`. */
    canStartVideo?: boolean;
  }>(),
  { title: "", muted: false, cameraOn: true, speakerOn: false, speakerPicker: false, encrypted: false, canStartVideo: false },
);
const emit = defineEmits<{
  (e: "hangup"): void;
  (e: "recover"): void;
  (e: "toggleMute"): void;
  (e: "toggleCamera"): void;
  (e: "toggleSpeaker"): void;
  (e: "switchCamera"): void;
  (e: "addMember"): void;
  (e: "startVideo"): void;
  (e: "minimize"): void;
  (e: "selectParticipant", id: string): void;
  /** The failed state's close key. */
  (e: "close"): void;
}>();

const { t } = useFlareI18n();
const instance = getCurrentInstance();
const phone = useCallPhone();
const focusedId = ref<string | null>(null);
/** The enlarged tile: only with someone else to put in the strip. */
const focused = computed(() => props.participants.length > 1 ? props.participants.find(p => p.id === focusedId.value) : undefined);
watch(() => props.participants.map(p => p.id).join("\u0000"), () => {
  if (focusedId.value && !props.participants.some(p => p.id === focusedId.value)) focusedId.value = null;
});
function select(id: string): void {
  emit("selectParticipant", id);
  if (props.participants.length > 1) focusedId.value = focusedId.value === id ? null : id;
}

/** Columns and rows of the grid; a short last row is centred (flex-wrap), never left with a gap. */
const grid = computed(() => {
  const n = props.participants.length;
  const cols = n <= 1 ? 1 : n <= 4 ? 2 : n <= 6 ? (phone.value ? 2 : 3) : n <= 9 ? 3 : phone.value ? 3 : 4;
  return { cols, rows: Math.max(1, Math.ceil(n / cols)) };
});
/** People in the call: those still being called have not joined. */
const joined = computed(() => props.participants.filter(p => !p.calling).length);
const statusText = computed(() => {
  if (props.state === "reconnecting") return t("call.reconnecting");
  // The host's reason is the status itself (§3.3), so the detail line below stays empty.
  if (props.state === "failed") return props.statusDetail?.trim() || t("call.failed");
  if (props.state === "ended") return t("call.ended", { duration: props.durationLabel ?? "" }).replace(/[\s·]+$/, "");
  if (props.state === "connected") return props.durationLabel ?? t("call.connected");
  if (props.state === "ringing") return t("call.ringing");
  return t("call.calling");
});
const canRedial = () => Boolean(instance?.vnode.props?.onRecover);
const canAddMember = () => Boolean(instance?.vnode.props?.onAddMember);
const bar = useCallWindow(() => emit("minimize"));
</script>

<template>
  <div class="flare-group-call" :class="[`flare-group-call--${mode}`, { 'is-phone': phone }]">
    <header class="flare-group-call__bar">
      <CallBarKey v-if="bar.canMinimize()" class="flare-group-call__minimize" :icon="flareIcons.collapse" :label="t('call.minimize')" @click="bar.minimize" />
      <div class="flare-group-call__title">
        <div class="flare-group-call__name">{{ title || t("call.groupCall") }}</div>
        <div class="flare-group-call__meta" :class="{ 'is-failed': state === 'failed' }" role="status">
          {{ t("call.participants", { count: joined }) }} · {{ statusText }}
        </div>
        <div v-if="statusDetail && statusDetail.trim() !== statusText.trim()" class="flare-group-call__meta">{{ statusDetail }}</div>
      </div>
      <span v-if="encrypted" class="flare-group-call__secure">
        <n-icon aria-hidden="true" size="var(--flare-size-icon-size-sm)" :component="flareIcons.lock" />
        <span>{{ t("call.encrypted") }}</span>
      </span>
      <CallBarKey
        v-if="bar.expandable()"
        data-call-expand="true"
        :icon="bar.expanded() ? flareIcons.collapse : flareIcons.expand"
        :label="bar.expanded() ? t('call.collapse') : t('call.expand')"
        @click="bar.toggleExpanded"
      />
    </header>

    <div class="flare-group-call__stage">
    <div class="flare-group-call__grid" :class="{ 'is-focused': focused }" :style="{ '--flare-group-cols': grid.cols, '--flare-group-rows': grid.rows }">
      <button
        v-for="p in participants"
        :key="p.id"
        type="button"
        class="flare-group-call__tile"
        :class="{ 'is-speaking': p.speaking, 'is-self': p.isSelf, 'is-calling': p.calling, 'is-main': focused?.id === p.id }"
        :aria-pressed="participants.length > 1 ? focused?.id === p.id : undefined"
        :data-participant="p.id"
        @click="select(p.id)"
      >
        <div class="flare-group-call__stream">
          <!-- The host renders the video of a tile that shows video; an empty slot and every other tile show the avatar. -->
          <slot v-if="mode === 'video' && !p.cameraOff && !p.calling" name="tile" :participant="p">
            <FlareAvatar :user-id="p.id" :display-name="p.name" :avatar-url="p.avatarUrl" :size="flareCallAvatar.tile" />
          </slot>
          <template v-else>
            <FlareAvatar :user-id="p.id" :display-name="p.name" :avatar-url="p.avatarUrl" :size="flareCallAvatar.tile" />
            <span v-if="p.calling" class="flare-group-call__calling">{{ t("call.calling") }}</span>
          </template>
        </div>
        <div class="flare-group-call__tag">
          <span class="flare-group-call__pname">
            <n-icon v-if="p.muted" class="flare-group-call__mic" aria-hidden="true" size="var(--flare-size-font-size-sm)" :component="flareIcons['mic-off']" />
            <n-icon v-else-if="p.cameraOff && mode === 'video'" class="flare-group-call__mic" aria-hidden="true" size="var(--flare-size-font-size-sm)" :component="flareIcons['camera-off']" />
            <span class="flare-group-call__label">{{ p.isSelf ? t("call.you") : p.name }}</span>
          </span>
        </div>
      </button>
    </div>
    </div>

    <div class="flare-group-call__controls">
      <CallFailedKeys
        v-if="state === 'failed'"
        :mode="mode"
        :redial="canRedial()"
        :redial-text="recoveryText"
        @close="emit('close')"
        @redial="emit('recover')"
      />
      <FlareCallControls
        v-else
        :inert="state === 'ended'"
        :disabled="state === 'ended' || controlsDisabled"
        :muted="muted"
        :camera-on="cameraOn"
        :speaker-on="speakerOn"
        :speaker-picker="speakerPicker"
        :mode="mode"
        :show-add-member="canAddMember()"
        :can-start-video="canStartVideo"
        @toggle-mute="emit('toggleMute')"
        @toggle-camera="emit('toggleCamera')"
        @toggle-speaker="emit('toggleSpeaker')"
        @switch-camera="emit('switchCamera')"
        @add-member="emit('addMember')"
        @start-video="emit('startVideo')"
        @hangup="emit('hangup')"
      ><template v-if="$slots.devices" #devices><slot name="devices" /></template></FlareCallControls>
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
  min-height: 0;
  color: var(--flare-color-call-on-stage);
  overflow: hidden;
  background: linear-gradient(180deg, var(--flare-color-call-stage-tint), transparent 40%), var(--flare-color-call-stage);
  --flare-group-gap: var(--flare-size-spacing-sm);
}
.flare-group-call.is-phone { --flare-group-gap: var(--flare-size-spacing-xs); }
.flare-group-call__bar {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  padding: calc(env(safe-area-inset-top, 0px) + var(--flare-size-spacing-md)) var(--flare-size-spacing-lg) var(--flare-size-spacing-md);
}
.flare-group-call__tile:focus-visible {
  outline: var(--flare-size-component-focus-ring-width) solid var(--flare-color-border-selected);
  outline-offset: var(--flare-size-component-focus-ring-offset);
}
.flare-group-call__title { flex: 1 1 auto; min-width: 0; }
.flare-group-call__name {
  font-size: var(--flare-size-font-size-xl);
  font-weight: var(--flare-size-font-weight-semibold);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-group-call__meta {
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-call-on-stage-secondary);
  font-variant-numeric: tabular-nums;
}
/* §12.17: a failure on the stage reads in call.errorText. */
.flare-group-call__meta.is-failed { color: var(--flare-color-call-error-text); }
.flare-group-call__secure {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  flex: 0 0 auto;
  color: var(--flare-color-call-on-stage-secondary);
  font-size: var(--flare-size-font-size-sm);
}
/* The grid's positioned box: an enlarged tile lies over it, outside the strip's horizontal scrolling. */
.flare-group-call__stage { position: relative; flex: 1 1 auto; min-height: 0; display: flex; }
/* Rows of equal height; the last short row centres its tiles. */
.flare-group-call__grid {
  flex: 1 1 auto;
  min-height: 0;
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  align-content: stretch;
  gap: var(--flare-group-gap);
  padding: 0 var(--flare-size-spacing-md) var(--flare-size-spacing-md);
  overflow: auto;
}
.flare-group-call__tile {
  position: relative;
  box-sizing: border-box;
  flex: 0 0 calc((100% - (var(--flare-group-cols) - 1) * var(--flare-group-gap)) / var(--flare-group-cols));
  height: calc((100% - (var(--flare-group-rows) - 1) * var(--flare-group-gap)) / var(--flare-group-rows));
  min-height: calc(var(--flare-size-component-call-tile-avatar) * 2);
  display: grid;
  place-items: center;
  padding: 0;
  border: 0;
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-call-tile);
  color: inherit;
  font: inherit;
  cursor: pointer;
  overflow: hidden;
}
/* Speaking: a 2-wide inner ring, drawn over the tile's video (which now fills the tile). */
.flare-group-call__tile.is-speaking::after {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  box-shadow: inset 0 0 0 2px var(--flare-color-call-speaking);
  pointer-events: none;
}
.flare-group-call__stream {
  display: grid;
  place-items: center;
  align-content: center;
  gap: var(--flare-size-spacing-xs);
  width: 100%;
  height: 100%;
}
.flare-group-call__stream :deep(.im-avatar) {
  width: var(--flare-size-component-call-tile-avatar) !important;
  height: var(--flare-size-component-call-tile-avatar) !important;
  --avatar-size: var(--flare-size-component-call-tile-avatar) !important;
}
.flare-group-call__tile.is-calling .flare-group-call__stream :deep(.im-avatar) { opacity: 0.5; }
.flare-group-call__calling { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-call-on-stage-secondary); }
.flare-group-call__stream :deep(video),
.flare-group-call__stream :deep(img) {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
/* §3.4 "视频画面 cover": a host's video fills the whole tile. As a grid item its 100% height resolved against an
   auto row, so a tall phone tile showed a 16:9 band with the tile colour above and below. */
.flare-group-call__stream :deep(video) { position: absolute; inset: 0; }
.flare-group-call__tag {
  position: absolute;
  inset-inline: var(--flare-size-spacing-sm);
  bottom: var(--flare-size-spacing-sm);
  display: flex;
  min-width: 0;
}
.flare-group-call__pname {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-3xs);
  min-width: 0;
  padding: var(--flare-size-spacing-3xs) var(--flare-size-spacing-2xs);
  border-radius: var(--flare-size-radius-sm);
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-call-on-stage);
  background: var(--flare-color-call-chip);
}
.flare-group-call__label { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
/* Focused: the main tile fills the stage above a bottom strip of component.callStripTileHeight (96) tiles. */
.flare-group-call__grid.is-focused {
  --flare-group-strip: var(--flare-size-component-call-strip-tile-height);
  flex-wrap: nowrap;
  align-items: flex-end;
  justify-content: safe center;
  overflow-x: auto;
  overflow-y: hidden;
}
.flare-group-call__grid.is-focused .flare-group-call__tile:not(.is-main) {
  flex: 0 0 auto;
  height: var(--flare-group-strip);
  min-height: 0;
  aspect-ratio: 4 / 3;
}
.flare-group-call__grid.is-focused .flare-group-call__tile:not(.is-main) .flare-group-call__stream :deep(.im-avatar) {
  width: var(--flare-size-layout-avatar-size) !important;
  height: var(--flare-size-layout-avatar-size) !important;
  --avatar-size: var(--flare-size-layout-avatar-size) !important;
}
.flare-group-call__grid.is-focused .flare-group-call__tile.is-main {
  position: absolute;
  inset: 0 var(--flare-size-spacing-md) calc(var(--flare-group-strip) + var(--flare-group-gap) + var(--flare-size-spacing-md));
  width: auto;
  height: auto;
  min-height: 0;
}
.flare-group-call__controls {
  flex: 0 0 auto;
  display: flex;
  justify-content: center;
  padding: var(--flare-size-spacing-lg) var(--flare-size-spacing-md) calc(var(--flare-size-spacing-2xl) + env(safe-area-inset-bottom, 0px));
}
.flare-group-call__controls [inert] { opacity: var(--flare-opacity-disabled); }
</style>
