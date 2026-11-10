<script setup lang="ts">
import { onMounted, onBeforeUnmount, onUpdated, ref, useSlots } from "vue";
import FlareAdminHelp from "./FlareAdminHelp.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

/** Layout only: the host owns scope, authorization, drafts and all writes. */
withDefaults(defineProps<{
  label: string;
  /** Visible workspace heading, composed with its scope and tools in one row. */
  title?: string;
  density?: "comfortable" | "compact";
  /** The host owns the surrounding surface when this workspace is integrated. */
  surface?: "card" | "integrated";
  /** Pane content owns its scroll area; the default body scrolls ordinary settings. */
  bodyLayout?: "scroll" | "pane";
}>(), { density: "comfortable", surface: "card", bodyLayout: "scroll" });
const { t } = useFlareI18n();
const slots = useSlots();
const root = ref<HTMLElement>();
const narrow = ref(false);
let observer: ResizeObserver | undefined;
const measure = () => {
  if (root.value)
    narrow.value = root.value.getBoundingClientRect().width < (slots.navigation ? 760 : 640);
};
onMounted(() => {
  measure();
  if (typeof ResizeObserver !== "undefined") {
    observer = new ResizeObserver(measure);
    if (root.value) observer.observe(root.value);
  }
});
onUpdated(measure);
onBeforeUnmount(() => observer?.disconnect());
</script>

<template>
  <section ref="root" class="flare-admin-settings" :class="{
    'flare-admin-settings--compact': density === 'compact',
    'flare-admin-settings--integrated': surface === 'integrated',
    'flare-admin-settings--pane': bodyLayout === 'pane',
  }" :aria-label="label">
    <header class="flare-admin-settings__toolbar">
      <h3 v-if="title" class="flare-admin-settings__title">{{ title }}</h3>
      <div v-if="$slots.scope" class="flare-admin-settings__scope">
        <slot name="scope" :narrow="narrow" />
      </div>
      <div class="flare-admin-settings__tools">
        <slot name="tools" />
        <FlareAdminHelp v-if="$slots.help" :label="t('adminSettings.help')">
          <div class="flare-admin-settings__help"><slot name="help" /></div>
        </FlareAdminHelp>
      </div>
    </header>
    <div
      v-if="$slots.notice"
      class="flare-admin-settings__notice"
      aria-live="polite"
    >
      <slot name="notice" />
    </div>
    <div class="flare-admin-settings__workspace" :class="{ 'has-navigation': !!$slots.navigation && !narrow }">
      <aside v-if="$slots.navigation && !narrow" class="flare-admin-settings__navigation">
        <slot name="navigation" />
      </aside>
      <div class="flare-admin-settings__body">
        <div v-if="$slots['compact-navigation'] && narrow" class="flare-admin-settings__compact-navigation">
          <slot name="compact-navigation" />
        </div>
        <div class="flare-admin-settings__content"><slot :narrow="narrow" /></div>
      </div>
    </div>
    <footer v-if="$slots.footer" class="flare-admin-settings__footer">
      <slot name="footer" />
    </footer>
  </section>
</template>

<style scoped>
.flare-admin-settings {
  width: 100%;
  min-width: 0;
  min-height: 0;
  height: 100%;
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-lg);
  box-sizing: border-box;
}
.flare-admin-settings__toolbar,
.flare-admin-settings__footer {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm);
  padding: 12px;
  flex: none;
}
.flare-admin-settings--integrated {
  border: 0;
  border-radius: 0;
}
.flare-admin-settings__toolbar {
  border-bottom: 1px solid var(--flare-color-border-secondary);
  max-height: 35%;
  overflow: auto;
}
.flare-admin-settings__title {
  margin: 0;
  min-width: 0;
  font-size: var(--flare-size-font-size-md);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
}
.flare-admin-settings--compact .flare-admin-settings__toolbar {
  padding-block: var(--flare-size-spacing-sm);
  column-gap: var(--flare-size-spacing-lg);
}
.flare-admin-settings__scope {
  flex: 1;
  min-width: min(20rem, 100%);
}
.flare-admin-settings--compact .flare-admin-settings__scope {
  flex: 1 1 20rem;
  min-width: min(16rem, 100%);
}
.flare-admin-settings__scope :deep(.n-form) {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 16px;
}
.flare-admin-settings__scope :deep(.n-form-item) {
  margin: 0;
  min-width: 0;
  flex: 0 1 420px;
}
.flare-admin-settings__tools {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-inline-start: auto;
}
.flare-admin-settings__notice {
  display: grid;
  gap: 8px;
  padding: 12px 12px 0;
  max-height: 35%;
  overflow: auto;
  flex: none;
}
.flare-admin-settings__body {
  min-width: 0;
  min-height: 0;
  flex: 1;
  overflow: auto;
  padding: 0 12px 12px;
  overscroll-behavior: contain;
}
.flare-admin-settings__workspace {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  flex: 1;
  min-width: 0;
  min-height: 0;
}
.flare-admin-settings__workspace.has-navigation {
  grid-template-columns: 192px minmax(0, 1fr);
}
.flare-admin-settings__navigation {
  min-width: 0;
  min-height: 0;
  overflow: auto;
  padding: var(--flare-size-spacing-md) var(--flare-size-spacing-sm);
  border-inline-end: 1px solid var(--flare-color-border-secondary);
}
.flare-admin-settings__compact-navigation {
  padding-block: var(--flare-size-spacing-md);
}
.flare-admin-settings--pane .flare-admin-settings__body {
  display: flex;
  flex-direction: column;
  overflow: hidden;
  padding: 0;
}
.flare-admin-settings--pane .flare-admin-settings__content {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
  min-height: 0;
  overflow: hidden;
}
.flare-admin-settings--pane .flare-admin-settings__compact-navigation {
  flex: none;
  padding: var(--flare-size-spacing-md);
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-admin-settings__footer {
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-admin-settings__help {
  overflow-wrap: anywhere;
  line-height: 1.6;
}
@media (max-width: 640px) {
  .flare-admin-settings__toolbar,
  .flare-admin-settings__footer {
    padding: 8px 12px;
  }
  .flare-admin-settings__tools :deep(.n-button),
  .flare-admin-settings__footer :deep(.n-button) {
    min-height: var(--flare-size-layout-control-height-sm);
  }
}
</style>
