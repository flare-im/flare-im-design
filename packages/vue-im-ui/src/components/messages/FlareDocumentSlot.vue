<script setup lang="ts">
// 证件拍摄位 —— 「核对并提交」页上一张证件照片的拍摄卡（docs/plugin-experience.md §6.3）：空框画证件示意线框、
// 已拍铺满照片可重拍、上传中画进度环、失败可重试。它就是 document 输入的 native 动作入口：点按发出 capture /
// retry，拍摄与上传都归宿主。
import { computed } from "vue";
import FlareIcon from "../general/FlareIcon.vue";
import { useFlareI18nOptional, useFlareLocaleOptional } from "../../shared/i18n/useFlareI18n";
import type { FlareDocumentSide } from "../../shared/contracts/capability-ui";

const props = withDefaults(
  defineProps<{
    /** The slot's name (证件正面 / 证件反面 / 本人手持证件). */
    label: string;
    /** Which outline the empty slot draws. */
    side: FlareDocumentSide;
    state?: "empty" | "captured" | "uploading" | "failed";
    /** The captured photo (blob:, data:image or https:), drawn cover. */
    imageUrl?: string;
    /** Upload progress 0–100 while uploading. */
    progress?: number;
    /** Not tappable (the form is submitting). */
    disabled?: boolean;
  }>(),
  { state: "empty", disabled: false },
);
const emit = defineEmits<{ (e: "capture"): void; (e: "retry"): void }>();
const { t } = useFlareI18nOptional();
const locale = useFlareLocaleOptional();
const zh = computed(() => locale.value.startsWith("zh"));
const percent = computed(() => Math.round(Math.min(100, Math.max(0, props.progress ?? 0))));
const caption = computed(() => {
  if (props.state === "captured") return t("documentCapture.retake");
  if (props.state === "uploading") return t("documentSlot.uploading", { percent: percent.value });
  if (props.state === "failed") return t("documentSlot.uploadFailed");
  return t("documentSlot.tapToCapture");
});
// "证件正面，已拍摄，点按重拍": the slot is one button, read as label, state, then what a tap does.
const accessibleName = computed(() => {
  const parts = [props.label];
  if (props.state === "captured") parts.push(t("documentSlot.captured"), t("documentSlot.tapToRetake"));
  else parts.push(caption.value);
  return parts.join(zh.value ? "，" : ", ");
});
const inert = computed(() => props.disabled || props.state === "uploading");
function tap(): void {
  if (inert.value) return;
  if (props.state === "failed") emit("retry");
  else emit("capture");
}
</script>

<template>
  <button
    type="button"
    class="flare-doc-slot"
    :class="[`is-${state}`, `is-${side}`]"
    :disabled="inert"
    :aria-label="accessibleName"
    :aria-busy="state === 'uploading' || undefined"
    :data-slot-state="state"
    @click="tap"
  >
    <img v-if="imageUrl && state !== 'empty'" class="flare-doc-slot__photo" :src="imageUrl" alt="" draggable="false" />
    <template v-if="state === 'empty' || (state === 'failed' && !imageUrl)">
      <!-- The ID outline behind the words: portrait box at the end (front), emblem at the start (back), person + card (holding). -->
      <span class="flare-doc-slot__sketch" aria-hidden="true"><span class="flare-doc-slot__mark" /><span v-if="side === 'holding'" class="flare-doc-slot__card" /></span>
    </template>
    <span v-if="state === 'empty'" class="flare-doc-slot__center" aria-hidden="true">
      <FlareIcon name="camera" size="lg" />
      <span class="flare-doc-slot__label">{{ label }}</span>
      <span class="flare-doc-slot__caption">{{ caption }}</span>
    </span>
    <template v-else-if="state === 'captured'">
      <span class="flare-doc-slot__badge" aria-hidden="true"><FlareIcon name="success" size="md" /></span>
      <span class="flare-doc-slot__strip" aria-hidden="true"><FlareIcon name="refresh" size="sm" />{{ caption }}</span>
    </template>
    <span v-else-if="state === 'uploading'" class="flare-doc-slot__center is-on-photo" aria-hidden="true">
      <svg class="flare-doc-slot__ring" viewBox="0 0 36 36">
        <circle class="flare-doc-slot__track" cx="18" cy="18" r="16" />
        <circle class="flare-doc-slot__value" cx="18" cy="18" r="16" pathLength="100" :stroke-dasharray="`${percent} 100`" />
      </svg>
      <span class="flare-doc-slot__caption">{{ caption }}</span>
    </span>
    <span v-else class="flare-doc-slot__center" :class="{ 'is-on-photo': imageUrl }" aria-hidden="true">
      <FlareIcon name="error" size="lg" />
      <span class="flare-doc-slot__label">{{ label }}</span>
      <span class="flare-doc-slot__caption">{{ caption }}</span>
    </span>
  </button>
