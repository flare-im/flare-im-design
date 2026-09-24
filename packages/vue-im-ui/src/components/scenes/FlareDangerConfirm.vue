<script setup lang="ts">
// Confirmation before something destructive. FR-042: the same confirmation, presented the way the
// platform presents things — a bottom sheet on a phone, a centered dialog on a pointer device — so a
// host never has to rebuild it as a sheet to look right on a phone. The events stay `confirm` and
// `cancel`: closing by scrim, Escape or the platform back is a cancel, and while `busy` it does not close.
//
// 一张面,两种出场 —— 以前这里是两棵树:手机走 FlareBottomSheet,指针设备走 naive
// 自己的模态。两者各有一套标题栏、一套按钮排布、一套关闭规则,连平台返回键都得在外面
// 再补一次。而 `FlareBottomSheet` 的 `presentation="auto"` 判的就是同一个
// `capabilities.bottomSheet`,所以那层分支只是把一件事写了两遍。现在只剩下按钮
// 怎么排的差别,那是 CSS 的事,不该长出第二棵组件树。
import { computed } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";

const props = defineProps<{
  open: boolean;
  title: string;
  description: string;
  target: string;
  busy?: boolean;
  error?: string;
  confirmText?: string;
  cancelText?: string;
}>();
const { t } = useFlareI18n();
const strings = computed(() => ({
  confirmText: props.confirmText ?? t("dangerConfirm.confirm"),
  cancelText: props.cancelText ?? t("dangerConfirm.cancel"),
}));
const emit = defineEmits<{ confirm: []; cancel: [] }>();
function confirm(): void { if (!props.busy) emit("confirm"); }
function cancel(): void { if (!props.busy) emit("cancel"); }
</script>

<template>
  <FlareBottomSheet :open="open" :title="title" :dismissible="!busy" @close="cancel">
    <div class="flare-danger-confirm">
      <p>{{ description }}</p>
      <strong>{{ target }}</strong>
      <p v-if="error" role="alert" class="flare-danger-confirm__error">{{ error }}</p>
      <div class="flare-danger-confirm__actions">
        <FlareButton
          variant="secondary"
          :label="strings.cancelText"
          :aria-label="strings.cancelText"
          :disabled="busy"
          block
          @click="cancel"
        />
        <FlareButton
          variant="danger"
          :label="strings.confirmText"
          :aria-label="strings.confirmText"
          :disabled="busy"
          :loading="busy"
          block
          @click="confirm"
        />
      </div>
    </div>
  </FlareBottomSheet>
</template>

<style scoped>
.flare-danger-confirm {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
}
.flare-danger-confirm__error {
  color: var(--flare-color-error-text);
}
/* On a sheet the keys are the sheet's own footer: full width, danger last, thumb-reachable. */
.flare-danger-confirm__actions {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  margin-top: var(--flare-size-spacing-md);
}
/* 弹窗里没有拇指够不够得着的问题,横排收在末端,和别的桌面弹窗一个样子。
   判据取自 FlareBottomSheet 画在面上的 data-flare-presentation —— 这里不再自己
   算一遍「现在是手机还是桌面」。 */
[data-flare-presentation="dialog"] .flare-danger-confirm,
[data-flare-presentation="drawer"] .flare-danger-confirm {
  padding: 0 var(--flare-size-spacing-lg) var(--flare-size-spacing-md);
}
[data-flare-presentation="dialog"] .flare-danger-confirm__actions,
[data-flare-presentation="drawer"] .flare-danger-confirm__actions {
  flex-direction: row;
  justify-content: flex-end;
}
[data-flare-presentation="dialog"] .flare-danger-confirm__actions :deep(.flare-button),
[data-flare-presentation="drawer"] .flare-danger-confirm__actions :deep(.flare-button) {
  width: auto;
  min-width: 96px;
}
</style>
