<script setup lang="ts">
// Unified "permission missing / denied" panel. The host owns the actual
// permission state and the request / openSettings side effects; this view only
// explains the requirement and dispatches. Spec: General/PermissionPrompt.
import { computed, getCurrentInstance } from 'vue';
import FlareIcon from './FlareIcon.vue';
import FlareButton from './FlareButton.vue';
import {
  defaultPermissionCopy, defaultPermissionStateLabel, permissionActions, permissionIcon, permissionStateIcon,
  type PermissionKind, type PermissionState,
} from '../../shared/contracts/permission-prompt';

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
  title?: string;
  description?: string;
  stateText?: string;
  requestText?: string;
  openSettingsText?: string;
  dismissText?: string;
}>(), { busy: false, compact: false, dismissText: '知道了' });

const emit = defineEmits<{ request: []; openSettings: []; dismiss: [] }>();

const instance = getCurrentInstance();
/** Read at render time: a listener the host did not bind means the action is not offered. */
function hasListener(name: 'onRequest' | 'onOpenSettings' | 'onDismiss'): boolean {
  return !!instance?.vnode.props?.[name];
}

const copy = computed(() => defaultPermissionCopy(props.kind, props.state, props.featureLabel));
const title = computed(() => props.title ?? copy.value.title);
const description = computed(() => props.description ?? copy.value.description);
const stateText = computed(() => props.stateText ?? defaultPermissionStateLabel(props.state));
const requestText = computed(() => props.requestText ?? copy.value.primaryLabel);
const openSettingsText = computed(() => props.openSettingsText ?? copy.value.primaryLabel);
const actions = () => permissionActions(props.state, {
  hasRequest: hasListener('onRequest'), hasOpenSettings: hasListener('onOpenSettings'), hasDismiss: hasListener('onDismiss'), busy: props.busy,
});
function onEscape() { if (!props.busy && hasListener('onDismiss')) emit('dismiss'); }
</script>

<template>
  <section
    class="flare-permission-prompt"
    :class="[`flare-permission-prompt--${state}`, { 'flare-permission-prompt--compact': compact }]"
    role="region"
    :aria-label="title"
    :aria-busy="busy"
    tabindex="-1"
    @keydown.escape.prevent="onEscape"
  >
    <span class="flare-permission-prompt__icon" aria-hidden="true">
      <FlareIcon :name="permissionIcon[kind]" :size="compact ? 20 : 26" />
    </span>
    <div class="flare-permission-prompt__body">
      <div class="flare-permission-prompt__heading">
        <h3 class="flare-permission-prompt__title">{{ title }}</h3>
        <span class="flare-permission-prompt__state" role="status">
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
        :size="compact ? 'md' : 'lg'"
        :loading="busy"
        @click="emit('request')"
      />
      <FlareButton
        v-if="actions().openSettings"
        :label="openSettingsText"
        variant="primary"
        :size="compact ? 'md' : 'lg'"
        :loading="busy"
        @click="emit('openSettings')"
      />
      <FlareButton
        v-if="actions().dismiss"
        :label="dismissText"
        variant="secondary"
        :size="compact ? 'md' : 'lg'"
        :disabled="busy"
        @click="emit('dismiss')"
      />
    </div>
  </section>
</template>

<style scoped>
.flare-permission-prompt {
  --flare-permission-tone: var(--flare-color-info);
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  gap: var(--flare-size-spacing-sm, 8px) var(--flare-size-spacing-md, 12px);
  align-items: start;
  min-width: 0;
  padding: var(--flare-size-spacing-lg, 16px);
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
}
.flare-permission-prompt:focus-visible { outline: 2px solid var(--flare-color-focus-ring, var(--flare-color-primary)); outline-offset: 2px; }
.flare-permission-prompt--undetermined { --flare-permission-tone: var(--flare-color-info); }
.flare-permission-prompt--denied { --flare-permission-tone: var(--flare-color-error); }
.flare-permission-prompt--restricted { --flare-permission-tone: var(--flare-color-warning); }
.flare-permission-prompt--unavailable { --flare-permission-tone: var(--flare-color-text-secondary); }

.flare-permission-prompt__icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  flex: none;
  border-radius: var(--flare-size-radius-full, 999px);
  color: var(--flare-color-primary);
  background: color-mix(in srgb, var(--flare-color-primary) 12%, transparent);
}
.flare-permission-prompt__body { min-width: 0; display: grid; gap: var(--flare-size-spacing-xs, 4px); }
.flare-permission-prompt__heading { display: flex; flex-wrap: wrap; align-items: center; gap: var(--flare-size-spacing-sm, 8px); }
.flare-permission-prompt__title { margin: 0; font-size: var(--flare-size-font-size-xl, 15px); font-weight: 600; overflow-wrap: anywhere; }
.flare-permission-prompt__state {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  font-size: var(--flare-size-font-size-xs, 11px);
  font-weight: 600;
  line-height: var(--flare-size-line-height-normal, 1.5);
  border-radius: var(--flare-size-radius-full, 999px);
  color: var(--flare-permission-tone);
  background: color-mix(in srgb, var(--flare-permission-tone) 12%, transparent);
  white-space: nowrap;
}
.flare-permission-prompt__description {
  margin: 0;
  font-size: var(--flare-size-font-size-md, 13px);
  line-height: var(--flare-size-line-height-normal, 1.5);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-permission-prompt__detail {
  margin: 0;
  font-size: var(--flare-size-font-size-sm, 12px);
  line-height: var(--flare-size-line-height-normal, 1.5);
  color: var(--flare-color-text-tertiary);
  overflow-wrap: anywhere;
}
.flare-permission-prompt__actions {
  grid-column: 2;
  display: flex;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm, 8px);
  margin-top: var(--flare-size-spacing-xs, 4px);
}
.flare-permission-prompt__actions :deep(.flare-button) { min-width: 48px; min-height: 48px; max-width: 100%; white-space: normal; }

/* Compact: one row for the composer strip. */
.flare-permission-prompt--compact {
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  padding: var(--flare-size-spacing-sm, 8px) var(--flare-size-spacing-md, 12px);
  border-radius: var(--flare-size-radius-md, 8px);
  border: 1px solid var(--flare-color-border-secondary);
}
.flare-permission-prompt--compact .flare-permission-prompt__icon { width: 32px; height: 32px; }
.flare-permission-prompt--compact .flare-permission-prompt__title { font-size: var(--flare-size-font-size-lg, 14px); }
.flare-permission-prompt--compact .flare-permission-prompt__description { font-size: var(--flare-size-font-size-sm, 12px); }
.flare-permission-prompt--compact .flare-permission-prompt__actions { grid-column: 3; margin-top: 0; }
@media (max-width: 480px) {
  .flare-permission-prompt--compact { grid-template-columns: auto minmax(0, 1fr); }
  .flare-permission-prompt--compact .flare-permission-prompt__actions { grid-column: 2; }
}
</style>
