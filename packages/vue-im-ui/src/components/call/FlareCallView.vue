<script setup lang="ts">
import { flareCallAvatar } from "./callSizes";
// A one-to-one call (docs/plugin-experience.md §3.3): one dark stage (colors.call.*) for voice and video in every
// theme. The peer sits in the middle of the stage until the call is connected with the peer's video showing, then the
// name and status move to the top bar, between minimize and (in a PC window) expand. A failed call says the host's
// reason as its status and trades the control bar for close + call again; an ended call is inert.
import { computed, getCurrentInstance, onBeforeUnmount, onMounted, ref, useSlots, watch } from "vue";
import type { FlareCallState } from "../../shared/contracts/call";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareCallControls from "./FlareCallControls.vue";
import CallFailedKeys from "./CallFailedKeys.vue";
import CallBarKey from "./CallBarKey.vue";
import { useCallWindow } from "./useCallWindow";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    peerName: string;
    mode: "audio" | "video";
    state: FlareCallState;
    durationLabel?: string;
    statusDetail?: string;
    /** The call-again key's label in the failed state (call.redial when absent); the key shows while the host listens to recover. */
    recoveryText?: string;
    peerAvatarUrl?: string;
    muted?: boolean;
    cameraOn?: boolean;
    speakerOn?: boolean;
    speakerPicker?: boolean;
    /** The host has not yet created a media session; hangup remains available. */
    controlsDisabled?: boolean;
    /** Show lock + call.encrypted in the top bar. */
    encrypted?: boolean;
    /** The peer muted their microphone: mic-off and call.peerMuted after the status line. */
    peerMuted?: boolean;
    /** The peer is speaking: the speaking ring around the avatar (never while peerMuted). */
    peerSpeaking?: boolean;
    /** Show the "switch to video" control in an audio call; it emits `startVideo`. */
    canStartVideo?: boolean;
  }>(),
  { muted: false, cameraOn: true, speakerOn: false, speakerPicker: false, encrypted: false, peerMuted: false, peerSpeaking: false, canStartVideo: false },
);
const emit = defineEmits<{
  (e: "hangup"): void;
  (e: "recover"): void;
  (e: "toggleMute"): void;
  (e: "toggleCamera"): void;
  (e: "toggleSpeaker"): void;
  (e: "switchCamera"): void;
  (e: "startVideo"): void;
  (e: "minimize"): void;
  /** The failed state's close key. */
  (e: "close"): void;
}>();

const { t } = useFlareI18n();
const instance = getCurrentInstance();
const statusText = computed(() => {
  if (props.state === "reconnecting") return t("call.reconnecting");
  // The host's reason is the status line itself (§3.3), so the detail line below stays empty.
  if (props.state === "failed") return props.statusDetail?.trim() || t("call.failed");
  // Without a duration the separator would dangle: "通话已结束 · ".
  if (props.state === "ended") return t("call.ended", { duration: props.durationLabel ?? "" }).replace(/[\s·]+$/, "");
  if (props.state === "connected") return props.durationLabel ?? t("call.connected");
  if (props.state === "ringing") return t("call.ringing");
  return props.mode === "video" ? t("call.waitingAnswer") : t("call.calling");
});
const pulsing = computed(() => props.state === "calling" || props.state === "ringing");
const speaking = computed(() => props.peerSpeaking && !props.peerMuted);
// Slots change after asynchronous camera capture; read them during each render.
const slots = useSlots();
const hasPreview = () => props.mode === "video" && !!slots.localVideo;
/** The peer's picture covers the stage: the avatar goes. */
const hasPicture = () => props.mode === "video" && !!slots.video;
/** Connected with the peer's picture: name and status ride in the top bar. */
const onTop = () => props.state === "connected" && hasPicture();
const bar = useCallWindow(() => emit("minimize"));
/** Listeners are not reactive props: read at render. */
const canRedial = () => Boolean(instance?.vnode.props?.onRecover);

