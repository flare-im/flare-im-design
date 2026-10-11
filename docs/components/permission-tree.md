# PermissionTree

The catalog component is **PermissionTree**: Vue `FlarePermissionTree`. Native kits: N/A — no Flutter, SwiftUI or Compose app edits roles, and the contract says so in `notes`.

## Overview
A tree of permission codes with tri-state checks. A leaf is a code; a parent only groups its leaves and reads as checked, mixed or clear from them. The host owns the leaf codes (`checkedCodes`); the tree derives every parent, so a parent is never stored and never drifts from what the role grants.

## When to use
Use it to edit or show what a role, an API key or a service account may do: the admin console's role editor, a credential's scopes, a "view only" summary of someone's permissions.

## When not to use
Do not use it for a group's own settings (GroupPermissionMatrix owns those rows), for a navigation tree, or for picking people (ContactList and MemberPanel). Do not store parent codes in the model to "remember" a group: the tree reads the group from its leaves.

## Anatomy
A bar with the search field (kit SearchBar), the selected count, a view-only hint when `readonly`, and expand-all / collapse-all; then the tree: one row per visible node with a fold chevron (groups only), the check box, the name and an optional description. The `node` slot replaces the name and description; `empty` replaces the no-match state.

## Variants
`readonly` shows the state and ignores every toggle. `searchable` (default true) draws the search field. `defaultExpanded` (default true) starts every group open. `disabledCodes` fixes individual leaves: a parent toggle leaves them as they are and a group whose leaves are all disabled is disabled too.

## Sizes
Rows are `--flare-component-permission-tree-row-height` (the control row) and at least 44 logical pixels on a coarse pointer; depth indents by one `spacing-xl` per level. The tree fills its container; long names wrap.

## States
Default, read-only, searching (matches highlighted, ancestors forced open), empty (no match). Per item: checked, mixed, clear, disabled, open or closed, focused (one roving tab stop).

## Interactions
Activating a leaf flips it; activating a group checks every enabled leaf below it, or clears them all when every enabled leaf is already checked; the tree emits `update:checkedCodes` with the leaf codes in a stable order. The chevron folds a group without toggling it. Typing filters by name, code or description: a match stays on screen with its ancestors (forced open) and its descendants; clearing the field restores the fold state. Expand all / collapse all act on every group.

## Keyboard
Tab reaches one item (roving tabindex). Arrow Down / Arrow Up move between visible items; Arrow Right opens a closed group, then moves to its first child; Arrow Left closes an open group, otherwise moves to the parent; Home / End move to the first / last visible item; Space or Enter toggles the item. The search field keeps its own keys.

## Accessibility
A named `tree` of `treeitem`s with `aria-level`, `aria-posinset` and `aria-setsize`; a group exposes `aria-expanded`; every item exposes `aria-checked` `true` / `false` / `mixed` derived from its leaves, and a fixed item `aria-disabled`. The item itself is the one control, so the box beside the name is decorative (a second focusable checkbox inside a tree item would be two controls for one thing). The selected count is a polite live region; read-only draws a view-only hint; no match is the empty text. Focus rings use the solid focus token; hover styles sit behind `(hover: hover)`.

## Responsive
Rows wrap and the bar folds its tools under the search field on narrow widths; no horizontal scrolling. The tree is the same on phones and desktops — it is a list of rows, not a grid.

## Platform differences
Vue only. The search field is the kit's SearchBar with no debounce (filtering is local and one pass).

## Code examples
```vue
<FlarePermissionTree
  :label="t('roles.permissions')"
  :nodes="catalogue"
  v-model:checked-codes="draft.permissions"
  :disabled-codes="notGrantable"
  :readonly="!canEdit"
>
  <template #node="{ node, matched }">
    <span :class="{ hit: matched }">{{ node.name }}</span>
    <code v-if="showCodes">{{ node.code }}</code>
  </template>
</FlarePermissionTree>
```

## API

### Props

| Prop | Type | Default | Description |
|---|---|---|---|
| `nodes` | `FlarePermissionNode[]` | required | The catalogue: `{ code, name, description?, children? }`. |
| `checkedCodes` | `string[]` | `[]` | v-model; the checked leaf codes. |
| `label` | `string` | kit "Permissions" | Accessible name of the tree. |
| `readonly` | `boolean` | `false` | Show the state, ignore toggles, draw the view-only hint. |
| `disabledCodes` | `string[]` | `[]` | Leaf codes that cannot change. |
| `searchable` | `boolean` | `true` | Draw the search field. |
| `searchPlaceholder` | `string` | kit "Search permissions" | Placeholder of the search field. |
| `defaultExpanded` | `boolean` | `true` | Start with every group open. |
| `emptyText` | `string` | kit "No matching permissions" | Text when nothing matches. |

### Emits

| Event | Payload | When |
|---|---|---|
| `update:checkedCodes` | `string[]` | An item was toggled by pointer, Space or Enter. |

### Slots

| Slot | Scope | Content |
|---|---|---|
| `node` | `{ node, depth, state, expanded, matched, disabled }` | An item's content (name and description by default). |
| `empty` | — | Replaces the no-match state. |

### Tokens
`--flare-component-permission-tree-row-height` (host seam in `component-tokens.css`); everything else is the semantic palette.

### Performance
The tree is flattened once per change of `nodes`; states, search and the rows on screen are each one pass over the flat list. A thousand nodes toggle and filter within a few frames; the unit test holds the budget.

## Do / Don't
Do pass the leaf codes only, fix what the current person may not grant with `disabledCodes`, and give a viewer `readonly` rather than a tree they can click with no effect. Don't derive parents in the host, don't debounce the search yourself, and don't nest a second checkbox in the `node` slot.