</template>

<style scoped>
.flare-doc-slot {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  aspect-ratio: 16 / 10;
  min-height: var(--flare-size-component-document-slot-height);
  padding: var(--flare-size-spacing-sm);
  overflow: hidden;
  box-sizing: border-box;
  border: 1.5px dashed var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font: inherit;
  text-align: center;
  cursor: pointer;
}
.flare-doc-slot:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-doc-slot:disabled { cursor: not-allowed; }
.flare-doc-slot.is-empty:disabled { opacity: var(--flare-opacity-disabled); }
.flare-doc-slot.is-captured,
.flare-doc-slot.is-uploading { border-style: solid; border-color: var(--flare-color-border-secondary); }
.flare-doc-slot.is-failed { border-style: solid; border-color: var(--flare-color-error); }
.flare-doc-slot__photo { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; user-select: none; }
/* A faint ID outline, centred, under the camera and the words. */
.flare-doc-slot__sketch {
  position: absolute;
  inset: var(--flare-size-spacing-md) var(--flare-size-spacing-lg);
  border: 1.5px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-md);
  opacity: var(--flare-opacity-muted);
}
.flare-doc-slot__mark {
  position: absolute;
  top: 50%;
  width: 22%;
  aspect-ratio: 3 / 4;
  transform: translateY(-50%);
  border: 1.5px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-sm);
}
.is-front .flare-doc-slot__mark { inset-inline-end: var(--flare-size-spacing-md); }
.is-back .flare-doc-slot__mark { inset-inline-start: var(--flare-size-spacing-md); aspect-ratio: 1; border-radius: var(--flare-size-radius-full); }
/* Holding: a person (head and shoulders) at the start, the card at the end. */
.is-holding .flare-doc-slot__mark { inset-inline-start: var(--flare-size-spacing-md); width: 18%; aspect-ratio: 1; top: 30%; border-radius: var(--flare-size-radius-full); }
.is-holding .flare-doc-slot__mark::after {
  content: "";
  position: absolute;
  top: 110%;
  left: -40%;
  width: 180%;
  height: 120%;
  border: 1.5px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-full) var(--flare-size-radius-full) 0 0;
}
.flare-doc-slot__card {
  position: absolute;
  bottom: var(--flare-size-spacing-md);
  inset-inline-end: var(--flare-size-spacing-md);
  width: 34%;
  aspect-ratio: var(--flare-size-component-document-frame-ratio);
  border: 1.5px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-sm);
}
.flare-doc-slot__center {
  position: relative;
  display: grid;
  justify-items: center;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
  color: var(--flare-color-text-secondary);
}
.flare-doc-slot.is-failed .flare-doc-slot__center { color: var(--flare-color-error-text); }
.flare-doc-slot__center.is-on-photo {
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-media-stage-shade);
  color: var(--flare-color-media-on-stage);
}
.flare-doc-slot__label {
  font-size: var(--flare-size-font-size-lg);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
}
.flare-doc-slot__center.is-on-photo .flare-doc-slot__label { color: inherit; }
.flare-doc-slot__caption { font-size: var(--flare-size-font-size-sm); font-variant-numeric: tabular-nums; }
.flare-doc-slot__badge {
  position: absolute;
  top: var(--flare-size-spacing-sm);
  inset-inline-end: var(--flare-size-spacing-sm);
  display: inline-flex;
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-success-text);
}
.flare-doc-slot__strip {
  position: absolute;
  inset-inline: 0;
  bottom: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--flare-size-spacing-xs);
  padding: var(--flare-size-spacing-lg) var(--flare-size-spacing-sm) var(--flare-size-spacing-sm);
  background: linear-gradient(transparent, var(--flare-color-media-stage-shade));
  color: var(--flare-color-media-on-stage);
  font-size: var(--flare-size-font-size-sm);
}
.flare-doc-slot__ring { width: var(--flare-size-icon-size-xl); height: var(--flare-size-icon-size-xl); transform: rotate(-90deg); }
.flare-doc-slot__ring circle { fill: none; stroke-width: 3; }
.flare-doc-slot__track { stroke: var(--flare-color-media-on-stage); opacity: var(--flare-opacity-muted); }
.flare-doc-slot__value { stroke: var(--flare-color-media-on-stage); stroke-linecap: round; }
@media (prefers-reduced-motion: no-preference) {
  .flare-doc-slot__value { transition: stroke-dasharray var(--flare-transition-normal); }
}
</style>
