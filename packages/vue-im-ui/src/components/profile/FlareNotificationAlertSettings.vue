<script setup lang="ts">
/**
 * A person's notification preferences as settings sections. Spec: Profile/NotificationAlertSettings.
 *
 * Do not disturb: the Quiet hours switch and, while it is on, Starts, Ends (read as the next day when it is not after
 * the start), Repeat and Alert me when mentioned. Notification content: Preview. Multiple devices: While active
 * elsewhere. Each section has its footer. Starts and Ends open the TimePicker's columns in the kit sheet, Repeat a sheet
 * of seven day switches that never empties, Preview and While active elsewhere a sheet with a vertical RadioGroup that
 * applies the pick and closes. Every row reports the whole next value through `change`; the host saves it. The value
 * is the protocol's shape (spec/notification-alert-vectors.json).
 *
 * On its own it draws a list of the three sections. A settings page that is already one FlareSettingsList fills the
 * `sections` slot instead: it gets the sections, `select` and `toggle`, which run a row of the group and return whether
 * it was one (`select(item) || open(item)`). Row keys: quietHours, quietHoursStart, quietHoursEnd, quietHoursRepeat,
 * quietHoursAllowMentions, notificationPreview, multiDevice.
 */
import { computed, ref, watch } from "vue";
import FlareSettingsList from "./FlareSettingsList.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareRadioGroup from "../form/FlareRadioGroup.vue";
import FlareTimeChoice from "../form/FlareTimeChoice.vue";
import type { FlareSelectOption, FlareSettingsItem, FlareSettingsSection } from "../../shared/contracts";
import {
  MULTI_DEVICE_ROW,
  NOTIFICATION_PREVIEW_ROW,
  QUIET_HOURS_ALLOW_MENTIONS_ROW,
  QUIET_HOURS_END_ROW,
  QUIET_HOURS_MINUTE_STEP,
  QUIET_HOURS_REPEAT_ROW,
  QUIET_HOURS_ROW,
  QUIET_HOURS_START_ROW,
  formatMinuteOfDay,
  multiDeviceAlerts,
  notificationPreviews,
  parseMinuteOfDay,
  quietHoursEndsNextDay,
  weekdayIsOn,
  weekdaySummary,
  weekdayToggle,
  type FlareMultiDeviceAlert,
  type FlareNotificationAlertPreferences,
  type FlareNotificationPreview,
  type FlareQuietHours,
} from "../../shared/contracts/notification-alert";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{
  /** The preferences shown; `change` reports the whole next value. */
  value: FlareNotificationAlertPreferences;
  /**
   * The rows show the value but take no input (while the host saves or cannot write). A picker already open stays open
   * and its pick still goes through `change`.
   */
  disabled?: boolean;
}>(), { disabled: false });
const emit = defineEmits<{ change: [value: FlareNotificationAlertPreferences] }>();
defineSlots<{
  /** The three sections in the host's own settings list; `select` and `toggle` run a row of the group. */
  sections?(props: {
    sections: FlareSettingsSection[];
    select: (item: FlareSettingsItem) => boolean;
    toggle: (item: FlareSettingsItem, on: boolean) => boolean;
  }): unknown;
}>();
const { t } = useFlareI18n();

type Picker = "start" | "end" | "repeat" | "preview" | "multiDevice";
const picker = ref<Picker | null>(null);
/** The picker last opened: its sheet keeps its title while it closes. */
const shown = ref<Picker>("start");
// The time and day rows belong to quiet hours: when they go, so do their pickers.
watch(() => props.value.quietHours.enabled, (enabled) => {
  if (!enabled && (picker.value === "start" || picker.value === "end" || picker.value === "repeat")) picker.value = null;
});
function openPicker(next: Picker): void {
  if (props.disabled) return;
  shown.value = next;
  picker.value = next;
}

const WEEKDAY_KEYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"] as const;
const WEEKDAY_ROW_PREFIX = "weekday:";

