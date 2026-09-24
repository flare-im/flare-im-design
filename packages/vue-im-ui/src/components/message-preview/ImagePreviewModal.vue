<template>
  <Teleport :to="overlayContainer">
    <div
      v-if="show"
      ref="surfaceEl"
      class="image-preview-modal"
      role="dialog"
      aria-modal="true"
      @click.self="requestClose"
    >
      <div class="image-preview-modal__toolbar">
        <div class="image-preview-modal__toolbar-left">
          <button
            type="button"
            class="image-preview-modal__icon-btn"
            :title="t('imagePreviewModal.zoomOut')"
            :aria-label="t('imagePreviewModal.zoomOut')"
            :disabled="!canTransform"
            @click="zoomOut"
          >
            <n-icon aria-hidden="true" :size="20" :component="flareIcons['zoom-out']" />
          </button>
          <span class="image-preview-modal__zoom-label" aria-live="polite">{{ zoomPercentLabel }}</span>
          <button
            type="button"
            class="image-preview-modal__icon-btn"
            :title="t('imagePreviewModal.zoomIn')"
            :aria-label="t('imagePreviewModal.zoomIn')"
            :disabled="!canTransform"
            @click="zoomIn"
          >
            <n-icon aria-hidden="true" :size="20" :component="flareIcons['zoom-in']" />
          </button>
          <button
            type="button"
            class="image-preview-modal__icon-btn image-preview-modal__icon-btn--text"
            :title="t('imagePreviewModal.actualSize')"
            :aria-label="t('imagePreviewModal.actualSize')"
            :disabled="!canTransform"
            @click="actualSize"
          >
            1:1
          </button>
          <button
            type="button"
            class="image-preview-modal__icon-btn"
            :title="t('imagePreviewModal.resetView')"
            :aria-label="t('imagePreviewModal.resetView')"
            :disabled="!canTransform"
            @click="resetView"
          >
            <n-icon aria-hidden="true" :size="20" :component="flareIcons.collapse" />
          </button>
          <button
            type="button"
            class="image-preview-modal__icon-btn"
            :title="t('imagePreviewModal.rotate')"
            :aria-label="t('imagePreviewModal.rotate')"
            :disabled="!canTransform"
            @click="rotateCw"
          >
            <n-icon aria-hidden="true" :size="20" :component="flareIcons.rotate" />
          </button>
        </div>
        <span v-if="pages" class="image-preview-modal__position" role="status" aria-live="polite">
          <span aria-hidden="true">{{ positionText }}</span>
          <span class="image-preview-modal__sr">{{ positionLabel }}</span>
        </span>
        <div class="image-preview-modal__toolbar-right">
          <button
            v-if="primaryActionIcon"
            type="button"
            class="image-preview-modal__icon-btn"
            :disabled="primaryActionDisabled"
            :title="primaryActionTitle"
            :aria-label="primaryActionTitle"
            @click="emitPrimary"
          >
            <n-icon aria-hidden="true" :size="22" :component="primaryActionIcon" />
          </button>
          <button
            type="button"
            class="image-preview-modal__icon-btn"
            :title="t('imagePreviewModal.close')"
            :aria-label="t('imagePreviewModal.close')"
            @click="requestClose"
          >
            <n-icon aria-hidden="true" :size="22" :component="flareIcons.close" />
          </button>
        </div>
      </div>

      <div class="image-preview-modal__body" @click.stop>
        <div v-if="!imageSrc.trim()" class="image-preview-modal__state" :role="loading ? 'status' : 'alert'">{{ loading ? loadingText : errorText }}</div>
        <div v-else class="image-preview-modal__stage" :data-image-state="imageState">
          <div v-if="downloading" class="image-preview-modal__progress" role="status" aria-live="polite">
            <span class="image-preview-modal__progress-label">{{ progressLabel }}</span>
            <div
              class="image-preview-modal__track"
              :class="{ 'is-indeterminate': progressIndeterminate }"
              role="progressbar"
              :aria-valuenow="progressIndeterminate ? undefined : progressPct"
              aria-valuemin="0"
              aria-valuemax="100"
            >
              <div
                class="image-preview-modal__fill"
                :style="progressIndeterminate ? undefined : { width: `${progressPct}%` }"
              />
            </div>
          </div>
          <div
            ref="viewportRef"
            class="image-preview-modal__viewport"
            :class="{ 'is-paging': pages && scale <= 1 }"
            tabindex="0"
            @wheel.prevent="onWheel"
            @pointerdown="onPointerDown"
            @pointerup="onPointerUp"
            @pointercancel="swipeStart = null"
          >
            <div class="image-preview-modal__transform" :style="transformStyle">
              <img
                ref="imageRef"
                :src="imageSrc"
                :alt="alt"
                draggable="false"
                class="image-preview-modal__img"
                :class="{ 'is-ready': imageState === 'ready' }"
                @load="onImageLoad"
                @error="onImageError"
              />
            </div>
          </div>
          <div v-if="loading || imageState === 'loading'" class="image-preview-modal__state image-preview-modal__state--overlay" role="status" aria-live="polite">{{ loadingText }}</div>
          <div v-else-if="imageState === 'error'" class="image-preview-modal__state image-preview-modal__state--overlay" role="alert">
            <span>{{ errorText }}</span>
            <button type="button" class="image-preview-modal__retry" @click="retryImage">{{ retryText }}</button>
          </div>
        </div>
      </div>

      <template v-if="pages">
        <button
          type="button"
          class="image-preview-modal__page image-preview-modal__page--previous"
          :title="t('imagePreviewModal.previous')"
          :aria-label="t('imagePreviewModal.previous')"
          :disabled="!hasPrevious"
          @click.stop="emit('previous')"
        >
          <n-icon aria-hidden="true" :size="24" :component="flareIcons['chevron-left']" />
        </button>
        <button
          type="button"
          class="image-preview-modal__page image-preview-modal__page--next"
          :title="t('imagePreviewModal.next')"
          :aria-label="t('imagePreviewModal.next')"
          :disabled="!hasNext"
          @click.stop="emit('next')"
        >
          <n-icon aria-hidden="true" :size="24" :component="flareIcons['chevron-right']" />
        </button>
      </template>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
