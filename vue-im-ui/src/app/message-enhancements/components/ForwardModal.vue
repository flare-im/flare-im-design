<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { NButton, NModal, NSelect, NTag } from "naive-ui";
import type { Conversation, Message } from "@flare-im/sdk/web";
import type { ForwardMode } from "../types";
import { messageStableId } from "../types";
import { useFlareI18n } from "../../shared/i18n";
const { t } = useFlareI18n();

const props = defineProps<{
  show: boolean;
  mode: ForwardMode;
  conversations: readonly Conversation[];
  messages: readonly Message[];
  activeConversationId: string;
  loading?: boolean;
}>();

const emit = defineEmits<{
  (event: "update:show", value: boolean): void;
  (event: "confirm", payload: { targetConversationId: string; title: string }): void;
}>();

const targetConversationId = ref("");
const title = ref("");

const options = computed(() =>
  props.conversations.map((conversation) => ({
    label: conversation.displayName || conversation.conversationId,
    value: conversation.conversationId,
  })),
);

const orderedMessages = computed(() =>
  [...props.messages].sort((left, right) =>
    Number(left.conversationSeq || left.createdAt || left.clientCreatedAt || 0)
    - Number(right.conversationSeq || right.createdAt || right.clientCreatedAt || 0),
  ),
);

const defaultTitle = computed(() =>
  props.mode === "merged" ? t("forward.chatHistoryCount", { count: orderedMessages.value.length }) : t("enhance.forwardEachMessages"),
);

watch(
  () => props.show,
  (open) => {
    if (!open) return;
    targetConversationId.value = props.activeConversationId;
    title.value = defaultTitle.value;
  },
);

function previewText(message: Message): string {
  const data = (message.content as { data?: Record<string, unknown> } | undefined)?.data;
  const text = typeof data?.text === "string" ? data.text : "";
  return text || message.content?.contentType || messageStableId(message);
}
</script>

<template>
  <n-modal
    :show="show"
    preset="card"
    class="forward-modal"
    :title="t('enhance.forwardConfirmTitle')"
    :bordered="false"
    @update:show="emit('update:show', $event)"
  >
    <div class="forward-modal__body">
      <div class="forward-modal__row">
        <span>{{ t('enhance.modeLabel') }}</span>
        <n-tag size="small" round>{{ mode === "merged" ? t('enhance.forwardMerged') : t('enhance.forwardEach') }}</n-tag>
      </div>
      <label class="forward-modal__field">
        <span>{{ t('enhance.targetConv') }}</span>
        <n-select
          v-model:value="targetConversationId"
          :options="options"
          filterable
          :placeholder="t('enhance.selectTargetConv')"
        />
      </label>
      <label class="forward-modal__field">
        <span>{{ t('enhance.previewTitleLabel') }}</span>
        <input v-model="title" class="forward-modal__input" :placeholder="t('enhance.forwardTitlePlaceholder')" />
      </label>
      <div class="forward-modal__preview">
        <div class="forward-modal__preview-head">
          <strong>{{ t('enhance.messagePreview') }}</strong>
          <span>{{ t('enhance.itemsCount', { count: orderedMessages.length }) }}</span>
        </div>
        <ol>
          <li v-for="item in orderedMessages" :key="messageStableId(item)">
            {{ previewText(item) }}
          </li>
        </ol>
      </div>
    </div>
    <template #footer>
      <div class="forward-modal__footer">
        <n-button :disabled="loading" @click="emit('update:show', false)">{{ t('common.cancel') }}</n-button>
        <n-button
          type="primary"
          :loading="loading"
          :disabled="!targetConversationId || orderedMessages.length === 0"
          @click="emit('confirm', { targetConversationId, title: title || defaultTitle })"
        >
          {{ t('enhance.confirmForward') }}
        </n-button>
      </div>
    </template>
  </n-modal>
</template>
