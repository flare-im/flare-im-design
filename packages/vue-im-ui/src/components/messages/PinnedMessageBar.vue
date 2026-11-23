<script setup lang="ts">
import { ChevronDownOutline, ChevronForwardOutline, PinOutline } from "../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import { computed, ref, watch } from 'vue';
import FlareBottomSheet from '../general/FlareBottomSheet.vue';
import FlareDrawer from '../general/FlareDrawer.vue';
import { useFlarePlatformSafe } from '../../shared/platform/useFlarePlatform';
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

const props = defineProps<{
  items: readonly PinnedMessageItem[];
}>();

const { t } = useFlareI18n();
const platform = useFlarePlatformSafe();
const expanded = ref(false);
// Follow the host shell's form factor, and keep an open list stable across resizing.
const useSheet = ref(platform.capabilities.value.bottomSheet);
watch(expanded, (open) => {
  if (open) useSheet.value = platform.capabilities.value.bottomSheet;
}, { flush: 'sync' });
watch(() => props.items.map(messageId).join('\u001f'), () => { expanded.value = false; });
const newestFirst = computed(() => [...props.items].reverse());
const current = computed(() => newestFirst.value[0]);
const currentPreview = computed(() => current.value?.senderDisplayName.trim()
  ? t('message.pinnedPreview', { name: current.value.senderDisplayName, text: preview(current.value) })
  : current.value ? preview(current.value) : '');
function focusCurrent() { if (current.value) focus(current.value); }
function focus(item: PinnedMessageItem) {
  expanded.value = false;
  emit('focus', messageId(item));
}

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
  <section v-if="items.length" class="pinned-panel" :aria-label="t('message.pinnedTitle')">
    <div class="pinned-panel__bar">
    <button type="button" class="pinned-panel__summary" :aria-label="t('message.pinnedLocate', { preview: currentPreview })" @click="focusCurrent">
      <span class="pinned-panel__icon">
        <n-icon size="var(--flare-size-icon-size-sm)" aria-hidden="true" :component="PinOutline" />
      </span>
      <strong>{{ t("message.pinnedTitle") }}</strong>
      <span class="pinned-panel__preview">{{ currentPreview }}</span>
    </button>
    <button v-if="items.length > 1" type="button" class="pinned-panel__all" :aria-label="t('message.pinnedOpenAll', { count: items.length })" aria-haspopup="dialog" :aria-expanded="expanded" @click="expanded = true">
      <span>{{ t("message.pinnedCount", { count: items.length }) }}</span>
      <n-icon size="var(--flare-size-icon-size-sm)" aria-hidden="true" :component="ChevronDownOutline" />
    </button>
    </div>
    <component :is="useSheet ? FlareBottomSheet : FlareDrawer" :open="expanded && items.length > 1" :title="t('message.pinnedTitle')" show-close @close="expanded = false">
    <div class="pinned-panel__list" :class="{ 'pinned-panel__list--sheet': useSheet }">
      <button
        v-for="item in newestFirst"
        :key="messageId(item)"
        type="button"
        class="pinned-panel__item"
        @click="focus(item)"
      >
        <span class="pinned-panel__avatar">{{ senderInitial(item) }}</span>
        <span class="pinned-panel__body">
          <b>{{ item.senderDisplayName || t("composer.replyFallback") }}</b>
          <span>{{ preview(item) }}</span>
        </span>
        <n-icon size="var(--flare-size-icon-size-sm)" aria-hidden="true" class="pinned-panel__chevron" :component="ChevronForwardOutline" />
      </button>
    </div>
    </component>
  </section>
</template>
