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
import { computed, getCurrentInstance, provide, ref, useSlots } from "vue";
import { screenLayoutKey } from "../../shared/screenLayout";
import { NIcon } from "naive-ui";
import { ArrowBackOutline } from "../../shared/icon-glyphs";
import { useFlareNativeBack } from "../../shared/platform/useFlareNativeBack";
import { dismissTopFlareContextualLayer } from "../../shared/useContextualLayer";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlareDestinationDepth } from "../../composables/useFlareShell";
import { useFlareSheetOwnHeader } from "../../shared/sheetHeader";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";
import FlareScreenHeader from "./FlareScreenHeader.vue";

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
    /** Use the destination header for a root page with an avatar or other leading control. */
    headerAppearance?: "destination";
    /** Pad the body (16px + safe-area). */
    padded?: boolean;
    /** Scrollable body. Default true. */
    scroll?: boolean;
    /**
     * Keep the header and content in a centred reading column on wide screens (profile, settings,
     * feeds); the page background still fills the pane. Narrow panes are unchanged.
     */
    readable?: boolean;
    /** Centre header, body and footer in one frame. Null/invalid widths leave the pane unconstrained. */
    contentMaxWidth?: number | null;
    /** Detail pane: compact heading, leading reading column and one shared content inset. */
    layout?: "page" | "detail";
    /** Stack independent sections inside one scrollable inset. */
    sectioned?: boolean;
  }>(),
  { title: undefined, back: false, surface: "canvas", padded: false, scroll: true, readable: false, layout: "page" },
);
provide(screenLayoutKey, {
  detail: computed(() => props.layout === "detail"),
  sectioned: computed(() => props.sectioned),
  title: computed(() => props.title),
});
const emit = defineEmits<{ (e: "back"): void }>();
const { t } = useFlareI18nOptional();
const { isH5 } = useFlareAdaptiveSafe();
const instance = getCurrentInstance();
const root = ref<HTMLElement | null>(null);
// 返回先退这一页之内最上面的上下文层(多选),再才是离开这一页;范围就是这张 screen 自己,
// 别的栏里的页不受影响。
// 名字不能叫 back:<script setup> 的绑定在模板里压过同名 prop,`v-if="back"` 就永远为真,
// 每一页(含四个 tab 根页)都会长出返回键。
function goBack(): void {
  if (dismissTopFlareContextualLayer(root.value)) return;
  emit("back");
}
const hasBackKey = () => Boolean(props.back && instance?.vnode.props?.onBack);
// The platform back does what the back button does.
useFlareNativeBack(hasBackKey, goBack);
// A page with its own way back, pushed into a kit surface (a drawer's page stack), brings its own header: the surface
// draws none, and its Escape and platform back go back one page here before they close it.
useFlareSheetOwnHeader({ active: hasBackKey, back: goBack });
// A page with a way back is not its destination's root: a shell hides its phone navigation under it.
useFlareDestinationDepth(() => props.back);

const slots = useSlots();
const hasHeader = computed(() => Boolean(props.title) || props.back || Boolean(slots.header));
const destinationHeader = computed(() => props.headerAppearance === "destination" && Boolean(props.title) && !props.back);
const contentWidth = computed(() => typeof props.contentMaxWidth === "number" && Number.isFinite(props.contentMaxWidth) && props.contentMaxWidth > 0 ? props.contentMaxWidth : undefined);
</script>

<template>
  <section ref="root" class="flare-screen" :class="[`flare-screen--${surface}`, { 'flare-screen--detail': layout === 'detail', 'flare-screen--readable': readable && contentWidth === undefined, 'flare-screen--constrained': contentWidth !== undefined }]" :style="{ '--flare-screen-content-max-width': contentWidth === undefined ? undefined : `${contentWidth}px` }">
    <header v-if="hasHeader" class="flare-screen__header" :class="{ 'is-destination': destinationHeader }" data-flare-overlay-chrome>
      <slot name="header">
        <FlareScreenHeader v-if="destinationHeader" as="div" appearance="destination" :title="title ?? ''">
          <template v-if="$slots.leading" #leading><slot name="leading" /></template>
          <template #actions><slot name="actions" /></template>
        </FlareScreenHeader>
        <template v-else>
        <button
          v-if="back"
          type="button"
          class="flare-screen__back"
          :aria-label="t('common.back')"
          @click="goBack"
        >
          <n-icon aria-hidden="true" :size="isH5 ? 'var(--flare-size-icon-size-lg)' : 'var(--flare-size-icon-size-md)'" :component="ArrowBackOutline" />
        </button>
        <h1 v-if="title" class="flare-screen__title">{{ title }}</h1>
        <div class="flare-screen__actions" :class="{ 'flare-phone-header-actions': isH5 }"><slot name="actions" /></div>
        </template>
      </slot>
    </header>

    <div class="flare-screen__body" :class="{ 'is-scroll': scroll, 'is-padded': padded || sectioned, 'is-sectioned': sectioned }">
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
  gap: var(--flare-size-spacing-sm);
  min-height: calc(var(--flare-size-layout-touch-target) + var(--flare-size-spacing-sm) * 2 + env(safe-area-inset-top, 0px));
  box-sizing: border-box;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  padding-top: calc(var(--flare-size-spacing-sm) + env(safe-area-inset-top, 0px));
  position: relative;
  z-index: 1;
}
.flare-screen__back {
  flex: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: var(--flare-size-layout-touch-target);
  height: var(--flare-size-layout-touch-target);
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
  font-size: var(--flare-size-font-size-5xl);
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
.flare-screen__header.is-destination {
  min-height: var(--flare-size-layout-header-height);
  padding-block: var(--flare-size-spacing-2xs);
  padding-block-start: calc(var(--flare-size-spacing-2xs) + env(safe-area-inset-top));
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
.flare-screen__body.is-sectioned {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-lg);
  padding-block-end: max(var(--flare-size-spacing-xl), env(safe-area-inset-bottom));
}
.flare-screen__body.is-sectioned > :slotted(*) { flex-shrink: 0; }

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
.flare-screen--constrained > .flare-screen__header,
.flare-screen--constrained > .flare-screen__body,
.flare-screen--constrained > .flare-screen__footer {
  width: 100%;
  max-width: var(--flare-screen-content-max-width);
  margin-inline: auto;
  box-sizing: border-box;
}
/* The detail pane owns the gutter once; participating kit children share its column. */
.flare-screen--detail > .flare-screen__header,
.flare-screen--detail > .flare-screen__body,
.flare-screen--detail > .flare-screen__body.is-padded,
.flare-screen--detail > .flare-screen__footer {
  width: 100%;
  max-width: calc(var(--flare-screen-content-max-width, var(--flare-component-screen-reading-width)) + var(--flare-size-spacing-xl) * 2);
  margin-inline: 0;
  box-sizing: border-box;
  padding-inline: var(--flare-size-spacing-xl);
}
.flare-screen--detail > .flare-screen__header { min-height: var(--flare-size-layout-header-height); }
.flare-screen--detail > .flare-screen__header .flare-screen__title { font-size: var(--flare-size-font-size-4xl); font-weight: var(--flare-size-font-weight-semibold); }
.flare-screen--detail > .flare-screen__body { padding-top: var(--flare-size-spacing-sm); padding-bottom: max(var(--flare-size-spacing-xl), env(safe-area-inset-bottom)); }
</style>
