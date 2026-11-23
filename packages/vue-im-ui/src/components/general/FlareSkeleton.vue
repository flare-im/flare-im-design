<script setup lang="ts">
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    /**
     * Preset layout: conversation list, message thread, profile header, text lines, or the plugin page shapes (R8):
     * card (one 160-high card), list (rows of list height) and form (4 labelled fields); tile is one composer panel item
     * (an icon square over a short label) standing in for a plugin item still loading (§4.1).
     */
    variant?: "conversation" | "message" | "profile" | "text" | "card" | "list" | "form" | "tile";
    /** Repeat count for list-style variants (conversation, message, text, list). */
    rows?: number;
    /** Disable the shimmer sweep (falls back to a static tint). */
    still?: boolean;
  }>(),
  { variant: "conversation", rows: 4, still: false },
);

const list = computed(() => Array.from({ length: Math.max(1, props.rows) }, (_, i) => i));
</script>

<template>
  <div class="flare-skeleton" :class="[`flare-skeleton--${variant}`, { 'is-still': still }]" aria-hidden="true">
    <!-- conversation / contact list rows -->
    <template v-if="variant === 'conversation'">
      <div v-for="i in list" :key="i" class="sk-row">
        <span class="sk sk-avatar" />
        <span class="sk-lines">
          <span class="sk sk-line" style="width: 42%" />
          <span class="sk sk-line" style="width: 68%" />
        </span>
        <span class="sk sk-time" />
      </div>
    </template>

    <!-- message thread bubbles, alternating sides -->
    <template v-else-if="variant === 'message'">
      <div v-for="i in list" :key="i" class="sk-msg" :class="{ 'is-me': i % 2 === 1 }">
        <span v-if="i % 2 === 0" class="sk sk-avatar sk-avatar--sm" />
        <span class="sk sk-bubble" :style="{ width: `${45 + ((i * 13) % 40)}%` }" />
      </div>
    </template>

    <!-- profile header -->
    <template v-else-if="variant === 'profile'">
      <div class="sk-profile">
        <span class="sk sk-avatar sk-avatar--lg" />
        <span class="sk sk-line" style="width: 40%; height: 15px" />
        <span class="sk sk-line" style="width: 60%" />
      </div>
    </template>

    <!-- plugin page shapes (R8): an overview card, list rows, a form's labelled fields -->
    <span v-else-if="variant === 'card'" class="sk sk-card" />
    <template v-else-if="variant === 'list'">
      <div v-for="i in list" :key="i" class="sk-list-row">
        <span class="sk-lines">
          <span class="sk sk-line" style="width: 46%" />
          <span class="sk sk-line" style="width: 28%" />
        </span>
        <span class="sk sk-time" />
      </div>
    </template>
    <template v-else-if="variant === 'form'">
      <div v-for="i in 4" :key="i" class="sk-field">
        <span class="sk sk-line" style="width: 30%" />
        <span class="sk sk-input" />
      </div>
    </template>

    <template v-else-if="variant === 'tile'">
      <span class="sk sk-tile" />
      <span class="sk sk-line sk-tile-label" />
    </template>

    <!-- generic stacked text lines -->
    <template v-else>
      <span v-for="i in list" :key="i" class="sk sk-line" :style="{ width: `${100 - ((i * 17) % 45)}%` }" />
    </template>
  </div>
</template>

<style scoped>
.flare-skeleton { display: flex; flex-direction: column; gap: var(--flare-size-spacing-2md); }
.sk {
  display: block;
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
  position: relative;
  overflow: hidden;
}
.sk::after {
  content: "";
  position: absolute;
  inset: 0;
  transform: translateX(-100%);
  background: linear-gradient(
    90deg,
    transparent,
    var(--flare-color-bg-primary),
    transparent
  );
  animation: flare-skeleton-sweep 1.4s ease-in-out infinite;
}
.is-still .sk::after { display: none; }
@media (prefers-reduced-motion: reduce) {
  .sk::after { animation: none; display: none; }
}
@keyframes flare-skeleton-sweep {
  100% { transform: translateX(100%); }
}
.sk-avatar { width: 44px; height: 44px; border-radius: 50%; flex: 0 0 auto; }
.sk-avatar--sm { width: 32px; height: 32px; }
.sk-avatar--lg { width: 72px; height: 72px; }
.sk-line { height: 11px; }
.sk-lines { flex: 1; display: flex; flex-direction: column; gap: 8px; }
.sk-time { width: 34px; height: 11px; flex: 0 0 auto; }
.sk-row { display: flex; align-items: center; gap: 12px; }

.flare-skeleton--message { gap: 18px; }
.sk-msg { display: flex; align-items: flex-end; gap: 8px; }
.sk-msg.is-me { flex-direction: row-reverse; }
.sk-bubble { height: 40px; border-radius: var(--flare-size-radius-lg); }

/* 160 high: spacing.xl × 8 (no dedicated token). */
.sk-card { height: var(--flare-size-component-skeleton-card-height); border-radius: var(--flare-size-radius-card); }
.flare-skeleton--list { gap: 0; }
.sk-list-row { display: flex; align-items: center; gap: var(--flare-size-spacing-md); min-height: var(--flare-size-layout-control-height-lg); }
.sk-list-row + .sk-list-row { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-skeleton--form { gap: var(--flare-size-spacing-lg); }
.sk-field { display: flex; flex-direction: column; gap: var(--flare-size-spacing-sm); }
.sk-input { height: var(--flare-size-layout-control-height-lg); border-radius: var(--flare-size-radius-lg); }

/* The composer panel item's footprint: a 52 icon square (control-height-lg + spacing.xs) over a short label. */
.flare-skeleton--tile { align-items: center; gap: var(--flare-size-spacing-2xs); }
.sk-tile { width: calc(var(--flare-size-layout-control-height-lg) + var(--flare-size-spacing-xs)); aspect-ratio: 1; border-radius: var(--flare-size-radius-lg); }
.sk-tile-label { width: 60%; }

.sk-profile { align-items: center; display: flex; flex-direction: column; gap: 12px; padding: 8px 0; }
</style>
