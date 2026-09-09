<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import FlareGlyph from "./FlareGlyph.vue";
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
  }>(),
  { icon: "folder", loading: false, tone: "normal" },
);
const emit = defineEmits<{ (e: "action"): void; (e: "tap"): void }>();
// The whole placeholder becomes tappable only when a @tap listener is bound.
const instance = getCurrentInstance();
const hasTapListener = computed(() => !!instance?.vnode.props?.onTap);
const isError = computed(() => props.tone === "error");
function onRootActivate() {
  if (hasTapListener.value) emit("tap");
}
</script>

<template>
  <div
    class="flare-empty"
    :class="{ 'is-tappable': hasTapListener, 'is-error': isError }"
    :role="hasTapListener ? 'button' : undefined"
    :tabindex="hasTapListener ? 0 : undefined"
    @click="onRootActivate"
    @keydown.enter.prevent="onRootActivate"
    @keydown.space.prevent="onRootActivate"
  >
    <div class="flare-empty__ico">
      <span v-if="loading" class="flare-empty__spinner" aria-hidden="true"></span>
      <slot v-else name="icon">
        <span
          class="flare-empty__glyph"
          :class="{ 'flare-empty__glyph--error': isError }"
        ><FlareGlyph :icon="icon" :size="44" /></span>
      </slot>
    </div>
    <div class="flare-empty__title">{{ title }}</div>
    <div v-if="description" class="flare-empty__desc">{{ description }}</div>
    <button
      v-if="actionText"
      class="flare-empty__act"
      @click.stop="emit('action')"
    >{{ actionText }}</button>
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
.flare-empty.is-tappable:focus-visible {
  outline: 2px solid var(--flare-color-primary, #7047D6);
  outline-offset: 4px;
  border-radius: var(--flare-size-radius-md, 8px);
}
.flare-empty__ico { font-size: 44px; opacity: 0.8; display: flex; align-items: center; justify-content: center; min-height: 44px; }
.flare-empty__glyph { display: inline-flex; align-items: center; justify-content: center; }
.flare-empty__glyph--error { color: var(--im-danger, var(--flare-color-error, #ef4444)); }
.flare-empty__title { font-size: 16px; color: var(--flare-color-text-primary); }
.flare-empty.is-error .flare-empty__title { color: var(--im-danger, var(--flare-color-error, #ef4444)); }
.flare-empty__desc { font-size: 13px; color: var(--flare-color-text-tertiary); max-width: 260px; }
.flare-empty.is-error .flare-empty__desc { overflow-wrap: anywhere; word-break: break-word; }
.flare-empty__act {
  margin-top: 8px;
  padding: 7px 18px;
  border-radius: var(--flare-size-radius-md, 8px);
  border: 1px solid var(--flare-color-primary);
  background: none;
  color: var(--flare-color-primary);
  font-size: 13px;
  cursor: pointer;
}
.flare-empty__spinner {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: 3px solid var(--flare-color-bg-selected, rgba(124, 58, 237, 0.18));
  border-top-color: var(--flare-color-primary, #7047D6);
  animation: flare-empty-spin 0.75s linear infinite;
}
.flare-empty.is-error .flare-empty__spinner {
  border-top-color: var(--im-danger, var(--flare-color-error, #ef4444));
}
@keyframes flare-empty-spin {
  to { transform: rotate(360deg); }
}
</style>