// 全屏图片查看器是一张模态面 —— 栈、滚动锁、焦点陷阱、Escape 和平台返回键都来自
// 共用的 `useFlareModalSurface`。以前它自己写 `document.body.style.overflow = ''`,
// 不计数也不还原:从一张面板里点开图片再关掉,面板还开着,背后的页面却又能滚了;
// 而且 Escape 两边各听各的 document,一次按键会连着关两层。
import { computed, nextTick, onBeforeUnmount, ref, watch } from 'vue';
import { useFlareModalSurface } from "../../shared/useModalSurface";
import { NIcon } from 'naive-ui';
import type { Component } from 'vue';
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const { t } = useFlareI18nOptional();
const ZOOM_STEP = 1.15;

const props = withDefaults(
  defineProps<{
    show: boolean;
    imageSrc: string;
    loading?: boolean;
    alt?: string;
    /** 下载 / 在文件夹中显示 */
    primaryActionIcon?: Component;
    primaryActionTitle?: string;
    primaryActionDisabled?: boolean;
    downloading?: boolean;
    progressLabel?: string;
    progressPct?: number;
    progressIndeterminate?: boolean;
    zoomMin?: number;
    zoomMax?: number;
    loadingText?: string;
    errorText?: string;
    retryText?: string;
    /** In a gallery: the position (from 0) of the image on screen, of `galleryCount`. */
    galleryIndex?: number;
    galleryCount?: number;
  }>(),
  {
    loading: false,
    alt: '',
    primaryActionTitle: '',
    primaryActionDisabled: false,
    downloading: false,
    progressLabel: '',
    progressPct: 0,
    progressIndeterminate: false,
    zoomMin: 0.1,
    zoomMax: 8,
    loadingText: 'Loading…',
    errorText: "Can't display image",
    retryText: 'Retry',
  },
);

const emit = defineEmits<{
  'update:show': [value: boolean];
  'primary-action': [];
  retry: [];
  /** In a gallery: show the image before / after this one. */
  previous: [];
  next: [];
}>();

/** A sideways swipe at least this long pages the gallery. */
const SWIPE_PAGE_PX = 60;

const scale = ref(1);
const rotateDeg = ref(0);
const viewportRef = ref<HTMLElement | null>(null);
const surfaceEl = ref<HTMLElement | null>(null);
const imageRef = ref<HTMLImageElement | null>(null);
const imageState = ref<'loading' | 'ready' | 'error'>('loading');

const canTransform = computed(
  () => props.show && !props.loading && imageState.value === 'ready' && Boolean(props.imageSrc.trim()),
);

const zoomPercentLabel = computed(() => `${Math.round(scale.value * 100)}%`);

