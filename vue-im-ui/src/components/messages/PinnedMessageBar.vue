<script setup lang="ts">
import { ChevronForwardOutline, PinOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { previewTextFromMessageContent } from "../../utils/messagePreview";

export type PinnedMessageItem = {
  serverId: string;
  clientMsgId: string;
  senderDisplayName: string;
  content?: {
    contentType?: string;
    data?: Record<string, unknown>;
  };
};

defineProps<{
  items: readonly PinnedMessageItem[];
}>();

const { t } = useFlareI18n();

const emit = defineEmits<{
  (event: "focus", messageId: string): void;
}>();

function messageId(item: PinnedMessageItem): string {
  return item.serverId || item.clientMsgId;
}

function preview(item: PinnedMessageItem): string {
  const rendered = previewTextFromMessageContent(item.content);
  if (rendered) return rendered;
  const data = item.content?.data ?? {};
  const text = String(data.text ?? data.body ?? data.preview ?? "").trim();
  if (text) return text;
  const type = item.content?.contentType;
  if (type === "image") return "[图片]";
  if (type === "video") return "[视频]";
  if (type === "file") return "[文件]";
  if (type === "location") return `[位置] ${String(data.title ?? data.address ?? "")}`;
  return type ? `[${type}]` : "置顶消息";
}

function senderInitial(item: PinnedMessageItem): string {
  const name = item.senderDisplayName.trim();
  return (name || preview(item)).slice(0, 1).toUpperCase();
}
</script>

<template>
  <section v-if="items.length" class="pinned-panel">
    <header class="pinned-panel__header">
      <span class="pinned-panel__icon">
        <n-icon :component="PinOutline" />
      </span>
      <strong>{{ t("message.pinnedTitle") }}</strong>
      <small>{{ t("message.pinnedCount", { count: items.length }) }}</small>
    </header>
    <div class="pinned-panel__list">
      <button
        v-for="item in items"
        :key="messageId(item)"
        type="button"
        class="pinned-panel__item"
        @click="emit('focus', messageId(item))"
      >
        <span class="pinned-panel__avatar">{{ senderInitial(item) }}</span>
        <span class="pinned-panel__body">
          <b>{{ item.senderDisplayName || t("composer.replyFallback") }}</b>
          <span>{{ preview(item) }}</span>
        </span>
        <n-icon class="pinned-panel__chevron" :component="ChevronForwardOutline" />
      </button>
    </div>
  </section>
</template>
