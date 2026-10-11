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
//
// A console write that is recorded asks for more than a yes: `reason` takes the audit reason the
// write carries (required unless `optional`, held to `maxBytes` of UTF-8), and `confirmPhrase` makes
// the person type the target's name before an irreversible step. The confirm key waits for both, and
// `confirm` hands the trimmed reason over. Both are Vue only (web consoles); the native presenters
// keep the plain confirmation.
import { computed, ref, watch } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { confirmReasonBytes, type FlareConfirmInput, type FlareConfirmReason } from "../../shared/contracts/scenes";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareFormField from "../form/FlareFormField.vue";

const props = defineProps<{
  open: boolean;
  title: string;
  description: string;
  target: string;
  busy?: boolean;
  error?: string;
  confirmText?: string;
  cancelText?: string;
  /** Ask for a reason (an audit reason) before the confirm key works. */
  reason?: FlareConfirmReason;
  /** Text the person types to confirm — the target's name or code — before the confirm key works. */
  confirmPhrase?: string;
}>();
const { t } = useFlareI18n();
const strings = computed(() => ({
  confirmText: props.confirmText ?? t("dangerConfirm.confirm"),
  cancelText: props.cancelText ?? t("dangerConfirm.cancel"),
}));
const emit = defineEmits<{ confirm: [input: FlareConfirmInput]; cancel: [] }>();

const reasonText = ref("");
const phraseText = ref("");
// A new question starts empty; a failed attempt keeps what was typed, so a retry is one press.
watch(() => props.open, (open) => {
  if (!open) return;
  reasonText.value = "";
  phraseText.value = "";
});
// Not `reason`: a <script setup> binding of a prop's name shadows the prop in the template.
const typedReason = computed(() => reasonText.value.trim());
const reasonTooLong = computed(() => props.reason?.maxBytes != null && confirmReasonBytes(typedReason.value) > props.reason.maxBytes);
const reasonMissing = computed(() => Boolean(props.reason) && !props.reason?.optional && !typedReason.value);
const phraseMatches = computed(() => !props.confirmPhrase || phraseText.value.trim() === props.confirmPhrase);
const ready = computed(() => !reasonMissing.value && !reasonTooLong.value && phraseMatches.value);

function confirm(): void { if (!props.busy && ready.value) emit("confirm", { reason: props.reason ? typedReason.value : "" }); }
function cancel(): void { if (!props.busy) emit("cancel"); }
</script>

<template>
  <FlareBottomSheet :open="open" :title="title" :dismissible="!busy" @close="cancel">
    <div class="flare-danger-confirm">
      <p>{{ description }}</p>
      <strong>{{ target }}</strong>
      <FlareFormField
        v-if="reason"
        class="flare-danger-confirm__reason"
        :label="reason.label"
        :required="!reason.optional"
        :hint="reason.hint"
        :error="reasonTooLong ? t('dangerConfirm.reasonTooLong', { max: reason.maxBytes ?? 0 }) : undefined"
      >
        <FlareInput v-model="reasonText" :placeholder="reason.placeholder" :max-length="reason.maxLength" :disabled="busy" />
      </FlareFormField>
      <FlareFormField v-if="confirmPhrase" class="flare-danger-confirm__phrase" :label="t('dangerConfirm.phraseLabel', { phrase: confirmPhrase })">
        <FlareInput v-model="phraseText" monospace autocomplete="off" :disabled="busy" />
      </FlareFormField>
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
          :disabled="busy || !ready"
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
   判据取自面上的 data-flare-presentation(FlareBottomSheet 自己的面写 sheet,交给
   FlareModal 时 FlareModal 写 dialog)—— 这里不再自己算一遍「现在是手机还是桌面」。 */
[data-flare-presentation="dialog"] .flare-danger-confirm {
  padding: 0 var(--flare-size-spacing-lg) var(--flare-size-spacing-md);
}
[data-flare-presentation="dialog"] .flare-danger-confirm__actions {
  flex-direction: row;
  justify-content: flex-end;
}
[data-flare-presentation="dialog"] .flare-danger-confirm__actions :deep(.flare-button) {
  width: auto;
  min-width: 96px;
}
</style>
