<script setup lang="ts">
// Connection / session details panel — opened from a StatusBanner or shown on the
// "network & connection" settings page. The host owns the state; this view only
// presents it and dispatches reconnect / reauth / copyDiagnostics.
import { computed, ref, useId } from 'vue';
import FlareIcon from './FlareIcon.vue';
import type { FlareIconName } from '../../shared/icons';
import {
  availableConnectionActions, connectionInProgress, connectionTone,
  type ConnectionState,
} from '../../shared/contracts/connection-details';

const props = withDefaults(defineProps<{
  state: ConnectionState;
  transport?: string;
  endpoint?: string;
  lastSyncAt?: string;
  reason?: string;
  diagnostics?: string;
  busy?: boolean;
  /** Host can reconnect (binds `@reconnect`); false hides the button. Native derives this from `onReconnect != null`. */
  hasReconnect?: boolean;
  /** Host can re-authenticate (binds `@reauth`); false hides the button. Native derives this from `onReauth != null`. */
  hasReauth?: boolean;
  title?: string;
  connectedText?: string;
  connectingText?: string;
  reconnectingText?: string;
  offlineText?: string;
  sessionExpiredText?: string;
  kickedText?: string;
  sdkUnreadyText?: string;
  transportLabel?: string;
  endpointLabel?: string;
  lastSyncLabel?: string;
  diagnosticsLabel?: string;
  reconnectText?: string;
  reauthText?: string;
  copyDiagnosticsText?: string;
}>(), {
  busy: false,
  hasReconnect: false,
  hasReauth: false,
  title: '连接详情',
  connectedText: '已连接',
  connectingText: '正在连接',
  reconnectingText: '正在重新连接',
  offlineText: '离线',
  sessionExpiredText: '登录已过期',
  kickedText: '已在其他设备登录',
  sdkUnreadyText: '客户端尚未就绪',
  transportLabel: '传输协议',
  endpointLabel: '服务地址',
  lastSyncLabel: '上次同步',
  diagnosticsLabel: '诊断信息',
  reconnectText: '重新连接',
  reauthText: '重新登录',
  copyDiagnosticsText: '复制诊断信息',
});
const emit = defineEmits<{ reconnect: []; reauth: []; copyDiagnostics: [] }>();

const stateText = computed(() => ({
  connected: props.connectedText,
  connecting: props.connectingText,
  reconnecting: props.reconnectingText,
  offline: props.offlineText,
  sessionExpired: props.sessionExpiredText,
  kicked: props.kickedText,
  sdkUnready: props.sdkUnreadyText,
})[props.state]);
const stateIcon = computed<FlareIconName>(() => ({
  connected: 'success', connecting: 'refresh', reconnecting: 'refresh', offline: 'error',
  sessionExpired: 'lock', kicked: 'devices', sdkUnready: 'info',
} as const)[props.state]);
const tone = computed(() => connectionTone(props.state));
const inProgress = computed(() => connectionInProgress(props.state));
const hasDiagnostics = computed(() => !!props.diagnostics?.trim());

// Visibility ignores busy (buttons stay in place); busy only disables them.
const visibleActions = computed(() => new Set(availableConnectionActions(props.state, {
  hasReconnect: props.hasReconnect, hasReauth: props.hasReauth,
  hasDiagnostics: hasDiagnostics.value, busy: false,
})));
const diagnosticsOpen = ref(false);
const diagnosticsId = useId();
</script>


<template>
  <section class="flare-connection-details" :class="`flare-connection-details--${tone}`" :aria-label="title" :aria-busy="busy">
    <h3 class="flare-connection-details__title">{{ title }}</h3>
    <div class="flare-connection-details__status" role="status" aria-live="polite">
      <span class="flare-connection-details__icon" aria-hidden="true"><FlareIcon :name="stateIcon" :size="20" /></span>
      <div class="flare-connection-details__status-body">
        <strong class="flare-connection-details__state">{{ stateText }}</strong>
        <p v-if="reason" class="flare-connection-details__reason">{{ reason }}</p>
      </div>
    </div>
    <progress v-if="inProgress" class="flare-connection-details__progress" :aria-label="stateText" />
    <dl v-if="transport || endpoint || lastSyncAt" class="flare-connection-details__meta">
      <template v-if="transport"><dt>{{ transportLabel }}</dt><dd>{{ transport }}</dd></template>
      <template v-if="endpoint"><dt>{{ endpointLabel }}</dt><dd class="flare-connection-details__endpoint" :title="endpoint">{{ endpoint }}</dd></template>
      <template v-if="lastSyncAt"><dt>{{ lastSyncLabel }}</dt><dd>{{ lastSyncAt }}</dd></template>
    </dl>
    <div v-if="visibleActions.size" class="flare-connection-details__actions">
      <button v-if="visibleActions.has('reconnect')" type="button" class="flare-connection-details__btn flare-connection-details__btn--primary" :disabled="busy" @click="emit('reconnect')">{{ reconnectText }}</button>
      <button v-if="visibleActions.has('reauth')" type="button" class="flare-connection-details__btn flare-connection-details__btn--primary" :disabled="busy" @click="emit('reauth')">{{ reauthText }}</button>
      <button v-if="visibleActions.has('copyDiagnostics')" type="button" class="flare-connection-details__btn" :disabled="busy" @click="emit('copyDiagnostics')">
        <FlareIcon name="copy" :size="16" /><span>{{ copyDiagnosticsText }}</span>
      </button>
    </div>
    <div v-if="hasDiagnostics" class="flare-connection-details__diagnostics">
      <button type="button" class="flare-connection-details__toggle" :aria-expanded="diagnosticsOpen" :aria-controls="diagnosticsId" @click="diagnosticsOpen = !diagnosticsOpen">
        <span class="flare-connection-details__chevron" :class="{ 'flare-connection-details__chevron--open': diagnosticsOpen }" aria-hidden="true"><FlareIcon name="forward" :size="14" /></span>
        <span>{{ diagnosticsLabel }}</span>
      </button>
      <pre v-show="diagnosticsOpen" :id="diagnosticsId" class="flare-connection-details__pre" tabindex="0">{{ diagnostics }}</pre>
    </div>
  </section>
