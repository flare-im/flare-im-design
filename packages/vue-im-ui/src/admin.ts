/** Focused admin entry: consume shared controls without importing the chat/composer graph. */
export { default as FlareUiProvider } from "./design-system/provider/FlareUiProvider.vue";
export { default as FlareDataTable } from "./components/data/FlareDataTable.vue";
export { default as FlareChartCard } from "./components/data/FlareChartCard.vue";
export { default as FlareEmptyState } from "./components/general/FlareEmptyState.vue";
export type { FlareChartPoint } from "./components/data/chart-geometry";
export { default as FlarePermissionTree } from "./components/data/FlarePermissionTree.vue";
export type {
  FlarePermissionNode,
  FlarePermissionSelectionMode,
} from "./components/data/permission-tree";
export type {
  FlareDataTableColumn,
  FlareDataTableRow,
  FlareDataTablePagination,
} from "./components/data/data-table";
export { default as FlareButton } from "./components/general/FlareButton.vue";
export { default as FlareDrawer } from "./components/general/FlareDrawer.vue";
export { default as FlareDangerConfirm } from "./components/scenes/FlareDangerConfirm.vue";
export { default as FlareInput } from "./components/general/FlareInput.vue";
export { default as FlareFormField } from "./components/form/FlareFormField.vue";
export { default as FlareCheckbox } from "./components/form/FlareCheckbox.vue";

export { default as FlareSchemaForm } from "./components/form/FlareSchemaForm.vue";

// Plugin admin pages (core SDK dispatch_admin views): the same PluginView, PluginForm and detail sheet the
// chat cards use, so a console draws plugin pages without importing the whole component index.
export { default as FlarePluginView } from "./components/messages/FlarePluginView.vue";
export { default as FlarePluginForm } from "./components/form/FlarePluginForm.vue";
export { default as FlarePluginDetailSheet } from "./components/messages/FlarePluginDetailSheet.vue";
export type {
  FlarePluginAction,
  FlarePluginActionPayload,
  FlarePluginActionStyle,
  FlarePluginBlock,
  FlarePluginFormError,
  FlarePluginFormIssue,
  FlarePluginInput,
  FlarePluginInputKind,
  FlarePluginMember,
  FlarePluginResolveUser,
  FlarePluginRow,
  FlarePluginRowsBlock,
  FlarePluginUser,
  FlarePluginViewInset,
  FlarePluginViewModel,
} from "./shared/contracts/plugin-ui";
export { flarePluginFilterInputs } from "./shared/contracts/plugin-ui";