// A gallery pages with the side keys, the arrow keys and a sideways swipe; a single image shows none of it.
const pages = computed(() => props.galleryIndex != null && (props.galleryCount ?? 0) > 1);
const hasPrevious = computed(() => pages.value && props.galleryIndex! > 0);
const hasNext = computed(() => pages.value && props.galleryIndex! < props.galleryCount! - 1);
const positionText = computed(() => `${(props.galleryIndex ?? 0) + 1} / ${props.galleryCount ?? 0}`);
const positionLabel = computed(() =>
  t('imagePreviewModal.position', { index: (props.galleryIndex ?? 0) + 1, count: props.galleryCount ?? 0 }),
);
const swipeStart = ref<{ x: number; y: number } | null>(null);

function onPointerDown(e: PointerEvent) {
  swipeStart.value = pages.value && scale.value <= 1 ? { x: e.clientX, y: e.clientY } : null;
}

function onPointerUp(e: PointerEvent) {
  const start = swipeStart.value;
  swipeStart.value = null;
  if (!start || !pages.value || scale.value > 1) return;
  const dx = e.clientX - start.x;
  const dy = e.clientY - start.y;
  if (Math.abs(dx) < SWIPE_PAGE_PX || Math.abs(dx) <= Math.abs(dy)) return;
  if (dx < 0 && hasNext.value) emit('next');
  else if (dx > 0 && hasPrevious.value) emit('previous');
}

const transformStyle = computed(() => ({
  transform: `rotate(${rotateDeg.value}deg) scale(${scale.value})`,
  transformOrigin: 'center center',
}));

function clampScale(v: number): number {
  const lo = props.zoomMin;
  const hi = props.zoomMax;
  return Math.min(hi, Math.max(lo, v));
}

function zoomIn() {
  scale.value = clampScale(scale.value * ZOOM_STEP);
}

function zoomOut() {
  scale.value = clampScale(scale.value / ZOOM_STEP);
}

function actualSize() {
  scale.value = 1;
}

function resetView() {
  scale.value = 1;
  rotateDeg.value = 0;
  viewportRef.value?.scrollTo({ left: 0, top: 0 });
}

function rotateCw() {
  rotateDeg.value = (rotateDeg.value + 90) % 360;
}

function onWheel(e: WheelEvent) {
  if (!canTransform.value) return;
  const delta = e.deltaY;
  if (delta > 0) {
    scale.value = clampScale(scale.value / ZOOM_STEP ** 0.35);
  } else if (delta < 0) {
    scale.value = clampScale(scale.value * ZOOM_STEP ** 0.35);
  }
}

function requestClose() {
  emit('update:show', false);
}

// autoFocus 关掉:焦点要落在可滚的图片视口上,放大之后方向键才推得动它。
// 共用实现默认送到第一个可聚焦元素(工具栏第一颗按钮),那样方向键就不滚图了。
const { overlayContainer } = useFlareModalSurface({
  open: () => props.show,
  surface: surfaceEl,
  autoFocus: false,
  onRequestClose: requestClose,
  onKeydown: (event) => onPreviewKeydown(event),
});

function onImageLoad() {
  imageState.value = imageRef.value?.naturalWidth ? 'ready' : 'error';
}

function onImageError() {
  imageState.value = 'error';
}

function retryImage() {
  imageState.value = 'loading';
  emit('retry');
  const image = imageRef.value;
  if (!image) return;
  const source = image.src;
  image.removeAttribute('src');
  requestAnimationFrame(() => image.setAttribute('src', source));
}

function emitPrimary() {
  emit('primary-action');
}

// 只在这张面处于栈顶时被调用;Escape 与 Tab 已经由共用实现收掉。
function onPreviewKeydown(e: KeyboardEvent) {
  // The arrow keys page while the image is not zoomed in; zoomed in, they move around it.
  if ((e.key === 'ArrowLeft' || e.key === 'ArrowRight') && pages.value && scale.value <= 1) {
    const forward = e.key === 'ArrowRight';
    if (forward && hasNext.value) {
      e.preventDefault();
      emit('next');
    } else if (!forward && hasPrevious.value) {
      e.preventDefault();
      emit('previous');
    }
    return;
  }
  if (!canTransform.value) return;
  if (e.key === '+' || e.key === '=') {
    e.preventDefault();
    zoomIn();
  } else if (e.key === '-' || e.key === '_') {
    e.preventDefault();
    zoomOut();
  } else   if (e.key === '0' && (e.metaKey || e.ctrlKey)) {
    e.preventDefault();
    actualSize();
  }
}

