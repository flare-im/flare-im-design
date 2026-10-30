import { computed, inject, onBeforeUnmount, provide, ref, watch, type ComputedRef, type InjectionKey, type Ref } from "vue";

/**
 * Sheet content that draws its own header row (a title with Cancel, say) tells the nearest kit sheet so,
 * and a sheet in `fill` mode then keeps its `title` as the accessible name only — the heading is not drawn
 * twice. Spec BottomSheet notes ("Fill mode").
 */
const FLARE_SHEET_HEADER: InjectionKey<{ owners: Ref<number>; backs: Array<() => void> }> = Symbol("flare-sheet-header");

/** Called by a sheet surface: the content below it may declare its own header. */
export function provideFlareSheetHeader(): ComputedRef<boolean> {
  return provideFlareSurfaceHeader().ownsHeader;
}

/**
 * Called by a surface that also hands Escape and the platform back to the page inside (FlareDrawer, spec Drawer
 * notes): `back()` runs the way back of the page that declared one last and says whether there was one; without one
 * the surface closes as usual.
 */
export function provideFlareSurfaceHeader(): { ownsHeader: ComputedRef<boolean>; back: () => boolean } {
  const owners = ref(0);
  const backs: Array<() => void> = [];
  provide(FLARE_SHEET_HEADER, { owners, backs });
  return {
    ownsHeader: computed(() => owners.value > 0),
    back: () => {
      const last = backs[backs.length - 1];
      if (!last) return false;
      last();
      return true;
    },
  };
}

/**
 * Declare, from the setup of sheet content, that it draws its own header. Outside a kit sheet it does
 * nothing; the declaration ends when the content unmounts. `back` is the content's own way back (a page's back key):
 * a surface that routes Escape and the platform back to its page calls it instead of closing. While `active` returns
 * false the content declares nothing.
 */
export function useFlareSheetOwnHeader(options: { active?: () => boolean; back?: () => void } = {}): void {
  const context = inject(FLARE_SHEET_HEADER, null);
  if (!context) return;
  const back = options.back ? () => options.back?.() : undefined;
  let held = false;
  function hold(on: boolean): void {
    if (on === held) return;
    held = on;
    context!.owners.value += on ? 1 : -1;
    if (!back) return;
    if (on) context!.backs.push(back);
    else context!.backs.splice(context!.backs.indexOf(back), 1);
  }
  if (options.active) watch(options.active, hold, { immediate: true });
  else hold(true);
  onBeforeUnmount(() => hold(false));
}

/**
 * Whether the calling content sits in a kit sheet (FlareBottomSheet, and the FlareModal it hands its content to
 * off the phone). Content that draws its own card shell elsewhere drops it there: the sheet is the surface.
 */
export function useFlareInsideSheet(): boolean {
  return inject(FLARE_SHEET_HEADER, null) !== null;
}
