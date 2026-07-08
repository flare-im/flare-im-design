<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { NButton, NModal, NSelect, NTag } from "naive-ui";
import type { Conversation, Message } from "flare-core-typescript-sdk/web";
import type { ForwardMode } from "../types";
import { messageStableId } from "../types";

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
  props.mode === "merged" ? `聊天记录 ${orderedMessages.value.length} 条` : "逐条转发消息",
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
    title="转发确认"
    :bordered="false"
    @update:show="emit('update:show', $event)"
  >
    <div class="forward-modal__body">
      <div class="forward-modal__row">
        <span>模式</span>
        <n-tag size="small" round>{{ mode === "merged" ? "合并转发" : "逐条转发" }}</n-tag>
      </div>
      <label class="forward-modal__field">
        <span>目标会话</span>
        <n-select
          v-model:value="targetConversationId"
          :options="options"
          filterable
          placeholder="选择目标会话"
        />
      </label>
      <label class="forward-modal__field">
        <span>预览标题</span>
        <input v-model="title" class="forward-modal__input" placeholder="转发标题" />
      </label>
      <div class="forward-modal__preview">
        <div class="forward-modal__preview-head">
          <strong>消息预览</strong>
          <span>{{ orderedMessages.length }} 条</span>
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
        <n-button :disabled="loading" @click="emit('update:show', false)">取消</n-button>
        <n-button
          type="primary"
          :loading="loading"
          :disabled="!targetConversationId || orderedMessages.length === 0"
          @click="emit('confirm', { targetConversationId, title: title || defaultTitle })"
        >
          确认转发
        </n-button>
      </div>
    </template>
  </n-modal>
</template>
