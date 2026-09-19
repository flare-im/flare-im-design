<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, ref } from "vue";
import { DownloadOutline } from "../../../../shared/icon-glyphs";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readArray, readString } from "../../../../utils/contentData";
import { downloadUrlWithFileName } from "../../../../utils/browserDownload";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import ImagePreviewModal from "../../../message-preview/ImagePreviewModal.vue";
import FlareImageGroupMessage from "../../standalone/FlareImageGroupMessage.vue";
import ImageGroupCell, { type ImageGroupCellResolution } from "./ImageGroupCell.vue";
import { injectTimelineImageGallery } from "../../timelineImageGallery";

// Timeline adapter: the core's image group → the public album body, each tile resolving its own image. In a
// message list a tile opens the list's gallery at its image, which each tile's resolution is reported to;
// outside one it opens this album's preview of the image. Either preview can save it.
const props = defineProps<{ content: ContentElem; isSelf: boolean; messageId?: string }>();
const { t } = useFlareI18n();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "image_group");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});
const rawImages = computed(() => readArray(payload.value, "images").map(asRecord));
const images = computed(() => rawImages.value.map((image) => ({ alt: readString(image, "description", "title") })));
const description = computed(() => readString(payload.value, "description"));

const resolved = reactive(new Map<number, ImageGroupCellResolution>());
const openIndex = ref<number | null>(null);
const opened = computed(() => (openIndex.value == null ? undefined : resolved.get(openIndex.value)));
const previewOpen = computed({
  get: () => openIndex.value != null && Boolean(opened.value?.fullUrl),
  set: (show: boolean) => { if (!show) openIndex.value = null; },
});

const gallery = injectTimelineImageGallery();
const reported = new Set<number>();

function onResolved(value: ImageGroupCellResolution): void {
  resolved.set(value.index, value);
  const messageId = props.messageId;
  if (!gallery || !messageId) return;
  gallery.report(messageId, value.index, {
    fullUrl: value.fullUrl,
    alt: value.alt,
    download: value.fullUrl ? () => void downloadUrlWithFileName(value.fullUrl, value.fileName) : null,
    downloading: false,
  });
  reported.add(value.index);
}

onBeforeUnmount(() => {
  const messageId = props.messageId;
  if (gallery && messageId) reported.forEach((index) => gallery.report(messageId, index, undefined));
});

function openTile(index: number): void {
  if (props.messageId && gallery?.open(props.messageId, index)) return;
  openIndex.value = index;
}

async function download(): Promise<void> {
  const item = opened.value;
  if (item?.fullUrl) await downloadUrlWithFileName(item.fullUrl, item.fileName);
}
</script>

<template>
  <div class="im-image-group">
    <FlareImageGroupMessage :images="images" :description="description" :self="isSelf" @open="openTile">
      <template #image="{ index }">
        <ImageGroupCell :image="rawImages[index]" :index="index" :message-id="messageId" @resolved="onResolved" />
      </template>
    </FlareImageGroupMessage>
    <ImagePreviewModal
      v-model:show="previewOpen"
      :image-src="opened?.fullUrl ?? ''"
      :alt="opened?.alt || t('mediaMessage.image')"
      :primary-action-icon="DownloadOutline"
      :primary-action-title="t('media.downloadImage')"
      @primary-action="download"
    />
  </div>
</template>

<style scoped>
/* `100%` as well as the viewport share: a media body must never be wider than the bubble it sits
   in. Without it a bubble narrower than 72vw — any bubble outside a timeline, or any narrow pane —
   has its picture hang out over the page edge (FR-157). */
.im-image-group {
  display: inline-flex;
  flex-direction: column;
  max-width: min(72vw, 100%);
}

@container flare-timeline (max-width: 599px) {
  .im-image-group {
    max-width: min(76vw, 100%);
  }
}
</style>
