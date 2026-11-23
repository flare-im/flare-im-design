<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import FlareGlyph from "./FlareGlyph.vue";
import FlareButton from "./FlareButton.vue";
import { flareDesignTokens } from "@flare-im/tokens";
const props = withDefaults(
  defineProps<{
    title: string;
    description?: string;
    actionText?: string;
    icon?: string;
    /** When true, render a brand spinner in place of the icon. */
    loading?: boolean;
    /** Visual tone: 'normal' (default) or 'error' (danger-colored title/icon). */
    tone?: "normal" | "error";
    /** In-block empty state (plugin pages, R8): icon 32, title 14/600, description 13, less padding. */
    compact?: boolean;
    /** Centre the state in a bounded, otherwise empty pane. */
    centered?: boolean;
  }>(),
  { icon: "folder", loading: false, tone: "normal", compact: false },
);
const emit = defineEmits<{ (e: "action"): void; (e: "tap"): void }>();
// component.emptyStateIconSize (44) as Flutter and iOS draw it; only the compact (R8 in-block) state is icon xl 32.
const ICON_SIZE = parseFloat(flareDesignTokens.sizes.component.emptyStateIconSize);
// The whole placeholder becomes tappable only when a @tap listener is bound.
const instance = getCurrentInstance();
const hasTapListener = () => Boolean(instance?.vnode.props?.onTap);
const isError = computed(() => props.tone === "error");
function onRootActivate() {
  if (hasTapListener()) emit("tap");
}
function onRootKeydown(event: KeyboardEvent) {
  if (!hasTapListener() || event.target !== event.currentTarget) return;
  event.preventDefault();
  emit("tap");
}
</script>

<template>
  <div
    class="flare-empty"
    :class="{ 'is-tappable': hasTapListener(), 'is-error': isError, 'is-compact': compact, 'is-centered': centered }"
    :role="hasTapListener() ? 'button' : loading ? 'status' : undefined"
    :aria-label="loading && !hasTapListener() ? title : undefined"
    :tabindex="hasTapListener() ? 0 : undefined"
    @click="onRootActivate"
    @keydown.enter="onRootKeydown"
    @keydown.space="onRootKeydown"
  >
    <div class="flare-empty__ico">
      <span v-if="loading" class="flare-empty__spinner" aria-hidden="true"></span>
      <slot v-else name="icon">
        <span
          class="flare-empty__glyph"
          :class="{ 'flare-empty__glyph--error': isError }"
        ><FlareGlyph :icon="icon" :size="compact ? 'xl' : ICON_SIZE" /></span>
      </slot>
    </div>
    <div class="flare-empty__title">{{ title }}</div>
    <div v-if="description" class="flare-empty__desc">{{ description }}</div>
    <div v-if="actionText" class="flare-empty__action" @click.stop>
      <FlareButton class="flare-empty__act" size="sm" variant="ghost" :label="actionText" @click="emit('action')" />
    </div>
    <div v-if="$slots.actions" class="flare-empty__actions" @click.stop><slot name="actions" /></div>
  </div>
</template>

<style scoped>
.flare-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 24px;
  text-align: center;
}
.flare-empty.is-tappable { cursor: pointer; }
.flare-empty.is-centered { min-height: 100%; justify-content: center; box-sizing: border-box; }
.flare-empty.is-tappable:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 4px;
  border-radius: var(--flare-size-radius-md);
}
.flare-empty__ico { font-size: var(--flare-size-component-empty-state-icon-size); opacity: 0.8; display: flex; align-items: center; justify-content: center; min-height: var(--flare-size-component-empty-state-icon-size); }
.flare-empty__glyph { display: inline-flex; align-items: center; justify-content: center; }
.flare-empty__glyph--error { color: var(--flare-color-error-text); }
.flare-empty__title { font-size: 16px; color: var(--flare-color-text-primary); }
.flare-empty.is-error .flare-empty__title { color: var(--flare-color-error-text); }
.flare-empty__desc { font-size: 13px; color: var(--flare-color-text-tertiary); max-width: 260px; }
.flare-empty.is-error .flare-empty__desc { overflow-wrap: anywhere; word-break: break-word; }
.flare-empty__action { margin-top: var(--flare-size-spacing-xs); }
.flare-empty__actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: var(--flare-size-spacing-sm);
  max-width: 100%;
}
.flare-empty__spinner {
  width: var(--flare-size-component-empty-state-icon-size);
  height: var(--flare-size-component-empty-state-icon-size);
  border-radius: 50%;
  border: 3px solid var(--flare-color-bg-selected);
  border-top-color: var(--flare-color-primary);
  animation: flare-empty-spin 0.75s linear infinite;
}
.flare-empty.is-error .flare-empty__spinner {
  border-top-color: var(--flare-color-error);
}
@keyframes flare-empty-spin {
  to { transform: rotate(360deg); }
}
@media (prefers-reduced-motion: reduce) {
  .flare-empty__spinner { animation: none; }
}
.flare-empty.is-compact { gap: var(--flare-size-spacing-xs); padding: var(--flare-size-spacing-lg); }
.flare-empty.is-compact .flare-empty__ico { font-size: var(--flare-size-icon-size-xl); min-height: var(--flare-size-icon-size-xl); }
.flare-empty.is-compact .flare-empty__spinner { width: var(--flare-size-icon-size-xl); height: var(--flare-size-icon-size-xl); }
.flare-empty.is-compact .flare-empty__title { font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-semibold); }
.flare-empty.is-compact .flare-empty__desc { font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary); }
</style>
