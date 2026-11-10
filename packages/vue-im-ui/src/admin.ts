/** Focused admin entry: consume shared controls without importing the chat/composer graph. */
export { default as FlareUiProvider } from "./design-system/provider/FlareUiProvider.vue";
export { default as FlareAuthShell } from "./components/layout/FlareAuthShell.vue";
export { default as FlareStatusBanner } from "./components/general/FlareStatusBanner.vue";
export { default as FlareDataTable } from "./components/data/FlareDataTable.vue";
export { default as FlareAdminList } from "./components/data/FlareAdminList.vue";
export { default as FlareAdminActions } from "./components/data/FlareAdminActions.vue";
export { default as FlareAdminSettings } from "./components/data/FlareAdminSettings.vue";
export { default as FlareAdminWorkspaceNavigation } from "./components/data/FlareAdminWorkspaceNavigation.vue";
export type {
  FlareAdminWorkspaceNavigationGroup,
  FlareAdminWorkspaceNavigationItem,
} from "./components/data/FlareAdminWorkspaceNavigation.vue";
export { default as FlareAdminSection } from "./components/data/FlareAdminSection.vue";
export { default as FlareAdminPolicyCard } from "./components/data/FlareAdminPolicyCard.vue";
export { default as FlareAdminCardGrid } from "./components/data/FlareAdminCardGrid.vue";
export { default as FlareAdminChecklist } from "./components/data/FlareAdminChecklist.vue";
export type {
  FlareAdminCheckItem,
  FlareAdminCheckStatus,
} from "./components/data/FlareAdminChecklist.vue";
export { default as FlareAdminHeatGrid } from "./components/data/FlareAdminHeatGrid.vue";
export type {
  FlareAdminHeatAxis,
  FlareAdminHeatCell,
  FlareAdminHeatTone,
} from "./components/data/FlareAdminHeatGrid.vue";
export { default as FlareDescriptionList } from "./components/data/FlareDescriptionList.vue";
export type { FlareDescriptionItem } from "./components/data/description-list";
export { default as FlareMetricTile } from "./components/data/FlareMetricTile.vue";
export { default as FlareAdminRelationshipTree } from "./components/data/FlareAdminRelationshipTree.vue";
export type { FlareAdminRelationshipNode } from "./components/data/FlareAdminRelationshipTree.vue";
export { default as FlareAdminSortableList } from "./components/data/FlareAdminSortableList.vue";
export type { FlareAdminSortableItem } from "./components/data/FlareAdminSortableList.vue";
// The composer "+" grid, for a console's preview of an application's panel layout.
export { default as FlareComposerActionPanel } from "./components/composer/FlareComposerActionPanel.vue";
export type {
  FlareComposerActionItem,
  FlareComposerPanelFormFactor,
} from "./components/composer/FlareComposerActionPanel.vue";
export { default as FlareAdminForm } from "./components/form/FlareAdminForm.vue";
export { default as FlareAdminModal } from "./components/form/FlareAdminModal.vue";
export { default as FlareAdminFormGrid } from "./components/form/FlareAdminFormGrid.vue";
export type {
  FlareAdminColumn,
  FlareAdminPagination,
} from "./components/data/admin-list";
export { default as FlareChartCard } from "./components/data/FlareChartCard.vue";
export { default as FlareEmptyState } from "./components/general/FlareEmptyState.vue";
export type { FlareChartPoint } from "./components/data/chart-geometry";
export { default as FlarePermissionTree } from "./components/data/FlarePermissionTree.vue";
export { default as FlarePermissionWorkbench } from "./components/data/FlarePermissionWorkbench.vue";
export type {
  FlarePermissionGroup,
  FlarePermissionMenu,
  FlarePermissionAction,
} from "./components/data/permission-workbench";
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
export { default as FlareAdminPopconfirm } from "./components/scenes/FlareAdminPopconfirm.vue";
export { default as FlareInput } from "./components/general/FlareInput.vue";
export { default as FlareFileUpload } from "./components/media/FlareFileUpload.vue";
export type { FlareUploadState } from "./shared/contracts/upload";
export { default as FlareFormField } from "./components/form/FlareFormField.vue";
export { default as FlareFilterTabs } from "./components/general/FlareFilterTabs.vue";
export { default as FlareActionMenu } from "./components/general/FlareActionMenu.vue";
export { default as FlareFilterBar } from "./components/general/FlareFilterBar.vue";
export { default as FlareCheckbox } from "./components/form/FlareCheckbox.vue";
export { default as FlareAdminEntitySelect } from "./components/form/FlareAdminEntitySelect.vue";
export type { FlareAdminEntityOption } from "./components/form/FlareAdminEntitySelect.vue";
export { default as FlareAdminMessageBody } from "./components/data/FlareAdminMessageBody.vue";
export type { FlareAdminAttachment } from "./components/data/FlareAdminMessageBody.vue";
export { default as FlareAdminAttachmentPreview } from "./components/data/FlareAdminAttachmentPreview.vue";
export { downloadAuthorizedAttachment } from "./utils/browserDownload";

export { default as FlareSchemaForm } from "./components/form/FlareSchemaForm.vue";

// Plugin admin pages (core SDK dispatch_admin views): the same PluginView, PluginForm and detail sheet the
// chat cards use, so a console draws plugin pages without importing the whole component index.
export { default as FlarePluginView } from "./components/messages/FlarePluginView.vue";
export { default as FlarePluginAdminList } from "./components/messages/FlarePluginAdminList.vue";
export { default as FlareMarkdownPreview } from "./components/message-preview/MarkdownPreview.vue";
export { default as FlarePluginForm } from "./components/form/FlarePluginForm.vue";
export { default as FlarePluginDetailSheet } from "./components/messages/FlarePluginDetailSheet.vue";
export type {
  FlarePluginField,
  FlarePluginFormat,
  FlarePluginProtectedItem,
  FlarePluginProtectedMediaBlock,
  FlarePluginProtectedMediaRead,
  FlarePluginProtectedMediaState,
  FlarePluginReference,
  FlarePluginReferenceRequest,
  FlarePluginRowCell,
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
  FlarePluginStrings,
  FlarePluginRowsBlock,
  FlarePluginUser,
  FlarePluginViewInset,
  FlarePluginViewModel,
} from "./shared/contracts/plugin-ui";
export { flarePluginFilterInputs } from "./shared/contracts/plugin-ui";

export type {
  SchemaSelection,
  SchemaSelectionLabels,
} from "./components/form/schema-selections";

export { default as FlareUserIdentity } from "./components/data/FlareUserIdentity.vue";
export type { FlareUserIdentityValue } from "./components/data/FlareUserIdentity.vue";
export { default as FlareAdminIconPicker } from "./components/form/FlareAdminIconPicker.vue";
export type { FlareAdminIconOption } from "./components/form/FlareAdminIconPicker.vue";
export { flarePluginProtectedMediaUrl } from "./shared/contracts/plugin-ui";
