import { computed, inject, onBeforeUnmount, provide, ref, type ComputedRef, type InjectionKey, type Ref } from "vue";

/**
 * Sheet content that draws its own header row (a title with Cancel, say) tells the nearest kit sheet so,
 * and a sheet in `fill` mode then keeps its `title` as the accessible name only — the heading is not drawn
 * twice. Spec BottomSheet notes ("Fill mode").
 */
const FLARE_SHEET_HEADER: InjectionKey<{ owners: Ref<number> }> = Symbol("flare-sheet-header");

/** Called by a sheet surface: the content below it may declare its own header. */
export function provideFlareSheetHeader(): ComputedRef<boolean> {
  const owners = ref(0);
  provide(FLARE_SHEET_HEADER, { owners });
  return computed(() => owners.value > 0);
}

/**
 * Declare, from the setup of sheet content, that it draws its own header. Outside a kit sheet it does
 * nothing; the declaration ends when the content unmounts.
 */
export function useFlareSheetOwnHeader(): void {
  const context = inject(FLARE_SHEET_HEADER, null);
  if (!context) return;
  context.owners.value += 1;
  onBeforeUnmount(() => { context.owners.value -= 1; });
}