</template>

<style scoped>
.flare-connection-details {
  display: grid;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  padding: var(--flare-size-spacing-lg);
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-xl);
}
.flare-connection-details--success { --flare-tone: var(--flare-color-success); }
.flare-connection-details--warning { --flare-tone: var(--flare-color-warning); }
.flare-connection-details--danger { --flare-tone: var(--flare-color-error); }
.flare-connection-details--neutral { --flare-tone: var(--flare-color-text-secondary); }

.flare-connection-details__title { margin: 0; font-size: var(--flare-size-font-size-2xl); font-weight: 600; }
.flare-connection-details__status {
  display: flex;
  gap: var(--flare-size-spacing-md);
  align-items: flex-start;
  padding: var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-lg);
  color: var(--flare-tone);
  background: color-mix(in srgb, var(--flare-tone) 10%, transparent);
  border: 1px solid color-mix(in srgb, var(--flare-tone) 24%, transparent);
}
.flare-connection-details__icon { flex: none; display: inline-flex; margin-top: 1px; }
.flare-connection-details__status-body { min-width: 0; flex: 1; display: grid; gap: var(--flare-size-spacing-xs); }
.flare-connection-details__state { font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-primary); }
.flare-connection-details__reason { margin: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-connection-details__progress { width: 100%; height: 4px; accent-color: var(--flare-tone); }

.flare-connection-details__meta {
  display: grid;
  grid-template-columns: max-content minmax(0, 1fr);
  gap: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg);
  margin: 0;
  font-size: var(--flare-size-font-size-md);
}
.flare-connection-details__meta dt { color: var(--flare-color-text-secondary); }
.flare-connection-details__meta dd { margin: 0; min-width: 0; overflow-wrap: anywhere; }
.flare-connection-details__endpoint { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; direction: ltr; unicode-bidi: isolate; }

.flare-connection-details__actions { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-sm); }
.flare-connection-details__btn {
  display: inline-flex; align-items: center; gap: var(--flare-size-spacing-xs);
  min-height: var(--flare-size-layout-touch-target); min-width: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  font: inherit; font-size: var(--flare-size-font-size-lg); cursor: pointer;
  color: var(--flare-color-text-primary); background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-md);
}
.flare-connection-details__btn--primary { color: #fff; background: var(--flare-color-primary); border-color: var(--flare-color-primary); }
.flare-connection-details__btn--primary:hover:not(:disabled) { background: var(--flare-color-primary-hover); }
.flare-connection-details__btn:hover:not(:disabled):not(.flare-connection-details__btn--primary) { background: var(--flare-color-bg-hover); }
.flare-connection-details__btn:disabled { cursor: not-allowed; color: var(--flare-color-text-disabled); background: var(--flare-color-bg-disabled); border-color: var(--flare-color-border-primary); }
.flare-connection-details__btn:focus-visible, .flare-connection-details__toggle:focus-visible, .flare-connection-details__pre:focus-visible {
  outline: 2px solid var(--flare-color-focus-ring); outline-offset: 2px;
}

.flare-connection-details__toggle {
  display: inline-flex; align-items: center; gap: var(--flare-size-spacing-xs);
  min-height: var(--flare-size-layout-touch-target); padding: 0 var(--flare-size-spacing-xs);
  font: inherit; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary);
  background: none; border: none; cursor: pointer;
}
.flare-connection-details__chevron { display: inline-flex; transition: transform var(--flare-transition-fast); }
.flare-connection-details__chevron--open { transform: rotate(90deg); }
.flare-connection-details__pre {
  margin: 0; max-height: 240px; overflow: auto; overscroll-behavior: contain;
  padding: var(--flare-size-spacing-md); font-size: var(--flare-size-font-size-sm); line-height: var(--flare-size-line-height-normal);
  white-space: pre-wrap; overflow-wrap: anywhere; direction: ltr; text-align: start;
  color: var(--flare-color-text-secondary); background: var(--flare-color-bg-secondary); border-radius: var(--flare-size-radius-md);
}
@media (prefers-reduced-motion: reduce) { .flare-connection-details__chevron { transition: none; } }
</style>
