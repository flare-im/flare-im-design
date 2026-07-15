<script setup lang="ts">
/**
 * Standalone sticker picker — a thin wrapper over `ComposerEmojiStickerPanel`
 * pinned to sticker-only mode (no emoji tab). Reuse it anywhere a sticker tray
 * is needed without dragging in the emoji surface.
 */
import ComposerEmojiStickerPanel, {
  type ComposerStickerPick,
} from "./ComposerEmojiStickerPanel/index.vue";

withDefaults(defineProps<{ canSend?: boolean; sending?: boolean }>(), {
  canSend: false,
  sending: false,
});

const emit = defineEmits<{
  (event: "send-sticker", payload: { picks: ComposerStickerPick[] }): void;
}>();
</script>

<template>
  <ComposerEmojiStickerPanel
    sticker-only
    active-tab="sticker"
    :can-send="canSend"
    :sending="sending"
    @send-sticker="(payload) => emit('send-sticker', payload)"
  />
</template>
