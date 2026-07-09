<script setup lang="ts">
import Avatar from "../conversation/FlareAvatar.vue";

withDefaults(
  defineProps<{
    title: string;
    subtitle?: string;
    avatarUserId?: string;
    avatarUrl?: string;
    presenceOnAvatar?: boolean;
    presenceStatus?: "online" | "offline" | "busy";
    typingText?: string;
  }>(),
  {
    subtitle: "",
    avatarUserId: "",
    avatarUrl: "",
    presenceOnAvatar: false,
    presenceStatus: "offline",
    typingText: "",
  },
);
</script>

<template>
  <div class="im-chat-identity">
    <Avatar
      :user-id="avatarUserId || title"
      :display-name="title"
      :avatar-url="avatarUrl"
      :size="44"
      :show-status="presenceOnAvatar"
      :status="presenceStatus"
    />
    <div class="im-chat-identity__body">
      <h2>{{ title }}</h2>
      <p v-if="typingText" class="im-chat-identity__typing">
        <span>{{ typingText }}</span>
        <i />
        <i />
        <i />
      </p>
      <p v-else-if="subtitle">{{ subtitle }}</p>
    </div>
  </div>
</template>

<style scoped>
.im-chat-identity {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.im-chat-identity__body {
  min-width: 0;
}

.im-chat-identity h2 {
  margin: 0;
  overflow: hidden;
  color: var(--im-chat-hdr-title, var(--flare-color-text-primary, #111318));
  font-size: 15px;
  font-weight: 800;
  letter-spacing: 0;
  line-height: 1.25;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.im-chat-identity p {
  margin: 2px 0 0;
  overflow: hidden;
  color: var(--im-chat-hdr-meta, var(--flare-color-text-secondary, #6b7280));
  font-size: 12px;
  line-height: 1.25;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.im-chat-identity__typing {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  color: var(--im-chat-hdr-typing, #2f6bff);
}

.im-chat-identity__typing i {
  width: 3px;
  height: 3px;
  border-radius: 50%;
  background: currentColor;
  opacity: 0.65;
  animation: imTypingPulse 1.1s ease-in-out infinite;
}

.im-chat-identity__typing i:nth-child(3) {
  animation-delay: 120ms;
}

.im-chat-identity__typing i:nth-child(4) {
  animation-delay: 240ms;
}

@keyframes imTypingPulse {
  0%,
  80%,
  100% {
    transform: translateY(0);
    opacity: 0.35;
  }
  40% {
    transform: translateY(-2px);
    opacity: 1;
  }
}
</style>
