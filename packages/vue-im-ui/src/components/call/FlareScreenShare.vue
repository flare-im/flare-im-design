<script setup lang="ts">
// Screen-share control and status panel for an ongoing call. Capture, source
// enumeration and encoding belong to the host / RTC plugin; this view only shows
// the reported state and dispatches start / stop / cancel intents.
// Permission denial is NOT handled here: the host renders
// PermissionPrompt(kind="screen", state="denied") instead.
import { computed } from 'vue';
import FlareIcon from '../general/FlareIcon.vue';
import {
  screenShareActions, screenShareIconName, screenShareTone,
  type ScreenShareState,
} from '../../shared/contracts/screen-share';
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{
  state: ScreenShareState;
  /** What is being shared, e.g. "整个屏幕" / "Chrome 窗口"; shown while sharing. */
  sourceLabel?: string;
  /** Who is sharing; shown while viewing. */
  presenterName?: string;
  /** Extra host explanation, e.g. a bitrate-limited notice or why it is unavailable. */
  detail?: string;
  busy?: boolean;
  /** Host can start sharing (binds `@start`); false hides the button. Native derives this from `onStart != null`. */
  hasStart?: boolean;
  /** Host can stop its own share (binds `@stop`); false hides the button. Native derives this from `onStop != null`. */
  hasStop?: boolean;
  /** Host can cancel a pending request (binds `@cancel`); false hides the button. Native derives this from `onCancel != null`. */
  hasCancel?: boolean;
  title?: string;
  idleText?: string;
  requestingText?: string;
  sharingText?: string;
  viewingText?: string;
  unavailableText?: string;
  sourceRowLabel?: string;
  presenterRowLabel?: string;
  startText?: string;
  stopText?: string;
  cancelText?: string;
}>(), {
  busy: false,
  hasStart: false,
  hasStop: false,
  hasCancel: false,
});
const { t } = useFlareI18n();
const strings = computed(() => ({
  title: props.title ?? t("screenShare.title"),
  idleText: props.idleText ?? t("screenShare.idle"),
  requestingText: props.requestingText ?? t("screenShare.requesting"),
  sharingText: props.sharingText ?? t("screenShare.sharing"),
  viewingText: props.viewingText ?? t("screenShare.viewing"),
  unavailableText: props.unavailableText ?? t("screenShare.unavailable"),
  sourceRowLabel: props.sourceRowLabel ?? t("screenShare.sourceRow"),
  presenterRowLabel: props.presenterRowLabel ?? t("screenShare.presenterRow"),
  startText: props.startText ?? t("screenShare.start"),
  stopText: props.stopText ?? t("screenShare.stop"),
  cancelText: props.cancelText ?? t("screenShare.cancel"),
}));
const emit = defineEmits<{ start: []; stop: []; cancel: [] }>();

const stateText = computed(() => ({
  idle: strings.value.idleText,
  requesting: strings.value.requestingText,
  sharing: strings.value.sharingText,
  viewing: strings.value.viewingText,
  unavailable: strings.value.unavailableText,
})[props.state]);
const stateIcon = computed(() => screenShareIconName(props.state));
const tone = computed(() => screenShareTone(props.state));
const requesting = computed(() => props.state === 'requesting');

// Visibility ignores busy (buttons stay in place); busy only disables them.
const actions = computed(() => screenShareActions(props.state, {
  hasStart: props.hasStart, hasStop: props.hasStop, hasCancel: props.hasCancel, busy: false,
}));
const source = computed(() => (props.state === 'sharing' ? props.sourceLabel?.trim() : ''));
const presenter = computed(() => (props.state === 'viewing' ? props.presenterName?.trim() : ''));
const detailText = computed(() => props.detail?.trim());
</script>

