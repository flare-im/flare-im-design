<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import FrozenStickerThumb from "../../composer/FrozenStickerThumb/index.vue";

type AssetUrlLoader = () => Promise<string | undefined>;

// Presentational sticker body. Contract props: `emoji` (glyph fallback) and `src`.
// Vue-only additions used by the timeline dispatcher: `loadSrc` (async asset resolver),
// `animated` (play instead of showing the frozen first frame) and `fallbackText`.
const props = withDefaults(
  defineProps<{
    emoji?: string;
    src?: string;
    loadSrc?: AssetUrlLoader;
    animated?: boolean;
    fallbackText?: string;
    alt?: string;
  }>(),
  { emoji: "🐱", src: "", animated: false, fallbackText: "", alt: "" },
);
const emit = defineEmits<{ (e: "click"): void }>();
const instance = getCurrentInstance();
// Only a body the host listens to is a button; a sticker in the timeline is plain content.
const interactive = computed(() => Boolean(instance?.vnode.props?.onClick));
const hasImage = computed(() => Boolean(props.src || props.loadSrc));
</script>
<template>
  <component :is="interactive ? 'button' : 'div'" class="fm-sticker" :type="interactive ? 'button' : undefined" @click="interactive && emit('click')">
    <img v-if="hasImage && animated && src" :src="src" :alt="alt" loading="lazy" decoding="async" />
    <FrozenStickerThumb v-else-if="hasImage" class="fm-sticker__thumb" :src="src" :load-src="loadSrc" :alt="alt" object-fit="contain" />
    <span v-else-if="fallbackText" class="fm-sticker__fallback">{{ fallbackText }}</span>
    <span v-else>{{ emoji }}</span>
  </component>
</template>
<style scoped>
.fm-sticker { display: inline-flex; justify-content: center; border: none; background: none; padding: 0; font-size: 72px; line-height: 1; color: inherit; }
button.fm-sticker { cursor: pointer; }
.fm-sticker img, .fm-sticker__thumb { width: min(8em, 180px); height: min(8em, 180px); max-width: min(8em, 180px); max-height: min(8em, 180px); font-size: var(--flare-size-font-size-lg); object-fit: contain; }
.fm-sticker__fallback { display: inline-flex; max-width: min(220px, 100%); min-width: 0; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-xl); line-height: 1.35; overflow-wrap: anywhere; text-align: center; }
</style>
