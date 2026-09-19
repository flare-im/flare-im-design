<script setup lang="ts">
import type { FlareNavigationGroup } from "../../shared/contracts/application";
import FlareAdaptiveNavigation from "./FlareAdaptiveNavigation.vue";

withDefaults(defineProps<{
  navigation: readonly FlareNavigationGroup[];
  activeNavigationId: string;
  hideNavigation?: boolean;
  label?: string;
}>(), { hideNavigation: false, label: "" });
const emit = defineEmits<{ (event: "navigate", id: string): void }>();
</script>

<template>
  <section class="flare-mobile-shell" :aria-label="label || undefined">
    <header v-if="$slots.appBar" class="flare-mobile-shell__app-bar"><slot name="appBar" /></header>
    <main class="flare-mobile-shell__content"><slot /></main>
    <FlareAdaptiveNavigation
      v-if="!hideNavigation"
      class="flare-mobile-shell__navigation"
      :groups="navigation"
      :active-id="activeNavigationId"
      responsive-mode="mobile"
      presentation="bottom"
      :label="label"
      @navigate="emit('navigate', $event)"
    />
    <div class="flare-mobile-shell__overlay"><slot name="overlay" /></div>
    <div class="flare-mobile-shell__floating"><slot name="floating" /></div>
    <div class="flare-mobile-shell__toast"><slot name="toast" /></div>
  </section>
</template>

<style scoped>
.flare-mobile-shell { position: relative; display: flex; flex-direction: column; width: 100%; height: 100dvh; min-height: 0; overflow: hidden; background: var(--flare-color-bg-primary); }
.flare-mobile-shell__app-bar { flex: none; padding-top: env(safe-area-inset-top); border-bottom: 1px solid var(--flare-color-border-primary); }
.flare-mobile-shell__content { flex: 1; min-width: 0; min-height: 0; overflow: hidden; }
.flare-mobile-shell__navigation { flex: none; }
/* Same overlay contract as the wide layout: a layer over the shell, not a flex item after the tab bar. */
.flare-mobile-shell__overlay { position: absolute; inset: 0; z-index: var(--flare-z-index-overlay); pointer-events: none; }
.flare-mobile-shell__overlay > * { pointer-events: auto; }
.flare-mobile-shell__floating,
.flare-mobile-shell__toast { display: contents; }
</style>
