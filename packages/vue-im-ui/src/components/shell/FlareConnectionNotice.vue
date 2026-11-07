<script setup lang="ts">
// The connection notice an app shell places once, above every tab: the core SDK's connection status in
// (the `connection://status` event, as it arrives), the kit's words, tone, countdown and way back out.
// What shows when is the tracker's call (utils/connectionNotice.ts, spec/connection-notice-vectors.json);
// this component feeds it the status, wakes when the presentation can next change and draws the banner
// with FlareStatusBanner. An action is drawn only while the host listens for it.
//
// The countdown and the sync progress change every second, so the banner itself is not a live region;
// the message alone is announced (politely) when it changes.
import { computed, getCurrentInstance, onBeforeUnmount, shallowRef, watch } from "vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import {
  FlareConnectionNoticeTracker,
  type FlareConnectionNoticeAction,
  type FlareConnectionNoticeModel,
  type FlareConnectionStatus,
} from "../../utils/connectionNotice";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import FlareTag from "../general/FlareTag.vue";

const props = withDefaults(
  defineProps<{
    /** The latest `connection://status`; null before the SDK has reported one. */
    status?: FlareConnectionStatus | null;
    /** Hang the banner over the content (FlareStatusBanner `floating`). */
    floating?: boolean;
  }>(),
  { status: null, floating: false },
);
const emit = defineEmits<{
  (e: "retry"): void;
  (e: "signIn"): void;
  (e: "update"): void;
  (e: "diagnose"): void;
}>();
const instance = getCurrentInstance();
const { t } = useFlareI18nOptional();

const tracker = new FlareConnectionNoticeTracker();
const model = shallowRef<FlareConnectionNoticeModel>(tracker.present(Date.now()));
let timer: ReturnType<typeof setTimeout> | undefined;

function refresh() {
  if (timer !== undefined) clearTimeout(timer);
  timer = undefined;
  const now = Date.now();
  model.value = tracker.present(now);
  const next = tracker.nextChangeAt(now);
  if (next !== null) timer = setTimeout(refresh, Math.max(0, next - now));
}

watch(
  () => props.status,
  (status) => {
    tracker.observe(status ?? { phase: "idle" }, Date.now());
    refresh();
  },
  { immediate: true, deep: true },
);
onBeforeUnmount(() => {
  if (timer !== undefined) clearTimeout(timer);
});

const TEXT_KEYS = {
  connecting: "connection.connecting",
  syncing: "connection.syncing",
  switching: "connection.switching",
  reconnecting: "connection.reconnecting",
  waitingForNetwork: "connection.waitingForNetwork",
  serviceUnavailable: "connection.serviceUnavailable",
  kicked: "connection.kicked",
  expired: "connection.expired",
  upgradeRequired: "connection.upgradeRequired",
  tenantUnavailable: "connection.tenantUnavailable",
} as const;
const ACTIONS: Record<FlareConnectionNoticeAction, { key: string; listener: string }> = {
  retry: { key: "connection.retry", listener: "onRetry" },
  signIn: { key: "connection.signIn", listener: "onSignIn" },
  update: { key: "connection.update", listener: "onUpdate" },
  diagnose: { key: "connection.diagnose", listener: "onDiagnose" },
};

const message = computed(() => (model.value.text ? t(TEXT_KEYS[model.value.text]) : ""));
const detail = computed(() => {
  if (model.value.countdown !== null) return t("connection.retryIn", { seconds: model.value.countdown });
  if (model.value.progress !== null) return `${Math.round(model.value.progress * 100)}%`;
  return "";
});
const bannerText = computed(() => (detail.value ? `${message.value} ${detail.value}` : message.value));
const action = computed(() => {
  const offered = model.value.action;
  return offered && instance?.vnode.props?.[ACTIONS[offered].listener] ? offered : null;
});
const actionText = computed(() => (action.value ? t(ACTIONS[action.value].key) : undefined));

function perform() {
  switch (action.value) {
    case "retry": emit("retry"); break;
    case "signIn": emit("signIn"); break;
    case "update": emit("update"); break;
    case "diagnose": emit("diagnose"); break;
  }
}
</script>

<template>
  <div class="flare-connection-notice" :data-flare-connection-phase="status?.phase ?? 'idle'">
    <span class="flare-connection-notice__spoken" role="status">{{ model.visible ? message : "" }}</span>
    <FlareTag
      v-if="model.badge"
      class="flare-connection-notice__badge"
      :label="t('connection.developmentMode')"
      tone="warning"
    />
    <FlareStatusBanner
      v-if="model.visible"
      :text="bannerText"
      :tone="model.tone ?? 'info'"
      :pulse="model.pulse"
      :action-text="actionText"
      :floating="floating"
      aria-live="off"
      @action="perform"
    />
  </div>
</template>

<style scoped>
.flare-connection-notice {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-xs);
}
.flare-connection-notice__badge {
  align-self: flex-end;
}
.flare-connection-notice__spoken {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
</style>
