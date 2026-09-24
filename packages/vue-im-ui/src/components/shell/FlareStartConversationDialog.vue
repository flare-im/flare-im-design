<script setup lang="ts">
// Phone form factors get a bottom sheet, pointer form factors a centered dialog: same fields,
// same events — 这正是 `FlareBottomSheet` 的 `presentation="auto"` 判的那个能力位,所以这里
// 不再自己算一遍 `asSheet`,也不再挂第二棵 naive 模态的树。少掉的那棵树还带走了
// `useCardHeadingLevel`:它存在的唯一理由是 naive 卡片头是个没有级别的标题。
import { nextTick, ref, watch } from "vue";
import { NButton, NInput, NSelect } from "naive-ui";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";

const { t } = useFlareI18n();

const open = defineModel<boolean>("open", { default: false });
const peerUserId = defineModel<string>("peerUserId", { default: "" });
// The dialog starts one of the two kinds a person can create; the rest of the union is for what exists.
const conversationKind = defineModel<"single" | "group">("conversationKind", { default: "single" });

const props = defineProps<{
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
  if (props.busy) return;
  open.value = false;
}

function submitDialog(): void {
  if (!peerUserId.value.trim()) return;
  emit("confirm");
}
</script>

<template>
  <FlareBottomSheet
    :open="open"
    :title="t('startConversation.openConversation')"
    :dismissible="!busy"
    @close="closeDialog"
  >
    <div class="start-dialog-form">
      <div class="start-dialog-field">
        <span>{{ conversationKind === "group" ? t("startConversation.memberIdLabel") : t("startConversation.userIdLabel") }}</span>
        <n-input
          ref="peerInputRef"
          v-model:value="peerUserId"
          size="large"
          clearable
          :placeholder="conversationKind === 'group' ? t('startConversation.membersPlaceholder') : t('startConversation.userIdPlaceholder')"
          @keydown.enter.prevent="submitDialog"
        />
        <small class="start-dialog-hint">
          {{
            conversationKind === "group"
              ? t("startConversation.groupHint")
              : t("startConversation.directHint")
          }}
        </small>
      </div>
      <div class="start-dialog-field">
        <span>{{ t("startConversation.conversationType") }}</span>
        <n-select
          v-model:value="conversationKind"
          :options="[
            { label: t('startConversation.typeDirect'), value: 'single' },
            { label: t('startConversation.typeGroup'), value: 'group' },
          ]"
        />
      </div>
      <div class="start-dialog-actions">
        <n-button text :disabled="busy" @click="closeDialog">{{ t("startConversation.cancel") }}</n-button>
        <n-button type="primary" :loading="busy" :disabled="!peerUserId.trim()" @click="submitDialog">
          {{ t("startConversation.openConversation") }}
        </n-button>
      </div>
    </div>
  </FlareBottomSheet>
</template>

<style scoped>
/* 这张表单的样式只有这一个出处。
   从前它同时被 design-system/styles/sheets-modals.css 里一组同名全局规则写着:
   Vue 的 scoped 只给选择器最后一段加属性,于是两边**同一个元素**逐条属性比特异性,
   谁赢看情况 —— 标签的字号颜色归这边(0,2,1 > 0,1,1),而字段的 margin-bottom: 12px、
   font-size: 14px、操作行的 margin-top: 26px 这边根本没声明,就归了全局那份。
   渲染出来是两份文件掺出来的结果:字段间距 16+12=28px、操作行上方 26px,两个都不在
   间距阶梯上(4/6/8/12/16/20/24),也没人设计过。全局那份已删,数值在这里按 token 重写。 */
.start-dialog-form {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-lg);
}

.start-dialog-field {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  color: var(--flare-color-text-primary);
  font-size: var(--flare-size-font-size-lg);
}

.start-dialog-field > span {
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-md);
}

.start-dialog-hint {
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-normal);
}

.start-dialog-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--flare-size-spacing-sm);
}

/* 主按钮还是 naive 的,scoped 够不到它的内部类,得显式穿透 —— 这条从前也在全局表里,
   它存在的唯一理由是这个组件用的是 n-button 而不是 FlareButton。 */
.start-dialog-actions :deep(.n-button--primary-type) {
  min-width: 68px;
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-primary);
}

/* 判据取自 FlareBottomSheet 画在面上的 data-flare-presentation —— 这里不再自己
   算一遍「现在是手机还是桌面」。 */
[data-flare-presentation="sheet"] .start-dialog-form {
  padding: 0 16px calc(16px + env(safe-area-inset-bottom, 0px));
}

[data-flare-presentation="sheet"] .start-dialog-actions {
  flex-direction: column-reverse;
}

[data-flare-presentation="dialog"] .start-dialog-form {
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-lg) var(--flare-size-spacing-md);
}
</style>
