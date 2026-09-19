<script setup>
import { ref } from "vue";
import { FlareConversationList } from "@flare-im/vue-ui/components";
import { conversationFixture } from "./conversation-fixture";
import DemoStage from "./DemoStage.vue";

const items = ref(conversationFixture.map((item) => ({ ...item })));
const capabilities = { pin: true, mute: true, markRead: true, markUnread: true };
const activeId = ref("li");
function action(action, id) {
  const item = items.value.find((item) => item.id === id);
  if (!item) return;
  if (action === "pin" || action === "unpin") item.pinned = action === "pin";
  if (action === "mute" || action === "unmute") item.muted = action === "mute";
  if (action === "markRead" || action === "markUnread") item.unreadCount = action === "markRead" ? 0 : 1;
}
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareConversationList :items="items" :active-id="activeId" :capabilities="capabilities" @select="activeId = $event" @action="action" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 380px; }
</style>