function syncVisualViewport() {
  if (typeof document === 'undefined') return;
  const viewport = window.visualViewport;
  const height = viewport?.height ?? window.innerHeight;
  document.documentElement.style.setProperty('--flare-image-preview-viewport-height', `${Math.max(0, height)}px`);
}

function listenVisualViewport() {
  syncVisualViewport();
  window.visualViewport?.addEventListener('resize', syncVisualViewport);
  window.visualViewport?.addEventListener('scroll', syncVisualViewport);
  window.addEventListener('orientationchange', syncVisualViewport);
}

function unlistenVisualViewport() {
  window.visualViewport?.removeEventListener('resize', syncVisualViewport);
  window.visualViewport?.removeEventListener('scroll', syncVisualViewport);
  window.removeEventListener('orientationchange', syncVisualViewport);
}

watch(
  () => props.show,
  (open) => {
    if (typeof document === 'undefined') return;
    if (open) {
      imageState.value = 'loading';
      listenVisualViewport();
      void nextTick(() => viewportRef.value?.focus());
    } else {
      unlistenVisualViewport();
    }
  },
);

watch(
  () => props.imageSrc,
  () => {
    imageState.value = 'loading';
    scale.value = 1;
    rotateDeg.value = 0;
    viewportRef.value?.scrollTo({ left: 0, top: 0 });
  },
);

onBeforeUnmount(() => {
  if (typeof document === 'undefined') return;
  unlistenVisualViewport();
  document.documentElement.style.removeProperty('--flare-image-preview-viewport-height');
});
</script>

<style scoped>
:global(:root) {
  --flare-image-preview-viewport-height: 100dvh;
}

.image-preview-modal {
  position: fixed;
  inset: 0;
  height: var(--flare-image-preview-viewport-height);
  max-height: var(--flare-image-preview-viewport-height);
  z-index: var(--flare-z-index-media);
  display: flex;
  flex-direction: column;
  background: rgba(0, 0, 0, 0.85);
  padding: calc(52px + env(safe-area-inset-top, 0px)) max(var(--flare-size-spacing-lg), env(safe-area-inset-right, 0px)) max(var(--flare-size-spacing-xl), env(safe-area-inset-bottom, 0px)) max(var(--flare-size-spacing-lg), env(safe-area-inset-left, 0px));
  box-sizing: border-box;
}

.image-preview-modal__toolbar {
  position: absolute;
  top: max(var(--flare-size-spacing-2sm), env(safe-area-inset-top, 0px));
  left: max(var(--flare-size-spacing-md), env(safe-area-inset-left, 0px));
  right: max(var(--flare-size-spacing-md), env(safe-area-inset-right, 0px));
  z-index: 3;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-md);
  flex-wrap: wrap;
  pointer-events: none;
}

.image-preview-modal__toolbar-left,
.image-preview-modal__toolbar-right {
  display: flex;
  align-items: center;
  gap: 2px;
  pointer-events: auto;
}

.image-preview-modal__position {
  font-size: var(--flare-size-font-size-md);
  font-variant-numeric: tabular-nums;
  color: rgba(255, 255, 255, 0.92);
  user-select: none;
  pointer-events: auto;
}

.image-preview-modal__sr {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  padding: 0;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

.image-preview-modal__page {
  position: absolute;
  top: 50%;
  z-index: 3;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: var(--flare-size-layout-touch-target);
  height: var(--flare-size-layout-touch-target);
  margin-top: calc(var(--flare-size-layout-touch-target) / -2);
  padding: 0;
  border: none;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.45);
  color: rgba(255, 255, 255, 0.95);
  cursor: pointer;
  transition: background 0.15s ease;
}

.image-preview-modal__page--previous {
  left: max(var(--flare-size-spacing-md), env(safe-area-inset-left, 0px));
}

.image-preview-modal__page--next {
  right: max(var(--flare-size-spacing-md), env(safe-area-inset-right, 0px));
}

.image-preview-modal__page:hover:not(:disabled) {
  background: rgba(0, 0, 0, 0.65);
}

.image-preview-modal__page:disabled {
  opacity: 0.35;
  cursor: not-allowed;
}

.image-preview-modal__page:focus-visible {
  outline: 2px solid white;
  outline-offset: 2px;
}

.image-preview-modal__zoom-label {
  min-width: 3rem;
  text-align: center;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
  color: rgba(255, 255, 255, 0.88);
  user-select: none;
}

