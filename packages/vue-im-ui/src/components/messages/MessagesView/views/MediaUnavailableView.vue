<script setup lang="ts">
import { computed } from "vue";
import MsgIcon from "../../standalone/MsgIcon.vue";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";

// A picture, a video or a voice message whose address could not be resolved (nothing to load, and nothing
// still loading): still that kind of message — its icon and the kit's words for why it is not there — never
// "unsupported". Nothing to tap, since there is nothing to retry from here. The same body in all four kits.
const props = defineProps<{ kind: "image" | "video" | "audio" }>();
const { t } = useFlareI18n();

const ICONS = { image: "image", video: "video", audio: "volume" } as const;
const KEYS = {
  image: "mediaMessage.unavailableImage",
  video: "mediaMessage.unavailableVideo",
  audio: "mediaMessage.unavailableAudio",
} as const;
const text = computed(() => t(KEYS[props.kind]));
</script>

<template>
  <span class="im-media-unavailable" role="img" :aria-label="text" :data-kind="kind">
    <MsgIcon :name="ICONS[kind]" :size="16" />
    <span aria-hidden="true">{{ text }}</span>
  </span>
</template>

<style scoped>
.im-media-unavailable {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-bg-tertiary);
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-size-font-size-sm);
  max-width: 100%;
}
</style>
