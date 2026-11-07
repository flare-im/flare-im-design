<script setup lang="ts">
// The update prompt: the SDK's update status in as plain values, the kit's words, progress and actions out, and every
// action back to the host. What shows when is utils/updatePrompt.ts (spec/update-prompt-vectors.json), the same in every
// kit. The component holds no SDK and never closes itself: `open` is the host's.
//
// The three forms are the kit's own surfaces: `sheet` is FlareBottomSheet, `modal` FlareModal, `fullscreen` FlareModal
// over the whole window with a FlareScreen page in it. An action is drawn only while the host listens for it. The scrim,
// Escape and platform back ask for `later`, so they do nothing on a forced prompt or one nobody can postpone.
//
// The percent changes all the time, so it stays out of the live region: the title and the message are announced when
// they change, politely, or assertively on a forced prompt.
import { computed, getCurrentInstance } from "vue";
import { formatBytes } from "../../shared/contracts/storage-usage";
import type { FlareButtonVariant } from "../../shared/contracts";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import {
  flareUpdatePrompt,
  flareUpdateVersionShown,
  type FlareUpdateFallbackTarget,
  type FlareUpdateProgress,
  type FlareUpdatePromptAction,
  type FlareUpdatePromptForm,
  type FlareUpdatePromptMessage,
  type FlareUpdatePromptTitle,
} from "../../utils/updatePrompt";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareModal from "../general/FlareModal.vue";
import FlareProgressBar from "../general/FlareProgressBar.vue";
import FlareScreen from "../layout/FlareScreen.vue";

const props = withDefaults(
  defineProps<{
    /** The prompt is on screen. */
    open: boolean;
    /** `sheet`, `modal` or `fullscreen`: `UpdateStatus.prompt`. */
    form: FlareUpdatePromptForm;
    /** `UpdateStatus.release?.version`; blank draws no version line. */
    version?: string | null;
    /** `UpdateStatus.release.notes`, already in the reader's language. */
    notes?: readonly string[];
    /** `UpdateStatus.blockReason`, already in the reader's language: a forced offer says it in place of its fixed words. */
    reason?: string | null;
    /** `UpdateStatus.release.sizeBytes`; null on a store update. */
    sizeBytes?: number | null;
    /** `UpdateStatus.release.mandatory`: nothing here can postpone it. */
    mandatory?: boolean;
    /** `UpdateStatus.state`. */
    state?: string | null;
    /** `UpdateStatus.progress`, as it arrives. */
    progress?: FlareUpdateProgress | null;
    /** `UpdateStatus.error.code`. */
    errorCode?: string | null;
    /** `UpdateStatus.error.retryable`. */
    retryable?: boolean;
    /** Where the fallback goes: the website on a direct install, the app store otherwise. */
    fallbackTarget?: FlareUpdateFallbackTarget;
    /** A forced prompt may step aside into read-only browsing. */
    canContinueReadOnly?: boolean;
  }>(),
  {
    version: null,
    notes: () => [],
    reason: null,
    sizeBytes: null,
    mandatory: false,
    state: null,
    progress: null,
    errorCode: null,
    retryable: true,
    fallbackTarget: "website",
    canContinueReadOnly: false,
  },
);
const emit = defineEmits<{
  (e: "update"): void;
  (e: "later"): void;
  (e: "skip"): void;
  (e: "retry"): void;
  (e: "fallback"): void;
  (e: "continueReadOnly"): void;
}>();
const instance = getCurrentInstance();
const { t } = useFlareI18nOptional();
const listens = (listener: string) => Boolean(instance?.vnode.props?.[listener]);

const model = computed(() => flareUpdatePrompt(props));

