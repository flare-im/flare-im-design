<script setup>
import { ref } from "vue";
import DemoStage from "./DemoStage.vue";
// The real composer panel: 157 animated emoji + sticker packs, resolved from the
// centralized flare-im-design/assets/emoji-sticker source served at /flare-im-ui-assets/.
import Panel from "flare-core-vue-im-ui/components/composer/ComposerEmojiStickerPanel/index.vue";

const activeTab = ref("emoji");
const last = ref("点一个表情或贴纸试试 · pick an emoji or sticker");

function onInsertEmoji(key) {
  last.value = `插入表情 [${key}]`;
}
function onSendSticker(payload) {
  const pick = payload?.picks?.[0];
  last.value = pick ? `发送贴纸 ${pick.packageId}/${pick.stickerId}` : "发送贴纸";
}
</script>

<template>
  <DemoStage>
    <div class="es-demo">
      <div class="es-hint">{{ last }}</div>
      <div class="es-panel">
        <Panel
          v-model:active-tab="activeTab"
          @insert-emoji="onInsertEmoji"
          @send-sticker="onSendSticker"
        />
      </div>
    </div>
  </DemoStage>
</template>

<style scoped>
.es-demo {
  width: 100%;
  max-width: 420px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.es-hint {
  font-size: 13px;
  color: var(--flare-color-text-secondary);
  padding: 8px 12px;
  border-radius: 10px;
  background: var(--flare-color-bg-secondary);
}
.es-panel {
  border: 1px solid var(--flare-color-border);
  border-radius: 12px;
  overflow: hidden;
  background: var(--flare-color-bg-primary);
}
</style>
