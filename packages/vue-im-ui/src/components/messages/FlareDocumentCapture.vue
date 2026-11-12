<script setup lang="ts">
// 证件拍摄 —— 引擎的 captureDocument 请求由宿主收到后画的取景面板（设计 7.2、7.5）。
// 相机画面由宿主提供（`preview` 插槽放宿主的 <video>，`capture` 回调从宿主的相机取一张静帧），
// Kit 不申请相机权限；Kit 负责取景框、提示、确认与重拍，以及压缩和去 EXIF：照片在画布上按方向
// 重画再编码成 JPEG，原文件的元数据一概不留（flareProcessDocumentPhoto）。`done` 交出的文件就是
// 宿主回给引擎的 {file}。
import { computed, onBeforeUnmount, ref, watch } from "vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import {
  flareDocumentFrameAspect,
  flareProcessDocumentPhoto,
  type FlareCapturedDocument,
  type FlareDocumentProcessError,
  type FlareDocumentSide,
} from "../../shared/contracts/capability-ui";

const props = withDefaults(
  defineProps<{
    open: boolean;
    /** Which side the plugin asked for (`captureDocument.side`). */
    side: FlareDocumentSide;
    /** The input's accept list (`captureDocument.accept`). */
    accept?: ReadonlyArray<string>;
    /** The input's size limit (`captureDocument.maxBytes`). */
    maxBytes: number;
    /** Takes a still from the host's camera; null: none taken. Absent or `cameraUnavailable`: no shutter. */
    capture?: () => Promise<Blob | null>;
    /** Lets the viewer choose a photo (the host's picker); null: none chosen. */
    pickPhoto?: () => Promise<Blob | null>;
    /** The host could not open the camera (refused or missing): the viewfinder says so and offers the album. */
    cameraUnavailable?: boolean;
  }>(),
  { accept: () => [], cameraUnavailable: false },
);
const emit = defineEmits<{ (e: "done", file: FlareCapturedDocument): void; (e: "cancel"): void }>();
const { t } = useFlareI18nOptional();

type Phase = { kind: "viewfinder" } | { kind: "processing" } | { kind: "review"; file: FlareCapturedDocument; url: string } | { kind: "error"; error: FlareDocumentProcessError };
const phase = ref<Phase>({ kind: "viewfinder" });
const aspect = computed(() => flareDocumentFrameAspect(props.side));
const busy = computed(() => phase.value.kind === "processing");
const canShoot = computed(() => Boolean(props.capture) && !props.cameraUnavailable && !busy.value);

function release(): void {
  if (phase.value.kind === "review") URL.revokeObjectURL(phase.value.url);
}
function reset(): void {
  release();
  phase.value = { kind: "viewfinder" };
}
watch(() => [props.open, props.side] as const, reset);
onBeforeUnmount(release);

async function take(source: (() => Promise<Blob | null>) | undefined): Promise<void> {
  if (!source || busy.value) return;
  const photo = await source();
  if (!photo) return;
  release();
  phase.value = { kind: "processing" };
  try {
    const file = await flareProcessDocumentPhoto(photo, props.side, { maxBytes: props.maxBytes, accept: props.accept });
    const url = URL.createObjectURL(new Blob([file.bytes], { type: file.contentType }));
    phase.value = { kind: "review", file, url };
  } catch (error) {
    const known: FlareDocumentProcessError[] = ["tooLarge", "failed", "notAccepted"];
    phase.value = { kind: "error", error: known.includes(error as FlareDocumentProcessError) ? (error as FlareDocumentProcessError) : "failed" };
  }
}
function use(): void {
  if (phase.value.kind !== "review") return;
  const file = phase.value.file;
  reset();
  emit("done", file);
}
function cancel(): void {
  if (busy.value) return;
  reset();
  emit("cancel");
}
const sideLabel = computed(() => t(`pluginForm.documentSide.${props.side}`));
</script>