function previewLabel(preview: FlareNotificationPreview): string {
  switch (preview) {
    case "senderOnly": return t("notificationAlertSettings.previewSenderOnly");
    case "hidden": return t("notificationAlertSettings.previewHidden");
    default: return t("notificationAlertSettings.previewFull");
  }
}
function multiDeviceLabel(policy: FlareMultiDeviceAlert): string {
  switch (policy) {
    case "immediate": return t("notificationAlertSettings.multiDeviceImmediate");
    case "badgeOnly": return t("notificationAlertSettings.multiDeviceBadgeOnly");
    default: return t("notificationAlertSettings.multiDeviceDelay");
  }
}
function repeatLabel(mask: number): string {
  const summary = weekdaySummary(mask);
  switch (summary.kind) {
    case "everyDay": return t("notificationAlertSettings.everyDay");
    case "weekdays": return t("notificationAlertSettings.weekdays");
    case "weekends": return t("notificationAlertSettings.weekends");
    default: return summary.days.map((day) => t(`notificationAlertSettings.${WEEKDAY_KEYS[day]}`)).join(t("displayName.separator"));
  }
}
function endLabel(quietHours: FlareQuietHours): string {
  const time = formatMinuteOfDay(quietHours.endMinute);
  return quietHoursEndsNextDay(quietHours) ? t("notificationAlertSettings.nextDay", { time }) : time;
}

// Built at render time, so a language switch and the host's new value both show at once.
function sections(): FlareSettingsSection[] {
  const { quietHours, preview, multiDevice } = props.value;
  const disabled = props.disabled;
  const quiet: FlareSettingsItem[] = [
    { key: QUIET_HOURS_ROW, label: t("notificationAlertSettings.quietHours"), kind: "toggle", value: quietHours.enabled, disabled },
  ];
  if (quietHours.enabled) {
    quiet.push(
      { key: QUIET_HOURS_START_ROW, label: t("notificationAlertSettings.start"), detail: formatMinuteOfDay(quietHours.startMinute), disabled },
      { key: QUIET_HOURS_END_ROW, label: t("notificationAlertSettings.end"), detail: endLabel(quietHours), disabled },
      { key: QUIET_HOURS_REPEAT_ROW, label: t("notificationAlertSettings.repeat"), detail: repeatLabel(quietHours.weekdays), disabled },
      { key: QUIET_HOURS_ALLOW_MENTIONS_ROW, label: t("notificationAlertSettings.allowMentions"), kind: "toggle", value: quietHours.allowMentions, disabled },
    );
  }
  return [
    { title: t("notificationAlertSettings.quietTitle"), items: quiet, footer: t("notificationAlertSettings.quietFooter") },
    {
      title: t("notificationAlertSettings.previewTitle"),
      items: [{ key: NOTIFICATION_PREVIEW_ROW, label: t("notificationAlertSettings.preview"), detail: previewLabel(preview), disabled }],
      footer: t("notificationAlertSettings.previewFooter"),
    },
    {
      title: t("notificationAlertSettings.multiDeviceTitle"),
      items: [{ key: MULTI_DEVICE_ROW, label: t("notificationAlertSettings.multiDevice"), detail: multiDeviceLabel(multiDevice), disabled }],
      footer: t("notificationAlertSettings.multiDeviceFooter"),
    },
  ];
}

function changeQuietHours(patch: Partial<FlareQuietHours>): void {
  emit("change", { ...props.value, quietHours: { ...props.value.quietHours, ...patch } });
}

/** Runs a picker row of the group and says whether `item` was one. */
function select(item: FlareSettingsItem): boolean {
  switch (item.key) {
    case QUIET_HOURS_START_ROW: openPicker("start"); return true;
    case QUIET_HOURS_END_ROW: openPicker("end"); return true;
    case QUIET_HOURS_REPEAT_ROW: openPicker("repeat"); return true;
    case NOTIFICATION_PREVIEW_ROW: openPicker("preview"); return true;
    case MULTI_DEVICE_ROW: openPicker("multiDevice"); return true;
    default: return false;
  }
}
/** Runs a switch row of the group and says whether `item` was one. */
function toggle(item: FlareSettingsItem, on: boolean): boolean {
  if (item.key === QUIET_HOURS_ROW) {
    if (!props.disabled) changeQuietHours({ enabled: on });
    return true;
  }
  if (item.key === QUIET_HOURS_ALLOW_MENTIONS_ROW) {
    if (!props.disabled) changeQuietHours({ allowMentions: on });
    return true;
  }
  return false;
}

