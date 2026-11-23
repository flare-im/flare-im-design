<script setup lang="ts">
import { flareCallAvatar } from "./callSizes";
// An incoming call (docs/plugin-experience.md §3.2) on the call stage. `fullscreen` (phones): avatar, name, the
// invite line, then decline and answer at a quarter and three quarters of the width; the answer key takes focus.
// `banner` (PC): a non-modal card at the window's top trailing corner that never takes focus, so Enter can never
// answer by accident. A video invite adds "answer with audio" (acceptAudio). Both announce the caller politely.
import { computed, nextTick, onMounted, ref } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    callerName: string;
    mode: "audio" | "video";
    callerAvatarUrl?: string;
    /** fullscreen (phones, default) or banner: the PC non-modal top-right card. */
    presentation?: "fullscreen" | "banner";
  }>(),
  { presentation: "fullscreen" },
);
const emit = defineEmits<{ (e: "accept"): void; (e: "reject"): void; (e: "acceptAudio"): void }>();

const { t } = useFlareI18n();
const answerIcon = computed(() => (props.mode === "video" ? flareIcons.video : flareIcons.phone));
const hint = computed(() => (props.mode === "video" ? t("call.invitingVideo") : t("call.invitingVoice")));
const banner = computed(() => props.presentation === "banner");
// A live region only speaks what changes after it exists: fill it once mounted.
const announcement = ref("");
const answerKey = ref<HTMLButtonElement | null>(null);
onMounted(async () => {
  await nextTick();
  announcement.value = `${props.callerName} ${hint.value}`;
  if (!banner.value) answerKey.value?.focus({ preventScroll: true });
});
</script>

<template>
  <section class="flare-incoming" :class="`flare-incoming--${presentation}`" :aria-label="callerName" :data-presentation="presentation">
    <span class="flare-incoming__live" role="status" aria-live="polite">{{ announcement }}</span>
    <div class="flare-incoming__peer">
      <div class="flare-incoming__avatar">
        <!-- FlareAvatar takes px; the CSS below sizes it from tokens. -->
        <FlareAvatar :user-id="callerName" :display-name="callerName" :avatar-url="callerAvatarUrl" :size="banner ? flareCallAvatar.banner : flareCallAvatar.stage" />
      </div>
      <div class="flare-incoming__text">
        <div class="flare-incoming__name">{{ callerName }}</div>
        <div class="flare-incoming__hint">{{ hint }}</div>
      </div>
    </div>

    <div class="flare-incoming__actions">
      <button
        v-if="mode === 'video'"
        type="button"
        class="flare-incoming__col flare-incoming__col--audio"
        :aria-label="t('call.answerAudio')"
        :title="t('call.answerAudio')"
        data-incoming-audio="true"
        @click="emit('acceptAudio')"
      >
        <span class="flare-incoming__ico is-audio"><n-icon aria-hidden="true" size="var(--flare-size-icon-size-md)" :component="flareIcons.phone" /></span>
      </button>
      <button type="button" class="flare-incoming__col" :aria-label="banner ? t('call.decline') : undefined" :title="banner ? t('call.decline') : undefined" data-incoming-reject="true" @click="emit('reject')">
        <span class="flare-incoming__ico is-reject"><n-icon aria-hidden="true" :size="banner ? 'var(--flare-size-icon-size-md)' : 'var(--flare-size-icon-size-xl)'" :component="flareIcons['end-call']" /></span>
        <span v-if="!banner" class="flare-incoming__lbl">{{ t("call.decline") }}</span>
      </button>
      <button ref="answerKey" type="button" class="flare-incoming__col" :aria-label="banner ? t('call.answer') : undefined" :title="banner ? t('call.answer') : undefined" data-incoming-accept="true" @click="emit('accept')">
        <span class="flare-incoming__ico is-accept"><n-icon aria-hidden="true" :size="banner ? 'var(--flare-size-icon-size-md)' : 'var(--flare-size-icon-size-xl)'" :component="answerIcon" /></span>
        <span v-if="!banner" class="flare-incoming__lbl">{{ t("call.answer") }}</span>
      </button>
    </div>
  </section>
</template>

<style scoped>
.flare-incoming {
  position: relative;
  box-sizing: border-box;
  color: var(--flare-color-call-on-stage);
  background: linear-gradient(180deg, var(--flare-color-call-stage-tint), transparent 40%), var(--flare-color-call-stage);
}
.flare-incoming__live {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
.flare-incoming__avatar {
  position: relative;
  flex: none;
  border-radius: var(--flare-size-radius-full);
}
.flare-incoming__name { font-weight: var(--flare-size-font-weight-semibold); overflow-wrap: anywhere; }
.flare-incoming__hint { color: var(--flare-color-call-on-stage-secondary); }
.flare-incoming__col {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  padding: 0;
  border: 0;
  background: none;
  color: inherit;
  font: inherit;
  cursor: pointer;
}
/* The focus ring follows the round key. */
.flare-incoming__col:focus-visible { outline: none; }
.flare-incoming__col:focus-visible .flare-incoming__ico {
  outline: var(--flare-size-component-focus-ring-width) solid var(--flare-color-border-selected);
  outline-offset: var(--flare-size-component-focus-ring-offset);
}
.flare-incoming__ico {
  display: grid;
  place-items: center;
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-color-call-on-stage);
  transition: transform var(--flare-transition-fast), background var(--flare-transition-fast);
}
.flare-incoming__col:active .flare-incoming__ico { transform: scale(var(--flare-size-component-press-scale)); }
.flare-incoming__ico.is-reject { background: var(--flare-color-call-hangup); }
.flare-incoming__col:active .is-reject { background: var(--flare-color-call-hangup-pressed); }
.flare-incoming__ico.is-accept { background: var(--flare-color-call-accept); }
.flare-incoming__col:active .is-accept { background: var(--flare-color-call-accept-pressed); }
.flare-incoming__ico.is-audio { background: var(--flare-color-call-control); }
@media (hover: hover) {
  .flare-incoming__col:hover .is-audio { background: var(--flare-color-call-control-hover); }
}
.flare-incoming__col:active .is-audio { background: var(--flare-color-call-control-hover); }
/* Reduced motion: a press changes colour only. */
@media (prefers-reduced-motion: reduce) {
  .flare-incoming__col:active .flare-incoming__ico { transform: none; }
}
.flare-incoming__lbl { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-call-on-stage-secondary); }

