<script setup lang="ts">
// A compact status strip (connection / sync / runtime state) with an optional
// pulsing dot and an optional inline action. Replaces the per-app bespoke
// runtime/connection/sync banners.
//
// `floating` is for a banner a host lifts out of the page flow and hangs over the
// content (a global connection notice, say). The inline fill is the tone at 10%:
// right on the page's own surface, but as an overlay the content underneath shows
// straight through it and the two sets of words collide. The floating form puts the
// tint on an opaque surface and adds the elevation that says it is above the page.
//
// `title` and `dismissible` (Vue only) make the same strip carry a notice a person reads once and
// puts away — a console's platform announcement: a bold first line over the text, and a close key
// that reports `dismiss` (the host remembers what was dismissed). Without them nothing changes.
import type { FlareTone } from "../../shared/contracts/tone";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import FlareIcon from "./FlareIcon.vue";

withDefaults(
  defineProps<{
    text: string;
    tone?: FlareTone;
    dot?: boolean;
    pulse?: boolean;
    actionText?: string;
    floating?: boolean;
    /** A bold first line over the text (a notice's subject). */
    title?: string;
    /** Draw a close key that reports `dismiss`; the host removes the banner and remembers it. */
    dismissible?: boolean;
  }>(),
  { tone: "info", dot: true, pulse: false, floating: false, title: undefined, dismissible: false },
);
const emit = defineEmits<{ (e: "action"): void; (e: "dismiss"): void }>();
const { t } = useFlareI18nOptional();
</script>

<template>
  <div
    class="flare-status-banner"
    :class="[`flare-status-banner--${tone}`, { 'is-floating': floating }]"
    role="status"
    aria-live="polite"
  >
    <span
      v-if="dot"
      aria-hidden="true"
      class="flare-status-banner__dot"
      :class="{ 'flare-status-banner__dot--pulse': pulse }"
    />
    <span v-if="title" class="flare-status-banner__body">
      <strong class="flare-status-banner__title">{{ title }}</strong>
      <span class="flare-status-banner__text">{{ text }}</span>
    </span>
    <span v-else class="flare-status-banner__text">{{ text }}</span>
    <button
      v-if="actionText"
      type="button"
      class="flare-status-banner__action"
      @click="emit('action')"
    >
      {{ actionText }}
    </button>
    <button
      v-if="dismissible"
      type="button"
      class="flare-status-banner__dismiss"
      :aria-label="t('common.close')"
      @click="emit('dismiss')"
    >
      <FlareIcon name="close" :size="16" />
    </button>
  </div>
</template>

<style scoped>
.flare-status-banner {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px var(--flare-size-spacing-2md);
  font-size: 13px;
  line-height: 1.4;
  border-radius: 10px;
  color: var(--flare-tone);
  background: color-mix(in srgb, var(--flare-tone) 10%, transparent);
  border: 1px solid color-mix(in srgb, var(--flare-tone) 24%, transparent);
}

/* Over content the tint alone is see-through; it needs a surface under it. */
.flare-status-banner.is-floating {
  background:
    linear-gradient(color-mix(in srgb, var(--flare-tone) 10%, transparent), color-mix(in srgb, var(--flare-tone) 10%, transparent)),
    var(--flare-color-bg-elevated);
  box-shadow: var(--flare-shadow-md);
}

.flare-status-banner--info {
  --flare-tone: var(--flare-color-info);
}
.flare-status-banner--success {
  --flare-tone: var(--flare-color-success);
}
.flare-status-banner--warning {
  --flare-tone: var(--flare-color-warning);
}
.flare-status-banner--danger {
  --flare-tone: var(--flare-color-error);
}
.flare-status-banner--neutral {
  --flare-tone: var(--flare-color-text-secondary);
}

.flare-status-banner__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex: none;
  background: currentColor;
}

.flare-status-banner__dot--pulse {
  animation: flare-status-pulse 1.4s ease-in-out infinite;
}

.flare-status-banner__text {
  flex: 1;
  min-width: 0;
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
}

.flare-status-banner__action {
  flex: none;
  font: inherit;
  font-weight: 600;
  cursor: pointer;
  color: var(--flare-color-text-primary);
  background: none;
  border: none;
  min-width: 48px;
  min-height: 48px;
  max-width: 50%;
  overflow-wrap: anywhere;
  padding: 8px;
  text-decoration: underline;
  text-underline-offset: 2px;
}

.flare-status-banner__action:focus-visible { outline: 2px solid currentColor; outline-offset: 2px; }

.flare-status-banner__body {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: var(--flare-size-spacing-3xs);
  min-width: 0;
}
.flare-status-banner__title {
  color: var(--flare-color-text-primary);
  font-weight: var(--flare-size-font-weight-semibold);
  overflow-wrap: anywhere;
}
/* The close key keeps the touch target the action key has, and sits at the top of a two-line notice. */
.flare-status-banner__dismiss {
  display: inline-flex;
  flex: none;
  align-self: flex-start;
  align-items: center;
  justify-content: center;
  min-width: var(--flare-size-layout-touch-target);
  min-height: var(--flare-size-layout-touch-target);
  margin: calc(var(--flare-size-spacing-sm) * -1) calc(var(--flare-size-spacing-2md) * -1) calc(var(--flare-size-spacing-sm) * -1) 0;
  padding: 0;
  border: none;
  border-radius: var(--flare-size-radius-md);
  color: var(--flare-color-text-secondary);
  background: none;
  cursor: pointer;
}
.flare-status-banner__dismiss:focus-visible { outline: 2px solid currentColor; outline-offset: -4px; }
@media (hover: hover) {
  .flare-status-banner__dismiss:hover { color: var(--flare-color-text-primary); }
}

@keyframes flare-status-pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.35;
  }
}

@media (prefers-reduced-motion: reduce) {
  .flare-status-banner__dot--pulse {
    animation: none;
  }
}
</style>