// §3.3 local preview: drag it, it snaps to the nearest corner of the stage; a tap (or Enter / Space) swaps which
// picture fills the stage. Both slots stay mounted where they are, only their classes trade places.
const root = ref<HTMLElement | null>(null);
const swapped = ref(false);
const corner = ref<{ top: boolean; end: boolean }>({ top: true, end: true });
const drag = ref<{ x: number; y: number } | null>(null);
/** Pointer travel (CSS px) under which a press is a tap, not a drag. */
const TAP_SLOP = 6;
let press: { x: number; y: number; id: number } | null = null;
function previewDown(event: PointerEvent): void {
  press = { x: event.clientX, y: event.clientY, id: event.pointerId };
  drag.value = { x: 0, y: 0 };
  window.addEventListener("pointermove", previewMove);
  window.addEventListener("pointerup", previewUp);
  window.addEventListener("pointercancel", previewUp);
}
function previewMove(event: PointerEvent): void {
  if (press && event.pointerId === press.id) drag.value = { x: event.clientX - press.x, y: event.clientY - press.y };
}
function previewUp(event: PointerEvent): void {
  if (!press || event.pointerId !== press.id) return;
  window.removeEventListener("pointermove", previewMove);
  window.removeEventListener("pointerup", previewUp);
  window.removeEventListener("pointercancel", previewUp);
  const moved = Math.hypot(event.clientX - press.x, event.clientY - press.y);
  press = null;
  drag.value = null;
  if (event.type === "pointercancel") return;
  if (moved < TAP_SLOP) {
    swapped.value = !swapped.value;
    return;
  }
  const box = root.value?.getBoundingClientRect();
  if (!box) return;
  const rtl = getComputedStyle(root.value!).direction === "rtl";
  const right = event.clientX > box.left + box.width / 2;
  corner.value = { top: event.clientY < box.top + box.height / 2, end: rtl ? !right : right };
}
function previewKey(event: KeyboardEvent): void {
  if (event.key !== "Enter" && event.key !== " ") return;
  event.preventDefault();
  swapped.value = !swapped.value;
}
const pipStyle = computed(() => drag.value ? { transform: `translate(${drag.value.x}px, ${drag.value.y}px)` } : undefined);
const pipBindings = computed(() => ({
  class: ["is-pip", corner.value.top ? "is-top" : "is-bottom", corner.value.end ? "is-end" : "is-start", { "is-dragging": Boolean(drag.value) }],
  style: pipStyle.value,
  role: "button",
  tabindex: 0,
  "aria-label": t("call.swapVideo"),
  "data-call-pip": "true",
  onPointerdown: previewDown,
  onKeydown: previewKey,
}));
watch(() => props.mode, mode => { if (mode !== "video") swapped.value = false; });

// §3.3 top bar: with the peer's video on a connected call it fades after 4 s without a pointer move, tap or focus,
// and comes back on any of them. Never under reduced motion.
const FADE_AFTER_MS = 4000;
const chromeHidden = ref(false);
let fadeTimer: ReturnType<typeof setTimeout> | undefined;
const reducedMotion = () => typeof window !== "undefined" && Boolean(window.matchMedia?.("(prefers-reduced-motion: reduce)").matches);
const fades = () => onTop() && !reducedMotion();
function wake(): void {
  chromeHidden.value = false;
  clearTimeout(fadeTimer);
  fadeTimer = setTimeout(() => { chromeHidden.value = fades(); }, FADE_AFTER_MS);
}
watch(() => [props.mode, props.state], wake);
onMounted(wake);
onBeforeUnmount(() => {
  clearTimeout(fadeTimer);
  window.removeEventListener("pointermove", previewMove);
  window.removeEventListener("pointerup", previewUp);
  window.removeEventListener("pointercancel", previewUp);
});
</script>

