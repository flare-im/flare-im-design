<script setup lang="ts">
import { computed } from "vue";
import type { FlareGridImage } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    images: FlareGridImage[];
    /** Cap the tiles; the last visible tile shows a "+N" overflow badge. */
    max?: number;
  }>(),
  { max: 9 },
);
const emit = defineEmits<{ (e: "open", index: number): void }>();

const visible = computed(() => props.images.slice(0, props.max));
const overflow = computed(() => Math.max(0, props.images.length - visible.value.length));

/** WeChat-style column count: 1 → single, 4 → 2×2, otherwise up to 3 wide. */
const cols = computed(() => {
  const n = visible.value.length;
  if (n <= 1) return 1;
  if (n === 4) return 2;
  if (n <= 3) return n;
  return 3;
});
const single = computed(() => visible.value.length === 1);
</script>

<template>
  <div
    class="flare-image-grid"
    :class="{ 'is-single': single }"
    :style="{ '--cols': cols }"
  >
    <button
      v-for="(img, i) in visible"
      :key="i"
      type="button"
      class="flare-image-grid__cell"
      @click="emit('open', i)"
    >
      <img v-if="img.url" :src="img.url" :alt="img.alt || ''" loading="lazy" />
      <span v-else class="flare-image-grid__ph" />
      <span
        v-if="overflow > 0 && i === visible.length - 1"
        class="flare-image-grid__more"
      >+{{ overflow }}</span>
    </button>
  </div>
</template>

<style scoped>
.flare-image-grid {
  display: grid;
  grid-template-columns: repeat(var(--cols, 3), 1fr);
  gap: 4px;
  width: max-content;
  max-width: 100%;
}
.flare-image-grid.is-single { width: auto; }
.flare-image-grid__cell {
  position: relative;
  padding: 0;
  border: none;
  cursor: pointer;
  overflow: hidden;
  border-radius: 8px;
  background: var(--flare-color-bg-secondary, #f0eef6);
  width: 84px;
  height: 84px;
  transition: filter var(--flare-transition-fast, 150ms ease);
}
.flare-image-grid.is-single .flare-image-grid__cell {
  width: auto;
  height: auto;
  max-width: 220px;
  max-height: 260px;
  border-radius: 12px;
}
.flare-image-grid__cell:hover { filter: brightness(0.96); }
.flare-image-grid__cell img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.flare-image-grid.is-single .flare-image-grid__cell img {
  width: auto;
  height: auto;
  max-width: 220px;
  max-height: 260px;
  object-fit: contain;
}
.flare-image-grid__ph {
  display: block;
  width: 100%;
  height: 100%;
}
.flare-image-grid__more {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  font-weight: 600;
  color: #fff;
  background: rgba(17, 19, 24, 0.42);
}
</style>
