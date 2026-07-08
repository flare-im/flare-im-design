<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { PlayCircleOutline, VideocamOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readString } from "../../../../utils/contentData";
import VideoPlayerModal from "../../../message-preview/VideoPlayerModal.vue";
import { buildMediaResolveRequest, readMediaLocalPath } from "../../../../utils/mediaResolveRequest";
import { useResolvedMediaUrl } from "../../../../composables/useMediaResolver";

const props = defineProps<{ content: ContentElem; isSelf: boolean; messageId?: string }>();

const previewOpen = ref(false);
const posterLoadFailed = ref(false);
const generatedPosterUrl = ref("");
const generatedPosterFailed = ref(false);
const generatingPoster = ref(false);

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "video");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const source = computed(() => asRecord(payload.value.source));
const cover = computed(() => asRecord(payload.value.cover));
const videoId = computed(() =>
  readString(source.value, "fileId", "videoId", "id") ||
  readString(payload.value, "videoId", "fileId", "id"),
);
const coverId = computed(() =>
  readString(cover.value, "imageId", "fileId", "id") ||
  readString(payload.value, "coverId", "coverFileId"),
);
const videoRequest = computed(() =>
  buildMediaResolveRequest({
    kind: "video",
    messageId: props.messageId,
    url: readString(source.value, "url", "localPreviewUrl", "downloadUrl") ||
      readString(payload.value, "url", "localPreviewUrl", "downloadUrl"),
    id: videoId.value,
    localPath: readMediaLocalPath(source.value, payload.value),
    mimeType: readString(source.value, "mimeType") || readString(payload.value, "mimeType"),
    fileName: readString(payload.value, "fileName", "title"),
  }),
);
const coverRequest = computed(() =>
  buildMediaResolveRequest({
    kind: "videoCover",
    messageId: props.messageId,
    url: readString(cover.value, "url", "localPreviewUrl", "downloadUrl") ||
      readString(payload.value, "coverUrl", "thumbnailUrl"),
    id: coverId.value,
    localPath: readMediaLocalPath(cover.value, payload.value),
    mimeType: readString(cover.value, "mimeType"),
    fileName: readString(payload.value, "fileName", "title"),
  }),
);
const resolvedVideo = useResolvedMediaUrl(videoRequest);
const resolvedPoster = useResolvedMediaUrl(coverRequest);
const videoUrl = computed(() => resolvedVideo.url.value);
const posterUrl = computed(() => resolvedPoster.url.value);
const displayPosterUrl = computed(() => posterUrl.value || generatedPosterUrl.value);
const description = computed(() => readString(payload.value, "description", "caption"));
const title = computed(() => description.value || readString(payload.value, "title") || "Video");

watch(posterUrl, () => {
  posterLoadFailed.value = false;
});

function capturePosterFromVideo(src: string): Promise<string> {
  if (typeof document === "undefined") return Promise.resolve("");
  return new Promise((resolve, reject) => {
    const video = document.createElement("video");
    const canvas = document.createElement("canvas");
    let settled = false;
    let timer = 0;

    const cleanup = () => {
      window.clearTimeout(timer);
      video.pause();
      video.removeAttribute("src");
      video.load();
    };
    const finish = (value: string) => {
      if (settled) return;
      settled = true;
      cleanup();
      resolve(value);
    };
    const fail = (error: unknown) => {
      if (settled) return;
      settled = true;
      cleanup();
      reject(error);
    };
    const draw = () => {
      try {
        const width = video.videoWidth;
        const height = video.videoHeight;
        if (!width || !height) {
          fail(new Error("video poster frame is empty"));
          return;
        }
        canvas.width = width;
        canvas.height = height;
        const context = canvas.getContext("2d");
        if (!context) {
          fail(new Error("canvas context unavailable"));
          return;
        }
        context.drawImage(video, 0, 0, width, height);
        finish(canvas.toDataURL("image/jpeg", 0.82));
      } catch (error) {
        fail(error);
      }
    };

    timer = window.setTimeout(() => fail(new Error("video poster timeout")), 8_000);
    video.crossOrigin = "anonymous";
    video.muted = true;
    video.playsInline = true;
    video.preload = "metadata";
    video.addEventListener("error", () => fail(new Error("video poster load failed")), { once: true });
    video.addEventListener("loadedmetadata", () => {
      const duration = Number.isFinite(video.duration) ? video.duration : 0;
      const target = duration > 0.4 ? 0.2 : 0;
      if (target <= 0) {
        video.addEventListener("loadeddata", draw, { once: true });
        return;
      }
      video.addEventListener("seeked", draw, { once: true });
      try {
        video.currentTime = target;
      } catch (error) {
        fail(error);
      }
    }, { once: true });
    video.src = src;
    video.load();
  });
}

