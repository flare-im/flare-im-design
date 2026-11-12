<script setup lang="ts">
// Unified "permission missing / denied" panel. The host owns the actual
// permission state and the request / openSettings side effects; this view only
// explains the requirement and dispatches. Spec: General/PermissionPrompt.
//
// `softAsk` is the non-blocking invitation a host shows at a moment it picks (the
// first visit to the conversation list, say): no state chip, a "Not now" key, and
// for the notifications kind copy of its own — "Turn on notifications" while the
// system can still ask, "Open Settings" once it was turned off. It shows only while
// the person can act on it. `granted` renders nothing, so a host binds the
// platform's status as it is. `presentation="sheet"` hosts the prompt in the kit
// bottom sheet (BottomSheet auto: a sheet on the phone, a Modal elsewhere), where
// closing it by the scrim, Escape or back is a dismiss.
import { computed, getCurrentInstance, type FunctionalComponent } from 'vue';
import FlareIcon from './FlareIcon.vue';
import FlareButton from './FlareButton.vue';
import FlareBottomSheet from './FlareBottomSheet.vue';
import {
  defaultPermissionCopy, defaultPermissionStateLabel, permissionActions, permissionIcon, permissionPromptShows,
  permissionSoftAskHasOwnCopy, permissionStateIcon,
  type PermissionKind, type PermissionPresentation, type PermissionState,
} from '../../shared/contracts/permission-prompt';
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{
  kind: PermissionKind;
  state: PermissionState;
  /** What the permission unlocks, e.g. "发送语音消息"; embedded in the default description. */
  featureLabel?: string;
  /** Extra host explanation shown under the description. */
  detail?: string;
  busy?: boolean;
  /** Inline single-row mode for placing above a composer; default is a card. */
  compact?: boolean;
  /** The non-blocking invitation: no state chip, "Not now", shown only while the person can act. */
  softAsk?: boolean;
  /** `inline` sits in the page; `sheet` hosts the prompt in the kit bottom sheet. */
  presentation?: PermissionPresentation;
  /** Sheet presentation only: whether the sheet is open. */
  open?: boolean;
  title?: string;
  description?: string;
  stateText?: string;
  requestText?: string;
  openSettingsText?: string;
  dismissText?: string;
}>(), { busy: false, compact: false, softAsk: false, presentation: 'inline', open: true });
const { t } = useFlareI18n();

const emit = defineEmits<{ request: []; openSettings: []; dismiss: [] }>();

const instance = getCurrentInstance();
/** Read at render time: a listener the host did not bind means the action is not offered. */
function hasListener(name: 'onRequest' | 'onOpenSettings' | 'onDismiss'): boolean {
  return !!instance?.vnode.props?.[name];
}

const shows = computed(() => permissionPromptShows(props.state, props.softAsk));
const sheet = computed(() => props.presentation === 'sheet');
const ownSoftAsk = computed(() => props.softAsk && permissionSoftAskHasOwnCopy(props.kind));
const copy = computed(() => defaultPermissionCopy(props.kind, props.state, props.featureLabel));
const title = computed(() => props.title ?? (ownSoftAsk.value ? t("permissionPrompt.softAsk.notificationsTitle") : copy.value.title));
const description = computed(() => {
  if (props.description !== undefined) return props.description;
  if (!ownSoftAsk.value) return copy.value.description;
  return props.state === 'denied' ? t("permissionPrompt.softAsk.notificationsDeniedBody") : t("permissionPrompt.softAsk.notificationsBody");
});
const stateText = computed(() => props.stateText ?? defaultPermissionStateLabel(props.state));
const requestText = computed(() => props.requestText ?? (ownSoftAsk.value ? t("permissionPrompt.softAsk.notificationsAction") : copy.value.primaryLabel));
const openSettingsText = computed(() => props.openSettingsText ?? (props.softAsk ? t("permissionPrompt.openSettings") : copy.value.primaryLabel));
const dismissText = computed(() => props.dismissText ?? (props.softAsk ? t("permissionPrompt.notNow") : t("permissionPrompt.dismiss")));
const actions = () => permissionActions(props.state, {
  hasRequest: hasListener('onRequest'), hasOpenSettings: hasListener('onOpenSettings'), hasDismiss: hasListener('onDismiss'), busy: props.busy,
});
const buttonSize = computed(() => (props.compact && !sheet.value ? 'md' : 'lg'));

/** The inline presentation: the prompt itself, with no surface around it. */
const InlineSurface: FunctionalComponent = (_, { slots }) => slots.default?.();
InlineSurface.inheritAttrs = false;
const surface = computed(() => (sheet.value ? FlareBottomSheet : InlineSurface));
// The prompt draws its own heading, so the sheet keeps the title as its accessible name only.
const surfaceProps = computed(() => (sheet.value
  ? { open: props.open && shows.value, title: title.value, titleHidden: true, dismissible: !props.busy && hasListener('onDismiss') }
  : {}));
function onSurfaceClose() { if (!props.busy && hasListener('onDismiss')) emit('dismiss'); }
// On a sheet the surface owns Escape (and closes as a dismiss); handling it here too would dismiss twice.
function onEscape() { if (!sheet.value && !props.busy && hasListener('onDismiss')) emit('dismiss'); }
</script>

