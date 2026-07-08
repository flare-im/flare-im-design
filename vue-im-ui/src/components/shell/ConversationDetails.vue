<script setup lang="ts">
import { computed } from "vue";
import { NButton, NDivider, NTag } from "naive-ui";
import Avatar from "../conversation/FlareAvatar.vue";
import type { Conversation } from "flare-core-typescript-sdk/web";

const props = defineProps<{
  conversation?: Readonly<Conversation>;
  connectionText: string;
  connectionTone: "success" | "warning" | "default";
  messageCount: number;
  latestMessageId: string;
}>();

const emit = defineEmits<{
  (event: "sync"): void;
  (event: "mark-read"): void;
  (event: "mark-unread"): void;
  (event: "pin", pinned: boolean): void;
  (event: "mute", muted: boolean): void;
  (event: "archive", archived: boolean): void;
  (event: "clear-history"): void;
  (event: "delete"): void;
  (event: "open-devtools"): void;
}>();

const title = computed(() => props.conversation?.displayName || "Conversation details");
const subtitle = computed(() => {
  const item = props.conversation;
  if (!item) return "Select a conversation";
  if (item.conversationType === "group") return `${item.membersCount} members`;
  if (item.conversationType === "ai") return "Assistant";
  return item.channelId;
});
</script>

<template>
  <aside class="details-pane">
    <template v-if="conversation">
      <section class="details-hero">
        <Avatar
          :user-id="conversation.channelId"
          :display-name="title"
          :avatar-url="conversation.avatarUrl"
          :size="56"
          show-status
          status="online"
        />
        <h2>{{ title }}</h2>
        <p>{{ subtitle }}</p>
        <div class="details-tags">
          <n-tag round size="small" :type="connectionTone">{{ connectionText }}</n-tag>
          <n-tag v-if="conversation.isPinned" round size="small" type="info">Pinned</n-tag>
          <n-tag v-if="conversation.isMuted" round size="small">Muted</n-tag>
        </div>
      </section>

      <section class="details-actions">
        <n-button secondary size="small" @click="emit('sync')">Sync</n-button>
        <n-button secondary size="small" @click="emit('mark-read')">Mark read</n-button>
        <n-button secondary size="small" @click="emit('mark-unread')">Mark unread</n-button>
        <n-button secondary size="small" @click="emit('pin', !conversation.isPinned)">
          {{ conversation.isPinned ? "Unpin" : "Pin" }}
        </n-button>
        <n-button secondary size="small" @click="emit('mute', !conversation.isMuted)">
          {{ conversation.isMuted ? "Unmute" : "Mute" }}
        </n-button>
        <n-button secondary size="small" @click="emit('archive', !conversation.isArchived)">
          {{ conversation.isArchived ? "Unarchive" : "Archive" }}
        </n-button>
        <n-button secondary size="small" @click="emit('clear-history')">Clear history</n-button>
        <n-button secondary size="small" type="error" @click="emit('delete')">Delete</n-button>
      </section>

      <n-divider />

      <section class="details-section">
        <div class="pane-title">Conversation status</div>
        <dl>
          <div><dt>Conversation ID</dt><dd>{{ conversation.conversationId }}</dd></div>
          <div><dt>Channel</dt><dd>{{ conversation.channelId }}</dd></div>
          <div><dt>Unread</dt><dd>{{ conversation.unreadCount }}</dd></div>
          <div><dt>Messages</dt><dd>{{ messageCount }}</dd></div>
          <div><dt>Latest Message</dt><dd>{{ latestMessageId || "-" }}</dd></div>
        </dl>
      </section>

      <n-divider />

      <section class="details-section">
        <div class="pane-title">Extensions</div>
        <div class="extension-list">
          <button type="button">Members & permissions</button>
          <button type="button">Files & media</button>
          <button type="button">Conversation plugins</button>
          <button type="button" @click="emit('open-devtools')">SDK diagnostics</button>
        </div>
      </section>
    </template>

    <section v-else class="details-empty">
      <h2>Select a conversation</h2>
      <p>Conversation info, members, media and extensions appear here.</p>
    </section>
  </aside>
</template>
