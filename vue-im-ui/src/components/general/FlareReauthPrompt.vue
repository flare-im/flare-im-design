<script setup lang="ts">
// Re-authentication prompt shown when the session can no longer be used
// (expired / kicked by another device / credential invalid / account disabled).
// The host owns the login flow and the container (full-screen overlay or
// dialog); this panel only names the reason, locks repeat submits, keeps the
// last failure visible and dispatches `reauthenticate` / `logout`.
import { computed, getCurrentInstance } from "vue";
import FlareIcon from "./FlareIcon.vue";
import FlarePrimaryButton from "./FlarePrimaryButton.vue";
import FlareButton from "./FlareButton.vue";
import FlareStatusBanner from "./FlareStatusBanner.vue";
import { reauthActions, reauthIcon, reauthTone, type ReauthReason } from "../../shared/contracts/reauth-prompt";

const props = withDefaults(
  defineProps<{
    reason: ReauthReason;
    /** Host-supplied detail, e.g. the device name / time of the kick. */
    detail?: string;
    /** Host sets this synchronously before dispatching; locks every action. */
    busy?: boolean;
    /** User-facing reason the last re-authentication failed; kept in the panel. */
    error?: string;
    /** Current account, so the user can confirm which one is being re-authenticated. */
    accountLabel?: string;
    title?: string;
    sessionExpiredText?: string;
    kickedText?: string;
    credentialInvalidText?: string;
    accountDisabledText?: string;
    reauthenticateText?: string;
    /** Accessible progress text shown in the primary button while busy. */
    busyText?: string;
    logoutText?: string;
    accountCaption?: string;
  }>(),
  {
    busy: false,
    title: "需要重新登录",
    sessionExpiredText: "登录状态已过期，请重新登录后继续。",
    kickedText: "你的账号已在其它设备登录，当前设备已下线。",
    credentialInvalidText: "登录凭证已失效，请重新登录。",
    accountDisabledText: "账号已被停用，暂时无法登录，请联系管理员。",
    reauthenticateText: "重新登录",
    busyText: "正在重新登录…",
    logoutText: "退出登录",
    accountCaption: "当前账号",
  },
);
const emit = defineEmits<{ (e: "reauthenticate"): void; (e: "logout"): void }>();

// Buttons appear only when the host bound the matching listener.
const instance = getCurrentInstance();
const hasReauth = computed(() => !!instance?.vnode.props?.onReauthenticate);
const hasLogout = computed(() => !!instance?.vnode.props?.onLogout);
const actions = computed(() => reauthActions(props.reason, { hasReauth: hasReauth.value, hasLogout: hasLogout.value, busy: props.busy }));
const tone = computed(() => reauthTone(props.reason));
const icon = computed(() => reauthIcon(props.reason));
const reasonText = computed(() => ({
  sessionExpired: props.sessionExpiredText,
  kicked: props.kickedText,
  credentialInvalid: props.credentialInvalidText,
  accountDisabled: props.accountDisabledText,
})[props.reason]);
const uid = `flare-reauth-${instance?.uid ?? 0}`;

function reauthenticate() { if (actions.value.reauthenticate.enabled) emit("reauthenticate"); }
function logout() { if (actions.value.logout.enabled) emit("logout"); }
function onEnter(event: KeyboardEvent) {
  // A focused button already fires click on Enter; only handle Enter elsewhere in the panel.
  if ((event.target as HTMLElement | null)?.tagName === "BUTTON") return;
  if (actions.value.primary === "reauthenticate") { event.preventDefault(); reauthenticate(); }
}
function onEscape(event: KeyboardEvent) {
  // A broken session cannot be dismissed: swallow Escape so a host dialog does not close.
  event.preventDefault();
  event.stopPropagation();
}
</script>

