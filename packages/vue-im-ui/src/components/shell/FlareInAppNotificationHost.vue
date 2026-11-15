<script setup lang="ts">
/**
 * Puts the in-app new-message banner on screen. Spec: Feedback/InAppNotificationHost.
 *
 * The app owns a presenter (`createFlareInAppNotifications()`), feeds it from the engine's `notification.present`
 * (surface `inApp`) and `notification.clear` events, and places this host once anywhere: it renders a fixed region at
 * the top centre, under the safe area and above the page. The presenter decides what shows and what waits
 * (spec/in-app-notification-vectors.json); the host owns the time: each banner stays
 * IN_APP_NOTIFICATION_DURATION_MS after it shows or is replaced, and the time stops while the banner is pressed,
 * hovered or focused and starts over when that ends. Opening dismisses the banner and reports `open`; the app routes.
 * Each banner is announced once through a polite status region. Reduced motion: no slide.
 */
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import FlareInAppNotificationBanner from "./FlareInAppNotificationBanner.vue";
import type { FlareInAppNotifications } from "../../composables/useFlareInAppNotifications";
import { IN_APP_NOTIFICATION_DURATION_MS, inAppNotificationSpoken } from "../../shared/contracts/in-app-notification";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = defineProps<{
  /** The presenter the app feeds. */
  notifications: FlareInAppNotifications;
}>();
const emit = defineEmits<{ open: [conversationId: string, messageId: string | undefined] }>();
const { t } = useFlareI18n();

const current = computed(() => props.notifications.current.value);
const pressed = ref(false);
const hovered = ref(false);
const focused = ref(false);
const held = computed(() => pressed.value || hovered.value || focused.value);
const mounted = ref(false);
const spoken = ref("");
let timer: ReturnType<typeof setTimeout> | null = null;

function stop(): void {
  if (timer !== null) clearTimeout(timer);
  timer = null;
}
/** Starts the visible banner's time over, unless nothing shows or the banner is held. */
function schedule(): void {
  stop();
  if (!mounted.value || !current.value || held.value) return;
  timer = setTimeout(() => {
    timer = null;
    props.notifications.dismiss();
  }, IN_APP_NOTIFICATION_DURATION_MS);
}
watch([() => props.notifications.revision.value, held, mounted, () => current.value === null], schedule);
// A banner that shows or is replaced is announced once.
watch(() => props.notifications.revision.value, () => {
  const shown = current.value;
  if (!shown) return;
  spoken.value = inAppNotificationSpoken(shown, {
    label: t("inAppNotification.label"),
    mention: t("inAppNotification.mention"),
    urgent: t("inAppNotification.urgent"),
    count: (count) => t("inAppNotification.count", { count }),
  });
});
// Another banner takes the place: the hold belonged to the one that left.
watch(() => current.value?.collapseId, () => {
  pressed.value = false;
  hovered.value = false;
  focused.value = false;
});
onMounted(() => { mounted.value = true; });
onBeforeUnmount(stop);

function hover(event: PointerEvent): void {
  if (event.pointerType === "mouse") hovered.value = true;
}
function focusOut(event: FocusEvent): void {
  const slot = event.currentTarget as HTMLElement | null;
  if (!slot?.contains(event.relatedTarget as Node | null)) focused.value = false;
}
function open(conversationId: string, messageId: string | undefined): void {
  props.notifications.dismiss();
  emit("open", conversationId, messageId);
}
</script>

<template>
  <div class="flare-in-app-host">
    <span class="flare-in-app-host__spoken" role="status">{{ spoken }}</span>
    <transition name="flare-in-app-host" mode="out-in">
      <div
        v-if="current"
        :key="current.collapseId"
        class="flare-in-app-host__slot"
        @pointerdown="pressed = true"
        @pointerup="pressed = false"
        @pointercancel="pressed = false"
        @pointerenter="hover"
        @pointerleave="hovered = false"
        @focusin="focused = true"
        @focusout="focusOut"
      >
        <FlareInAppNotificationBanner :notification="current" @open="open" @dismiss="notifications.dismiss()" />
      </div>
    </transition>
  </div>
</template>

<style scoped>
.flare-in-app-host {
  position: fixed;
  z-index: var(--flare-z-index-toast);
  top: calc(env(safe-area-inset-top, 0px) + var(--flare-size-spacing-sm));
  left: 50%;
  width: min(var(--flare-size-layout-auth-form-max-width), calc(100vw - 2 * var(--flare-size-spacing-md)));
  transform: translateX(-50%);
  pointer-events: none;
}
.flare-in-app-host__slot { pointer-events: auto; }
.flare-in-app-host__spoken {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
.flare-in-app-host-enter-active,
.flare-in-app-host-leave-active {
  transition: opacity var(--flare-transition-normal), transform var(--flare-transition-normal);
}
.flare-in-app-host-enter-from,
.flare-in-app-host-leave-to {
  opacity: 0;
  transform: translateY(calc(-100% - var(--flare-size-spacing-sm)));
}
@media (prefers-reduced-motion: reduce) {
  .flare-in-app-host-enter-from,
  .flare-in-app-host-leave-to { transform: none; }
}
</style>