const TITLE_KEYS: Record<FlareUpdatePromptTitle, string> = {
  available: "updatePrompt.titleAvailable",
  required: "updatePrompt.titleRequired",
  metered: "updatePrompt.titleMetered",
  downloading: "updatePrompt.titleDownloading",
  verifying: "updatePrompt.titleVerifying",
  ready: "updatePrompt.titleReady",
  installing: "updatePrompt.titleInstalling",
  failed: "updatePrompt.titleFailed",
};
const MESSAGE_KEYS: Record<Exclude<FlareUpdatePromptMessage, "reason">, string> = {
  required: "updatePrompt.messageRequired",
  requiredReadOnly: "updatePrompt.messageRequiredReadOnly",
  metered: "updatePrompt.messageMetered",
  meteredUnknown: "updatePrompt.messageMeteredUnknown",
  ready: "updatePrompt.messageReady",
  manifestUnavailable: "updatePrompt.failManifestUnavailable",
  manifestRejected: "updatePrompt.failManifestRejected",
  noArtifact: "updatePrompt.failNoArtifact",
  insufficientSpace: "updatePrompt.failInsufficientSpace",
  downloadFailed: "updatePrompt.failDownload",
  hashMismatch: "updatePrompt.failHashMismatch",
  installFailed: "updatePrompt.failInstall",
  signatureMismatch: "updatePrompt.failSignatureMismatch",
  downgradeRejected: "updatePrompt.failDowngrade",
  notSkippable: "updatePrompt.failNotSkippable",
  unknown: "updatePrompt.failUnknown",
};
const ACTIONS: Record<FlareUpdatePromptAction, { listener: string; perform: () => void }> = {
  update: { listener: "onUpdate", perform: () => emit("update") },
  continueDownload: { listener: "onUpdate", perform: () => emit("update") },
  restart: { listener: "onUpdate", perform: () => emit("update") },
  retry: { listener: "onRetry", perform: () => emit("retry") },
  fallback: { listener: "onFallback", perform: () => emit("fallback") },
  later: { listener: "onLater", perform: () => emit("later") },
  background: { listener: "onLater", perform: () => emit("later") },
  skip: { listener: "onSkip", perform: () => emit("skip") },
  continueReadOnly: { listener: "onContinueReadOnly", perform: () => emit("continueReadOnly") },
};

function actionText(action: FlareUpdatePromptAction): string {
  switch (action) {
    case "update": return t("connection.update");
    case "continueDownload": return t("updatePrompt.continueDownload");
    case "restart": return t("updatePrompt.restart");
    case "retry": return t("updatePrompt.retry");
    case "fallback": return t(props.fallbackTarget === "store" ? "updatePrompt.fallbackStore" : "updatePrompt.fallbackWebsite");
    case "later": return t("updatePrompt.later");
    case "background": return t("updatePrompt.background");
    case "skip": return t("updatePrompt.skip");
    case "continueReadOnly": return t("updatePrompt.continueReadOnly");
  }
}

function actionVariant(action: FlareUpdatePromptAction, index: number): FlareButtonVariant {
  if (index === 0) return "primary";
  return action === "fallback" || action === "continueReadOnly" ? "secondary" : "quiet";
}

const actions = computed(() => model.value.actions.filter((action) => listens(ACTIONS[action].listener)));
const sizeText = computed(() => formatBytes(props.sizeBytes));
const titleText = computed(() => t(TITLE_KEYS[model.value.title]));
const messageText = computed(() => {
  const { message } = model.value;
  if (message === null) return null;
  if (message === "reason") return props.reason;
  const text = t(MESSAGE_KEYS[message]);
  return message === "metered" ? `${text} ${sizeText.value}` : text;
});
const versionText = computed(() => {
  if (!flareUpdateVersionShown(props.version)) return null;
  const version = `${t("updatePrompt.version")} ${props.version}`;
  return sizeText.value ? `${version} · ${sizeText.value}` : version;
});
const progressText = computed(() => {
  const percent = model.value.progress?.percent ?? null;
  if (percent === null) return null;
  const received = formatBytes(props.progress?.received);
  const total = formatBytes(props.progress?.total);
  return received && total ? `${percent}% · ${received} / ${total}` : `${percent}%`;
});
const spoken = computed(() => (messageText.value ? `${titleText.value} ${messageText.value}` : titleText.value));
const showNotes = computed(() => model.value.notes && props.notes.length > 0);

