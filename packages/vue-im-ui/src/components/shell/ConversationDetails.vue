<script setup lang="ts">
import { computed } from "vue";
import { NButton, NDivider, NTag } from "naive-ui";
import Avatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareConversationDetailsModel } from "../../shared/contracts/conversation";
import type { FlareTone } from "../../shared/contracts/tone";

const props = withDefaults(
  defineProps<{
    /** Structural conversation view supplied by the host. */
    conversation?: Readonly<FlareConversationDetailsModel>;
    connectionText: string;
    /** Semantic tone of the connection tag (shared FlareTone enum). */
    tone?: FlareTone;
    messageCount: number;
    latestMessageId: string;
  }>(),
  { conversation: undefined, tone: "neutral" },
);

/** naive-ui tag type for a FlareTone — the only place the naive enum is spelled. */
const TAG_TYPE: Record<FlareTone, "info" | "success" | "warning" | "error" | "default"> = {
  info: "info",
  success: "success",
  warning: "warning",
  danger: "error",
  neutral: "default",
};

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

const { t } = useFlareI18n();

const resolvedTone = computed<FlareTone>(() => props.tone);
const tagType = computed(() => TAG_TYPE[resolvedTone.value]);

const title = computed(() => props.conversation?.displayName || t("conversationDetails.title"));
const subtitle = computed(() => {
  const item = props.conversation;
  if (!item) return t("conversationDetails.selectHint");
  const kind = item.conversationKind ?? "single";
  if (kind === "group") return t("conversationDetails.members", { count: item.membersCount ?? 0 });
  if (kind === "ai") return t("conversationDetails.assistant");
  return item.channelId ?? "";
});
</script>

<template>
  <aside class="details-pane">
    <template v-if="conversation">
      <section class="details-hero">
        <Avatar
          :user-id="conversation.channelId || conversation.conversationId"
          :display-name="title"
          :avatar-url="conversation.avatarUrl"
          :size="56"

        />
        <h2>{{ title }}</h2>
        <p>{{ subtitle }}</p>
        <div class="details-tags">
          <n-tag round size="small" :type="tagType" :data-tone="resolvedTone">{{ connectionText }}</n-tag>
          <n-tag v-if="conversation.isPinned" round size="small" type="info">{{ t("conversationDetails.pinned") }}</n-tag>
          <n-tag v-if="conversation.isMuted" round size="small">{{ t("conversationDetails.muted") }}</n-tag>
        </div>
      </section>

      <section class="details-actions">
        <n-button secondary size="small" @click="emit('sync')">{{ t("conversationDetails.sync") }}</n-button>
        <n-button secondary size="small" @click="emit('mark-read')">{{ t("conversationDetails.markRead") }}</n-button>
        <n-button secondary size="small" @click="emit('mark-unread')">{{ t("conversationDetails.markUnread") }}</n-button>
        <n-button secondary size="small" @click="emit('pin', !conversation.isPinned)">
          {{ conversation.isPinned ? t("conversationDetails.unpin") : t("conversationDetails.pin") }}
        </n-button>
        <n-button secondary size="small" @click="emit('mute', !conversation.isMuted)">
          {{ conversation.isMuted ? t("conversationDetails.unmute") : t("conversationDetails.mute") }}
        </n-button>
        <n-button secondary size="small" @click="emit('archive', !conversation.isArchived)">
          {{ conversation.isArchived ? t("conversationDetails.unarchive") : t("conversationDetails.archive") }}
        </n-button>
        <n-button secondary size="small" @click="emit('clear-history')">{{ t("conversationDetails.clearHistory") }}</n-button>
        <n-button secondary size="small" type="error" @click="emit('delete')">{{ t("conversationDetails.delete") }}</n-button>
      </section>

      <n-divider />

      <section class="details-section">
        <div class="pane-title">{{ t("conversationDetails.status") }}</div>
        <dl>
          <div><dt>{{ t("conversationDetails.channel") }}</dt><dd>{{ conversation.channelId || "-" }}</dd></div>
          <div><dt>{{ t("conversationDetails.unread") }}</dt><dd>{{ conversation.unreadCount ?? 0 }}</dd></div>
          <div><dt>{{ t("conversationDetails.messages") }}</dt><dd>{{ messageCount }}</dd></div>
        </dl>
        <details class="details-diagnostics">
          <summary>{{ t("conversationDetails.diagnostics") }}</summary>
          <dl>
            <div><dt>{{ t("conversationDetails.conversationId") }}</dt><dd>{{ conversation.conversationId }}</dd></div>
            <div><dt>{{ t("conversationDetails.latestMessage") }}</dt><dd>{{ latestMessageId || "-" }}</dd></div>
          </dl>
        </details>
      </section>

      <n-divider />

      <section class="details-section">
        <div class="pane-title">{{ t("conversationDetails.extensions") }}</div>
        <div class="extension-list">
          <button type="button">{{ t("conversationDetails.membersAndPermissions") }}</button>
          <button type="button">{{ t("conversationDetails.filesAndMedia") }}</button>
          <button type="button">{{ t("conversationDetails.plugins") }}</button>
          <button type="button" @click="emit('open-devtools')">{{ t("conversationDetails.diagnostics") }}</button>
        </div>
      </section>
    </template>

    <section v-else class="details-empty">
      <h2>{{ t("conversationDetails.selectHint") }}</h2>
      <p>{{ t("conversationDetails.emptyHint") }}</p>
    </section>
  </aside>
</template>
