<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from "vue";
import { NButton, NPopover } from "naive-ui";

/** Read-only help. Keep Native popover behavior while bounding the virtual anchor. */
defineProps<{ label: string }>();
const width = ref(320);
const open = ref(false);
const point = ref<{ x: number; y: number }>();
let trigger: HTMLElement | undefined;
function position() {
  if (!trigger?.isConnected) return;
  const rect = trigger.getBoundingClientRect();
  width.value = Math.min(320, Math.max(160, window.innerWidth - 24));
  point.value = {
    x: Math.max(
      width.value / 2 + 12,
      Math.min(
        window.innerWidth - width.value / 2 - 12,
        rect.left + rect.width / 2,
      ),
    ),
    y: rect.bottom,
  };
}
function anchor(event: MouseEvent) {
  if (event.currentTarget instanceof HTMLElement) {
    trigger = event.currentTarget;
    position();
    open.value = !open.value;
  }
}
function closeOutside(event: MouseEvent) {
  if (event.target instanceof Node && trigger?.contains(event.target)) return;
  open.value = false;
}
onMounted(() => {
  window.addEventListener("resize", position);
  window.addEventListener("scroll", position, true);
});
onBeforeUnmount(() => {
  window.removeEventListener("resize", position);
  window.removeEventListener("scroll", position, true);
  trigger = undefined;
});
</script>

<template>
  <span class="flare-admin-help" @keydown.esc.stop.prevent="open = false">
    <NButton
      size="small"
      :aria-label="label"
      :aria-expanded="open"
      @click="anchor"
      >{{ label }}</NButton
    >
    <NPopover
      trigger="manual"
      :show="open"
      placement="bottom"
      :width="width"
      :x="point?.x ?? 0"
      :y="point?.y ?? 0"
      @clickoutside="closeOutside"
      :style="{
        maxWidth: 'calc(100vw - 24px)',
        maxHeight: '60dvh',
        overflowY: 'auto',
        overflowWrap: 'anywhere',
      }"
    >
      <slot />
    </NPopover>
  </span>
</template>