const dismissible = computed(() => model.value.dismissible && listens("onLater"));
const surface = computed(() => (props.form === "sheet" ? FlareBottomSheet : FlareModal));
const surfaceProps = computed(() => {
  const shared = { open: props.open, title: titleText.value, titleHidden: true, dismissible: dismissible.value };
  if (props.form === "sheet") return shared;
  const fullscreen = props.form === "fullscreen";
  return { ...shared, showClose: false, fullscreen, scrollable: !fullscreen };
});
const page = computed(() => (props.form === "fullscreen" ? FlareScreen : "div"));
const pageProps = computed(() => (props.form === "fullscreen" ? { surface: "surface", padded: true } : {}));

function dismiss() {
  if (dismissible.value) emit("later");
}
</script>

<template>
  <component :is="surface" v-bind="surfaceProps" @close="dismiss">
    <component :is="page" v-bind="pageProps">
      <div class="flare-update-prompt" :class="`flare-update-prompt--${form}`" :data-flare-update-phase="model.phase">
        <span class="flare-update-prompt__spoken" :role="model.live === 'assertive' ? 'alert' : 'status'" :aria-live="model.live" aria-atomic="true">{{ spoken }}</span>
        <header class="flare-update-prompt__header">
          <h2 class="flare-update-prompt__title">{{ titleText }}</h2>
          <p v-if="versionText" class="flare-update-prompt__version">{{ versionText }}</p>
        </header>
        <p v-if="messageText" class="flare-update-prompt__message">{{ messageText }}</p>
        <div v-if="model.progress" class="flare-update-prompt__progress">
          <FlareProgressBar
            :value="model.progress.value"
            :indeterminate="model.progress.value === null"
            :label="titleText"
          />
          <p v-if="progressText" class="flare-update-prompt__progress-text">{{ progressText }}</p>
        </div>
        <section v-if="showNotes" class="flare-update-prompt__notes">
          <h3 class="flare-update-prompt__notes-title">{{ t("updatePrompt.notes") }}</h3>
          <ul class="flare-update-prompt__notes-list">
            <li v-for="(note, index) in notes" :key="index">{{ note }}</li>
          </ul>
        </section>
        <footer v-if="actions.length" class="flare-update-prompt__actions">
          <FlareButton
            v-for="(action, index) in actions"
            :key="action"
            :label="actionText(action)"
            :variant="actionVariant(action, index)"
            size="lg"
            block
            :data-flare-update-action="action"
            @click="ACTIONS[action].perform()"
          />
        </footer>
      </div>
    </component>
  </component>
</template>

<style scoped>
.flare-update-prompt {
  position: relative;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-lg);
  min-width: 0;
  padding: var(--flare-size-spacing-lg);
  color: var(--flare-color-text-primary);
}
.flare-update-prompt--fullscreen {
  width: min(100%, var(--flare-size-component-sheet-dialog-width));
  margin-inline: auto;
  padding: 0;
}
.flare-update-prompt__spoken {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
.flare-update-prompt__header,
.flare-update-prompt__progress,
.flare-update-prompt__notes {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
}
.flare-update-prompt__title {
  margin: 0;
  font-size: var(--flare-text-section-font-size);
  font-weight: var(--flare-size-font-weight-semibold);
  line-height: var(--flare-text-section-line-height);
  overflow-wrap: anywhere;
}
.flare-update-prompt__version,
.flare-update-prompt__progress-text {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-caption-line-height);
  overflow-wrap: anywhere;
}
.flare-update-prompt__message {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-body-font-size);
  line-height: var(--flare-text-body-line-height);
  overflow-wrap: anywhere;
}
.flare-update-prompt__notes-title {
  margin: 0;
  font-size: var(--flare-text-body-font-size);
  font-weight: var(--flare-size-font-weight-semibold);
  line-height: var(--flare-text-body-line-height);
}
.flare-update-prompt__notes-list {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-xs);
  margin: 0;
  padding-inline-start: var(--flare-size-spacing-lg);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-body-font-size);
  line-height: var(--flare-text-body-line-height);
  overflow-wrap: anywhere;
}
.flare-update-prompt__actions {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
}
</style>
