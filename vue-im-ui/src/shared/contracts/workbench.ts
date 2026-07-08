export type FlareWorkbenchShellMode = "conversations" | "chat" | "lab";

export function workbenchShellClass(mode: FlareWorkbenchShellMode | string | undefined): string {
  if (mode === "chat") return "workbench-shell--chat";
  if (mode === "lab") return "workbench-shell--lab";
  return "workbench-shell--conversations";
}
