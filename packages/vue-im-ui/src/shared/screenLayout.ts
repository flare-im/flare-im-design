import { computed, inject, type ComputedRef, type InjectionKey } from "vue";

/** Internal presentation context: nested screens reset it; callbacks and data remain host-owned. */
export const screenLayoutKey: InjectionKey<{
  detail: ComputedRef<boolean>;
  sectioned: ComputedRef<boolean>;
  title: ComputedRef<string | undefined>;
}> = Symbol("flare-screen-layout");

export function useScreenLayout() {
  const screen = inject(screenLayoutKey, null);
  return {
    detail: computed(() => screen?.detail.value ?? false),
    sectioned: computed(() => screen?.sectioned.value ?? false),
    title: computed(() => screen?.title.value),
  };
}
