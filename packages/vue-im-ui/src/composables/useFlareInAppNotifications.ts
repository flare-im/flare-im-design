import { shallowRef, type Ref } from "vue";
import {
  emptyInAppNotificationQueue,
  inAppNotificationClear,
  inAppNotificationClearAll,
  inAppNotificationDismiss,
  inAppNotificationPresent,
  type FlareInAppNotification,
  type FlareInAppNotificationQueue,
  type FlareInAppNotificationStep,
} from "../shared/contracts/in-app-notification";

/**
 * The presenter of the in-app new-message banner: the app feeds it and FlareInAppNotificationHost draws it. The app
 * forwards the engine's `notification.present` events whose surface is `inApp` to `present`, and its
 * `notification.clear` events to `clear` / `clearAll`; the queue follows spec/in-app-notification-vectors.json and the
 * host owns the time on screen. No timers live here, so it is safe to create outside a component (a store) and
 * during SSR.
 */
export interface FlareInAppNotifications {
  /** The visible banner. */
  readonly current: Readonly<Ref<FlareInAppNotification | null>>;
  /** Banners waiting, oldest first, at most three. */
  readonly pending: Readonly<Ref<readonly FlareInAppNotification[]>>;
  /** Moves whenever a banner shows or the visible one is replaced: the host starts its time over. */
  readonly revision: Readonly<Ref<number>>;
  /** Shows, replaces or queues an item. */
  present(notification: FlareInAppNotification): void;
  /** The visible banner goes and the next waiting one shows. */
  dismiss(): void;
  /** Takes away the banners of these collapse ids (the engine's `notification.clear`). */
  clear(collapseIds: readonly string[]): void;
  /** Takes every banner away (`notification.clear` with `all`). */
  clearAll(): void;
}

export function createFlareInAppNotifications(): FlareInAppNotifications {
  const current = shallowRef<FlareInAppNotification | null>(null);
  const pending = shallowRef<readonly FlareInAppNotification[]>([]);
  const revision = shallowRef(0);

  function queue(): FlareInAppNotificationQueue {
    return current.value || pending.value.length ? { current: current.value, pending: pending.value } : emptyInAppNotificationQueue;
  }
  function apply(step: FlareInAppNotificationStep): void {
    current.value = step.queue.current;
    pending.value = step.queue.pending;
    if (step.restart) revision.value += 1;
  }

  return {
    current,
    pending,
    revision,
    present: (notification) => apply(inAppNotificationPresent(queue(), notification)),
    dismiss: () => apply(inAppNotificationDismiss(queue())),
    clear: (collapseIds) => apply(inAppNotificationClear(queue(), collapseIds)),
    clearAll: () => apply(inAppNotificationClearAll()),
  };
}
