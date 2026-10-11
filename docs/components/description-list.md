# DescriptionList

The catalog component is **DescriptionList**: Vue `FlareDescriptionList`. Native kits: N/A — no Flutter, SwiftUI or Compose app ships an admin console, and the contract says so in `notes`.

## Overview
The facts of one record as label / value lines — a user's ids and dates, a message's sender, sequence and status, an application's contact — in a real `<dl>`. The host owns the record and formats each value; the list lays the lines out in columns by its own width, says "not set" for an empty value and offers a copy key on identifiers.

## When to use
Use it in a console's detail drawers and pages: the read-only facts of a user, a group, a message, an application, a credential or an audit event, next to the actions that change them.

## When not to use
Do not use it for settings a person changes (SettingsList and SettingsRow), for a list of many records (DataTable), or for a profile people see in the IM apps (ProfileCard, ContactDetail). Do not use it to lay out a form.

## Anatomy
An optional named group around a `<dl>`; one line per item, each a `<div>` holding a `<dt>` (the label) and a `<dd>` (the value, then an optional copy key). A line can span several columns. The `item-<key>` slot replaces one line's value.

## Variants
`labelPlacement` is `start` (label beside its value, in a shared label column `--flare-component-description-list-label-width` wide) or `top` (label above). `appearance` is `plain` (inside the host's surface) or `card` (its own bordered surface). `monospace` sets an item's value in the monospaced face; `copyable` adds the copy key.

## Sizes
`columns` (1–4, default 2) on a wide container; an item's `span` is clamped to the columns. Under 480px of its own width the list is one column; under 320px the labels move above their values. The copy key keeps a 48 logical pixel hit area without making the line taller.

## States
Default; an empty value (`null`, `undefined`, an empty string) is "not set" — a dash on screen, words for a screen reader, never a blank or "null". Zero is a value.

## Interactions
A copy key writes the value's text to the clipboard and emits `copy(key, copied)`; `copied` is false when the browser refused. The host shows the toast. Nothing else is interactive unless the host puts a control into an `item-<key>` slot.

## Keyboard
Tab reaches each copy key; Enter or Space copies.

## Accessibility
A description list (`dl` / `dt` / `dd`), so a screen reader announces each term with its definition. With `label` the list is a named group. An empty value reads "Not set" (the dash is hidden). Each copy key is named "Copy <label>". Colours are semantic tokens and keep their contrast in dark mode.

## Responsive
The list asks its own container (a container query), not the window: a wide drawer shows two columns, a narrow drawer or a phone one.

## Platform differences
Vue only. The native kits have no admin console to put it in.

## Code examples
```vue
<FlareDescriptionList
  :items="[
    { key: 'serverId', label: t('messages.serverId'), value: detail.server_id, monospace: true, copyable: true },
    { key: 'seq', label: t('messages.seq'), value: detail.conversation_seq },
    { key: 'sender', label: t('messages.sender'), value: detail.sender_name },
    { key: 'kind', label: t('messages.kind'), value: detail.content_kind },
    { key: 'createdAt', label: t('messages.createdAt'), value: dateTime(detail.created_at) },
  ]"
  @copy="(key, copied) => toast(copied ? t('common.copied') : t('common.copyFailed'))"
>
  <template #item-kind="{ value }"><FlareTag :label="String(value)" /></template>
</FlareDescriptionList>
```

## API

### Props

| Prop | Type | Default | Description |
|---|---|---|---|
| `items` | `FlareDescriptionItem[]` | required | The lines (`key`, `label`, `value`, `span`, `monospace`, `copyable`). |
| `columns` | `number` | `2` | Columns on a wide container (1–4). |
| `labelPlacement` | `'start' \| 'top'` | `'start'` | Label beside or above its value. |
| `label` | `string` | — | Names the list as a group. |
| `appearance` | `'plain' \| 'card'` | `'plain'` | Inside the host's surface, or its own card. |

### Emits

| Event | Payload | When |
|---|---|---|
| `copy` | `(key: string, copied: boolean)` | A copy key was pressed; `copied` is false when the clipboard refused. |

### Slots

| Slot | Scope | Content |
|---|---|---|
| `item-<key>` | `{ item, value }` | Replaces one line's value (a Tag, a link, an avatar). |

### Tokens
`--flare-component-description-list-label-width` (host seam in `component-tokens.css`); everything else is the semantic palette.

## Do / Don't
Do format every value in the host, leave an unknown value empty so the list says "not set", mark identifiers `monospace` and `copyable`, and show a toast for `copy`. Don't write "—" or "null" yourself, don't put editable controls in the list to make it a form, and don't hide the labels on narrow screens — the list already stacks.
