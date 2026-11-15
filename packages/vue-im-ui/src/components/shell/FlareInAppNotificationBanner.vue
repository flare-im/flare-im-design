<script setup lang="ts">
/**
 * The banner for a message that arrived while the app is open on another screen.
 * Spec: Feedback/InAppNotificationBanner.
 *
 * Avatar (the host's `avatarUrl`, else the title's initials coloured by the conversation), the title and one line of
 * preview, both ellipsised; above one message the kit's "[3条]" goes before the body, and mentions / urgent put their
 * tag before it with an accent. A click (or Enter / Space) opens: `open(conversationId, messageId)`. A swipe up past a
 * short distance, the close key or Escape dismisses. FlareInAppNotificationHost places the banner, queues the next
 * ones and runs its time; a host rarely draws it on its own.
 */
import { computed, ref } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import {
  IN_APP_NOTIFICATION_SWIPE_DISMISS_PX,
  inAppNotificationEmphasis,
  inAppNotificationShowsCount,
  inAppNotificationSpoken,
  inAppNotificationTag,
  type FlareInAppNotification,
  type FlareInAppNotificationWords,
} from "../../shared/contracts/in-app-notification";

const props = defineProps<{
  /** What the banner shows. */
  notification: FlareInAppNotification;
}>();
const emit = defineEmits<{
  open: [conversationId: string, messageId: string | undefined];
  dismiss: [];
}>();
const { t } = useFlareI18n();

const words = computed<FlareInAppNotificationWords>(() => ({
  label: t("inAppNotification.label"),
  mention: t("inAppNotification.mention"),
  urgent: t("inAppNotification.urgent"),
  count: (count) => t("inAppNotification.count", { count }),
}));
const emphasis = computed(() => inAppNotificationEmphasis(props.notification.channel));
const tag = computed(() => inAppNotificationTag(props.notification, words.value));
const countText = computed(() => (inAppNotificationShowsCount(props.notification) ? words.value.count(props.notification.count ?? 1) : ""));
const spoken = computed(() => inAppNotificationSpoken(props.notification, words.value));

/** Pixels the banner has followed the finger upwards (0 or less). */
const offset = ref(0);
/** A press under way: where it started. */
let press: { id: number; y: number } | null = null;
/** The press turned into a swipe, so the click that ends it does not open. */
let swiped = false;
/** Movement before a press counts as a swipe rather than a tap. */
const SLOP_PX = 4;

function onPointerDown(event: PointerEvent): void {
  if (event.button !== 0) return;
  press = { id: event.pointerId, y: event.clientY };
  swiped = false;
}
function onPointerMove(event: PointerEvent): void {
  if (!press || event.pointerId !== press.id) return;
  const travelled = Math.min(0, event.clientY - press.y);
  if (!swiped && travelled < -SLOP_PX) {
    swiped = true;
    (event.currentTarget as HTMLElement | null)?.setPointerCapture?.(event.pointerId);
  }
  if (swiped) offset.value = travelled;
}
function onPointerEnd(event: PointerEvent): void {
  if (!press || event.pointerId !== press.id) return;
  const dismissed = swiped && offset.value <= -IN_APP_NOTIFICATION_SWIPE_DISMISS_PX;
  press = null;
  offset.value = 0;
  if (dismissed) emit("dismiss");
}
function open(): void {
  if (swiped) {
    swiped = false;
    return;
  }
  emit("open", props.notification.conversationId, props.notification.messageId);
}
</script>

<template>
  <div
    class="flare-in-app-banner"
    :class="[emphasis ? `is-${emphasis}` : null, { 'is-swiping': offset < 0 }]"
    :style="offset < 0 ? { transform: `translateY(${offset}px)` } : undefined"
    @pointerdown="onPointerDown"
    @pointermove="onPointerMove"
    @pointerup="onPointerEnd"
    @pointercancel="onPointerEnd"
    @keydown.esc.prevent="emit('dismiss')"
  >
    <button type="button" class="flare-in-app-banner__open" :aria-label="spoken" @click="open">
      <FlareAvatar
        class="flare-in-app-banner__avatar"
        aria-hidden="true"
        :user-id="notification.conversationId"
        :display-name="notification.title"
        :avatar-url="notification.avatarUrl"
        :size="40"
      />
      <span class="flare-in-app-banner__text">
        <span class="flare-in-app-banner__title">{{ notification.title }}</span>
        <span class="flare-in-app-banner__body">
          <span v-if="tag" class="flare-in-app-banner__tag">{{ tag }}</span>
          <span v-if="countText" class="flare-in-app-banner__count">{{ countText }}</span>
          {{ notification.body }}
        </span>
      </span>
    </button>
    <FlareIconButton
      class="flare-in-app-banner__close"
      :icon="flareIcons.close"
      :ariaLabel="t('common.close')"
      size="sm"
      @click="emit('dismiss')"
    />
  </div>
</template>

<style scoped>
.flare-in-app-banner {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  box-sizing: border-box;
  width: 100%;
  padding: var(--flare-size-spacing-sm);
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-elevated);
  box-shadow: var(--flare-shadow-lg);
  color: var(--flare-color-text-primary);
  touch-action: none;
  transition: transform var(--flare-transition-fast);
}
.flare-in-app-banner.is-swiping { transition: none; }
.flare-in-app-banner.is-urgent { border-color: var(--flare-color-error); }
.flare-in-app-banner__open {
  display: flex;
  flex: 1;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  min-height: var(--flare-size-layout-touch-target);
  padding: 0;
  border: 0;
  background: transparent;
  color: inherit;
  font: inherit;
  text-align: start;
  cursor: pointer;
}
.flare-in-app-banner__open:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
  border-radius: var(--flare-size-radius-md);
}
.flare-in-app-banner__text {
  display: grid;
  gap: var(--flare-size-spacing-3xs);
  min-width: 0;
}
.flare-in-app-banner__title,
.flare-in-app-banner__body {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-in-app-banner__title {
  font-size: var(--flare-size-font-size-lg);
  font-weight: 600;
  line-height: var(--flare-size-line-height-tight);
}
.flare-in-app-banner__body {
  font-size: var(--flare-size-font-size-md);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-secondary);
}
.flare-in-app-banner__tag,
.flare-in-app-banner__count { margin-inline-end: var(--flare-size-spacing-xs); }
.flare-in-app-banner.is-mentions .flare-in-app-banner__tag { color: var(--flare-color-primary-text); font-weight: 600; }
.flare-in-app-banner.is-urgent .flare-in-app-banner__tag { color: var(--flare-color-error-text); font-weight: 600; }
.flare-in-app-banner__close { flex: none; color: var(--flare-color-text-tertiary); }
@media (prefers-reduced-motion: reduce) {
  .flare-in-app-banner { transition: none; }
}
</style>
