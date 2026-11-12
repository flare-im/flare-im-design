/**
 * NotificationDeliverySettings contract: whether new messages can reach the person when the app is not in
 * front. The host reads the platform (the notification permission, the battery settings) and runs every action;
 * the component only shows the state and dispatches.
 */

/** The system notification permission, as a settings row says it. */
export type NotificationStatus = "on" | "off" | "notTurnedOn";

/** What the system lets the app do in the background, in the words of the platform's battery settings. */
export type BackgroundDelivery = "unrestricted" | "optimized" | "restricted";

/** One extra way to keep background delivery working, offered by the host (a phone maker's auto-start page). */
export interface NotificationGuideAction {
  /** Row label; defaults to the kit's "Auto-start settings". */
  label?: string;
  onSelect: () => void;
}

export const notificationStatuses: readonly NotificationStatus[] = ["on", "off", "notTurnedOn"];
export const backgroundDeliveries: readonly BackgroundDelivery[] = ["unrestricted", "optimized", "restricted"];

/**
 * Row keys of the section, stable for tests and for hosts that read the rendered rows. A host that places the group
 * in its own settings list (the `section` slot) keeps its own rows on other keys.
 */
export const NOTIFICATION_STATUS_ROW = "notifications";
export const BACKGROUND_DELIVERY_ROW = "backgroundDelivery";
export const BATTERY_SETTINGS_ROW = "batteryUsage";
