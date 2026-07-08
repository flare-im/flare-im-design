<script setup lang="ts">
import FlareAvatar from "../conversation/FlareAvatar.vue";
import type { FlareContact } from "../../shared/contracts";

defineProps<{ contact: FlareContact }>();
const emit = defineEmits<{
  (e: "message"): void;
  (e: "call"): void;
  (e: "video"): void;
  (e: "edit"): void;
  (e: "remove"): void;
  (e: "block"): void;
}>();
</script>

<template>
  <div class="flare-contact-detail">
    <FlareAvatar :user-id="contact.id" :display-name="contact.name" :avatar-url="contact.avatarUrl" :size="88" />
    <div class="flare-contact-detail__name">{{ contact.name }}</div>
    <div v-if="contact.signature" class="flare-contact-detail__sig">{{ contact.signature }}</div>
    <div class="flare-contact-detail__actions">
      <button class="is-primary" @click="emit('message')">💬 Message</button>
      <button @click="emit('call')">📞 Voice</button>
      <button @click="emit('video')">📹 Video</button>
    </div>
  </div>
</template>

<style scoped>
.flare-contact-detail {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 28px 16px;
}
.flare-contact-detail__name { font-size: 20px; font-weight: 600; color: var(--flare-color-text-primary); margin-top: 8px; }
.flare-contact-detail__sig { font-size: 14px; color: var(--flare-color-text-tertiary); }
.flare-contact-detail__actions { display: flex; gap: 12px; margin-top: 20px; width: 100%; }
.flare-contact-detail__actions button {
  flex: 1;
  padding: 10px;
  border-radius: var(--flare-size-radius-md, 6px);
  border: none;
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font-size: 13px;
  cursor: pointer;
}
.flare-contact-detail__actions button.is-primary { background: var(--flare-color-primary); color: #fff; }
</style>
