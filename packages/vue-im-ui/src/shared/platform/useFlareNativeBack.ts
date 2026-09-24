import { onScopeDispose, toValue, watch, type MaybeRefOrGetter } from "vue";
import { useFlarePlatformSafe, type FlarePlatformContext } from "./useFlarePlatform";

/**
 * While `active` is true, the platform back action (the Android back gesture, or the browser's back
 * when the host creates its adapter with `createWebPlatformAdapter({ historyBack: true })`) calls
 * `onBack` instead of leaving the page. The layer that became active last receives it first.
 *
 * `active` must be false whenever the layer is off screen, and `onBack` should close the layer:
 * otherwise back stays captured. Does nothing unless the capabilities declare `nativeBack` and the
 * adapter implements `onNativeBack`.
 */
export function useFlareNativeBack(active: MaybeRefOrGetter<boolean>, onBack: () => void): void {
  const platform = useFlarePlatformSafe();
  let release: (() => void) | undefined;
  function stop(): void {
    release?.();
    release = undefined;
  }
  watch(
    () => Boolean(toValue(active)) && hasNativeBack(platform),
    (enabled) => {
      stop();
      if (enabled) release = claimNativeBack(platform, onBack);
    },
    { immediate: true },
  );
  onScopeDispose(stop);
}

function hasNativeBack(platform: FlarePlatformContext): boolean {
  return platform.capabilities.value.nativeBack && typeof platform.adapter.value.onNativeBack === "function";
}

/**
 * Claim the platform back for `onBack` now and return the release, or undefined when the platform
 * has none. For a layer that opens imperatively and should not keep a watcher while closed (a
 * message menu exists once per timeline message). `onBack` may return `false` to leave the action
 * unconsumed (a layer that is mounted but hidden); anything else counts as consumed.
 */
export function claimNativeBack(platform: FlarePlatformContext, onBack: () => boolean | void): (() => void) | undefined {
  if (!hasNativeBack(platform)) return undefined;
  return platform.adapter.value.onNativeBack!(() => onBack() !== false);
}