<template>
  <section
    class="flare-screen-share"
    :class="[`flare-screen-share--${tone}`, { 'flare-screen-share--active': state === 'sharing' }]"
    :aria-label="strings.title"
    :aria-busy="busy"
  >
    <h3 class="flare-screen-share__title">{{ strings.title }}</h3>
    <div class="flare-screen-share__status" role="status" aria-live="polite">
      <span class="flare-screen-share__icon" aria-hidden="true"><FlareIcon :name="stateIcon" :size="20" /></span>
      <div class="flare-screen-share__status-body">
        <strong class="flare-screen-share__state">{{ stateText }}</strong>
        <p v-if="detailText" class="flare-screen-share__detail">{{ detailText }}</p>
      </div>
    </div>
    <progress v-if="requesting" class="flare-screen-share__progress" :aria-label="strings.requestingText" />
    <dl v-if="source || presenter" class="flare-screen-share__meta">
      <template v-if="source"><dt>{{ strings.sourceRowLabel }}</dt><dd>{{ source }}</dd></template>
      <template v-if="presenter"><dt>{{ strings.presenterRowLabel }}</dt><dd>{{ presenter }}</dd></template>
    </dl>
    <div v-if="actions.start || actions.stop || actions.cancel" class="flare-screen-share__actions">
      <button
        v-if="actions.start"
        type="button"
        class="flare-screen-share__btn flare-screen-share__btn--primary"
        :disabled="!actions.enabled"
        @click="emit('start')"
      >
        <FlareIcon name="devices" :size="16" /><span>{{ strings.startText }}</span>
      </button>
      <button
        v-if="actions.stop"
        type="button"
        class="flare-screen-share__btn flare-screen-share__btn--stop"
        :disabled="!actions.enabled"
        @click="emit('stop')"
      >
        <FlareIcon name="block" :size="16" /><span>{{ strings.stopText }}</span>
      </button>
      <button
        v-if="actions.cancel"
        type="button"
        class="flare-screen-share__btn"
        :disabled="!actions.enabled"
        @click="emit('cancel')"
      >{{ strings.cancelText }}</button>
    </div>
  </section>
</template>

<style scoped>
.flare-screen-share {
  display: grid;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  padding: var(--flare-size-spacing-lg);
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-xl);
}
.flare-screen-share--neutral { --flare-tone: var(--flare-color-text-secondary); }
.flare-screen-share--warning { --flare-tone: var(--flare-color-warning); }
.flare-screen-share--success { --flare-tone: var(--flare-color-success); }
.flare-screen-share--info { --flare-tone: var(--flare-color-info); }

.flare-screen-share__title { margin: 0; font-size: var(--flare-size-font-size-2xl); font-weight: 600; }
.flare-screen-share__status {
  display: flex;
  gap: var(--flare-size-spacing-md);
  align-items: flex-start;
  padding: var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-lg);
  color: var(--flare-tone);
  background: color-mix(in srgb, var(--flare-tone) 10%, transparent);
  border: 1px solid color-mix(in srgb, var(--flare-tone) 24%, transparent);
}
.flare-screen-share--active .flare-screen-share__status {
  background: color-mix(in srgb, var(--flare-tone) 16%, transparent);
  border-color: color-mix(in srgb, var(--flare-tone) 44%, transparent);
}
.flare-screen-share__icon { flex: none; display: inline-flex; margin-top: 1px; }
.flare-screen-share__status-body { min-width: 0; flex: 1; display: grid; gap: var(--flare-size-spacing-xs); }
.flare-screen-share__state { font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-primary); overflow-wrap: anywhere; }
.flare-screen-share__detail { margin: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-screen-share__progress { width: 100%; height: 4px; accent-color: var(--flare-tone); }

.flare-screen-share__meta {
  display: grid;
  grid-template-columns: max-content minmax(0, 1fr);
  gap: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg);
  margin: 0;
  font-size: var(--flare-size-font-size-md);
}
.flare-screen-share__meta dt { color: var(--flare-color-text-secondary); }
.flare-screen-share__meta dd { margin: 0; min-width: 0; overflow-wrap: anywhere; }

.flare-screen-share__actions { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-sm); }
.flare-screen-share__btn {
  display: inline-flex; align-items: center; justify-content: center; gap: var(--flare-size-spacing-xs);
  min-height: var(--flare-size-layout-touch-target); min-width: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  font: inherit; font-size: var(--flare-size-font-size-lg); cursor: pointer;
  color: var(--flare-color-text-primary); background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-md);
}
.flare-screen-share__btn--primary { color: #fff; background: var(--flare-color-primary); border-color: var(--flare-color-primary); }
.flare-screen-share__btn--primary:hover:not(:disabled) { background: var(--flare-color-primary-hover); }
.flare-screen-share__btn--stop { color: var(--flare-color-error-text); border-color: var(--flare-color-error); }
.flare-screen-share__btn--stop:hover:not(:disabled) { background: color-mix(in srgb, var(--flare-color-error) 10%, transparent); }
.flare-screen-share__btn:hover:not(:disabled):not(.flare-screen-share__btn--primary):not(.flare-screen-share__btn--stop) { background: var(--flare-color-bg-hover); }
.flare-screen-share__btn:disabled {
  cursor: not-allowed; color: var(--flare-color-text-disabled);
  background: var(--flare-color-bg-disabled); border-color: var(--flare-color-border-primary);
}
.flare-screen-share__btn:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
</style>
