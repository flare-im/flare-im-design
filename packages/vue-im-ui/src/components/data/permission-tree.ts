/**
 * The host-owned contract of FlarePermissionTree and the pure rules it draws from. A tree of a
 * thousand nodes is flattened once; every derived answer — which nodes are checked or mixed,
 * which match a search, which rows are on screen — is one pass over that flat list, keyed by
 * code, so a keystroke or a toggle never walks the tree per node.
 */

export interface FlarePermissionNode {
  /** The permission code a leaf stands for; a parent's code only groups. */
  code: string;
  name: string;
  description?: string;
  children?: readonly FlarePermissionNode[];
}

export type FlarePermissionCheckState = "checked" | "indeterminate" | "none";

export interface FlarePermissionTreeEntry {
  node: FlarePermissionNode;
  code: string;
  depth: number;
  parent: string | null;
  /** Direct children, in order. */
  childCodes: string[];
  /** Every leaf below this node (itself, for a leaf). */
  leafCodes: string[];
  isLeaf: boolean;
  /** Position among siblings, 1-based, and how many siblings there are. */
  posInSet: number;
  setSize: number;
}

export interface FlarePermissionTreeSearch {
  /** Nodes to show: matches, their ancestors and their descendants. `null` when not searching. */
  visible: ReadonlySet<string> | null;
  /** Ancestors of a match, drawn open regardless of the person's own expand state. */
  open: ReadonlySet<string>;
  /** The nodes whose text matched. */
  matched: ReadonlySet<string>;
}

/** Pre-order flattening; `leafCodes` are gathered bottom-up in the same pass. */
export function flattenPermissionNodes(nodes: readonly FlarePermissionNode[]): FlarePermissionTreeEntry[] {
  const out: FlarePermissionTreeEntry[] = [];
  const visit = (node: FlarePermissionNode, depth: number, parent: string | null, posInSet: number, setSize: number): FlarePermissionTreeEntry => {
    const children = node.children ?? [];
    const entry: FlarePermissionTreeEntry = {
      node,
      code: node.code,
      depth,
      parent,
      childCodes: [],
      leafCodes: [],
      isLeaf: children.length === 0,
      posInSet,
      setSize,
    };
    out.push(entry);
    if (entry.isLeaf) {
      entry.leafCodes = [node.code];
      return entry;
    }
    children.forEach((child, index) => {
      const childEntry = visit(child, depth + 1, node.code, index + 1, children.length);
      entry.childCodes.push(childEntry.code);
      for (const leaf of childEntry.leafCodes) entry.leafCodes.push(leaf);
    });
    return entry;
  };
  nodes.forEach((node, index) => visit(node, 0, null, index + 1, nodes.length));
  return out;
}

/**
 * Checked / mixed / none for every node from the leaf codes alone, in one bottom-up pass: a
 * parent is checked when every child is, mixed when any child is checked or mixed.
 */
export function permissionTreeStates(
  entries: readonly FlarePermissionTreeEntry[],
  checked: ReadonlySet<string>,
): Map<string, FlarePermissionCheckState> {
  const states = new Map<string, FlarePermissionCheckState>();
  for (let index = entries.length - 1; index >= 0; index -= 1) {
    const entry = entries[index];
    if (entry.isLeaf) {
      states.set(entry.code, checked.has(entry.code) ? "checked" : "none");
      continue;
    }
    let all = true;
    let any = false;
    for (const child of entry.childCodes) {
      const state = states.get(child) ?? "none";
      if (state !== "checked") all = false;
      if (state !== "none") any = true;
    }
    states.set(entry.code, all ? "checked" : any ? "indeterminate" : "none");
  }
  return states;
}

/**
 * The next checked list after one node is activated. A leaf flips; a parent whose enabled leaves
 * are all checked clears them, otherwise it checks them all. Disabled leaves keep whatever state
 * they have and do not decide the direction — a group holding an unchecked disabled leaf still
 * reads as mixed, yet must clear once everything the person may change is on.
 * Order is kept so the host's list does not reshuffle on every toggle.
 */
export function permissionTreeToggle(
  entry: FlarePermissionTreeEntry,
  checked: readonly string[],
  disabled: ReadonlySet<string>,
): string[] {
  const leaves = entry.leafCodes.filter((code) => !disabled.has(code));
  if (leaves.length === 0) return [...checked];
  const have = new Set(checked);
  const on = leaves.some((code) => !have.has(code));
  if (!on) {
    const drop = new Set(leaves);
    return checked.filter((code) => !drop.has(code));
  }
  return [...checked, ...leaves.filter((code) => !have.has(code))];
}

const normalize = (text: string) => text.trim().toLocaleLowerCase();

/**
 * Which nodes a query keeps on screen. A match is kept with every ancestor (so it can be reached)
 * and every descendant (a matched group shows what it holds). Ancestors of a match are forced open.
 */
export function permissionTreeSearch(
  entries: readonly FlarePermissionTreeEntry[],
  byCode: ReadonlyMap<string, FlarePermissionTreeEntry>,
  query: string,
): FlarePermissionTreeSearch {
  const needle = normalize(query);
  if (!needle) return { visible: null, open: new Set(), matched: new Set() };
  const matched = new Set<string>();
  for (const entry of entries) {
    const { name, description, code } = entry.node;
    if (normalize(name).includes(needle) || normalize(code).includes(needle) || (description && normalize(description).includes(needle))) {
      matched.add(entry.code);
    }
  }
  const visible = new Set<string>();
  const open = new Set<string>();
  for (const code of matched) {
    visible.add(code);
    let parent = byCode.get(code)?.parent ?? null;
    while (parent && !open.has(parent)) {
      open.add(parent);
      visible.add(parent);
      parent = byCode.get(parent)?.parent ?? null;
    }
  }
  // Descendants of a match: pre-order means a node's subtree follows it, so one forward scan does.
  for (let index = 0; index < entries.length; index += 1) {
    const entry = entries[index];
    if (!matched.has(entry.code) || entry.isLeaf) continue;
    for (let inner = index + 1; inner < entries.length && entries[inner].depth > entry.depth; inner += 1) {
      visible.add(entries[inner].code);
    }
  }
  return { visible, open, matched };
}

/**
 * The rows on screen, in order: a node is drawn when every ancestor is open (expanded by the
 * person, or forced open by the search) and the search, if any, keeps it.
 */
export function permissionTreeRows(
  entries: readonly FlarePermissionTreeEntry[],
  expanded: ReadonlySet<string>,
  search: FlarePermissionTreeSearch,
): FlarePermissionTreeEntry[] {
  const rows: FlarePermissionTreeEntry[] = [];
  // The depth below which everything is hidden by a closed ancestor; Infinity when none is.
  let closedBelow = Number.POSITIVE_INFINITY;
  for (const entry of entries) {
    if (entry.depth > closedBelow) continue;
    closedBelow = Number.POSITIVE_INFINITY;
    if (search.visible && !search.visible.has(entry.code)) {
      // A hidden node hides its subtree too, except when a descendant is itself visible —
      // then the node would be visible as that descendant's ancestor. So this is a leaf-side cut.
      continue;
    }
    rows.push(entry);
    if (!entry.isLeaf && !expanded.has(entry.code) && !search.open.has(entry.code)) closedBelow = entry.depth;
  }
  return rows;
}
