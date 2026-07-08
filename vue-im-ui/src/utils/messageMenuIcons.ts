import { h, type Component } from "vue";
import {
  ArrowRedoOutline,
  ArrowUndoOutline,
  CopyOutline,
  CreateOutline,
  DownloadOutline,
  EyeOutline,
  FlagOutline,
  FolderOpenOutline,
  ListOutline,
  PinOutline,
  RefreshOutline,
  TrashOutline,
} from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { MessageMenuSheetIcon } from "./buildMessageMenuOptions";

export const MESSAGE_MENU_ICON_COMPONENTS: Record<MessageMenuSheetIcon, Component> = {
  reply: ArrowUndoOutline,
  forward: ArrowRedoOutline,
  recall: ArrowUndoOutline,
  resend: RefreshOutline,
  "multi-select": ListOutline,
  mark: FlagOutline,
  pin: PinOutline,
  "pin-self": PinOutline,
  unpin: PinOutline,
  copy: CopyOutline,
  edit: CreateOutline,
  preview: EyeOutline,
  download: DownloadOutline,
  folder: FolderOpenOutline,
  delete: TrashOutline,
};

export function renderMessageMenuIcon(icon?: MessageMenuSheetIcon, danger = false) {
  if (!icon) return undefined;
  const component = MESSAGE_MENU_ICON_COMPONENTS[icon];
  if (!component) return undefined;
  return () =>
    h(
      NIcon,
      {
        size: 18,
        color: danger ? "var(--im-danger)" : undefined,
      },
      { default: () => h(component) },
    );
}
