<script setup lang="ts">
import { computed, ref, watch } from "vue";
import MsgIcon from "./MsgIcon.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";

// Presentational — emits `click`; the host opens the full-size viewer. A fixed
// `width` × `height` crops the thumbnail; give `maxWidth` / `maxHeight` instead
// to size within bounds preserving aspect (how the timeline dispatcher renders
// it). A failed load shows a placeholder and the next tap retries the load
// instead of emitting `click`.
const props = withDefaults(
  defineProps<{
    src?: string;
    width?: number;
    height?: number;
    maxWidth?: number | string;
    maxHeight?: number | string;
    alt?: string;
    badge?: string;
    loading?: boolean;
  }>(),
  { src: "", width: 132, height: 92, alt: "", badge: "", loading: false },
);
const emit = defineEmits<{ (e: "click"): void }>();
const { t } = useFlareI18nOptional();

const failed = ref(false);
const retryKey = ref(0);
watch(
  () => props.src,
  () => {
    failed.value = false;
    retryKey.value = 0;
  },
);

const flexible = computed(() => props.maxWidth != null || props.maxHeight != null);
const css = (value: number | string | undefined) => (typeof value === "number" ? `${value}px` : value);
const sizeStyle = computed(() =>
  flexible.value
    ? { "--fm-img-max-w": css(props.maxWidth) ?? "100%", "--fm-img-max-h": css(props.maxHeight) ?? "none" }
    : { width: `${props.width}px`, height: `${props.height}px` },
);
const showImage = computed(() => Boolean(props.src) && !failed.value);
const placeholderText = computed(() => {
  if (props.loading) return t("mediaMessage.loading");
  if (failed.value) return `${t("mediaMessage.imageFailed")} · ${t("mediaMessage.tapToRetry")}`;
  return "";
});
const label = computed(() => {
  const base = props.alt || t("mediaMessage.image");
  return placeholderText.value ? `${base}, ${placeholderText.value}` : base;
});

function onClick(): void {
  if (failed.value) {
    failed.value = false;
    retryKey.value += 1;
    return;
  }
  emit("click");
}
</script>
<template>
  <button
    type="button"
    class="fm-img"
    :class="{ 'fm-img--flex': flexible, 'fm-img--failed': failed }"
    :style="sizeStyle"
    :aria-label="label"
    @click="onClick"
  >
    <img
      v-if="showImage"
      :key="`${src}:${retryKey}`"
      :src="src"
      :alt="alt"
      loading="lazy"
      decoding="async"
      @error="failed = true"
    />
    <span v-else class="ph">
      <MsgIcon name="image" :size="26" />
      <small v-if="placeholderText">{{ placeholderText }}</small>
    </span>
    <span v-if="badge && showImage" class="badge">{{ badge }}</span>
  </button>
</template>
<style scoped>
.fm-img { position: relative; padding: 0; border: none; border-radius: 12px; overflow: hidden; background: var(--flare-color-bg-tertiary); display: grid; place-items: center; color: var(--flare-color-text-tertiary); cursor: pointer; }
.fm-img img { display: block; width: 100%; height: 100%; object-fit: cover; }
.fm-img:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.fm-img--flex { width: auto; height: auto; min-width: min(220px, 100%); min-height: 132px; max-width: min(var(--fm-img-max-w), 100%); }
.fm-img--flex img { width: auto; height: auto; min-height: 132px; max-width: 100%; max-height: var(--fm-img-max-h); object-fit: contain; }
.ph { display: grid; place-items: center; gap: var(--flare-size-spacing-2xs); padding: var(--flare-size-spacing-md); color: var(--flare-color-text-secondary); }
.ph small { font-size: var(--flare-size-font-size-xs); color: var(--flare-color-text-tertiary); text-align: center; }
.badge { position: absolute; right: var(--flare-size-spacing-sm); bottom: var(--flare-size-spacing-sm); padding: 2px var(--flare-size-spacing-2xs); border-radius: var(--flare-size-radius-sm); background: rgba(0, 0, 0, 0.55); color: #fff; font-size: var(--flare-size-font-size-xs); line-height: 1.3; }
</style>
