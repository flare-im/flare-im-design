<script setup lang="ts">
import { computed, onBeforeUnmount, ref } from "vue";
import FlareVoiceMessage from "../../standalone/FlareVoiceMessage.vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readNumber, readString } from "../../../../utils/contentData";
import { buildMediaResolveRequest, readMediaLocalPath } from "../../../../utils/mediaResolveRequest";
import { useResolvedMediaUrl } from "../../../../composables/useMediaResolver";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";

const props = defineProps<{ content: ContentElem; isSelf: boolean; messageId?: string }>();
const { t } = useFlareI18n();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "audio");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const source = computed(() => asRecord(payload.value.source));
const audioRef = ref<HTMLAudioElement | null>(null);
const isPlaying = ref(false);
const currentSeconds = ref(0);
const loadedDurationSeconds = ref(0);
const playbackError = ref(false);

const payloadDurationSeconds = computed(() => {
  const ms = readNumber(payload.value, 0, "durationMs", "duration_ms", "durationMillis", "duration_millis");
  if (ms > 0) return Math.max(1, Math.round(ms / 1000));
  const seconds = readNumber(payload.value, 0, "durationSeconds", "duration_seconds", "duration");
  return seconds > 0 ? Math.max(1, Math.round(seconds)) : 0;
});

const durationSeconds = computed(() => loadedDurationSeconds.value || payloadDurationSeconds.value);
const sourceId = computed(() =>
  readString(
    payload.value,
    "audioId",
    "fileId",
    "mediaId",
    "id",
    "uuid",
  ) || readString(source.value, "audioId", "fileId", "mediaId", "id", "uuid"),
);
const sourceDirectUrl = computed(() =>
  readString(
    payload.value,
    "url",
    "mediaUrl",
    "media_url",
    "downloadUrl",
    "download_url",
    "previewUrl",
    "preview_url",
    "src",
  ) || readString(source.value, "url", "mediaUrl", "media_url", "downloadUrl", "download_url"),
);
const sourceRequest = computed(() =>
  buildMediaResolveRequest({
    kind: "audio",
    messageId: props.messageId,
    url: sourceDirectUrl.value,
    id: sourceId.value,
    localPath: readMediaLocalPath(source.value, payload.value),
    mimeType: readString(source.value, "mimeType") || readString(payload.value, "mimeType"),
    fileName: readString(source.value, "fileName", "name", "title") || readString(payload.value, "fileName", "name", "title"),
  }),
);
const resolvedAudio = useResolvedMediaUrl(sourceRequest);
const audioUrl = computed(() => resolvedAudio.url.value);
const progressRatio = computed(() => {
  if (!durationSeconds.value) return 0;
  return Math.min(1, Math.max(0, currentSeconds.value / durationSeconds.value));
});

async function togglePlay(): Promise<void> {
  const node = audioRef.value;
  if (!node || !audioUrl.value) return;
  playbackError.value = false;
  if (isPlaying.value) {
    node.pause();
    return;
  }
  try {
    await node.play();
  } catch {
    playbackError.value = true;
    isPlaying.value = false;
  }
}

function onLoadedMetadata(): void {
  const duration = audioRef.value?.duration ?? 0;
  loadedDurationSeconds.value = Number.isFinite(duration) ? Math.max(0, duration) : 0;
}

function onTimeUpdate(): void {
  const current = audioRef.value?.currentTime ?? 0;
  currentSeconds.value = Number.isFinite(current) ? current : 0;
}

function onSeek(ratio: number): void {
  const node = audioRef.value;
  if (!node || !durationSeconds.value) return;
  node.currentTime = Math.min(1, Math.max(0, ratio)) * durationSeconds.value;
  currentSeconds.value = node.currentTime;
}

function onEnded(): void {
  isPlaying.value = false;
  currentSeconds.value = 0;
}

onBeforeUnmount(() => {
  audioRef.value?.pause();
});
</script>

<template>
  <div class="im-audio">
    <FlareVoiceMessage
      embedded
      :outbound="isSelf"
      :seconds="durationSeconds"
      :elapsed-seconds="currentSeconds"
      :playing="isPlaying"
      :progress="progressRatio"
      :disabled="!audioUrl"
      @play="togglePlay"
      @seek="onSeek"
    />
    <p v-if="playbackError" class="im-audio__error" role="status">
      {{ t("voicePlayer.playbackError") }}
    </p>
    <audio
      v-if="audioUrl"
      ref="audioRef"
      :src="audioUrl"
      preload="metadata"
      class="im-audio__player"
      @loadedmetadata="onLoadedMetadata"
      @timeupdate="onTimeUpdate"
      @play="isPlaying = true"
      @pause="isPlaying = false"
      @ended="onEnded"
      @error="playbackError = true"
    />
  </div>
</template>

<style scoped>
.im-audio {
  display: inline-grid;
  max-width: 100%;
  gap: 5px;
  color: inherit;
}

.im-audio__error {
  max-width: 240px;
  margin: 0;
  color: var(--flare-color-error-text);
  font-size: 11px;
  line-height: 1.3;
}

.im-audio__player {
  display: none;
}
</style>
