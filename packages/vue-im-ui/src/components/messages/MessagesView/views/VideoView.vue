<script setup lang="ts">
import { computed, ref, watch } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readNumber, readString } from "../../../../utils/contentData";
import VideoPlayerModal from "../../../message-preview/VideoPlayerModal.vue";
import { buildMediaResolveRequest, readMediaLocalPath } from "../../../../utils/mediaResolveRequest";
import { useResolvedMediaUrl } from "../../../../composables/useMediaResolver";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import FlareVideoMessage from "../../standalone/FlareVideoMessage.vue";

// Timeline adapter: video payload → source / poster resolution (with a poster
// frame captured from the video when the payload has none) → the contract body
// in flexible mode. The player modal and caption stay here.
const props = defineProps<{ content: ContentElem; isSelf: boolean; messageId?: string }>();
const { t } = useFlareI18n();

const previewOpen = ref(false);
const generatedPosterUrl = ref("");
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
const title = computed(() => description.value || readString(payload.value, "title") || t("mediaMessage.video"));
const durationLabel = computed(() => {
  const ms = readNumber(payload.value, 0, "durationMs", "duration_ms", "durationMillis", "duration_millis");
  const seconds = ms > 0 ? ms / 1000 : readNumber(payload.value, 0, "durationSeconds", "duration_seconds", "durationSec", "duration");
  if (!(seconds > 0)) return "";
  const whole = Math.round(seconds);
  return `${String(Math.floor(whole / 60)).padStart(2, "0")}:${String(whole % 60).padStart(2, "0")}`;
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
    if (!nextVideoUrl || nextPosterUrl) {
      generatingPoster.value = false;
      return;
    }
    generatingPoster.value = true;
    void capturePosterFromVideo(nextVideoUrl)
      .then((poster) => {
        if (canceled) return;
        generatedPosterUrl.value = poster;
      })
      .catch(() => {
        if (canceled) return;
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
    <FlareVideoMessage
      :poster="displayPosterUrl"
      :duration="durationLabel"
      :alt="title"
      :loading="resolvedPoster.loading.value || generatingPoster"
      :disabled="!videoUrl"
      max-width="var(--flare-component-media-video-width)"
      max-height="min(260px, 42vh)"
      @play="previewOpen = true"
    />
    <p v-if="description" class="im-media-caption">{{ description }}</p>
    <VideoPlayerModal v-model:show="previewOpen" :video-src="videoUrl" :poster="displayPosterUrl" :title="title" />
  </div>
</template>

<style scoped>
/* `100%` as well as the viewport share: a media body must never be wider than the bubble it sits
   in. Without it a bubble narrower than 72vw — any bubble outside a timeline, or any narrow pane —
   has its picture hang out over the page edge (FR-157). */
.im-video {
  position: relative;
  display: inline-flex;
  flex-direction: column;
  gap: 7px;
  max-width: min(72vw, 100%);
}
</style>
