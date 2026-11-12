<script setup lang="ts">
import { onBeforeUnmount, ref, watch } from "vue";
import FlareIcon from "../../../general/FlareIcon.vue";
import { useFlareI18nOptional } from "../../../../shared/i18n/useFlareI18n";
import {
  flarePluginImageRatio,
  flarePluginProtectedMediaSource,
  type FlarePluginImageBlock,
  type FlarePluginImageSource,
} from "../../../../shared/contracts/plugin-ui";

// A picture (vocabulary 2) at its declared aspect. The view holds no address: a package asset path or the id of a
// file the plugin uploaded privately, which the host's `resolve` turns into what it fetched (blob:, https:,
// data:image, or a Tauri host's asset:// / http://asset.localhost file address only). Until then, or when the host has nothing, the frame keeps its size and says so.
const props = defineProps<{
  block: FlarePluginImageBlock;
  resolve?: (source: FlarePluginImageSource) => string | undefined | Promise<string | undefined>;
}>();
const { t } = useFlareI18nOptional();
const url = ref<string>();
const failed = ref(false);
let alive = true;
let request = 0;
onBeforeUnmount(() => {
  alive = false;
});
watch(
  () => [props.block.asset, props.block.fileId, Boolean(props.resolve)] as const,
  () => {
    const current = ++request;
    url.value = undefined;
    failed.value = false;
    const source: FlarePluginImageSource = props.block.asset ? { asset: props.block.asset } : { fileId: props.block.fileId };
    if (!props.resolve || (!source.asset && !source.fileId)) {
      failed.value = true;
      return;
    }
    const settle = (answer: string | undefined) => {
      if (!alive || current !== request) return;
      url.value = flarePluginProtectedMediaSource(answer);
      failed.value = !url.value;
    };
    try {
      const answer = props.resolve(source);
      if (answer && typeof (answer as Promise<string | undefined>).then === "function") {
        (answer as Promise<string | undefined>).then(settle, () => settle(undefined));
      } else settle(answer as string | undefined);
    } catch {
      settle(undefined);
    }
  },
  { immediate: true },
);
</script>

<template>
  <figure class="flare-plugin-image" :style="{ aspectRatio: String(flarePluginImageRatio(block.aspect)) }" :data-image-aspect="block.aspect">
    <img v-if="url" class="flare-plugin-image__img" :src="url" :alt="block.alt" loading="lazy" decoding="async" @error="failed = true; url = undefined" />
    <div v-else class="flare-plugin-image__placeholder" role="img" :aria-label="block.alt" :aria-busy="!failed || undefined">
      <FlareIcon name="image" :size="24" aria-hidden="true" />
      <span v-if="failed" class="flare-plugin-image__note">{{ t("pluginView.imageUnavailable") }}</span>
    </div>
  </figure>
</template>

<style scoped>
.flare-plugin-image {
  position: relative;
  width: 100%;
  margin: 0;
  overflow: hidden;
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-tertiary);
}
.flare-plugin-image__img { display: block; width: 100%; height: 100%; object-fit: cover; }
.flare-plugin-image__placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--flare-size-spacing-xs);
  width: 100%;
  height: 100%;
  color: var(--flare-color-text-tertiary);
}
.flare-plugin-image__note { font-size: var(--flare-size-font-size-sm); }
</style>
