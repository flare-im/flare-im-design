# DataTable

The catalog component is **DataTable**: Vue `FlareDataTable`. Native kits: N/A — no Flutter, SwiftUI or Compose app ships an admin console, and the contract says so in `notes`.

## Overview
A list of host-owned records in a real `<table>`: sorting the host performs (the table only reports which column and which way), server-side pagination, a tri-state selection that spans pages and raises a batch toolbar, and a column chooser whose choice the host keeps. It knows nothing about what the rows are.

## When to use
Use it for the operational lists of a web console — users, apps, groups, audit events, credentials — where a person scans, sorts, pages, selects a few rows and acts on them. Rows come from a server one page at a time.

## When not to use
Do not use it for an IM list a person reads rather than operates (conversations, contacts, group members): those are ConversationList, ContactList and GroupMemberGrid, which know their own rows. Do not use it to lay out a form or a settings page, and do not sort or page a large set in the browser — the host asks the server.

## Anatomy
An optional bar above the table (`toolbar` slot on the leading side; the column chooser and, on narrow containers, a sort menu on the trailing side), the batch toolbar that appears with a non-empty selection, the table in its scroll box (header row, body rows, an optional selection column and an optional `row-actions` column), and the pager (range text, page-size select, previous / next, page of pages). Regions use semantic tokens and host-owned content.

## Variants
`density` is `comfortable` (a touch row, for reading) or `compact` (a control row, for scanning); the hit areas do not shrink. `stickyHeader` pins the header inside the table's own scroll box, whose height is `--flare-component-data-table-max-height`. `selectable`, `columnChooser` and `pagination` each add their region only when set.

## Sizes
The table fills its container. A column takes `width` or `minWidth` (numbers are px); `ellipsis` keeps a cell on one line with the full text in `title`. Row heights are `--flare-component-data-table-row-height` / `--flare-component-data-table-row-height-compact`. Every control keeps a 48 logical pixel hit area (44 on a coarse pointer at minimum).

## States
Default, loading (`aria-busy`, placeholder rows and a status), empty (the empty text or the `empty` slot), selection (the batch toolbar is up), sorted (one header carries `aria-sort`). A selected row is `aria-selected` and drawn on the selected surface.

## Interactions
A sortable header cycles ascending, descending, then back to the host's order; the table emits `update:sort` and never reorders rows itself. Previous / next and the page-size select emit `update:pagination` (a new page size resets to page 1). A source that pages by cursor and cannot count (`has_more` / `next_cursor`) leaves `total` out and passes `hasNext`: the pager shows the rows of this page and the page number, previous / next move one page at a time and next follows `hasNext`; the host keeps the cursor of each page it visited. The header checkbox selects or clears the rows of this page and keeps keys from other pages; each row checkbox toggles its row. The chooser emits `update:visibleColumns` with the keys in column order; the last visible column and a column with `hideable: false` cannot be hidden. A row emits `rowClick` only for a host that listens; its checkbox and its actions do not activate the row.

