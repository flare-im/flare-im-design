<script setup lang="ts">
/**
 * FlareScreen — the base page scaffold every business page builds on.
 *
 * It owns the themed page surface (auto light/dark via design tokens + system
 * follow), an optional header (back / large title / actions), and a scrollable,
 * safe-area-padded body. Business code writes:
 *
 *   <FlareScreen title="通讯录" back @back="goBack">
 *     <template #actions>…</template>
 *     …page content…
 *   </FlareScreen>
 *
 * and gets a consistent, fully themeable page for free — change the theme once
 * (FlareUiProvider `theme-mode` / useFlareConfig().setThemeMode) and every screen
 * follows. No page-level colours are hard-coded; everything reads from tokens.
 */
import { computed, useSlots } from "vue";
import { NIcon } from "naive-ui";
import { ArrowBackOutline } from "../../shared/icon-glyphs";

const props = withDefaults(
  defineProps<{
    /** Large-title text. Omit for a headerless page (or use the `header` slot). */
    title?: string;
    /** Show a leading back button (emits `back`). */
    back?: boolean;
    /**
     * Page surface:
     *  - `canvas`  grouped-list background (elevated cards float on it) — default
     *  - `surface` a single flat panel (bg-primary)
     *  - `aurora`  canvas with a subtle violet light wash at the top
     */
    surface?: "canvas" | "surface" | "aurora";
    /** Pad the body (16px + safe-area). */
    padded?: boolean;
    /** Scrollable body. Default true. */
    scroll?: boolean;
  }>(),
  { title: undefined, back: false, surface: "canvas", padded: false, scroll: true },
);
const emit = defineEmits<{ (e: "back"): void }>();

const slots = useSlots();
const hasHeader = computed(() => Boolean(props.title) || props.back || Boolean(slots.header));
</script>

<template>
  <section class="flare-screen" :class="`flare-screen--${surface}`">
    <header v-if="hasHeader" class="flare-screen__header">
      <slot name="header">
        <button
          v-if="back"
          type="button"
          class="flare-screen__back"
          :aria-label="'Back'"
          @click="emit('back')"
        >
          <n-icon :size="22" :component="ArrowBackOutline" />
        </button>
        <h1 v-if="title" class="flare-screen__title">{{ title }}</h1>
        <div class="flare-screen__actions"><slot name="actions" /></div>
      </slot>
    </header>

    <div class="flare-screen__body" :class="{ 'is-scroll': scroll, 'is-padded': padded }">
      <slot />
    </div>

    <footer v-if="slots.footer" class="flare-screen__footer"><slot name="footer" /></footer>
  </section>
</template>

<style scoped>
.flare-screen {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  min-height: 0;
  position: relative;
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-primary, #15131c);
}
.flare-screen--surface { background: var(--flare-color-bg-primary, #fff); }
/* Aurora — a soft violet light wash at the top of the canvas. */
.flare-screen--aurora::before {
  content: "";
  position: absolute;
  inset: 0 0 auto 0;
  height: 220px;
  pointer-events: none;
  background:
    radial-gradient(120% 100% at 12% -40%,
      color-mix(in srgb, var(--flare-color-primary, #7c3aed) 22%, transparent), transparent 60%);
}

.flare-screen__header {
  flex: none;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 14px 16px;
  padding-top: max(14px, env(safe-area-inset-top));
  position: relative;
  z-index: 1;
}
.flare-screen__back {
  flex: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  margin-left: -6px;
  border: none;
  border-radius: 8px;
  background: none;
  color: var(--flare-color-text-primary, #15131c);
  cursor: pointer;
  transition: background var(--flare-transition-fast, 140ms ease);
}
.flare-screen__back:hover { background: var(--flare-color-bg-hover, rgba(0, 0, 0, 0.05)); }
.flare-screen__title {
  flex: 1;
  min-width: 0;
  margin: 0;
  font-size: 24px;
  font-weight: 700;
  line-height: 1.2;
  color: var(--flare-color-text-primary, #15131c);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-screen__actions {
  flex: 0 0 auto;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.flare-screen__body {
  flex: 1;
  min-width: 0;
  min-height: 0;
  position: relative;
  z-index: 1;
}
.flare-screen__body.is-scroll { overflow-y: auto; -webkit-overflow-scrolling: touch; }
.flare-screen__body.is-padded {
  padding: 16px;
  padding-bottom: max(16px, env(safe-area-inset-bottom));
}

.flare-screen__footer {
  flex: none;
  padding-bottom: env(safe-area-inset-bottom);
  background: var(--flare-color-bg-primary, #fff);
  border-top: 1px solid var(--flare-color-border-primary, #e9e6f1);
}
</style>