<template>
  <div
    ref="root"
    class="flare-call-view"
    :class="[`flare-call-view--${state}`, `flare-call-view--${mode}`, { 'flare-call-view--preview': hasPreview(), 'is-chrome-hidden': chromeHidden }]"
    @pointermove="wake"
    @pointerdown="wake"
    @focusin="wake"
  >
    <div v-if="mode === 'video'" class="flare-call-view__video" v-bind="swapped && hasPreview() ? pipBindings : { class: 'is-full' }">
      <slot name="video" />
    </div>
    <!-- The host's own camera, as a picture-in-picture in a corner (top trailing at first). -->
    <div v-if="hasPreview()" class="flare-call-view__local" v-bind="swapped ? { class: 'is-full' } : pipBindings">
      <slot name="localVideo" />
    </div>

    <!-- §3.1 top bar: minimize at the start; the peer in the middle once connected on video; encryption and the PC
         window's expand / collapse at the end. -->
    <div class="flare-call-view__bar">
      <span class="flare-call-view__side">
        <CallBarKey v-if="bar.canMinimize()" class="flare-call-view__minimize" :icon="flareIcons.collapse" :label="t('call.minimize')" @click="bar.minimize" />
      </span>
      <div v-if="onTop()" class="flare-call-view__peer is-top">
        <div class="flare-call-view__name">{{ peerName }}</div>
        <div class="flare-call-view__status" role="status">
          {{ statusText }}
          <span v-if="peerMuted" class="flare-call-view__muted"><n-icon aria-hidden="true" size="var(--flare-size-icon-size-xs)" :component="flareIcons['mic-off']" />{{ t("call.peerMuted") }}</span>
        </div>
      </div>
      <span class="flare-call-view__side is-end">
        <span v-if="encrypted" class="flare-call-view__secure">
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
      </span>
    </div>

    <div class="flare-call-view__stage">
      <div v-if="!hasPicture()" class="flare-call-view__avatar" :class="{ 'is-pulsing': pulsing, 'is-speaking': speaking }">
        <!-- FlareAvatar takes px; the CSS below sizes it from component.callAvatarSize(Window). -->
        <FlareAvatar :user-id="peerName" :display-name="peerName" :avatar-url="peerAvatarUrl" :size="flareCallAvatar.stage" />
      </div>
      <div v-if="!onTop()" class="flare-call-view__peer">
        <div class="flare-call-view__name">{{ peerName }}</div>
        <div class="flare-call-view__status" role="status">
          <span v-if="state === 'reconnecting'" class="flare-call-view__dot" aria-hidden="true" />{{ statusText }}
          <span v-if="peerMuted" class="flare-call-view__muted"><n-icon aria-hidden="true" size="var(--flare-size-icon-size-xs)" :component="flareIcons['mic-off']" />{{ t("call.peerMuted") }}</span>
        </div>
        <div v-if="statusDetail && statusDetail.trim() !== statusText.trim()" class="flare-call-view__status">{{ statusDetail }}</div>
      </div>
    </div>

    <div class="flare-call-view__controls" :inert="state === 'ended'">
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
        :disabled="state === 'ended' || controlsDisabled"
        :muted="muted"
        :camera-on="cameraOn"
        :speaker-on="speakerOn"
        :speaker-picker="speakerPicker"
        :mode="mode"
        :can-start-video="canStartVideo"
        @toggle-mute="emit('toggleMute')"
        @toggle-camera="emit('toggleCamera')"
        @toggle-speaker="emit('toggleSpeaker')"
        @switch-camera="emit('switchCamera')"
        @start-video="emit('startVideo')"
        @hangup="emit('hangup')"
      ><template v-if="$slots.devices" #devices><slot name="devices" /></template></FlareCallControls>
    </div>
  </div>
</template>