/* ── fullscreen ───────────────────────────────────────────────────────── */
.flare-incoming--fullscreen {
  width: 100%;
  height: 100%;
  min-height: 0;
  display: flex;
  flex-direction: column;
  padding: var(--flare-size-spacing-lg) var(--flare-size-spacing-lg) calc(var(--flare-size-component-call-hangup-size) + env(safe-area-inset-bottom, 0px));
  overflow: auto;
}
.flare-incoming--fullscreen .flare-incoming__peer {
  flex: 1 0 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--flare-size-spacing-lg);
  /* The avatar sits about 22% down the screen. */
  padding-top: 22%;
  text-align: center;
}
.flare-incoming--fullscreen .flare-incoming__text { display: grid; gap: var(--flare-size-spacing-xs); }
.flare-incoming--fullscreen .flare-incoming__avatar :deep(.im-avatar) {
  width: var(--flare-size-component-call-avatar-size) !important;
  height: var(--flare-size-component-call-avatar-size) !important;
  --avatar-size: var(--flare-size-component-call-avatar-size) !important;
}
/* Ringing: a 2-wide halo of the stage ink at 20%, breathing over 1.6 s; still under reduced motion. */
.flare-incoming--fullscreen .flare-incoming__avatar::after {
  content: "";
  position: absolute;
  inset: calc(var(--flare-size-spacing-xs) * -1);
  border-radius: var(--flare-size-radius-full);
  border: 2px solid color-mix(in srgb, var(--flare-color-call-on-stage) 20%, transparent);
  animation: flare-incoming-breathe 1.6s ease-in-out infinite alternate;
}
@keyframes flare-incoming-breathe {
  from { transform: scale(1); opacity: 1; }
  to { transform: scale(1.12); opacity: 0.4; }
}
@media (prefers-reduced-motion: reduce) {
  .flare-incoming--fullscreen .flare-incoming__avatar::after { animation: none; }
}
.flare-incoming--fullscreen .flare-incoming__name { font-size: var(--flare-size-font-size-5xl); }
.flare-incoming--fullscreen .flare-incoming__hint { font-size: var(--flare-size-font-size-xl); }
/* Decline and answer centred at a quarter and three quarters of the width; answer-with-audio above, between them. */
.flare-incoming--fullscreen .flare-incoming__actions {
  flex: none;
  display: grid;
  grid-template-columns: 1fr 1fr;
  justify-items: center;
  row-gap: var(--flare-size-spacing-2xl);
}
.flare-incoming--fullscreen .flare-incoming__col--audio { grid-column: 1 / -1; }
.flare-incoming--fullscreen .flare-incoming__ico {
  width: var(--flare-size-component-call-hangup-size);
  height: var(--flare-size-component-call-hangup-size);
}
.flare-incoming--fullscreen .flare-incoming__ico.is-audio {
  width: var(--flare-size-layout-control-height-md);
  height: var(--flare-size-layout-control-height-md);
}

/* ── banner (PC) ──────────────────────────────────────────────────────── */
.flare-incoming--banner {
  position: fixed;
  top: var(--flare-size-spacing-lg);
  inset-inline-end: var(--flare-size-spacing-lg);
  /* Above modals (it never blocks them), below toasts. */
  z-index: calc(var(--flare-z-index-toast) - 1);
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  width: min(var(--flare-size-component-call-incoming-banner-width), calc(100vw - var(--flare-size-spacing-lg) * 2));
  box-sizing: border-box;
  height: var(--flare-size-component-call-incoming-banner-height);
  padding: 0 var(--flare-size-spacing-lg);
  border-radius: var(--flare-size-radius-xl);
  box-shadow: var(--flare-shadow-lg);
}
.flare-incoming--banner .flare-incoming__peer {
  flex: 1 1 auto;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
}
.flare-incoming--banner .flare-incoming__avatar :deep(.im-avatar) {
  width: var(--flare-size-component-call-incoming-banner-avatar) !important;
  height: var(--flare-size-component-call-incoming-banner-avatar) !important;
  --avatar-size: var(--flare-size-component-call-incoming-banner-avatar) !important;
}
.flare-incoming--banner .flare-incoming__text { min-width: 0; }
.flare-incoming--banner .flare-incoming__name {
  font-size: var(--flare-size-font-size-xl);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-incoming--banner .flare-incoming__hint { font-size: var(--flare-size-font-size-md); }
.flare-incoming--banner .flare-incoming__actions { flex: none; display: flex; gap: var(--flare-size-spacing-sm); }
.flare-incoming--banner .flare-incoming__ico {
  width: var(--flare-size-layout-control-height-md);
  height: var(--flare-size-layout-control-height-md);
}
/* 40 keys, 44 hit areas. */
.flare-incoming--banner .flare-incoming__col::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  width: var(--flare-size-layout-touch-target-min);
  height: var(--flare-size-layout-touch-target-min);
  transform: translate(-50%, -50%);
}
</style>
