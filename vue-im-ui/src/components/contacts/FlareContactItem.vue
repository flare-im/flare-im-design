<script setup lang="ts">
import { computed } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import type { FlareContact } from "../../shared/contracts";

const props = withDefaults(defineProps<{ item: FlareContact; showPresence?: boolean }>(), {
  showPresence: false,
});
defineEmits<{ (e: "select"): void }>();

// Avatar supports online / offline / busy — map "away" onto busy so it still shows.
const avatarStatus = computed<"online" | "offline" | "busy">(() => {
  if (props.item.presence === "online") return "online";
  if (props.item.presence === "busy" || props.item.presence === "away") return "busy";
  return "offline";
});
</script>

<template>
  <div class="flare-contact-item" @click="$emit('select')">
    <FlareAvatar
      :user-id="item.id"
      :display-name="item.name"
      :avatar-url="item.avatarUrl"
      :size="40"
      :show-status="showPresence && !!item.presence"
      :status="avatarStatus"
    />
    <div class="flare-contact-item__body">
      <div class="flare-contact-item__name">{{ item.name }}</div>
      <div v-if="item.signature" class="flare-contact-item__sig">{{ item.signature }}</div>
    </div>
  </div>
</template>

<style scoped>
.flare-contact-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 14px;
  cursor: pointer;
  border-radius: var(--flare-size-radius-lg, 10px);
  transition: background var(--flare-transition-fast, 150ms ease);
}
.flare-contact-item:hover {
  background: var(--flare-color-bg-hover);
}
.flare-contact-item__body {
  min-width: 0;
}
.flare-contact-item__name {
  color: var(--flare-color-text-primary);
  font-weight: 500;
}
.flare-contact-item__sig {
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 240px;
}
</style>
