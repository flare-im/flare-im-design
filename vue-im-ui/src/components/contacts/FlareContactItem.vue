<script setup lang="ts">
import FlareAvatar from "../conversation/FlareAvatar.vue";
import type { FlareContact } from "../../shared/contracts";

defineProps<{ item: FlareContact; showPresence?: boolean }>();
const emit = defineEmits<{ (e: "select"): void }>();
</script>

<template>
  <div class="flare-contact-item" @click="emit('select')">
    <FlareAvatar :user-id="item.id" :display-name="item.name" :avatar-url="item.avatarUrl" :size="40" />
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
}
.flare-contact-item__name { color: var(--flare-color-text-primary); font-weight: 500; }
.flare-contact-item__sig {
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 240px;
}
</style>
