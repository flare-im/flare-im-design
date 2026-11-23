<script setup lang="ts">
// 证件拍摄 —— 引擎的 captureDocument 请求由宿主收到后画的取景面板（设计 7.2、7.5）。
// 相机画面由宿主提供（`preview` 插槽放宿主的 <video>，`capture` 回调从宿主的相机取一张静帧），
// Kit 不申请相机权限；Kit 负责取景框、提示、确认与重拍，以及压缩和去 EXIF：照片在画布上按方向
// 重画再编码成 JPEG，原文件的元数据一概不留（flareProcessDocumentPhoto）。`done` 交出的文件就是
// 宿主回给引擎的 {file}。
import { computed, nextTick, onBeforeUnmount, ref, watch } from "vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareModal from "../general/FlareModal.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
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
let generation = 0;
const canShoot = computed(() => Boolean(props.capture) && !props.cameraUnavailable && !busy.value);

function release(): void {
  if (phase.value.kind === "review") URL.revokeObjectURL(phase.value.url);
}
function reset(): void {
  generation++;
  release();
  phase.value = { kind: "viewfinder" };
}
watch(() => [props.open, props.side] as const, reset);
onBeforeUnmount(() => { generation++; release(); });

// §6.4: full screen on a phone (the shell's form factor, else the viewport under breakpoints.sm, so a host without
// FlareUiProvider still gets it); the 560 dialog elsewhere. Decided on opening: switching while open would remount
// the host's camera preview.
const platform = useFlarePlatformSafe();
const narrowViewport = () => typeof globalThis.matchMedia === "function" && globalThis.matchMedia("(max-width: 599.98px)").matches;
const fullscreen = ref(false);
watch(() => props.open, (open) => { if (open) fullscreen.value = platform.capabilities.value.bottomSheet || narrowViewport(); }, { immediate: true });

// Keyboard (§6.4): the shutter comes first in the panel, so it holds the opening focus and Space takes the photo; the
// review hands focus to "use photo", so Enter uses it; Escape is the surface's own close (cancel, inert while busy).
const root = ref<HTMLElement>();
watch(() => phase.value.kind, async (kind, before) => {
  if (!props.open || (kind !== "review" && kind !== "viewfinder") || kind === before) return;
  await nextTick();
  root.value?.querySelector<HTMLElement>(kind === "review" ? "[data-doc-use]" : "[data-doc-shoot]:not(:disabled)")?.focus({ preventScroll: true });
});