<template>
  <component :is="surface" v-bind="surfaceProps" @close="onSurfaceClose">
    <section
      v-if="shows"
      class="flare-permission-prompt"
      :class="[`flare-permission-prompt--${state}`, {
        'flare-permission-prompt--compact': compact && !sheet,
        'flare-permission-prompt--sheet': sheet,
        'flare-permission-prompt--soft-ask': softAsk,
      }]"
      role="region"
      :aria-label="title"
      :aria-busy="busy"
      tabindex="-1"
      @keydown.escape.prevent="onEscape"
    >
      <span class="flare-permission-prompt__icon" aria-hidden="true">
        <FlareIcon :name="permissionIcon[kind]" :size="compact && !sheet ? 20 : 26" />
      </span>
      <div class="flare-permission-prompt__body">
        <div class="flare-permission-prompt__heading">
          <h3 class="flare-permission-prompt__title">{{ title }}</h3>
          <span v-if="!softAsk" class="flare-permission-prompt__state" role="status">
            <FlareIcon :name="permissionStateIcon[state]" :size="14" />
            <span>{{ stateText }}</span>
          </span>
        </div>
        <p class="flare-permission-prompt__description">{{ description }}</p>
        <p v-if="detail" class="flare-permission-prompt__detail">{{ detail }}</p>
      </div>
      <div v-if="actions().request || actions().openSettings || actions().dismiss" class="flare-permission-prompt__actions">
        <FlareButton
          v-if="actions().request"
          :label="requestText"
          variant="primary"
          :size="buttonSize"
          :block="sheet"
          :loading="busy"
          @click="emit('request')"
        />
        <FlareButton
          v-if="actions().openSettings"
          :label="openSettingsText"
          variant="primary"
          :size="buttonSize"
          :block="sheet"
          :loading="busy"
          @click="emit('openSettings')"
        />
        <FlareButton
          v-if="actions().dismiss"
          :label="dismissText"
          variant="secondary"
          :size="buttonSize"
          :block="sheet"
          :disabled="busy"
          @click="emit('dismiss')"
        />
      </div>
    </section>
  </component>
</template>

<style scoped>
.flare-permission-prompt {
  /* 两条线：tone 画色块，tone-text 写字。同一个 #6D5DF6 当背景够用，当 11px
     文字只有 3.72:1，所以文字走 *-text 那一族 token。 */
  --flare-permission-tone: var(--flare-color-info);
  --flare-permission-tone-text: var(--flare-color-info-text);
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  gap: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  align-items: start;
  min-width: 0;
  padding: var(--flare-size-spacing-lg);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
}
.flare-permission-prompt:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-permission-prompt--undetermined { --flare-permission-tone: var(--flare-color-info); --flare-permission-tone-text: var(--flare-color-info-text); }
.flare-permission-prompt--denied { --flare-permission-tone: var(--flare-color-error); --flare-permission-tone-text: var(--flare-color-error-text); }
.flare-permission-prompt--restricted { --flare-permission-tone: var(--flare-color-warning); --flare-permission-tone-text: var(--flare-color-warning-text); }
.flare-permission-prompt--unavailable { --flare-permission-tone: var(--flare-color-text-secondary); --flare-permission-tone-text: var(--flare-color-text-secondary); }

.flare-permission-prompt__icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  flex: none;
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-color-primary-text);
  background: color-mix(in srgb, var(--flare-color-primary) 12%, transparent);
}
.flare-permission-prompt__body { min-width: 0; display: grid; gap: var(--flare-size-spacing-xs); }
.flare-permission-prompt__heading { display: flex; flex-wrap: wrap; align-items: center; gap: var(--flare-size-spacing-sm); }
.flare-permission-prompt__title { margin: 0; font-size: var(--flare-size-font-size-xl); font-weight: 600; overflow-wrap: anywhere; }
.flare-permission-prompt__state {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  font-size: var(--flare-size-font-size-xs);
  font-weight: 600;
  line-height: var(--flare-size-line-height-normal);
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-permission-tone-text);
  background: color-mix(in srgb, var(--flare-permission-tone) 12%, transparent);
  white-space: nowrap;
}
.flare-permission-prompt__description {
  margin: 0;
  font-size: var(--flare-size-font-size-md);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-permission-prompt__detail {
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-tertiary);
  overflow-wrap: anywhere;
}
.flare-permission-prompt__actions {
  grid-column: 2;
  display: flex;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm);
  margin-top: var(--flare-size-spacing-xs);
}
.flare-permission-prompt__actions :deep(.flare-button) { min-width: 48px; min-height: 48px; max-width: 100%; white-space: normal; }

/* Compact: one row for the composer strip. */
.flare-permission-prompt--compact {
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-md);
  border: 1px solid var(--flare-color-border-secondary);
}
.flare-permission-prompt--compact .flare-permission-prompt__icon { width: 32px; height: 32px; }
.flare-permission-prompt--compact .flare-permission-prompt__title { font-size: var(--flare-size-font-size-lg); }
.flare-permission-prompt--compact .flare-permission-prompt__description { font-size: var(--flare-size-font-size-sm); }
.flare-permission-prompt--compact .flare-permission-prompt__actions { grid-column: 3; margin-top: 0; }
@media (max-width: 480px) {
  .flare-permission-prompt--compact { grid-template-columns: auto minmax(0, 1fr); }
  .flare-permission-prompt--compact .flare-permission-prompt__actions { grid-column: 2; }
}

/* Sheet: the sheet is the surface. One centered column, full-width keys with the action first. */
.flare-permission-prompt--sheet {
  grid-template-columns: minmax(0, 1fr);
  justify-items: center;
  text-align: center;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg) var(--flare-size-spacing-xl);
  border-radius: 0;
  background: transparent;
}
.flare-permission-prompt--sheet .flare-permission-prompt__heading { justify-content: center; }
.flare-permission-prompt--sheet .flare-permission-prompt__actions {
  grid-column: 1;
  justify-self: stretch;
  flex-direction: column;
  margin-top: var(--flare-size-spacing-sm);
}
</style>
