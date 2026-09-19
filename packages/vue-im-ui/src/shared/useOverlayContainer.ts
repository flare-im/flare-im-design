// Overlay teleport target — where adaptive sheets (Select, TimePicker, …) mount
// their scrim + panel. Defaults to "body" (full-screen on a real device). A host
// can provide a specific element to scope overlays to a container — e.g. the docs
// device-frame preview teleports the app-mode sheet INTO the phone frame so its
// position:fixed is contained by the frame's transform, instead of the page.
import { computed, inject, provide, ref, toValue, type InjectionKey, type MaybeRefOrGetter, type Ref } from "vue";

export type FlareOverlayTarget = string | HTMLElement;

const OVERLAY_CONTAINER_KEY: InjectionKey<Ref<FlareOverlayTarget>> = Symbol("flare-overlay-container");

/** Provide the overlay teleport target for this subtree (element or selector; falls back to "body"). */
export function provideFlareOverlayContainer(target: MaybeRefOrGetter<FlareOverlayTarget | null | undefined>): void {
  provide(
    OVERLAY_CONTAINER_KEY,
    computed(() => toValue(target) ?? "body"),
  );
}

/** Read the overlay teleport target; "body" when no host provided one. */
export function useFlareOverlayContainer(): Ref<FlareOverlayTarget> {
  return inject(OVERLAY_CONTAINER_KEY, ref<FlareOverlayTarget>("body"));
}
