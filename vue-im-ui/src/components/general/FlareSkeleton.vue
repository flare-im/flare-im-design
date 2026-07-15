<script setup lang="ts">
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    /** Preset layout: conversation list, message thread, or profile header. */
    variant?: "conversation" | "message" | "profile" | "text";
    /** Repeat count for list-style variants. */
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

    <!-- generic stacked text lines -->
    <template v-else>
      <span v-for="i in list" :key="i" class="sk sk-line" :style="{ width: `${100 - ((i * 17) % 45)}%` }" />
    </template>
  </div>
</template>

<style scoped>
.flare-skeleton { display: flex; flex-direction: column; gap: 14px; }
.sk {
  display: block;
  border-radius: var(--flare-size-radius-md, 8px);
  background: var(--flare-color-bg-secondary, #f0eef6);
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
    var(--flare-color-bg-primary, rgba(255, 255, 255, 0.65)),
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
.sk-bubble { height: 40px; border-radius: var(--flare-size-radius-lg, 14px); }

.sk-profile { align-items: center; display: flex; flex-direction: column; gap: 12px; padding: 8px 0; }
</style>