watch(
  [videoUrl, posterUrl],
  ([nextVideoUrl, nextPosterUrl], _previous, onCleanup) => {
    let canceled = false;
    onCleanup(() => {
      canceled = true;
    });
    generatedPosterUrl.value = "";
    generatedPosterFailed.value = false;
    if (!nextVideoUrl || nextPosterUrl) {
      generatingPoster.value = false;
      return;
    }
    generatingPoster.value = true;
    void capturePosterFromVideo(nextVideoUrl)
      .then((poster) => {
        if (canceled) return;
        generatedPosterUrl.value = poster;
        generatedPosterFailed.value = !poster;
      })
      .catch(() => {
        if (canceled) return;
        generatedPosterFailed.value = true;
      })
      .finally(() => {
        if (!canceled) generatingPoster.value = false;
      });
  },
  { immediate: true },
);
</script>

<template>
  <div class="im-video">
    <button type="button" class="im-video__button" :disabled="!videoUrl" @click="previewOpen = true">
      <img
        v-if="displayPosterUrl && !posterLoadFailed"
        :src="displayPosterUrl"
        :alt="title"
        class="im-video__poster"
        loading="lazy"
        @error="posterLoadFailed = true"
      />
      <div v-else class="im-video__placeholder">
        <n-icon :component="VideocamOutline" :size="28" />
        <span>
          {{
            resolvedPoster.loading.value || generatingPoster
              ? "Generating cover"
              : posterUrl || generatedPosterFailed
                ? "Cover failed to load"
                : "Video"
          }}
        </span>
      </div>
      <n-icon class="im-video__play" :component="PlayCircleOutline" :size="42" />
    </button>
    <p v-if="description" class="im-video__title">{{ description }}</p>
    <VideoPlayerModal v-model:show="previewOpen" :video-src="videoUrl" :poster="displayPosterUrl" :title="title" />
  </div>
</template>

<style scoped>
.im-video__button {
  position: relative;
  display: block;
  overflow: hidden;
  width: var(--im-media-video-width);
  min-width: min(var(--im-media-card-min-width), 72vw);
  min-height: 132px;
  padding: 0;
  border: 0;
  border-radius: 14px;
  background: color-mix(in srgb, var(--im-bg-surface-alt, #f2f3f5) 92%, #ffffff 8%);
  box-shadow: var(--im-bubble-shadow, 0 1px 2px rgba(17, 19, 24, 0.06));
  cursor: pointer;
}

.im-video {
  position: relative;
  display: inline-flex;
  flex-direction: column;
  gap: 7px;
}

.im-video__poster,
.im-video__placeholder {
  display: block;
  width: 100%;
  min-height: 132px;
  max-height: min(260px, 42vh);
  object-fit: cover;
}

.im-video__placeholder {
  display: grid;
  place-items: center;
  gap: 6px;
  min-height: 120px;
  background: var(--im-bg-surface-alt, #f2f3f5);
  color: var(--im-text-secondary);
  font-size: 12px;
}

.im-video__button:disabled {
  cursor: default;
}

.im-video__button:disabled .im-video__play {
  opacity: 0.35;
}

.im-video__play {
  position: absolute;
  inset: 0;
  margin: auto;
  color: rgba(255, 255, 255, 0.92);
  filter: drop-shadow(0 2px 8px rgba(0, 0, 0, 0.35));
}

.im-video__title {
  width: var(--im-media-video-width);
  min-width: min(var(--im-media-card-min-width), 72vw);
  max-width: 72vw;
  margin: 0;
  font-size: 12px;
  color: var(--im-text-primary);
  line-height: 1.45;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}

</style>
