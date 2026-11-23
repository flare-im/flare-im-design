<script setup lang="ts">
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";
// Screen-level large-title header — the quiet top bar for a tab surface
// (inbox / directory / me). Distinct from ChatHeader (conversation chrome).
withDefaults(defineProps<{
  title: string;
  eyebrow?: string;
  meta?: string;
  compact?: boolean;
  appearance?: "destination";
  as?: "header" | "div";
}>(), { as: "header" });
const { isH5 } = useFlareAdaptiveSafe();
</script>

<template>
  <component :is="as" class="flare-screen-header" :class="{ 'flare-screen-header--compact': compact, 'flare-screen-header--destination': appearance === 'destination', 'flare-screen-header--embedded': as === 'div' }">
    <!-- Back, a profile avatar, a picker: what the screen is reached through, before its title. -->
    <div v-if="$slots.leading" class="flare-screen-header__leading"><slot name="leading" /></div>
    <div class="flare-screen-header__heading">
      <span v-if="eyebrow" class="flare-screen-header__eyebrow">{{ eyebrow }}</span>
      <h1 class="flare-screen-header__title">{{ title }}</h1>
      <span v-if="meta" class="flare-screen-header__meta">{{ meta }}</span>
    </div>
    <div class="flare-screen-header__actions" :class="{ 'flare-phone-header-actions': isH5 }">
      <slot name="actions" />
    </div>
  </component>
</template>

<style scoped>
.flare-screen-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: var(--flare-size-spacing-2md) 16px;
  background: var(--flare-color-bg-primary);
}
.flare-screen-header__leading {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
}
.flare-screen-header__heading {
  flex: 1;
  display: grid;
  gap: 2px;
  min-width: 0;
}
.flare-screen-header__eyebrow {
  color: var(--flare-color-text-tertiary);
  font-size: 11px;
  font-weight: 700;
  line-height: 1.2;
  text-transform: uppercase;
}
.flare-screen-header__title {
  margin: 0;
  font-size: var(--flare-size-font-size-5xl);
  font-weight: 700;
  line-height: 1.2;
  color: var(--flare-color-text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-screen-header__meta {
  overflow: hidden;
  color: var(--flare-color-text-tertiary);
  font-size: 12px;
  font-weight: 500;
  line-height: 1.35;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-screen-header__actions {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  flex: 0 0 auto;
}
.flare-screen-header--compact { min-height: 56px; box-sizing: border-box; padding-block: 6px; }
.flare-screen-header--compact .flare-screen-header__title { font-size: var(--flare-size-font-size-4xl); }
.flare-screen-header--destination {
  --flare-destination-header-padding: var(--flare-size-spacing-2xs);
  min-height: var(--flare-size-layout-header-height);
  padding-block: var(--flare-destination-header-padding);
  padding-block-start: calc(var(--flare-destination-header-padding) + env(safe-area-inset-top));
  box-sizing: border-box;
  gap: var(--flare-size-spacing-sm);
}
.flare-screen-header--destination .flare-screen-header__leading {
  justify-content: center;
  min-width: var(--flare-size-layout-touch-target-min);
  min-height: var(--flare-size-layout-touch-target-min);
}
.flare-screen-header--destination .flare-screen-header__title {
  font-size: var(--flare-size-font-size-4xl);
}
.flare-screen-header--destination .flare-screen-header__actions {
  gap: var(--flare-size-spacing-sm);
}
.flare-screen-header--destination .flare-screen-header__actions.flare-phone-header-actions {
  gap: var(--flare-size-spacing-2xs);
}
.flare-screen-header--embedded {
  width: 100%;
  min-height: 0;
  padding: 0;
  padding-inline-end: var(--flare-size-spacing-sm);
  background: transparent;
}
</style>
