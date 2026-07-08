<script setup lang="ts">
import { nextTick, ref, watch } from "vue";
import { NButton, NInput, NModal, NSelect } from "naive-ui";

const open = defineModel<boolean>("open", { default: false });
const peerUserId = defineModel<string>("peerUserId", { default: "" });
const conversationType = defineModel<"single" | "group">("conversationType", { default: "single" });

defineProps<{
  busy?: boolean;
}>();

const emit = defineEmits<{
  (event: "confirm"): void;
}>();

const peerInputRef = ref<InstanceType<typeof NInput> | null>(null);

watch(open, (visible) => {
  if (!visible) return;
  void nextTick(() => {
    peerInputRef.value?.focus();
  });
});

function closeDialog(): void {
  open.value = false;
}

function submitDialog(): void {
  if (!peerUserId.value.trim()) return;
  emit("confirm");
}
</script>

<template>
  <n-modal
    v-model:show="open"
    preset="card"
    title="打开会话"
    class="start-dialog-modal"
    :auto-focus="false"
    :trap-focus="true"
    :mask-closable="true"
    style="max-width: 420px"
    @after-enter="() => peerInputRef?.focus()"
  >
    <div class="start-dialog-field">
      <span>{{ conversationType === "group" ? "成员 ID" : "对方 ID" }}</span>
      <n-input
        ref="peerInputRef"
        v-model:value="peerUserId"
        size="large"
        clearable
        :placeholder="conversationType === 'group' ? '输入成员 userId，可用逗号或空格分隔' : '输入对方真实 userId'"
        @keydown.enter.prevent="submitDialog"
      />
      <small class="start-dialog-hint">
        {{
          conversationType === "group"
            ? "群聊由 SDK 通过 getGroupConversationByUserIds 按成员列表生成"
            : "会话 ID 由 SDK 通过 getOneConversation 自动生成"
        }}
      </small>
    </div>
    <div class="start-dialog-field">
      <span>会话类型</span>
      <n-select
        v-model:value="conversationType"
        :options="[
          { label: '单聊', value: 'single' },
          { label: '群聊', value: 'group' },
        ]"
      />
    </div>
    <template #action>
      <n-button text @click="closeDialog">取消</n-button>
      <n-button type="primary" :loading="busy" :disabled="!peerUserId.trim()" @click="submitDialog">
        打开
      </n-button>
    </template>
  </n-modal>
</template>
