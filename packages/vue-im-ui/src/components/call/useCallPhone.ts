import { computed, onBeforeUnmount, onMounted, ref, type ComputedRef } from "vue";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import { FLARE_BREAKPOINT_H5_MAX } from "../../shared/contracts/layout";

/**
 * The phone form of a call (docs/plugin-experience.md §0.2): the provider's phone shell (`bottomSheet`), or, with or
 * without a provider, a viewport narrower than breakpoints.sm (600), so a host without FlareUiProvider still gets it.
 */
export function useCallPhone(): ComputedRef<boolean> {
  const platform = useFlarePlatformSafe();
  const query = `(max-width: ${FLARE_BREAKPOINT_H5_MAX}px)`;
  const list = typeof window !== "undefined" ? window.matchMedia?.(query) : undefined;
  const narrow = ref(Boolean(list?.matches));
  const sync = () => { narrow.value = Boolean(list?.matches); };
  onMounted(() => list?.addEventListener?.("change", sync));
  onBeforeUnmount(() => list?.removeEventListener?.("change", sync));
  return computed(() => platform.capabilities.value.bottomSheet || narrow.value);
}