<style scoped>
.flare-call-view {
  position: relative;
  width: 100%;
  height: 100%;
  min-height: 0;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
  padding: var(--flare-size-spacing-lg) var(--flare-size-spacing-lg) calc(var(--flare-size-spacing-2xl) + env(safe-area-inset-bottom, 0px));
  gap: var(--flare-size-spacing-lg);
  color: var(--flare-color-call-on-stage);
  overflow: auto;
  /* The same stage in light and dark themes: a tint over the top 40%, fading out. */
  background: linear-gradient(180deg, var(--flare-color-call-stage-tint), transparent 40%), var(--flare-color-call-stage);
  --flare-call-avatar: var(--flare-size-component-call-avatar-size);
  --flare-call-name-size: var(--flare-size-font-size-5xl);
}
/* A PC or tablet window is smaller than a phone's full screen. */
@media (min-width: 600px) {
  .flare-call-view {
    --flare-call-avatar: var(--flare-size-component-call-avatar-size-window);
    --flare-call-name-size: var(--flare-size-font-size-4xl);
  }
}
.flare-call-view__video :deep(video) { width: 100%; height: 100%; object-fit: cover; }
/* The picture that fills the stage. */
.is-full {
  position: absolute;
  z-index: 0;
  inset: 0;
}
/* Reconnecting: the last frame stays, dimmed by 40%. */
.flare-call-view--reconnecting .flare-call-view__video { filter: brightness(calc(1 - var(--flare-opacity-dim))); }
.flare-call-view--video::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background: linear-gradient(var(--flare-color-call-chip), transparent 28%, transparent 60%, var(--flare-color-call-chip));
}
.flare-call-view__bar {
  position: relative;
  z-index: 3;
  flex: none;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-height: var(--flare-size-layout-touch-target);
  padding-top: env(safe-area-inset-top, 0px);
}
/* The two ends share the spare width, so the peer between them stays centred; they never shrink under their keys. */
.flare-call-view__side {
  flex: 1 0 0;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
}
.flare-call-view__side.is-end { justify-content: flex-end; }
.flare-call-view__secure {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  color: var(--flare-color-call-on-stage-secondary);
  font-size: var(--flare-size-font-size-sm);
  white-space: nowrap;
}
.flare-call-view__stage {
  position: relative;
  z-index: 1;
  flex: 1 1 auto;
  min-height: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--flare-size-spacing-lg);
}
.flare-call-view__avatar {
  position: relative;
  border-radius: var(--flare-size-radius-full);
}
.flare-call-view__avatar :deep(.im-avatar) {
  width: var(--flare-call-avatar) !important;
  height: var(--flare-call-avatar) !important;
  --avatar-size: var(--flare-call-avatar) !important;
}
/* Calling / ringing: a soft breathing halo around the avatar; still under reduced motion. */
.flare-call-view__avatar.is-pulsing::after {
  content: "";
  position: absolute;
  inset: calc(var(--flare-size-spacing-xs) * -1);
  border-radius: var(--flare-size-radius-full);
  border: 2px solid color-mix(in srgb, var(--flare-color-call-on-stage) 20%, transparent);
  animation: flare-call-breathe 1.6s ease-in-out infinite alternate;
}
@keyframes flare-call-breathe {
  from { transform: scale(1); opacity: 1; }
  to { transform: scale(1.12); opacity: 0.4; }
}
/* Speaking: a 3-wide ring of color.call.speaking. */
.flare-call-view__avatar.is-speaking {
  box-shadow: 0 0 0 3px var(--flare-color-call-speaking);
  transition: box-shadow var(--flare-transition-fast);
}
.flare-call-view__peer {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  max-width: 100%;
  text-align: center;
  overflow-wrap: anywhere;
}
/* Connected on video: name and status in the top bar, one line each. */
.flare-call-view__peer.is-top { flex: 0 1 auto; min-width: 0; gap: 0; }
.flare-call-view__peer.is-top .flare-call-view__status { font-size: var(--flare-size-font-size-md); }
.flare-call-view__peer.is-top .flare-call-view__name {
  max-width: 100%;
  font-size: var(--flare-size-font-size-xl);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-call-view__name {
  font-size: var(--flare-call-name-size);
  font-weight: var(--flare-size-font-weight-semibold);
}
/* The peer muted: mic-off 14 and its words after the status (§12.17). */
.flare-call-view__muted {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-3xs);
}
.flare-call-view__status {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  color: var(--flare-color-call-on-stage-secondary);
  font-size: var(--flare-size-font-size-xl);
  font-variant-numeric: tabular-nums;
}
/* §12.17: a failure on the stage reads in call.errorText. */
.flare-call-view--failed .flare-call-view__status { color: var(--flare-color-call-error-text); }
.flare-call-view__dot {
  flex: none;
  width: var(--flare-size-spacing-sm);
  height: var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-warning);
  animation: flare-call-dot 1.2s ease-in-out infinite alternate;
}
@keyframes flare-call-dot { to { opacity: 0.35; } }
@media (prefers-reduced-motion: reduce) {
  .flare-call-view__avatar.is-pulsing::after,
  .flare-call-view__dot { animation: none; }
}
/* The small picture: a corner of the stage, below the top bar and above the control bar; drag to move, tap to swap. */
.is-pip {
  position: absolute;
  z-index: 2;
  width: var(--flare-size-component-call-preview-width);
  aspect-ratio: 9 / 16;
  overflow: hidden;
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-call-stage);
  box-shadow: var(--flare-shadow-md);
  cursor: grab;
  touch-action: none;
}
.is-pip.is-dragging { cursor: grabbing; }
.is-pip:focus-visible { outline: var(--flare-size-component-focus-ring-width) solid var(--flare-color-border-selected); outline-offset: var(--flare-size-component-focus-ring-offset); }
.is-pip.is-top { top: calc(env(safe-area-inset-top, 0px) + var(--flare-size-spacing-lg) * 2 + var(--flare-size-layout-touch-target)); }
.is-pip.is-bottom { bottom: calc(env(safe-area-inset-bottom, 0px) + var(--flare-size-spacing-2xl) * 2 + var(--flare-size-component-call-control-size) + var(--flare-size-layout-touch-target)); }
.is-pip.is-end { inset-inline-end: var(--flare-size-spacing-lg); }
.is-pip.is-start { inset-inline-start: var(--flare-size-spacing-lg); }
.flare-call-view__video :deep(img),
.flare-call-view__local :deep(video),
.flare-call-view__local :deep(img) {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.flare-call-view__controls {
  position: relative;
  z-index: 3;
  flex: none;
  display: flex;
  justify-content: center;
}
.flare-call-view--ended .flare-call-view__controls { opacity: var(--flare-opacity-disabled); }
/* The fading top bar (never under reduced motion: the script does not hide it then). */
.flare-call-view__bar { transition: opacity var(--flare-transition-normal); }
.is-chrome-hidden .flare-call-view__bar { opacity: 0; pointer-events: none; }
</style>
