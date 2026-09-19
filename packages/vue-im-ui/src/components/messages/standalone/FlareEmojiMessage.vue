<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import FrozenStickerThumb from "../../composer/FrozenStickerThumb/index.vue";

type AssetUrlLoader = () => Promise<string | undefined>;

// Presentational large-emoji body. Contract prop: `emoji` (a unicode glyph).
// Vue-only additions used by the timeline dispatcher for emoji-pack assets: `loadSrc`
// (async asset resolver) and `fallbackText` (bracket form when the pack key is unknown).
const props = withDefaults(
  defineProps<{ emoji?: string; loadSrc?: AssetUrlLoader; fallbackText?: string; alt?: string }>(),
  { emoji: "🎉", fallbackText: "", alt: "" },
);
const emit = defineEmits<{ (e: "click"): void }>();
const instance = getCurrentInstance();
const interactive = computed(() => Boolean(instance?.vnode.props?.onClick));
</script>
<template>
  <component :is="interactive ? 'button' : 'div'" class="fm-emoji" :type="interactive ? 'button' : undefined" @click="interactive && emit('click')">
    <FrozenStickerThumb v-if="loadSrc" class="fm-emoji__thumb" :load-src="loadSrc" :alt="alt" object-fit="contain" />
    <span v-else-if="fallbackText" class="fm-emoji__fallback">{{ fallbackText }}</span>
    <span v-else>{{ emoji }}</span>
  </component>
</template>
<style scoped>
.fm-emoji { display: inline-flex; justify-content: center; border: none; background: none; padding: 0; font-size: 40px; line-height: 1; color: inherit; }
button.fm-emoji { cursor: pointer; }
.fm-emoji__thumb { width: min(5.5em, 120px); height: min(5.5em, 120px); font-size: var(--flare-size-font-size-lg); }
.fm-emoji__fallback { display: inline-flex; max-width: 100%; min-width: 0; overflow-wrap: anywhere; font-size: var(--flare-size-font-size-3xl); color: var(--flare-color-text-secondary); line-height: 1.35; text-align: center; }
</style>