<template>
  <FlareBottomSheet :open="open" :title="sideLabel" :dismissible="!busy" fill max-height="92vh" show-close @close="cancel">
    <div class="flare-doc-capture" :data-side="side" :aria-busy="busy || undefined">
      <div class="flare-doc-capture__stage">
        <img
          v-if="phase.kind === 'review'"
          class="flare-doc-capture__review"
          :src="phase.url"
          :alt="sideLabel"
          draggable="false"
          data-doc-review="true"
        />
        <template v-else>
          <div class="flare-doc-capture__preview"><slot name="preview" /></div>
          <div class="flare-doc-capture__mask" aria-hidden="true">
            <div class="flare-doc-capture__frame" :class="{ 'is-portrait': side === 'holding' }" :style="{ aspectRatio: String(aspect) }" data-doc-frame="true" />
          </div>
          <p v-if="cameraUnavailable" class="flare-doc-capture__unavailable" role="status">{{ t("documentCapture.cameraUnavailable") }}</p>
        </template>
      </div>
      <p v-if="phase.kind === 'processing'" class="flare-doc-capture__hint" role="status">{{ t("documentCapture.processing") }}</p>
      <p v-else-if="phase.kind === 'error'" class="flare-doc-capture__error" role="alert" data-doc-error="true">{{ t(`documentCapture.${phase.error}`) }}</p>
      <p v-else-if="phase.kind === 'viewfinder'" class="flare-doc-capture__hint">{{ t(`documentCapture.hint.${side}`) }}</p>
      <div class="flare-doc-capture__actions">
        <template v-if="phase.kind === 'review'">
          <FlareButton block size="lg" :label="t('documentCapture.use')" data-doc-use="true" @click="use" />
          <FlareButton block size="lg" variant="secondary" :label="t('documentCapture.retake')" data-doc-retake="true" @click="reset" />
        </template>
        <template v-else>
          <FlareButton
            v-if="capture && !cameraUnavailable"
            block
            size="lg"
            :label="t('documentCapture.shoot')"
            :loading="busy"
            :disabled="!canShoot"
            data-doc-shoot="true"
            @click="take(capture)"
          />
          <FlareButton
            v-if="pickPhoto"
            block
            size="lg"
            :variant="capture && !cameraUnavailable ? 'secondary' : 'primary'"
            :label="t('documentCapture.fromAlbum')"
            :disabled="busy"
            data-doc-album="true"
            @click="take(pickPhoto)"
          />
        </template>
      </div>
    </div>
  </FlareBottomSheet>
</template>

<style scoped>
.flare-doc-capture {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-md);
  height: 100%;
  min-height: 0;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg) var(--flare-size-spacing-lg);
  color: var(--flare-color-text-primary);
}
.flare-doc-capture__stage {
  position: relative;
  flex: 1 1 auto;
  min-height: 240px;
  overflow: hidden;
  border-radius: var(--flare-size-radius-lg);
  /* A camera stage stays dark in both themes (the media stage tokens). */
  background: var(--flare-color-media-stage);
}
.flare-doc-capture__preview,
.flare-doc-capture__preview :deep(video),
.flare-doc-capture__preview :deep(img) {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.flare-doc-capture__mask { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; padding: var(--flare-size-spacing-lg); pointer-events: none; }
/* The frame: what is outside it is dimmed by its own spread shadow. */
.flare-doc-capture__frame {
  width: min(100%, 520px);
  max-height: 100%;
  border: 2px solid var(--flare-color-media-on-stage);
  border-radius: var(--flare-size-radius-md);
  box-shadow: 0 0 0 9999px var(--flare-color-media-stage-shade);
}
.flare-doc-capture__frame.is-portrait { width: auto; height: min(100%, 520px); }
.flare-doc-capture__review { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: contain; user-select: none; }
.flare-doc-capture__unavailable {
  position: absolute;
  inset-inline: var(--flare-size-spacing-lg);
  bottom: var(--flare-size-spacing-lg);
  margin: 0;
  text-align: center;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-media-on-stage);
}
.flare-doc-capture__hint { margin: 0; text-align: center; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary); }
.flare-doc-capture__error { margin: 0; text-align: center; font-size: var(--flare-size-font-size-md); color: var(--flare-color-error-text); }
.flare-doc-capture__actions { display: flex; flex-direction: column; gap: var(--flare-size-spacing-sm); }
</style>
