import { flarePluginArchetype, flarePluginPageAppearanceOf, flarePluginPageInlineForm, flarePluginResultBlock } from "./plugin-experience";
import type { FlarePluginPageAppearance, FlarePluginViewModel } from "./plugin-ui";

/** Why a plugin page reads itself again (spec PluginPage rules.refresh, plugin-refresh-vectors afterAction/afterReturn):
 * pull or key by hand, timer for refreshMs and a pending result, action after an action settles, return when the host
 * comes back to the page. */
export type FlarePluginRefreshReason = "pull" | "key" | "timer" | "action" | "return";

/** A visible, quiet page may refresh; a form must never lose an in-progress edit. */
export function flarePluginMayRefresh(state: { visible: boolean; foreground: boolean; loading: boolean; refreshing: boolean; busy: boolean; interaction: boolean }): boolean {
  return state.visible && state.foreground && !state.loading && !state.refreshing && !state.busy && !state.interaction;
}

/** How control came back to a page (afterReturn): the next page popped, a result's done key, or an action that sent a card. */
export type FlarePluginReturnEvent = "pop" | "done" | "messageCard";

/** R4 afterReturn: refresh this page (`self`), the flow's origin page, or close the plugin pages. */
export function flarePluginAfterReturn(event: FlarePluginReturnEvent, origin = false): { refresh: boolean; reason?: "return"; page: "self" | "origin" | "close" } {
  if (event === "pop") return { refresh: true, reason: "return", page: "self" };
  if (event === "done" && origin) return { refresh: true, reason: "return", page: "origin" };
  return { refresh: false, page: "close" };
}

/** §12.1: what a stacked plugin page is to the done key (spec/plugin-refresh-vectors.json doneTarget). */
export type FlarePluginPageKind = "overview" | "task" | "records" | "result";

/**
 * §12.1 doneTarget: the index (bottom to top) of the nearest page below the top one that is an overview or a records
 * page — done pops to it and refreshes it with reason return; null closes the host's plugin page stack.
 */
export function flarePluginDoneTarget(stack: ReadonlyArray<FlarePluginPageKind>): number | null {
  for (let index = stack.length - 2; index >= 0; index--) if (stack[index] === "overview" || stack[index] === "records") return index;
  return null;
}

/**
 * What a page is for {@link flarePluginDoneTarget}, read from the view it shows as FlarePluginPage draws it (`appearance`
 * absent derives it, R12): a result block makes a result page; an account is its layout's archetype (wallet an overview,
 * flow a task, else records); a document is its R2 archetype. No view yet (or unavailable): a task, which done passes over.
 */
export function flarePluginPageKind(view: FlarePluginViewModel | undefined, appearance?: FlarePluginPageAppearance): FlarePluginPageKind {
  if (!view || !view.available) return "task";
  if (flarePluginResultBlock(view)) return "result";
  if (flarePluginPageAppearanceOf(view, appearance) === "account") {
    const layout = view.presentation?.props.layout;
    return !view.presentation || layout === "wallet" ? "overview" : layout === "flow" ? "task" : "records";
  }
  const archetype = flarePluginArchetype(view, { embedded: true, inlineFormActionId: flarePluginPageInlineForm(view) });
  return archetype === "overview" || archetype === "records" ? archetype : "task";
}
