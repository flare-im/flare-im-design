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

const title = computed(() => props.conversation?.displayName || "会话详情");
const subtitle = computed(() => {
  const item = props.conversation;
  if (!item) return "请选择会话";
  if (item.conversationType === "group") return `${item.membersCount} 位成员`;
  if (item.conversationType === "ai") return "智能助手";
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
          <n-tag v-if="conversation.isPinned" round size="small" type="info">置顶</n-tag>
          <n-tag v-if="conversation.isMuted" round size="small">免打扰</n-tag>
        </div>
      </section>

      <section class="details-actions">
        <n-button secondary size="small" @click="emit('sync')">同步</n-button>
        <n-button secondary size="small" @click="emit('mark-read')">标为已读</n-button>
        <n-button secondary size="small" @click="emit('mark-unread')">标为未读</n-button>
        <n-button secondary size="small" @click="emit('pin', !conversation.isPinned)">
          {{ conversation.isPinned ? "取消置顶" : "置顶" }}
        </n-button>
        <n-button secondary size="small" @click="emit('mute', !conversation.isMuted)">
          {{ conversation.isMuted ? "取消免打扰" : "免打扰" }}
        </n-button>
        <n-button secondary size="small" @click="emit('archive', !conversation.isArchived)">
          {{ conversation.isArchived ? "取消归档" : "归档" }}
        </n-button>
        <n-button secondary size="small" @click="emit('clear-history')">清空记录</n-button>
        <n-button secondary size="small" type="error" @click="emit('delete')">删除</n-button>
      </section>

      <n-divider />

      <section class="details-section">
        <div class="pane-title">会话状态</div>
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
        <div class="pane-title">扩展入口</div>
        <div class="extension-list">
          <button type="button">成员与权限</button>
          <button type="button">文件与媒体</button>
          <button type="button">会话插件</button>
          <button type="button" @click="emit('open-devtools')">SDK 诊断</button>
        </div>
      </section>
    </template>

    <section v-else class="details-empty">
      <h2>选择会话</h2>
      <p>会话资料、成员、媒体与扩展能力会显示在这里。</p>
    </section>
  </aside>
</template>