## Keyboard
Tab visits the sort buttons, the checkboxes, the row actions and the pager in reading order. Enter or Space on a sortable header cycles its sort; on an activatable row it activates the row. Escape clears a non-empty selection (the batch toolbar is a contextual layer, the same rule as the message and conversation batch toolbars, so the platform back and the kit's back controls clear it too). The column chooser opens on its trigger, moves focus to its first checkbox, closes on Escape and returns focus to the trigger.

## Accessibility
`table`, `rowgroup`, `row`, `columnheader` and `cell` are explicit roles, so they survive the stacked form, which changes `display`. The table is named by `label`. Sortable headers carry `aria-sort`; the header checkbox reads `mixed` when some rows of the page are selected; every row checkbox is named by its row number. The batch toolbar is a named `toolbar` whose count is a polite live region. The pager is a named `navigation` with a named page-size combobox; a cursor-paged table reports `aria-rowcount="-1"` because its total is unknown. Decorative glyphs are hidden; focus rings use the solid focus token; hover styles sit behind `(hover: hover)`.

## Responsive
The table asks its own container, not the window. Under 600px each row stacks into labelled lines (`data-label` is the column title), the selection checkbox sits beside the stack, the header stays in the accessibility tree, and sorting is a menu in the bar. Nothing scrolls sideways.

## Platform differences
Vue only. The column chooser is a popover on pointer devices and a bottom sheet on the phone form factor (the kit's `bottomSheet` capability), the same split as ActionMenu and Select.

## Code examples
```vue
<FlareDataTable
  :label="t('users.title')"
  :columns="columns"
  :rows="page.rows"
  :loading="pending"
  :pagination="page.pagination"
  :sort="query.sort"
  selectable
  column-chooser
  v-model:selected-keys="selected"
  v-model:visible-columns="prefs.userColumns"
  @update:pagination="(next) => load({ ...query, page: next.page, pageSize: next.pageSize })"
  @update:sort="(sort) => load({ ...query, sort, page: 1 })"
  @row-click="(row) => open(row.id)"
>
  <template #toolbar><FlareSearchBar v-model="keyword" @search="load" /></template>
  <template #cell-status="{ value }">{{ t(`users.status.${value}`) }}</template>
  <template #row-actions="{ row }"><FlareButton variant="text" size="sm" :label="t('users.edit')" @click="edit(row)" /></template>
  <template #batch="{ selectedKeys, clear }"><FlareButton variant="danger" size="sm" :label="t('users.freeze')" @click="freeze(selectedKeys).then(clear)" /></template>
</FlareDataTable>
```

## API

### Props

| Prop | Type | Default | Description |
|---|---|---|---|
| `columns` | `FlareDataTableColumn[]` | required | Columns in display order (`key`, `title`, `width`, `minWidth`, `sortable`, `align`, `ellipsis`, `slot`, `hideable`). |
| `rows` | `Record<string, unknown>[]` | required | The rows of this page, already sorted and paged by the host. |
| `rowKey` | `string \| (row, index) => string` | `'id'` | What identifies a row. |
| `label` | `string` | kit "Table" | Accessible name of the table. |
| `loading` | `boolean` | `false` | Placeholder rows and `aria-busy`. |
| `emptyText` | `string` | kit "No data yet" | Text of the empty state. |
| `pagination` | `FlareDataTablePagination \| null` | `null` | `{ page, pageSize, total?, hasNext?, pageSizes? }`; without `total` it pages by cursor. |
| `paginationDisabled` | `boolean` | `false` | Lock page and page-size controls during a host mutation. Loading also locks them. |
| `sort` | `FlareDataTableSort \| null` | `null` | `{ key, order: 'asc' \| 'desc' }`. |
| `selectable` | `boolean` | `false` | Row and header checkboxes; a selection raises the batch toolbar. |
| `selectionDisabled` | `boolean` | `false` | Preserve the host's confirmed batch target: lock row/header checkboxes, clear, exit and Escape. Loading also locks selection. Late row events must still refer to this page. |
| `selectedKeys` | `string[]` | `[]` | v-model; keys of the selected rows across pages. |
| `columnChooser` | `boolean` | `false` | The show / hide columns control. |
| `visibleColumns` | `string[] \| null` | `null` | v-model; keys the chooser shows, `null` for all. |
| `stickyHeader` | `boolean` | `false` | Pin the header inside the table's scroll box. |
| `density` | `'comfortable' \| 'compact'` | `'comfortable'` | Row height. |
| `fill` | `boolean` | `false` | In a height-bounded host panel, rows scroll while toolbar and pagination stay reachable. |

### Emits

| Event | Payload | When |
|---|---|---|
| `update:sort` | `FlareDataTableSort \| null` | A sortable header was activated (ascending, descending, then `null`). |
| `update:pagination` | `FlareDataTablePagination` | Previous / next (one page at a time for a cursor source), or a new page size (page 1). |
| `update:selectedKeys` | `string[]` | A checkbox, the header checkbox, clear or Escape. |
| `update:visibleColumns` | `string[]` | A column was shown or hidden, keys in column order. |
| `rowClick` | `(row, index)` | A row was activated by pointer, Enter or Space (only for a host that listens). |

### Slots

| Slot | Scope | Content |
|---|---|---|
| `cell-<key>` (or `column.slot`) | `{ row, value, index, column }` | One column's cells. |
| `row-actions` | `{ row, index }` | A trailing actions column; clicks here never activate the row. |
| `batch` | `{ selectedKeys, selectedRows, clear }` | The host's actions in the batch toolbar. |
| `toolbar` | — | The leading side of the bar above the table. |
| `empty` | — | Replaces the empty state. |

### Tokens
`--flare-component-data-table-row-height`, `--flare-component-data-table-row-height-compact`, `--flare-component-data-table-max-height` (host seams in `component-tokens.css`); everything else is the semantic palette.

## Do / Don't
Do give the table a name, fetch on every `update:pagination` / `update:sort`, keep `selectedKeys` and `visibleColumns` in host state (and persist the columns), and put destructive batch actions behind the kit's confirm. Don't sort or page in the component's rows, don't put a second interactive control inside a cell without stopping its click, and don't hide the header on narrow containers with your own CSS — the table already stacks its rows.