const timeOpen = computed(() => picker.value === "start" || picker.value === "end");
const timeTitle = computed(() => (shown.value === "end" ? t("notificationAlertSettings.end") : t("notificationAlertSettings.start")));
const timeValue = computed(() => formatMinuteOfDay(picker.value === "end" ? props.value.quietHours.endMinute : props.value.quietHours.startMinute));
function pickTime(text: string): void {
  const minute = parseMinuteOfDay(text);
  changeQuietHours(picker.value === "end" ? { endMinute: minute } : { startMinute: minute });
  picker.value = null;
}

function weekdaySection(): FlareSettingsSection {
  const mask = props.value.quietHours.weekdays;
  const onCount = WEEKDAY_KEYS.filter((_, day) => weekdayIsOn(mask, day)).length;
  return {
    items: WEEKDAY_KEYS.map((key, day) => {
      const on = weekdayIsOn(mask, day);
      // The last day left cannot be turned off: quiet hours always repeat on some day.
      return { key: `${WEEKDAY_ROW_PREFIX}${day}`, label: t(`notificationAlertSettings.${key}`), kind: "toggle" as const, value: on, disabled: on && onCount === 1 };
    }),
  };
}
function toggleDay(item: FlareSettingsItem, on: boolean): void {
  if (!item.key.startsWith(WEEKDAY_ROW_PREFIX)) return;
  const day = Number(item.key.slice(WEEKDAY_ROW_PREFIX.length));
  const mask = props.value.quietHours.weekdays;
  const next = weekdayToggle(mask, day, on);
  if (next !== mask) changeQuietHours({ weekdays: next });
}

const choiceOpen = computed(() => picker.value === "preview" || picker.value === "multiDevice");
const choiceTitle = computed(() => (shown.value === "multiDevice" ? t("notificationAlertSettings.multiDevice") : t("notificationAlertSettings.preview")));
const choiceOptions = computed<FlareSelectOption[]>(() => (shown.value === "multiDevice"
  ? multiDeviceAlerts.map((policy) => ({ value: policy, label: multiDeviceLabel(policy) }))
  : notificationPreviews.map((preview) => ({ value: preview, label: previewLabel(preview) }))));
const choiceValue = computed(() => (shown.value === "multiDevice" ? props.value.multiDevice : props.value.preview));
function pickChoice(choice: string): void {
  if (shown.value === "multiDevice") {
    if (multiDeviceAlerts.includes(choice as FlareMultiDeviceAlert)) emit("change", { ...props.value, multiDevice: choice as FlareMultiDeviceAlert });
  } else if (notificationPreviews.includes(choice as FlareNotificationPreview)) {
    emit("change", { ...props.value, preview: choice as FlareNotificationPreview });
  }
  picker.value = null;
}
</script>

<template>
  <div class="flare-notification-alert">
    <slot name="sections" :sections="sections()" :select="select" :toggle="toggle">
      <FlareSettingsList :sections="sections()" @select="select" @toggle="toggle" />
    </slot>
    <FlareBottomSheet :open="timeOpen" :title="timeTitle" @close="picker = null">
      <FlareTimeChoice
        v-if="timeOpen"
        sheet
        :value="timeValue"
        :minute-step="QUIET_HOURS_MINUTE_STEP"
        @confirm="pickTime"
        @cancel="picker = null"
      />
    </FlareBottomSheet>
    <FlareBottomSheet :open="picker === 'repeat'" :title="t('notificationAlertSettings.repeat')" @close="picker = null">
      <FlareSettingsList :sections="[weekdaySection()]" @toggle="toggleDay" />
    </FlareBottomSheet>
    <FlareBottomSheet :open="choiceOpen" :title="choiceTitle" @close="picker = null">
      <div class="flare-notification-alert__choices">
        <FlareRadioGroup vertical :model-value="choiceValue" :options="choiceOptions" @change="pickChoice" />
      </div>
    </FlareBottomSheet>
  </div>
</template>

<style scoped>
.flare-notification-alert { min-width: 0; }
.flare-notification-alert__choices {
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg) var(--flare-size-spacing-lg);
}
</style>
