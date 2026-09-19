<script setup lang="ts">
import { computed, nextTick, ref, watch } from "vue";
import { NButton, NInput, NModal, NSelect } from "naive-ui";
import { useCardHeadingLevel } from "../../composables/useCardHeadingLevel";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";

const { t } = useFlareI18n();
const platform = useFlarePlatformSafe();
/** Phone form factors get a bottom sheet, pointer form factors a centered modal: same fields, same events. */
const asSheet = computed(() => platform.capabilities.value.bottomSheet);

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

// naive-ui's card header is a heading with no level; the kit supplies one once the dialog is up.
useCardHeadingLevel(open, "start-dialog-modal");
</script>

<template>
  <component
    :is="asSheet ? FlareBottomSheet : NModal"
    v-bind="asSheet
      ? { open, title: t('startConversation.openConversation'), dismissible: !busy, class: 'start-dialog-sheet' }
      : { show: open, preset: 'card', title: t('startConversation.openConversation'), class: 'start-dialog-modal', autoFocus: false, trapFocus: true, maskClosable: !busy, style: 'max-width: 420px' }"
    @close="closeDialog"
    @update:show="(value: boolean) => { if (!value) closeDialog(); }"
  >
    <div class="start-dialog-form" data-flare-presentation="dialog" :data-flare-sheet="asSheet ? 'true' : undefined">
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
  </component>
</template>

<style scoped>
.start-dialog-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.start-dialog-field {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.start-dialog-field > span {
  color: var(--flare-color-text-secondary);
  font-size: 13px;
}

.start-dialog-hint {
  color: var(--flare-color-text-tertiary);
  font-size: 12px;
}

.start-dialog-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

.start-dialog-sheet .start-dialog-form {
  padding: 0 16px calc(16px + env(safe-area-inset-bottom, 0px));
}

.start-dialog-sheet .start-dialog-actions {
  flex-direction: column-reverse;
}
</style>
