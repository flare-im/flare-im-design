import type { Component } from "vue";
import { FolderOpenOutline } from "../shared/icon-glyphs";
import { flareIcons, type FlareIconName } from "../shared/icons";
import type { MessageMenuSheetIcon } from "./buildMessageMenuOptions";

/** Semantic icon per built-in message menu item. `folder` opens the containing folder and has no cross-platform name. */
const MESSAGE_MENU_ICON_NAMES: Record<Exclude<MessageMenuSheetIcon, "folder">, FlareIconName> = {
  reply: "reply",
  forward: "forward",
  recall: "recall",
  resend: "refresh",
  "multi-select": "multi-select",
  mark: "mark",
  pin: "pin",
  "pin-self": "pin-self",
  unpin: "unpin",
  copy: "copy",
  edit: "edit",
  preview: "eye",
  download: "download",
  delete: "delete",
};

export const MESSAGE_MENU_ICON_COMPONENTS: Record<MessageMenuSheetIcon, Component> = {
  ...Object.fromEntries(Object.entries(MESSAGE_MENU_ICON_NAMES).map(([icon, name]) => [icon, flareIcons[name]])),
  folder: FolderOpenOutline,
} as Record<MessageMenuSheetIcon, Component>;

/** The glyph of a menu item: a built-in menu icon, or a semantic Flare icon name for host actions. */
export function messageMenuGlyph(icon?: string): Component | undefined {
  if (!icon) return undefined;
  return MESSAGE_MENU_ICON_COMPONENTS[icon as MessageMenuSheetIcon] ?? flareIcons[icon as FlareIconName];
}
