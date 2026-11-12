<script setup lang="ts">
/**
 * Whether new messages reach the person when the app is not in front, as one settings section.
 * Spec: Profile/NotificationDeliverySettings.
 *
 * "New message notifications" shows the system permission (on / off / not turned on) and hands the
 * press to the host in `statusAction`: the host asks for the permission or opens the system settings,
 * whichever the platform allows. With `background` (Android-style platforms) a second row shows what
 * the battery settings let the app do and opens a guide in the kit bottom sheet: why background
 * running matters, the battery settings (`openBatterySettings`) and any auto-start pages the host
 * knows of (`vendorActions`). The component reads nothing from the platform and opens nothing itself.
 *
 * On its own it draws the group as a list of one section. A settings page that is already one
 * FlareSettingsList fills the `section` slot instead: the slot gets the group as one settings
 * section and `select`, which runs a row of the group (the status action, or the background guide)
 * and returns whether the row was one, so the page lists the section among its own and hands every
 * row to `select` first (`select(item) || open(item)`). The group's rows are keyed `notifications`
 * and `backgroundDelivery`; the page's own rows keep other keys.
 */
import { computed, getCurrentInstance, ref, watch } from "vue";
import FlareSettingsList from "./FlareSettingsList.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import type { FlareSettingsItem, FlareSettingsSection } from "../../shared/contracts";
import {
  BACKGROUND_DELIVERY_ROW, BATTERY_SETTINGS_ROW, NOTIFICATION_STATUS_ROW,
  type BackgroundDelivery, type NotificationGuideAction, type NotificationStatus,
} from "../../shared/contracts/notification-delivery";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{
  /** The system notification permission; null until it has been read. */
  status: NotificationStatus | null;
  /** What the battery settings let the app do; leave it out where the platform has no such setting. */
  background?: BackgroundDelivery | null;
  /** Auto-start pages of the phone maker, offered in the background guide. */
  vendorActions?: NotificationGuideAction[];
  /** Section header; an empty string draws none. */
  title?: string;
  /** A note under the section. */
  footer?: string;
}>(), { background: null, vendorActions: () => [] });
const emit = defineEmits<{ statusAction: []; openBatterySettings: [] }>();
defineSlots<{
  /** The group as one section of the host's own settings list; `select` runs a row of the group. */
  section?(props: { section: FlareSettingsSection; select: (item: FlareSettingsItem) => boolean }): unknown;
}>();
const { t } = useFlareI18n();
const instance = getCurrentInstance();
/** A row whose action the host did not bind is information only. */
function rowKind(listener: "onStatusAction" | "onOpenBatterySettings"): FlareSettingsItem["kind"] {
  return instance?.vnode.props?.[listener] ? "navigation" : "value";
}

const guideOpen = ref(false);
// The guide belongs to the background row: when the row goes, so does the guide.
watch(() => props.background, (background) => { if (!background) guideOpen.value = false; });
const VENDOR_PREFIX = "vendor:";

const statusText = computed(() => {
  switch (props.status) {
    case "on": return t("notificationDeliverySettings.on");
    case "off": return t("notificationDeliverySettings.off");
    case "notTurnedOn": return t("notificationDeliverySettings.notTurnedOn");
    default: return undefined;
  }
});
const backgroundText = computed(() => {
  switch (props.background) {
    case "unrestricted": return t("notificationDeliverySettings.unrestricted");
    case "optimized": return t("notificationDeliverySettings.optimized");
    case "restricted": return t("notificationDeliverySettings.restricted");
    default: return undefined;
  }
});
const backgroundLabel = computed(() => t("notificationDeliverySettings.background"));

// Built at render time: which actions the host bound decides the row kinds.
function section(): FlareSettingsSection {
  const items: FlareSettingsItem[] = [
    { key: NOTIFICATION_STATUS_ROW, label: t("notificationDeliverySettings.newMessages"), icon: "notification", kind: rowKind("onStatusAction"), detail: statusText.value },
  ];
  if (props.background) {
    items.push({ key: BACKGROUND_DELIVERY_ROW, label: backgroundLabel.value, icon: "refresh", kind: "navigation", detail: backgroundText.value });
  }
  return { title: props.title ?? t("notificationDeliverySettings.title"), items, footer: props.footer };
}
function guideSection(): FlareSettingsSection {
  return {
    items: [
      { key: BATTERY_SETTINGS_ROW, label: t("notificationDeliverySettings.battery"), kind: rowKind("onOpenBatterySettings"), detail: backgroundText.value },
      ...props.vendorActions.map((action, index) => ({
        key: `${VENDOR_PREFIX}${index}`,
        label: action.label ?? t("notificationDeliverySettings.autoStart"),
        kind: "navigation" as const,
      })),
    ],
  };
}

/** Runs a row of the group and says whether `item` was one. */
function select(item: FlareSettingsItem): boolean {
  if (item.key === NOTIFICATION_STATUS_ROW) {
    emit("statusAction");
    return true;
  }
  if (item.key === BACKGROUND_DELIVERY_ROW && props.background) {
    guideOpen.value = true;
    return true;
  }
  return false;
}
function selectInGuide(item: FlareSettingsItem) {
  if (item.key === BATTERY_SETTINGS_ROW) {
    emit("openBatterySettings");
    return;
  }
  if (item.key.startsWith(VENDOR_PREFIX)) props.vendorActions[Number(item.key.slice(VENDOR_PREFIX.length))]?.onSelect();
}
</script>

<template>
  <div class="flare-notification-delivery">
    <slot name="section" :section="section()" :select="select">
      <FlareSettingsList :sections="[section()]" @select="select" />
    </slot>
    <FlareBottomSheet :open="guideOpen" :title="backgroundLabel" @close="guideOpen = false">
      <div class="flare-notification-delivery__guide">
        <p class="flare-notification-delivery__text">{{ t("notificationDeliverySettings.explanation") }}</p>
        <p v-if="vendorActions.length" class="flare-notification-delivery__text">{{ t("notificationDeliverySettings.autoStartHint") }}</p>
        <FlareSettingsList :sections="[guideSection()]" @select="selectInGuide" />
      </div>
    </FlareBottomSheet>
  </div>
</template>

<style scoped>
.flare-notification-delivery { min-width: 0; }
.flare-notification-delivery__guide {
  display: grid;
  gap: var(--flare-size-spacing-sm);
  padding: var(--flare-size-spacing-xs) 0 var(--flare-size-spacing-lg);
}
.flare-notification-delivery__text {
  margin: 0;
  padding: 0 var(--flare-size-spacing-lg);
  font-size: var(--flare-size-font-size-md);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
</style>