<template>
  <section
    class="flare-reauth-prompt"
    :class="[`flare-reauth-prompt--${tone}`, `flare-reauth-prompt--${reason}`]"
    role="group"
    tabindex="-1"
    :aria-labelledby="`${uid}-title`"
    :aria-describedby="`${uid}-reason`"
    :aria-busy="busy || undefined"
    @keydown.enter="onEnter"
    @keydown.escape="onEscape"
  >
    <span class="flare-reauth-prompt__glyph" aria-hidden="true"><FlareIcon :name="icon" :size="28" /></span>
    <h2 :id="`${uid}-title`" class="flare-reauth-prompt__title">{{ title }}</h2>
    <p :id="`${uid}-reason`" class="flare-reauth-prompt__reason">{{ reasonText }}</p>
    <p v-if="detail" class="flare-reauth-prompt__detail">{{ detail }}</p>
    <p v-if="accountLabel" class="flare-reauth-prompt__account">
      <span class="flare-reauth-prompt__account-caption">{{ accountCaption }}</span>
      <span class="flare-reauth-prompt__account-label" :title="accountLabel">{{ accountLabel }}</span>
    </p>
    <div v-if="error" class="flare-reauth-prompt__error" role="alert">
      <FlareStatusBanner :text="error" tone="danger" />
    </div>
    <div v-if="actions.reauthenticate.visible || actions.logout.visible" class="flare-reauth-prompt__actions">
      <FlarePrimaryButton
        v-if="actions.reauthenticate.visible"
        :label="reauthenticateText"
        :loading="busy"
        :loading-label="busyText"
        :disabled="!actions.reauthenticate.enabled"
        @click="reauthenticate"
      />
      <FlareButton
        v-if="actions.logout.visible"
        :label="logoutText"
        variant="secondary"
        size="lg"
        block
        :disabled="!actions.logout.enabled"
        @click="logout"
      />
    </div>
  </section>
</template>

<style scoped>
.flare-reauth-prompt {
  --flare-reauth-tone: var(--flare-color-info);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--flare-size-spacing-sm, 8px);
  width: 100%;
  max-width: 400px;
  margin: 0 auto;
  padding: var(--flare-size-spacing-2xl, 24px) var(--flare-size-spacing-xl, 20px);
  box-sizing: border-box;
  text-align: center;
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
  border-radius: var(--flare-size-radius-xl, 14px);
  outline: none;
}
.flare-reauth-prompt:focus-visible { outline: 2px solid var(--flare-color-focus-ring, var(--flare-color-primary)); outline-offset: 2px; }
.flare-reauth-prompt--warning { --flare-reauth-tone: var(--flare-color-warning); }
.flare-reauth-prompt--danger { --flare-reauth-tone: var(--flare-color-error); }
.flare-reauth-prompt__glyph {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 56px;
  height: 56px;
  border-radius: 50%;
  color: var(--flare-reauth-tone);
  background: color-mix(in srgb, var(--flare-reauth-tone) 12%, transparent);
}
.flare-reauth-prompt__title { margin: var(--flare-size-spacing-sm, 8px) 0 0; font-size: var(--flare-size-font-size-3xl, 18px); font-weight: 600; line-height: 1.3; }
.flare-reauth-prompt__reason { margin: 0; font-size: var(--flare-size-font-size-lg, 14px); line-height: 1.5; overflow-wrap: anywhere; }
.flare-reauth-prompt__detail { margin: 0; font-size: var(--flare-size-font-size-md, 13px); line-height: 1.5; color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-reauth-prompt__account {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  max-width: 100%;
  margin: var(--flare-size-spacing-xs, 4px) 0 0;
  padding: 4px 10px;
  font-size: var(--flare-size-font-size-sm, 12px);
  border-radius: var(--flare-size-radius-full, 999px);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
}
.flare-reauth-prompt__account-caption { flex: none; }
.flare-reauth-prompt__account-label { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: var(--flare-color-text-primary); font-weight: 600; }
.flare-reauth-prompt__error { width: 100%; margin-top: var(--flare-size-spacing-xs, 4px); text-align: start; }
.flare-reauth-prompt__actions { display: grid; gap: var(--flare-size-spacing-sm, 8px); width: 100%; margin-top: var(--flare-size-spacing-md, 12px); }
</style>
