<script setup lang="ts">
// Body for a message whose content type this client cannot render. The raw type
// token is kept as a diagnostic line, never used as the message body — a reader
// who sees only `[flare.poll.v2]` learns nothing and it reads as a rendering bug.
// Spec: Message/UnknownMessage.
import { computed, getCurrentInstance } from 'vue';
import FlareIcon from '../general/FlareIcon.vue';
import { unknownMessagePresentation } from '../../shared/contracts/unknown-message';

const props = withDefaults(defineProps<{
  /** Raw wire content type, e.g. "flare.poll.v2". */
  contentType?: string;
  /** Human name for the type when the host knows it. */
  label?: string;
  /** Plain-text fallback the sender's client attached. */
  summary?: string;
  self?: boolean;
  /** Host action, e.g. "了解如何升级"; omit the listener and no button is rendered. */
  actionText?: string;
  hint?: string;
  unsupportedText?: string;
  diagnosticLabel?: string;
}>(), {
  self: false,
  hint: '当前版本无法显示这条消息',
  unsupportedText: '不支持的消息类型',
  diagnosticLabel: '消息类型',
  actionText: '',
});

const emit = defineEmits<{ action: [] }>();

const instance = getCurrentInstance();
/** No bound listener means the host cannot act, so no button is offered. */
const hasAction = computed(() => Boolean(instance?.vnode.props?.onAction) && props.actionText.trim().length > 0);

const view = computed(() => unknownMessagePresentation({
  contentType: props.contentType,
  label: props.label,
  summary: props.summary,
  hint: props.hint,
  unsupportedText: props.unsupportedText,
}));
</script>

<template>
  <div class="flare-unknown-message" :class="{ 'flare-unknown-message--self': self }">
    <div class="flare-unknown-message__head">
      <span class="flare-unknown-message__icon" aria-hidden="true"><FlareIcon name="info" :size="16" /></span>
      <span class="flare-unknown-message__title">{{ view.title }}</span>
    </div>
    <p class="flare-unknown-message__body">{{ view.body }}</p>
    <p v-if="view.diagnostic" class="flare-unknown-message__diagnostic">
      <span class="flare-unknown-message__diagnostic-label">{{ diagnosticLabel }}</span>
      <code dir="ltr">{{ view.diagnostic }}</code>
    </p>
    <button v-if="hasAction" type="button" class="flare-unknown-message__action" @click="emit('action')">
      {{ actionText }}
    </button>
  </div>
</template>

<style scoped>
.flare-unknown-message {
  display: grid;
  gap: 4px;
  min-width: 0;
  max-width: 100%;
}
.flare-unknown-message__head {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--flare-color-text-secondary, #626978);
}
.flare-unknown-message--self .flare-unknown-message__head,
.flare-unknown-message--self .flare-unknown-message__body,
.flare-unknown-message--self .flare-unknown-message__diagnostic {
  color: inherit;
  opacity: 0.92;
}
.flare-unknown-message__icon { display: inline-flex; flex: 0 0 auto; }
.flare-unknown-message__title { font-size: 13px; font-weight: 600; }
.flare-unknown-message__body {
  margin: 0;
  font-size: 14px;
  overflow-wrap: anywhere;
  color: var(--flare-color-text-primary, #20232D);
}
.flare-unknown-message--self .flare-unknown-message__body { color: inherit; }
.flare-unknown-message__diagnostic {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 6px;
  margin: 0;
  font-size: 12px;
  color: var(--flare-color-text-tertiary, #687182);
}
.flare-unknown-message__diagnostic code {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  overflow-wrap: anywhere;
  unicode-bidi: isolate;
}
.flare-unknown-message__action {
  justify-self: start;
  min-height: 48px;
  padding: 0 12px;
  margin-top: 2px;
  border: 1px solid var(--flare-color-border-primary, #E3E5EB);
  border-radius: var(--flare-size-radius-md, 8px);
  background: transparent;
  color: inherit;
  font: inherit;
  cursor: pointer;
}
.flare-unknown-message__action:focus-visible {
  outline: 2px solid var(--flare-color-primary, #7047D6);
  outline-offset: 2px;
}
</style>
