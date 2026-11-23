<script setup lang="ts">
import { nextTick, ref, watch } from "vue";
import FlareTextarea from "../form/FlareTextarea.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareComposerReplyStrip from "../composer/FlareComposerReplyStrip.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareMomentComment } from "../../shared/contracts";
const value = defineModel<string>({ default: "" });
const props = withDefaults(defineProps<{ replyTo?: FlareMomentComment; busy?: boolean; disabled?: boolean; error?: string; maxLength?: number }>(), { busy: false, disabled: false, maxLength: 500 });
const emit = defineEmits<{ submit: []; cancelReply: [] }>();
const { t } = useFlareI18n();
const root = ref<HTMLFormElement>();
let restoreFocus = false;
function focus() { root.value?.querySelector("textarea")?.focus({ preventScroll: true }); }
function submit() {
 if (props.busy || props.disabled || !value.value.trim()) return;
 restoreFocus = true;
 emit("submit");
}
watch(() => props.replyTo?.id, id => { if (id && !props.busy && !props.disabled) void nextTick(focus); });
watch(() => props.busy, (busy, wasBusy) => { if (wasBusy && !busy && restoreFocus && !props.disabled) { restoreFocus = false; void nextTick(focus); } });
</script>
<template>
 <form ref="root" class="flare-comment-composer" :aria-label="t('moment.comment')" :aria-busy="busy" @submit.prevent="submit">
  <FlareComposerReplyStrip v-if="replyTo" :sender-name="replyTo.author.name" :summary="replyTo.text" :label="t('moment.replyTo')" :disabled="busy || disabled" @cancel="!busy && !disabled && emit('cancelReply')" />
  <p v-if="error" class="flare-comment-composer__error" role="alert">{{ error }}</p>
  <div class="flare-comment-composer__row" :class="{ 'is-counted': value.length >= maxLength * 0.8 }">
   <FlareTextarea v-model="value" :aria-label="replyTo ? t('moment.replyToUser', { name: replyTo.author.name }) : t('moment.comment')" :placeholder="t('moment.commentPlaceholder')" size="sm" :rows="1" :max-rows="3" :maxlength="maxLength" :show-count="value.length >= maxLength * 0.8" :disabled="busy || disabled" @enter="submit" />
   <FlareButton size="sm" :loading="busy" :disabled="busy || disabled || !value.trim()" @click="submit">{{ t(error ? 'common.retry' : 'composerSendButton.label') }}</FlareButton>
  </div>
 </form>
</template>
<style scoped>
.flare-comment-composer { display: flex; flex-direction: column; gap: var(--flare-size-spacing-xs); width: 100%; box-sizing: border-box; padding-bottom: var(--flare-size-spacing-sm); min-width: 0; min-height: 0; max-height: calc(var(--flare-visible-viewport-height, 100dvh) - var(--flare-size-layout-touch-target) - var(--flare-size-spacing-lg)); overflow-y: auto; overscroll-behavior: contain; }
.flare-comment-composer__row { display: flex; align-items: stretch; gap: var(--flare-size-spacing-sm); min-height: var(--flare-size-layout-control-height-md); }
.flare-comment-composer__row.is-counted { min-height: calc(var(--flare-size-layout-control-height-sm) * 2); }
.flare-comment-composer__row > :first-child { flex: 1; min-width: 0; }
.flare-comment-composer__row > :last-child { flex: none; align-self: flex-end; }
.flare-comment-composer__error { margin: 0; flex: none; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-error-text); overflow-wrap: anywhere; }
</style>
