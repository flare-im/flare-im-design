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
import { computed, getCurrentInstance, useSlots } from "vue";
import { NIcon } from "naive-ui";
import { ArrowBackOutline } from "../../shared/icon-glyphs";
import { useFlareNativeBack } from "../../shared/platform/useFlareNativeBack";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlareDestinationDepth } from "../../composables/useFlareShell";

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
     *  - `brand`   canvas with a subtle current-theme accent wash at the top
     */
    surface?: "canvas" | "surface" | "brand";
    /** Pad the body (16px + safe-area). */
    padded?: boolean;
    /** Scrollable body. Default true. */
    scroll?: boolean;
    /**
     * Keep the header and content in a centred reading column on wide screens (profile, settings,
     * feeds); the page background still fills the pane. Narrow panes are unchanged.
     */
    readable?: boolean;
  }>(),
  { title: undefined, back: false, surface: "canvas", padded: false, scroll: true, readable: false },
);
const emit = defineEmits<{ (e: "back"): void }>();
const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
// The platform back does what the back button does.
useFlareNativeBack(() => Boolean(props.back && instance?.vnode.props?.onBack), () => emit("back"));
// A page with a way back is not its destination's root: a shell hides its phone navigation under it.
useFlareDestinationDepth(() => props.back);

const slots = useSlots();
const hasHeader = computed(() => Boolean(props.title) || props.back || Boolean(slots.header));
</script>

<template>
  <section class="flare-screen" :class="[`flare-screen--${surface}`, { 'flare-screen--readable': readable }]">
    <header v-if="hasHeader" class="flare-screen__header">
      <slot name="header">
        <button
          v-if="back"
          type="button"
          class="flare-screen__back"
          :aria-label="t('common.back')"
          @click="emit('back')"
        >
          <n-icon aria-hidden="true" :size="22" :component="ArrowBackOutline" />
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
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
}
.flare-screen--surface { background: var(--flare-color-bg-primary); }
/* A restrained wash derived from the current semantic primary color. */
.flare-screen--brand::before {
  content: "";
  position: absolute;
  inset: 0 0 auto 0;
  height: 220px;
  pointer-events: none;
  background:
    radial-gradient(120% 100% at 12% -40%,
      color-mix(in srgb, var(--flare-color-primary) 22%, transparent), transparent 60%);
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
  width: 40px;
  height: 40px;
  margin-left: -10px;
  border: none;
  border-radius: 8px;
  background: none;
  color: var(--flare-color-text-primary);
  cursor: pointer;
  transition: background var(--flare-transition-fast);
}
.flare-screen__back:hover { background: var(--flare-color-bg-hover); }
.flare-screen__title {
  flex: 1;
  min-width: 0;
  margin: 0;
  font-size: 24px;
  font-weight: 700;
  line-height: 1.2;
  color: var(--flare-color-text-primary);
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

/* Reading column: padding centres the content (percentages resolve against the screen's width),
   so slotted layouts keep their own structure. */
.flare-screen--readable .flare-screen__header {
  padding-inline: max(16px, calc((100% - var(--flare-component-screen-reading-width)) / 2));
}
.flare-screen--readable .flare-screen__body {
  padding-inline: max(0px, calc((100% - var(--flare-component-screen-reading-width)) / 2));
}
.flare-screen--readable .flare-screen__body.is-padded {
  padding-inline: max(16px, calc((100% - var(--flare-component-screen-reading-width)) / 2));
}

.flare-screen__footer {
  flex: none;
  padding-bottom: env(safe-area-inset-bottom);
  background: var(--flare-color-bg-primary);
  border-top: 1px solid var(--flare-color-border-primary);
}
</style>
