<script setup lang="ts">
import { computed } from "vue";
import MsgIcon from "./MsgIcon.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import { flareImageGroupLayout } from "../../../utils/imageGroupLayout";

/** One image of an album, as the body draws it. */
export interface FlareImageGroupItem {
  /** The full-size image. */
  src?: string;
  /** A smaller image to draw in the tile; `src` when there is none. */
  thumbnailSrc?: string;
  /** What the image shows, in words. */
  alt?: string;
}

/**
 * image group — an album: square tiles laid out by the shared rule (`spec/image-group-layout-vectors.json`),
 * the last drawn tile reading `+N` when the album holds more images than tiles, and the album's description
 * under them. Presentational: a tile emits `open` with its image's index and the host decides what opens —
 * one image, or the conversation's gallery. A host that resolves its images itself draws each tile through
 * the `image` slot; the tile keeps its button, label and `+N` cover either way.
 */
const props = withDefaults(defineProps<{
  images?: readonly FlareImageGroupItem[];
  description?: string;
  self?: boolean;
}>(), { images: () => [], description: "", self: false });
const emit = defineEmits<{ (e: "open", index: number): void }>();
const { t } = useFlareI18nOptional();

const count = computed(() => props.images.length);
const layout = computed(() => flareImageGroupLayout(count.value));
const tiles = computed(() => props.images.slice(0, layout.value.visible));
const covered = (index: number) => layout.value.more > 0 && index === layout.value.visible - 1;
const label = (index: number) =>
  covered(index)
    ? t("message.imageGroupItemMore", { index: index + 1, count: count.value, more: layout.value.more })
    : t("message.imageGroupItem", { index: index + 1, count: count.value });
</script>

<template>
  <div v-if="count" class="fm-album" :class="{ 'is-self': self }" role="group" :aria-label="t('message.imageGroupLabel', { count })">
    <div class="fm-album__grid" :style="{ '--fm-album-columns': String(layout.columns) }">
      <div v-for="(image, index) in tiles" :key="index" class="fm-album__tile">
        <slot name="image" :image="image" :index="index">
          <img v-if="image.thumbnailSrc || image.src" :src="image.thumbnailSrc || image.src" :alt="image.alt ?? ''" loading="lazy" decoding="async" />
          <span v-else class="fm-album__placeholder"><MsgIcon name="image" :size="22" /></span>
        </slot>
        <button type="button" class="fm-album__open" :aria-label="label(index)" @click="emit('open', index)">
          <span v-if="covered(index)" class="fm-album__more" aria-hidden="true">+{{ layout.more }}</span>
        </button>
      </div>
    </div>
    <p v-if="description.trim()" class="fm-album__description">{{ description.trim() }}</p>
  </div>
</template>

<style scoped>
.fm-album {
  display: inline-flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-2xs);
  width: min(var(--flare-component-media-image-max-width), 72vw);
  max-width: 100%;
}
.fm-album__grid {
  display: grid;
  grid-template-columns: repeat(var(--fm-album-columns), minmax(0, 1fr));
  gap: var(--flare-size-spacing-xs);
  overflow: hidden;
  border-radius: var(--flare-size-radius-lg);
}
.fm-album__tile {
  position: relative;
  overflow: hidden;
  aspect-ratio: 1 / 1;
  background: var(--flare-color-bg-tertiary);
  color: var(--flare-color-text-tertiary);
}
.fm-album__tile :deep(img) {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.fm-album__placeholder {
  display: grid;
  place-items: center;
  width: 100%;
  height: 100%;
}
.fm-album__open {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  padding: 0;
  border: 0;
  background: transparent;
  cursor: zoom-in;
}
.fm-album__open:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
/* The covered last tile: its own image dimmed under the count of the images not drawn. */
.fm-album__more {
  display: grid;
  place-items: center;
  width: 100%;
  height: 100%;
  background: rgb(0 0 0 / 45%);
  color: #fff;
  font-size: var(--flare-size-font-size-2xl);
  font-weight: 700;
}
.fm-album__description {
  margin: 0;
  color: inherit;
  font-size: var(--flare-size-font-size-md);
  line-height: 1.45;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
</style>