.image-preview-modal__icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 36px;
  min-height: 36px;
  padding: var(--flare-size-spacing-2xs);
  border: none;
  border-radius: var(--flare-size-radius-md);
  background: transparent;
  color: rgba(255, 255, 255, 0.92);
  cursor: pointer;
  transition: background 0.15s ease;
}

.image-preview-modal__icon-btn--text {
  font-size: var(--flare-size-font-size-sm);
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  letter-spacing: 0;
}

.image-preview-modal__icon-btn:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.12);
}

.image-preview-modal__icon-btn:disabled {
  opacity: 0.35;
  cursor: not-allowed;
}

.image-preview-modal__body {
  flex: 1;
  min-height: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.image-preview-modal__state {
  color: rgba(255, 255, 255, 0.9);
  font-size: var(--flare-size-font-size-lg);
  padding: var(--flare-size-spacing-2xl);
}

.image-preview-modal__state--overlay {
  position: absolute;
  inset: 0;
  z-index: 2;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--flare-size-spacing-md);
  pointer-events: none;
}

.image-preview-modal__retry {
  min-width: var(--flare-size-layout-touch-target);
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg);
  border: 1px solid rgba(255, 255, 255, 0.72);
  border-radius: var(--flare-size-radius-md);
  color: rgba(255, 255, 255, 0.96);
  background: rgba(0, 0, 0, 0.48);
  cursor: pointer;
  pointer-events: auto;
}

.image-preview-modal__retry:focus-visible {
  outline: 2px solid white;
  outline-offset: 2px;
}

.image-preview-modal__stage {
  position: relative;
  width: 100%;
  height: 100%;
  min-height: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.image-preview-modal__progress {
  position: absolute;
  top: 8px;
  right: 8px;
  z-index: 2;
  width: min(200px, calc(100% - 24px));
  padding: 8px var(--flare-size-spacing-2sm);
  border-radius: 10px;
  background: rgba(0, 0, 0, 0.55);
  backdrop-filter: blur(6px);
  pointer-events: none;
  box-sizing: border-box;
}

.image-preview-modal__progress-label {
  display: block;
  font-size: 11px;
  line-height: 1.3;
  color: rgba(255, 255, 255, 0.92);
  font-variant-numeric: tabular-nums;
  margin-bottom: 6px;
}

.image-preview-modal__track {
  width: 100%;
  height: 4px;
  border-radius: 2px;
  background: rgba(255, 255, 255, 0.2);
  overflow: hidden;
}

.image-preview-modal__fill {
  height: 100%;
  border-radius: 2px;
  background: rgba(126, 184, 255, 0.95);
  transition: width 0.12s ease-out;
}

.image-preview-modal__track.is-indeterminate .image-preview-modal__fill {
  width: 40% !important;
  animation: image-preview-indeterminate 1s ease-in-out infinite;
}

@keyframes image-preview-indeterminate {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(350%);
  }
}

.image-preview-modal__viewport {
  overflow: auto;
  max-width: 100%;
  max-height: 100%;
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  outline: none;
  overscroll-behavior: contain;
  touch-action: pan-x pan-y pinch-zoom;
}

.image-preview-modal__viewport:focus-visible { outline: 2px solid white; outline-offset: -2px; }

/* Paging: a sideways swipe belongs to the gallery, not to the browser's panning. */
.image-preview-modal__viewport.is-paging {
  touch-action: pan-y pinch-zoom;
}

.image-preview-modal__transform {
  flex-shrink: 0;
}

.image-preview-modal__img {
  display: block;
  max-width: calc(100vw - var(--flare-size-spacing-2xl) - var(--flare-size-spacing-sm) - env(safe-area-inset-left, 0px) - env(safe-area-inset-right, 0px));
  max-height: calc(var(--flare-image-preview-viewport-height) - 96px - env(safe-area-inset-top, 0px) - env(safe-area-inset-bottom, 0px));
  width: auto;
  height: auto;
  object-fit: contain;
  border-radius: 4px;
  vertical-align: top;
  user-select: none;
  opacity: 0;
}

.image-preview-modal__img.is-ready {
  opacity: 1;
}

@media (prefers-reduced-motion: reduce) {
  .image-preview-modal__icon-btn,
  .image-preview-modal__page,
  .image-preview-modal__fill { transition: none; }
  .image-preview-modal__track.is-indeterminate .image-preview-modal__fill { animation: none; transform: none; }
}
</style>
