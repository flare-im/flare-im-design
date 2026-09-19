<script setup lang="ts">
import { ChevronForwardOutline, PinOutline } from "../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { previewTextFromMessageContent } from "../../utils/messagePreview";
import { resolveMessageId } from "../../shared/contracts/messageRow";

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
  return resolveMessageId(item);
}

function preview(item: PinnedMessageItem): string {
  const rendered = previewTextFromMessageContent(item.content);
  if (rendered) return rendered;
  const data = item.content?.data ?? {};
  const text = String(data.text ?? data.body ?? data.preview ?? "").trim();
  if (text) return text;
  const type = item.content?.contentType;
  if (type === "image") return t("preview.image");
  if (type === "video") return t("preview.video");
  if (type === "file") return t("preview.file");
  if (type === "location") {
    const label = String(data.title ?? data.address ?? "").trim();
    return label ? t("preview.locationNamed", { label }) : t("preview.location");
  }
  // An unknown content type is internal vocabulary: say only that the message is pinned.
  return t("message.pinnedFallback");
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
        <n-icon aria-hidden="true" :component="PinOutline" />
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
        <n-icon aria-hidden="true" class="pinned-panel__chevron" :component="ChevronForwardOutline" />
      </button>
    </div>
  </section>
</template>
