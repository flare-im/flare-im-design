/** A visible, quiet page may refresh; a form must never lose an in-progress edit. */
export function flarePluginMayRefresh(state: { visible: boolean; foreground: boolean; loading: boolean; refreshing: boolean; busy: boolean; interaction: boolean }): boolean {
  return state.visible && state.foreground && !state.loading && !state.refreshing && !state.busy && !state.interaction;
}
