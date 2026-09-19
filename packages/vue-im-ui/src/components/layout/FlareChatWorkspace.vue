<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from "vue";

const props = withDefaults(defineProps<{
  label?: string;
  composerPlacement?: "flow" | "overlay";
  selectionMode?: boolean;
}>(), { composerPlacement: "flow", selectionMode: false });
const composerElement = ref<HTMLElement | null>(null);
const composerHeight = ref(0);
let observer: ResizeObserver | undefined;
const timelineBottomInset = computed(() => props.selectionMode
  ? 84 : Math.max(24, Math.min(48, Math.round(composerHeight.value * 0.18))));

watch(composerElement, (element) => {
  observer?.disconnect();
  if (!element) { composerHeight.value = 0; return; }
  const measure = () => {
    const height = Math.ceil(element.getBoundingClientRect().height);
    if (height !== composerHeight.value) composerHeight.value = height;
  };
  measure();
  if (typeof ResizeObserver !== "undefined") {
    observer = new ResizeObserver(measure);
    observer.observe(element);
  }
}, { flush: "post" });
onBeforeUnmount(() => observer?.disconnect());
</script>

<template>
  <section
    class="flare-chat-workspace"
    :class="{ 'flare-chat-workspace--overlay': composerPlacement === 'overlay' }"
    :style="{ '--flare-workspace-composer-height': `${composerHeight}px` }"
    :aria-label="label"
  >
    <div v-if="$slots.context" class="flare-chat-workspace__context"><slot name="context" /></div>
    <div class="flare-chat-workspace__header"><slot name="header" /></div>
    <div v-if="$slots.notice" class="flare-chat-workspace__notice"><slot name="notice" /></div>
    <div v-if="$slots.toolbar" class="flare-chat-workspace__toolbar"><slot name="toolbar" /></div>
    <div class="flare-chat-workspace__timeline"><slot name="timeline" :bottom-inset="timelineBottomInset" /></div>
    <div v-if="$slots.composer" ref="composerElement" class="flare-chat-workspace__composer"><slot name="composer" /></div>
    <slot name="overlays" />
  </section>
</template>

<style scoped>
.flare-chat-workspace {
  position: relative;
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
  width: 100%;
  height: 100%;
  min-width: 0;
  min-height: 0;
  overflow: hidden;
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-secondary);
  /* Everything inside a chat — its own chrome, the composer, the timeline — is laid out for this
     box, not for the window: a chat in a narrow pane of a wide desktop reads like a chat on a phone. */
  container: flare-chat / inline-size;
}

.flare-chat-workspace__header,
.flare-chat-workspace__context,
.flare-chat-workspace__composer {
  flex: none;
  min-width: 0;
}

.flare-chat-workspace__context {
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg);
  background: var(--flare-color-bg-primary);
}

.flare-chat-workspace__timeline {
  position: relative;
  display: flex;
  flex-direction: column;
  flex: 1;
  min-width: 0;
  min-height: 0;
  overflow: hidden;
}

.flare-chat-workspace__notice {
  display: grid;
  flex: none;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg) 0;
}

.flare-chat-workspace__toolbar {
  flex: none;
  min-width: 0;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md);
}

.flare-chat-workspace--overlay .flare-chat-workspace__timeline {
  padding-bottom: var(--flare-workspace-composer-height);
}

.flare-chat-workspace--overlay .flare-chat-workspace__composer {
  position: absolute;
  inset-inline: 0;
  bottom: 0;
  z-index: 5;
  display: flex;
  flex-direction: column;
  max-height: min(58dvh, 460px);
  border-top: 0;
  background: transparent;
}

.flare-chat-workspace__composer {
  position: relative;
  z-index: 1;
  background: var(--flare-color-bg-primary);
  border-top: 1px solid color-mix(in srgb, var(--flare-color-border-primary) 72%, transparent);
}

@container flare-chat (max-width: 599px) {
  .flare-chat-workspace__context {
    padding-inline: var(--flare-size-spacing-sm);
  }

  .flare-chat-workspace__composer {
    padding-bottom: env(safe-area-inset-bottom);
  }
}
</style>
