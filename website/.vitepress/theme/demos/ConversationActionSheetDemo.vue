<script setup>
import { computed, inject, ref } from "vue";
import { FlareConversationActionSheet, FlareConversationRow, FlareBottomSheet } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
import { previewContextKey } from "./preview-context";

const preview = inject(previewContextKey, null);
const mobile = computed(() => preview?.viewport.value === "mobile");
const conversation = ref({ id: "conv-1", title: "设计评审", pinned: false, muted: false, unreadCount: 3, archived: false });
const capabilities = { pin: true, mute: true, markRead: true, archive: true, hide: true, delete: true };
const sheetOpen = ref(true);
const row = computed(() => ({ ...conversation.value, displayName: conversation.value.title, timestampLabel: "14:02", lastMessagePreview: "本周设计稿已更新，请查收。" }));
function apply({ action }) {
  const c = conversation.value;
  if (action === "pin" || action === "unpin") c.pinned = action === "pin";
  if (action === "mute" || action === "unmute") c.muted = action === "mute";
  if (action === "markRead") c.unreadCount = 0;
  if (action === "archive" || action === "unarchive") c.archived = action === "archive";
  sheetOpen.value = false;
}
</script>

<template>
  <DemoStage>
    <div v-if="!mobile" class="cas-demo__popover" data-preview-platform="desktop">
      <FlareConversationActionSheet :conversation="conversation" :capabilities="capabilities" @action="apply" />
    </div>
    <div v-else data-preview-platform="mobile">
      <!-- 行是 listitem，放在 list 里才是它的真实用法。 -->
      <div role="list">
        <FlareConversationRow :item="row" @select="sheetOpen = true" />
      </div>
      <FlareBottomSheet :open="sheetOpen" @close="sheetOpen = false">
        <FlareConversationActionSheet :conversation="conversation" :capabilities="capabilities" @action="apply" @close="sheetOpen = false" />
      </FlareBottomSheet>
    </div>
  </DemoStage>
</template>

<style scoped>
.cas-demo__popover { width: 280px; max-width: 100%; margin-inline: auto; border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-md); background: var(--flare-color-bg-primary); }
</style>
