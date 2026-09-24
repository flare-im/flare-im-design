<script setup lang="ts">
import { computed, ref, watch } from "vue";
import MsgIcon from "./MsgIcon.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";

// Presentational — emits `play`; the host opens the player. The fixed 148 × 92
// thumbnail is the default; give `maxWidth` / `maxHeight` to size the poster
// within bounds (how the timeline dispatcher renders it). `loading` is the
// host still producing a poster; `disabled` means nothing is playable yet.
const props = withDefaults(
  defineProps<{
    poster?: string;
    duration?: string;
    alt?: string;
    maxWidth?: number | string;
    maxHeight?: number | string;
    loading?: boolean;
    disabled?: boolean;
  }>(),
  { poster: "", duration: "00:00", alt: "", loading: false, disabled: false },
);
const emit = defineEmits<{ (e: "play"): void }>();
const { t } = useFlareI18nOptional();

const posterFailed = ref(false);
watch(
  () => props.poster,
  () => {
    posterFailed.value = false;
  },
);

const flexible = computed(() => props.maxWidth != null || props.maxHeight != null);
const css = (value: number | string | undefined) => (typeof value === "number" ? `${value}px` : value);
const sizeStyle = computed(() =>
  flexible.value
    ? { "--fm-video-max-w": css(props.maxWidth) ?? "100%", "--fm-video-max-h": css(props.maxHeight) ?? "none" }
    : undefined,
);
const showPoster = computed(() => Boolean(props.poster) && !posterFailed.value);
const placeholderText = computed(() => {
  if (props.loading) return t("mediaMessage.generatingCover");
  if (posterFailed.value) return t("mediaMessage.coverFailed");
  return "";
});
const label = computed(() => {
  const parts = [props.alt || t("mediaMessage.video"), props.duration, placeholderText.value];
  return parts.filter(Boolean).join(", ");
});
</script>
<template>
  <button
    type="button"
    class="fm-video"
    :class="{ 'fm-video--flex': flexible }"
    :style="sizeStyle"
    :disabled="disabled"
    :aria-label="label"
    @click="emit('play')"
  >
    <img v-if="showPoster" :src="poster" :alt="alt" loading="lazy" decoding="async" @error="posterFailed = true" />
    <span v-else class="ph">
      <MsgIcon name="video" :size="24" />
      <small v-if="placeholderText">{{ placeholderText }}</small>
    </span>
    <span class="play"><MsgIcon name="play" :size="30" /></span>
    <span v-if="duration" class="dur">{{ duration }}</span>
  </button>
</template>
<style scoped>
.fm-video { padding: 0; border: none; position: relative; width: 148px; height: 92px; border-radius: var(--flare-size-radius-card); overflow: hidden; background: var(--flare-color-bg-tertiary); display: grid; place-items: center; cursor: pointer; }
.fm-video img { display: block; width: 100%; height: 100%; object-fit: cover; }
.fm-video:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.fm-video:disabled { cursor: default; }
.fm-video:disabled .play { opacity: 0.35; }
.fm-video--flex { width: var(--fm-video-max-w); max-width: 100%; height: auto; min-height: 132px; }
.fm-video--flex img { height: auto; min-height: 132px; max-height: var(--fm-video-max-h); }
.fm-video--flex .ph { width: 100%; min-height: 132px; }
.ph { display: grid; place-items: center; gap: var(--flare-size-spacing-2xs); color: var(--flare-color-text-secondary); }
.ph svg { opacity: 0.5; color: var(--flare-color-text-tertiary); }
.ph small { font-size: var(--flare-size-font-size-xs); color: var(--flare-color-text-tertiary); text-align: center; }
.play { position: absolute; inset: 0; display: grid; place-items: center; color: #fff; background: rgba(0,0,0,.28); }
.dur { position: absolute; right: 6px; bottom: 5px; font-size: var(--flare-size-font-size-2xs); color: #fff; background: rgba(0,0,0,.45); padding: 1px 5px; border-radius: 5px; font-variant-numeric: tabular-nums; }
</style>
