/** Presentation-only selection model. The host owns permission bundles and all writes. */
export interface FlarePermissionAction {
  key: string;
  label: string;
  disabled?: boolean;
}
export interface FlarePermissionMenu extends FlarePermissionAction {
  kind?: "menu" | "button";
  actions: FlarePermissionAction[];
}
export interface FlarePermissionGroup {
  key: string;
  label: string;
  menus: FlarePermissionMenu[];
}
export type FlarePermissionFilter = "all" | "selected" | "changed";

export function permissionWorkbenchItems(
  groups: readonly FlarePermissionGroup[],
) {
  return groups.flatMap((group) =>
    group.menus.flatMap((menu) => [
      { ...menu, kind: menu.kind ?? "menu", context: group.label },
      ...menu.actions.map((action) => ({
        ...action,
        kind: "button" as const,
        context: menu.label,
        disabled: menu.disabled || action.disabled,
      })),
    ]),
  );
}
export function permissionWorkbenchChanges(
  groups: readonly FlarePermissionGroup[],
  checked: readonly string[],
  baseline: readonly string[],
) {
  const selected = new Set(checked),
    before = new Set(baseline);
  return permissionWorkbenchItems(groups)
    .filter((item) => selected.has(item.key) !== before.has(item.key))
    .map((item) => ({ ...item, added: selected.has(item.key) }));
}
export function filterPermissionWorkbench(
  groups: readonly FlarePermissionGroup[],
  query: string,
  mode: FlarePermissionFilter,
  checked: readonly string[],
  baseline: readonly string[],
) {
  const needle = query.trim().toLocaleLowerCase(),
    selected = new Set(checked),
    before = new Set(baseline);
  const admitted = (key: string) =>
    mode === "all" ||
    (mode === "selected"
      ? selected.has(key)
      : selected.has(key) !== before.has(key));
  return groups.flatMap((group) => {
    const groupMatch = group.label.toLocaleLowerCase().includes(needle);
    const menus = group.menus.flatMap((menu) => {
      const menuMatch =
        !needle ||
        groupMatch ||
        menu.label.toLocaleLowerCase().includes(needle);
      const actions = menu.actions.filter(
        (action) =>
          admitted(action.key) &&
          (menuMatch || action.label.toLocaleLowerCase().includes(needle)),
      );
      return (menuMatch && admitted(menu.key)) || actions.length
        ? [{ ...menu, actions }]
        : [];
    });
    return menus.length ? [{ ...group, menus }] : [];
  });
}
export function togglePermissionWorkbench(
  groups: readonly FlarePermissionGroup[],
  checked: readonly string[],
  key: string,
  on: boolean,
) {
  const item = permissionWorkbenchItems(groups).find(
    (candidate) => candidate.key === key,
  );
  if (!item || item.disabled) return [...checked];
  const next = new Set(checked);
  if (on) next.add(key);
  else next.delete(key);
  return [...next];
}
