import {
  inject,
  onScopeDispose,
  provide,
  toValue,
  watch,
  type InjectionKey,
  type MaybeRefOrGetter,
  type Ref,
} from "vue";
import type { FlareApplicationResponsiveMode } from "../shared/contracts/application";
import { provideFlareShellPlatform } from "../shared/platform/useFlarePlatform";
import { provideFlareShellAdaptive } from "./useAdaptiveMode";
import { provideFlareShellViewport } from "./useViewport";

// The shell contract (FR-095): a shell measures its own box and hands the mode down, keeps each destination
// it has shown, and steps its phone navigation aside while the active destination shows a page beyond its root.

interface FlareShellContext {
  responsiveMode: Readonly<Ref<FlareApplicationResponsiveMode | undefined>>;
}

interface FlareDestinationRegistry {
  enter(): () => void;
  claimMain(): () => void;
}

const shellKey: InjectionKey<FlareShellContext> = Symbol("flare-shell");
const destinationKey: InjectionKey<FlareDestinationRegistry> = Symbol("flare-shell-destination");

/**
 * A shell hands the mode its own box resolves to (undefined until measured) to everything inside it — and makes it the
 * one answer to "is this a phone" there (FR-139): the adaptive, viewport and platform contexts its subtree reads follow
 * the shell's mode, so a select, a picker, the composer, a sheet and the message menu choose their presentation from
 * the shell's box and not from the window.
 */
export function provideFlareShell(responsiveMode: Readonly<Ref<FlareApplicationResponsiveMode | undefined>>): void {
  provide(shellKey, { responsiveMode });
  const adaptive = provideFlareShellAdaptive(responsiveMode);
  provideFlareShellViewport(responsiveMode);
  provideFlareShellPlatform(adaptive);
}

/** The mode of the shell this component is inside, or undefined outside any shell. */
export function useFlareShellResponsiveMode(): Readonly<Ref<FlareApplicationResponsiveMode | undefined>> | undefined {
  return inject(shellKey, null)?.responsiveMode;
}

/**
 * A shell destination counts the pages beyond its root that are showing inside it, and is the page's main landmark
 * unless a pane frame inside it claims that role for its own content pane (and marks its list and detail as
 * complementary beside it).
 */
export function provideFlareDestination(depth: Ref<number>, mainClaims: Ref<number>): void {
  provide(destinationKey, {
    claimMain() {
      mainClaims.value += 1;
      let released = false;
      return () => {
        if (released) return;
        released = true;
        mainClaims.value -= 1;
      };
    },
    enter() {
      depth.value += 1;
      let left = false;
      return () => {
        if (left) return;
        left = true;
        depth.value -= 1;
      };
    },
  });
}

/** A pane frame inside a shell destination takes the main landmark for its content pane, for as long as it is mounted. */
export function useFlareDestinationMainLandmark(): void {
  const release = inject(destinationKey, null)?.claimMain();
  if (release) onScopeDispose(release);
}

/**
 * While `active` is true, this component is a page beyond the root of the destination it is shown in: a
 * detail, a sub-page, a chat that took the list's place. The shell hides its phone navigation while the
 * active destination has one. Kit pages declare themselves (FlareScreen with `back`, a pane frame showing a
 * pane other than its root); a page the host draws itself declares itself with this. Outside a shell it does
 * nothing.
 */
export function useFlareDestinationDepth(active: MaybeRefOrGetter<boolean>): void {
  const registry = inject(destinationKey, null);
  if (!registry) return;
  let leave: (() => void) | undefined;
  watch(
    () => Boolean(toValue(active)),
    (on) => {
      if (on && !leave) leave = registry.enter();
      else if (!on && leave) {
        leave();
        leave = undefined;
      }
    },
    { immediate: true },
  );
  onScopeDispose(() => {
    leave?.();
    leave = undefined;
  });
}
