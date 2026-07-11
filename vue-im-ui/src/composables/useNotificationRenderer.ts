import { inject, provide, type Component, type InjectionKey } from "vue";

/** Normalized notification content handed to a host-provided renderer. */
export type FlareNotificationPayload = {
  title: string;
  body: string;
  notificationType: string;
  data: Record<string, string>;
};

/**
 * Host extension point for notification bodies. The kit renders a neutral
 * centered line by default; a product can inject richer notices (call-signal
 * tiles, custom system cards, …) without the kit knowing product semantics.
 *
 * Return:
 *  - a `Component` — rendered with a `payload` prop, replacing the default line
 *  - `false` — hide the notification entirely (it is surfaced elsewhere)
 *  - `null` / `undefined` — fall back to the default centered line
 */
export type FlareNotificationResolver = (
  payload: FlareNotificationPayload,
) => Component | false | null | undefined;

const defaultResolver: FlareNotificationResolver = () => null;

const flareNotificationResolverKey: InjectionKey<FlareNotificationResolver> = Symbol(
  "flare-notification-resolver",
);

/** Provide a notification renderer to descendant message views. */
export function useFlareNotificationProvider(resolver?: FlareNotificationResolver): void {
  provide(flareNotificationResolverKey, resolver ?? defaultResolver);
}

/** Resolve the host notification renderer (a no-op default when none is provided). */
export function useFlareNotificationResolver(): FlareNotificationResolver {
  return inject(flareNotificationResolverKey, defaultResolver);
}