async function take(source: (() => Promise<Blob | null>) | undefined): Promise<void> {
  if (!source || busy.value || !props.open) return;
  const current = ++generation;
  release();
  phase.value = { kind: "processing" };
  try {
    const photo = await source();
    if (generation !== current || !props.open) return;
    if (!photo) { phase.value = { kind: "viewfinder" }; return; }
    const file = await flareProcessDocumentPhoto(photo, props.side, { maxBytes: props.maxBytes, accept: props.accept });
    if (generation !== current || !props.open) return;
    const url = URL.createObjectURL(new Blob([new Uint8Array(file.bytes)], { type: file.contentType }));
    phase.value = { kind: "review", file, url };
  } catch (error) {
    if (generation !== current || !props.open) return;
    const known: FlareDocumentProcessError[] = ["tooLarge", "failed", "notAccepted", "format"];
    phase.value = { kind: "error", error: known.includes(error as FlareDocumentProcessError) ? (error as FlareDocumentProcessError) : "failed" };
  }
}
function use(): void {
  if (!props.open || phase.value.kind !== "review") return;
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
// ID-1 sides take the token's card ratio (§6.4); holding keeps the 3:4 portrait of the capability vectors.
const frameRatio = computed(() => props.side === "holding" ? String(aspect.value) : "var(--flare-size-component-document-frame-ratio)");
</script>

<template>
  <component
    :is="fullscreen ? FlareModal : FlareBottomSheet"
    :open="open"
    :title="sideLabel"
    :dismissible="!busy"
    v-bind="fullscreen
      ? { fullscreen: true, titleHidden: true, showClose: false, scrollable: false }
      : { fill: true, maxHeight: '92vh', dialogWidth: 'var(--flare-size-component-capture-preview-width)', showClose: true }"
    @close="cancel"
  >
    <div ref="root" class="flare-doc-capture" :class="{ 'is-fullscreen': fullscreen }" :data-side="side" :aria-busy="busy || undefined">
      <FlareStatusBanner v-if="phase.kind === 'error'" role="alert" tone="danger" :text="t(`documentCapture.${phase.error}`)" data-doc-error="true" />
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
          <div class="flare-doc-capture__mask">
            <div class="flare-doc-capture__frame" :class="{ 'is-portrait': side === 'holding' }" :style="{ aspectRatio: frameRatio }" data-doc-frame="true">
              <template v-if="side === 'holding'">
                <span class="flare-doc-capture__face" aria-hidden="true" />
                <span class="flare-doc-capture__card" aria-hidden="true" />
              </template>
              <template v-else>
                <span v-for="corner in ['ts', 'te', 'bs', 'be']" :key="corner" class="flare-doc-capture__corner" :class="`is-${corner}`" aria-hidden="true" />
              </template>
              <p v-if="phase.kind === 'processing'" class="flare-doc-capture__inside" role="status">
                <span class="flare-doc-capture__spinner" aria-hidden="true" />{{ t("documentCapture.processing") }}
              </p>
              <p v-else-if="cameraUnavailable" class="flare-doc-capture__inside" role="status">
                <FlareIcon name="camera-off" size="xl" />{{ t("documentCapture.cameraUnavailable") }}
              </p>
            </div>
            <p v-if="phase.kind !== 'processing'" class="flare-doc-capture__hint">
              <span>{{ t(`documentCapture.hint.${side}`) }}</span>
              <span class="flare-doc-capture__hint-sub">{{ t("documentCapture.hint.glare") }}</span>
            </p>
          </div>
        </template>
      </div>
      <!-- DOM order puts the main key first (it takes the opening focus); the grid still draws retake | use and
           album | shutter | cancel. -->
      <div v-if="phase.kind === 'review'" class="flare-doc-capture__actions is-review">
        <FlareButton block class="flare-doc-capture__use" :label="t('documentCapture.use')" data-doc-use="true" @click="use" />
        <FlareButton block class="flare-doc-capture__retake" variant="secondary" :label="t('documentCapture.retake')" data-doc-retake="true" @click="reset" />
      </div>
      <div v-else class="flare-doc-capture__actions">
        <button
          v-if="capture && !cameraUnavailable"
          type="button"
          class="flare-doc-capture__shutter"
          :aria-label="t('documentCapture.shoot')"
          :title="fullscreen ? undefined : `${t('documentCapture.shoot')} (Space)`"
          :aria-busy="busy || undefined"
          :disabled="!canShoot"
          data-doc-shoot="true"
          @click="take(capture)"
        />
        <FlareButton
          v-if="pickPhoto"
          class="flare-doc-capture__album"
          variant="quiet"
          :icon="flareIcons.image"
          :label="fullscreen ? t('documentCapture.fromAlbum') : t('pluginFileChoose')"
          :disabled="busy"
          data-doc-album="true"
          @click="take(pickPhoto)"
        />
        <FlareButton class="flare-doc-capture__cancel" variant="quiet" :label="t('common.cancel')" :disabled="busy" @click="cancel" />
      </div>
    </div>
  </component>
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
.flare-doc-capture__mask {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-2xl);
  pointer-events: none;
}
/* The frame: what is outside it is dimmed by its own spread shadow; four white corner marks (3 × 24) draw its edge. */
.flare-doc-capture__frame {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  max-height: 100%;
  min-height: 0;
  border-radius: var(--flare-size-radius-md);
  box-shadow: 0 0 0 9999px var(--flare-color-media-stage-shade);
}
.flare-doc-capture__frame.is-portrait { width: auto; height: 100%; }
.flare-doc-capture__corner {
  position: absolute;
  width: var(--flare-size-spacing-2xl);
  height: var(--flare-size-spacing-2xl);
  border: 0 solid var(--flare-color-media-on-stage);
}
.flare-doc-capture__corner.is-ts { top: 0; inset-inline-start: 0; border-top-width: var(--flare-size-component-capture-frame-stroke); border-inline-start-width: var(--flare-size-component-capture-frame-stroke); border-start-start-radius: var(--flare-size-radius-md); }
.flare-doc-capture__corner.is-te { top: 0; inset-inline-end: 0; border-top-width: var(--flare-size-component-capture-frame-stroke); border-inline-end-width: var(--flare-size-component-capture-frame-stroke); border-start-end-radius: var(--flare-size-radius-md); }
.flare-doc-capture__corner.is-bs { bottom: 0; inset-inline-start: 0; border-bottom-width: var(--flare-size-component-capture-frame-stroke); border-inline-start-width: var(--flare-size-component-capture-frame-stroke); border-end-start-radius: var(--flare-size-radius-md); }
.flare-doc-capture__corner.is-be { bottom: 0; inset-inline-end: 0; border-bottom-width: var(--flare-size-component-capture-frame-stroke); border-inline-end-width: var(--flare-size-component-capture-frame-stroke); border-end-end-radius: var(--flare-size-radius-md); }
/* Holding: the face oval (half the width) above, the ID card (60%) lower at the end side. */
.flare-doc-capture__face {
  position: absolute;
  top: 8%;
  left: 25%;
  width: 50%;
  aspect-ratio: 3 / 4;
  border: 2px dashed var(--flare-color-media-on-stage);
  border-radius: var(--flare-size-radius-full);
}
.flare-doc-capture__card {
  position: absolute;
  bottom: 8%;
  inset-inline-end: 6%;
  width: 60%;
  aspect-ratio: var(--flare-size-component-document-frame-ratio);
  border: 2px solid var(--flare-color-media-on-stage);
  border-radius: var(--flare-size-radius-md);
}
.flare-doc-capture__inside {
  position: relative;
  display: grid;
  justify-items: center;
  gap: var(--flare-size-spacing-sm);
  margin: 0;
  padding: var(--flare-size-spacing-md);
  text-align: center;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-media-on-stage);
}
.flare-doc-capture__spinner {
  width: var(--flare-size-icon-size-xl);
  height: var(--flare-size-icon-size-xl);
  box-sizing: border-box;
  border: 3px solid var(--flare-color-media-on-stage);
  border-inline-end-color: transparent;
  border-radius: var(--flare-size-radius-full);
}
@media (prefers-reduced-motion: no-preference) {
  .flare-doc-capture__spinner { animation: flare-doc-capture-spin 0.8s linear infinite; }
}
@keyframes flare-doc-capture-spin { to { transform: rotate(360deg); } }
.flare-doc-capture__review { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: contain; user-select: none; }
/* The hints sit on the stage under the frame: the side's line, then avoid glare. */
.flare-doc-capture__hint {
  position: relative;
  display: grid;
  gap: var(--flare-size-spacing-xs);
  margin: 0;
  text-align: center;
  font-size: var(--flare-size-font-size-xl);
  color: var(--flare-color-media-on-stage);
}
.flare-doc-capture__hint-sub { font-size: var(--flare-size-font-size-md); opacity: var(--flare-opacity-muted); }
/* Album | shutter | cancel; the review is retake | use, equal widths. Columns are fixed, whatever the DOM order. */
.flare-doc-capture__actions {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  grid-auto-flow: dense;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
}
.flare-doc-capture__album { grid-column: 1; grid-row: 1; justify-self: start; }
.flare-doc-capture__shutter { grid-column: 2; grid-row: 1; }
.flare-doc-capture__cancel { grid-column: 3; grid-row: 1; justify-self: end; }
.flare-doc-capture__actions.is-review { grid-template-columns: 1fr 1fr; }
.flare-doc-capture__retake { grid-column: 1; grid-row: 1; }
.flare-doc-capture__use { grid-column: 2; grid-row: 1; }
/* Phone: the whole screen is the dark media stage, down to the safe areas. */
.flare-doc-capture.is-fullscreen {
  padding: calc(var(--flare-size-spacing-sm) + env(safe-area-inset-top, 0px)) var(--flare-size-spacing-lg) calc(var(--flare-size-spacing-lg) + env(safe-area-inset-bottom, 0px));
  background: var(--flare-color-media-stage);
  color: var(--flare-color-media-on-stage);
}
/* The quiet keys sit on the stage: its ink, and a light tint of it for hover. */
.flare-doc-capture.is-fullscreen .flare-doc-capture__album,
.flare-doc-capture.is-fullscreen .flare-doc-capture__cancel {
  --flare-color-text-primary: var(--flare-color-media-on-stage);
  --flare-color-text-secondary: var(--flare-color-media-on-stage);
  --flare-color-bg-secondary: color-mix(in srgb, var(--flare-color-media-on-stage) calc(var(--flare-opacity-tint-weak) * 100%), transparent);
}
.flare-doc-capture.is-fullscreen .flare-doc-capture__stage { border-radius: 0; margin-inline: calc(var(--flare-size-spacing-lg) * -1); }
/* §6.4: in the PC dialog the camera picture is 16:10. */
.flare-doc-capture:not(.is-fullscreen) .flare-doc-capture__stage { flex: none; aspect-ratio: var(--flare-size-component-capture-preview-ratio); }
/* The shutter: a white disc inside a 4-wide ring, component.captureShutterSize across. */
.flare-doc-capture__shutter {
  width: var(--flare-size-component-capture-shutter-size);
  height: var(--flare-size-component-capture-shutter-size);
  padding: 0;
  border: 4px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-full);
  /* §6.4: the disc is white in both themes (the stage's ink), never the theme's text colour. */
  background: var(--flare-color-media-on-stage);
  box-shadow: inset 0 0 0 3px var(--flare-color-bg-primary);
  cursor: pointer;
}
.flare-doc-capture.is-fullscreen .flare-doc-capture__shutter { border-color: var(--flare-color-media-on-stage); box-shadow: inset 0 0 0 3px var(--flare-color-media-stage); }
.flare-doc-capture__shutter:focus-visible { outline: var(--flare-size-component-focus-ring-width) solid var(--flare-color-border-selected); outline-offset: var(--flare-size-component-focus-ring-offset); }
.flare-doc-capture__shutter:disabled { opacity: var(--flare-opacity-disabled); cursor: not-allowed; }
</style>
