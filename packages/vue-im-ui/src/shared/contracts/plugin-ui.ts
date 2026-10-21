/** Presentation only. Core SDK resolves declarations, leases and fallback. */
export interface FlarePluginViewModel {
  available: boolean;
  title: string;
  fields: ReadonlyArray<{ label: string; value: string }>;
  actions: ReadonlyArray<{ id: string; label: string }>;
}
