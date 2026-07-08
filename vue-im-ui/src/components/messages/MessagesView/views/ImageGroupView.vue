<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readArray, readString } from "../../../../utils/contentData";
import ImageGroupCell from "./ImageGroupCell.vue";

const props = defineProps<{ content: ContentElem; isSelf: boolean; messageId?: string }>();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "image_group");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const images = computed(() => readArray(payload.value, "images"));
const description = computed(() => readString(payload.value, "description"));
const title = computed(() => readString(payload.value, "title") || `[多图] ${images.value.length || 0} 张`);
const imageCells = computed(() =>
  images.value.slice(0, 4).map((image, index) => {
    const item = asRecord(image);
    return {
      key: readString(item, "imageId", "id") || String(index),
      item,
    };
  }),
);
</script>

<template>
  <div class="im-image-group">
    <div class="im-image-group__grid" :aria-label="title">
      <div v-for="(image, index) in imageCells" :key="image.key" class="im-image-group__cell">
        <ImageGroupCell :image="image.item" :index="index" :message-id="messageId" />
      </div>
    </div>
    <strong class="im-image-group__title">{{ title }}</strong>
    <p v-if="description" class="im-media-caption im-image-group__desc">{{ description }}</p>
  </div>
</template>

<style scoped>
.im-image-group {
  display: inline-flex;
  flex-direction: column;
  gap: 7px;
  width: min(var(--im-media-image-max-width), 72vw);
  min-width: min(var(--im-media-card-min-width), 72vw);
  max-width: 72vw;
}

.im-image-group__grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 6px;
  overflow: hidden;
  padding: 6px;
  border-radius: 14px;
  background: color-mix(in srgb, var(--im-bg-surface-alt, #f2f3f5) 92%, #ffffff 8%);
  box-shadow: var(--im-bubble-shadow, 0 1px 2px rgba(17, 19, 24, 0.06));
}

.im-image-group__cell {
  display: grid;
  place-items: center;
  overflow: hidden;
  aspect-ratio: 1 / 1;
  min-height: 96px;
  border-radius: 10px;
  background: color-mix(in srgb, var(--im-bg-surface, #ffffff) 82%, var(--im-bg-surface-alt, #f2f3f5));
  color: var(--im-text-secondary);
}

.im-image-group__cell img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.im-image-group__title {
  display: block;
  margin: 0;
  color: var(--im-text-primary);
  font-size: 13px;
  font-weight: 800;
  line-height: 1.35;
}

.im-image-group__desc {
  margin: -3px 0 0;
  color: var(--im-text-primary);
  font-size: 12px;
  line-height: 1.45;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

@media (max-width: 599px) {
  .im-image-group {
    max-width: 76vw;
  }

  .im-image-group__cell {
    min-height: 82px;
  }
}
</style>
