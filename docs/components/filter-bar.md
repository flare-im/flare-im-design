# FilterBar

The catalog component is **FilterBar**: Vue `FlareFilterBar`. Native kits: N/A — no Flutter, SwiftUI or Compose app ships an admin console, and the contract says so in `notes`.

## Overview
The query form above a console list. Labelled fields (one `FormField` around a kit control each) sit in a grid that wraps by the bar's own width; Search and Reset keys end the last row; the conditions people rarely use fold behind "More filters". The host owns every value and runs the query — the bar only says when (`search`, `reset`).

## When to use
Use it above the operational lists of a web console — users, groups, messages, audit events, invitations — wherever a person narrows a server-side list with more than one condition and then asks for it.

## When not to use
Do not use it for a single free-text search (SearchBar, which debounces and searches as the person types), for switching between fixed views of a list (FilterTabs), or for a form that creates or edits a record (FormField and the overlay that holds it). Do not put the query results inside it.

## Anatomy
An optional hint line (it also describes the region), the field grid (default slot, then the `more` slot while expanded), and the keys at the end of the last row: Search, Reset, the More filters disclosure (only when `more` has content), then the host's own keys from the `actions` slot.

## Variants
`resettable` (default true) draws Reset. Without a `more` slot there is no disclosure. `searchText` and `resetText` rename the keys. `moreActiveCount` writes how many folded fields hold a value on the disclosure while it is closed ("More filters (2)").

## Sizes
The bar fills its container. A field is never narrower than `--flare-component-filter-bar-field-min-width` (200px); the grid holds as many columns as fit. The keys take the last two cells of the last row, or the whole row when the grid is one column wide; the key size follows the kit's control size, so the keys line up with the fields.

## States
Default, loading (`loading`: the Search key is busy and disabled, and Enter does not queue a second query), expanded (`v-model:expanded` shows the folded fields).

## Interactions
Search emits `search`; Reset emits `reset` and the host clears its values. The disclosure toggles `expanded` and keeps focus on itself. Enter in a one-line text field emits `search`. A control that acts on its own Enter keeps it: a key the control already handled (`preventDefault`), a combobox that says it is expanded, an IME composition, a textarea, a button, Enter with a modifier.

## Keyboard
Tab visits the fields in reading order, then Search, Reset, the disclosure and the host's keys. Enter in a one-line field searches. Enter or Space on the disclosure shows or hides the folded fields.

## Accessibility
The bar is a named `search` landmark (default name: the kit's "Filters"), described by its hint. It is not a `<form>`, so a host button in `actions` never submits by accident. Each field is a labelled FormField. The disclosure exposes `aria-expanded` and, while open, `aria-controls` on the folded fields; its name includes the count of folded fields that hold a value. The Search key is `aria-busy` while the host runs the query.

## Responsive
The grid asks the bar's own width, not the window: a wide page shows several fields per row, a drawer or a phone one per row with the keys on their own full-width row. Nothing scrolls sideways.

## Platform differences
Vue only. The native kits have no admin console to put it in.

## Code examples
```vue
<FlareFilterBar
  :hint="t('messages.hint')"
  :loading="pending"
  :more-active-count="[query.senderId, query.channelId].filter(Boolean).length"
  v-model:expanded="moreOpen"
  @search="runSearch"
  @reset="resetQuery"
>
  <FlareFormField :label="t('messages.conversation')"><FlareInput v-model="query.conversationId" monospace clearable /></FlareFormField>
  <FlareFormField :label="t('messages.messageId')"><FlareInput v-model="query.messageId" monospace clearable /></FlareFormField>
  <template #more>
    <FlareFormField :label="t('messages.sender')"><FlareInput v-model="query.senderId" monospace clearable /></FlareFormField>
    <FlareFormField :label="t('messages.channel')"><FlareInput v-model="query.channelId" monospace clearable /></FlareFormField>
  </template>
  <template #actions><FlareButton variant="secondary" :label="t('common.export')" @click="exportRows" /></template>
</FlareFilterBar>
```

## API

### Props

| Prop | Type | Default | Description |
|---|---|---|---|
| `label` | `string` | kit "Filters" | Accessible name of the search region. |
| `hint` | `string` | — | A line above the fields; also describes the region. |
| `loading` | `boolean` | `false` | The host is running the query. |
| `searchText` | `string` | kit "Search" | Search key text. |
| `resetText` | `string` | kit "Reset" | Reset key text. |
| `resettable` | `boolean` | `true` | Draw the Reset key. |
| `moreActiveCount` | `number` | `0` | Folded fields that hold a value, shown on the closed disclosure. |
| `expanded` | `boolean` | `false` | v-model; whether the `more` fields are shown. |

### Emits

| Event | Payload | When |
|---|---|---|
| `search` | — | The Search key, or Enter in a one-line text field (not while `loading`). |
| `reset` | — | The Reset key. |
| `update:expanded` | `boolean` | The disclosure was toggled. |

### Slots

| Slot | Content |
|---|---|
| default | The fields that are always shown (one FormField each). |
| `more` | The fields folded behind "More filters". |
| `actions` | Host keys after Search, Reset and the disclosure. |

### Tokens
`--flare-component-filter-bar-field-min-width` (host seam in `component-tokens.css`); everything else is the semantic palette and the kit's control sizes.

## Do / Don't
Do keep every value in host state, put each condition in its own FormField with a label, count the folded conditions that hold a value, and run the query only on `search`. Don't search on every keystroke from inside the bar, don't hide a condition that is set without saying so, and don't wrap the bar in your own `<form>` — Enter is already handled.
