# @flare-im/vue-ui

Vue 3 presentation components for the Flare IM design system. Components receive host-owned view state and emit typed UI intents. The package does not create sessions, perform network requests, own persistence, or route an application.

## Install

```bash
npm install @flare-im/vue-ui @flare-im/tokens vue naive-ui
```

The package publishes Vue and TypeScript source so the host bundler compiles it with the application's Vue version and CSS pipeline. Vite and Nuxt support this directly; Webpack consumers must include the package in their Vue loader rule.

## Public Entries

| Path                           | Contents                                                                              |
| ------------------------------ | ------------------------------------------------------------------------------------- |
| `@flare-im/vue-ui`             | Complete public API                                                                   |
| `@flare-im/vue-ui/admin`       | Focused shared table, drawer, form and provider entry without the chat/composer graph |
| `@flare-im/vue-ui/admin.css`   | Tokens and admin control foundations without chat/timeline styles                     |
| `@flare-im/vue-ui/components`  | General, IM, and composition components                                               |
| `@flare-im/vue-ui/contracts`   | Host-facing view-state and interaction contracts                                      |
| `@flare-im/vue-ui/theme`       | Theme runtime and semantic token helpers                                              |
| `@flare-im/vue-ui/i18n`        | Built-in locales and locale registration                                              |
| `@flare-im/vue-ui/composables` | UI-only adaptive and interaction composables                                          |
| `@flare-im/vue-ui/utils`       | Presentation helpers                                                                  |
| `@flare-im/vue-ui/style.css`   | Generated tokens and component styles                                                 |

## Usage

```vue
<script setup lang="ts">
import {
  FlareConversationList,
  FlareConversationRow,
  FlareUiProvider,
} from "@flare-im/vue-ui/components";
import "@flare-im/vue-ui/style.css";
</script>

<template>
  <FlareUiProvider layout-mode="auto">
    <FlareConversationList :items="rows" active-id="c1">
      <template #item="{ item, active }">
        <FlareConversationRow
          :item="item"
          :active="active"
          @select="onSelect"
        />
      </template>
    </FlareConversationList>
  </FlareUiProvider>
</template>
```

## Ownership

Message timelines fill the chat pane: incoming messages align to its left edge and
outgoing messages to its right edge, with shared responsive gutters. Reading-width
limits apply to individual bubbles; system notices remain centred. Hosts should
not add a centred maximum width around the timeline.

Admin tables can set `fill` inside a height-bounded panel: only the rows scroll, while
the column toolbar and pagination remain reachable on narrow and short viewports.
Set `paginationDisabled` during a host-owned mutation to lock both page and page-size
controls without hiding the readable rows. Loading locks paging automatically.
Set `selectionDisabled` for a confirmed batch mutation: row/header checkboxes, clear,
exit and Escape cannot change its target set while the host owns the write. Loading
also locks selection; the host still checks permission and current-page membership.
Use `rowSelectable` when some rows cannot join a batch: both row checkboxes and
select-all respect the same predicate. Hosts remain responsible for validation and
for clearing selections when their source records or permissions change.
Cursor sources display only the actual count on this page and the page number: short
or filtered pages do not justify a global row offset or an estimated total.
Use `FlarePermissionTree selection-mode="independent"` when parents are real grants:
every code is toggled on its own, never by ancestor/descendant inference. The default
leaf-selection mode is for grouping-only trees. The host still owns authorization.

The package owns rendering, focus, selection affordances, responsive composition, accessibility semantics, theme resolution, and deterministic UI state projection. The host owns application routing, data acquisition, authoritative lifecycle state, permissions, commands, persistence, media transport, and business policy.

General UI and IM UI are logical layers inside one cohesive package. They are not separate placeholder packages and there are no compatibility entry points for the former repository layout.

## Plugin administration lists

`FlarePluginAdminList` adapts a resolved `FlarePluginRowsBlock` to `FlareAdminList`.
It shares the ordinary query form, measured filter folding, action toolbar, column
chooser, native table and remote pagination. It preserves plugin cell time, identity,
badge, detail and row-action semantics. The default plugin table/list/card layouts
remain unchanged.

```vue
<FlarePluginView
  :view="view"
  embedded
  actions-placement="rows"
  content-layout="list"
  error-presentation="external"
  note-presentation="plain"
  :error="actionError"
  :form-errors="formErrors"
  :settle-token="settleToken"
  @action="runAuthorizedAction"
>
  <template #rows="{ shownBlock, strings, busy, busyActionId, busyRow, actions, run, runAction, openRow, loadMore }">
    <FlarePluginForm
      :inputs="filterInputs" :values="filters" :busy="busy" presentation="filters"
      @submit="applyFilters" @cancel="resetFilters"
    >
      <template #layout="{ fields, submit, reset, invalid }">
        <FlarePluginAdminList
          :block="shownBlock" :strings="strings" :label="view.title"
          :busy="busy" :busy-action-id="busyActionId" :busy-row="busyRow"
          :pagination="pagination" :error="readError" :filters-invalid="invalid"
          v-model:visible-column-keys="visibleColumnKeys"
          @search="submit" @reset="reset" @update:pagination="changePage"
          @row-action="run" @open-row="openRow" @load-more="loadMore"
        >
          <template #filters>
            <component v-for="field in fields" :is="field" :key="field.key" />
          </template>
          <template #actions>
            <FlareButton
              v-for="action in actions" :key="action.id" size="sm"
              :label="action.label" :disabled="busy" @click="runAction(action)"
            />
          </template>
        </FlarePluginAdminList>
      </template>
    </FlarePluginForm>
  </template>
</FlarePluginView>
```

Derive `filterInputs` with `flarePluginFilterInputs(view)` rather than using action
inputs as query fields. `fields` contains one native form item per input, so pass
each VNode directly into the list's `filters` slot; nesting the whole form there
would make it one measured field. The layout replaces the form shell and footer,
while retaining the same typed draft, validation, references and server errors.
`reset` discards unapplied edits back to controlled values and emits `cancel` so
the host can clear its applied query. `invalid` with `filters-invalid` reveals
advanced-field errors without replacing the inputs.

Override a control with `#field-inputId` or the fallback `#field`. The slot receives
`input`, `value`, `setValue`, `disabled`, `error`, `controlId`, `labelId` and
`describedBy`. Bind the supplied identity/accessibility values to the replacement
control; the kit keeps the label, required state, validation and feedback wrapper.
`setValue` respects the current busy/directory guard. Directory authorization and
option acquisition remain host responsibilities.

Pagination is controlled (`page`, `pageSize`, `total`, `pageSizes`); the adapter
never slices supplied rows or invents a server total. Without an authoritative
total use `hasNext` cursor pagination. `search`, `reset`, `update:pagination`,
`rowAction`, `openRow` and `loadMore` request host work only. Read failures render
as neutral actionable content, with an `error-actions` retry slot. Action failures
remain on `FlarePluginView` for its external-notification settlement contract.

The `rows` slot keeps its original `block`, `busy`, `run` arguments and adds the
formatted `shownBlock` and toolbar/detail helpers above. Row and page actions
both retain the view's single confirmation, form and failed-value pipeline.
With multiple row blocks only the first receives the page toolbar actions.
`content-layout="list"` fills a bounded flex parent only when the view has rows;
the admin rows presenter passes that space to `FlareAdminList` so its table body
scrolls and its pagination stays in the content footer. Notes and other static
blocks keep natural height. The default `flow` layout preserves cards and chat.

## File and image uploads

`FlareFileUpload` is available from the main, components and focused admin entries.
It composes `FlareImageUploadSlot` with a native single-file picker. Set `image`
to render a host-provided preview; ordinary files show their name and transfer
state. All labels are supplied by the host for localization.

The controlled `state` is `empty`, `selected`, `uploading`, `uploaded` or `failed`.
`progress` is a percentage; omit it for an indeterminate transfer. The component
emits `select(File)`, `upload`, `retry`, `cancel` and `remove` intents. It does not
read bytes, create preview URLs, upload, delete media or change the supplied state.
The host owns an uploaded file's durable media reference separately from temporary
preview/access URLs and releases any local object URL when its intent ends.

Pass `accept` from the authenticated backend policy. It is only a native picker
hint: the backend remains authoritative for type, content, size, tenant and owner
checks. There is no default size or MIME policy in the Kit. Permission changes,
application changes and form closure must cancel the host's pending transfer and
discard stale results. `disabled` closes all mutation controls.

`FlareImageUploadSlot` preserves its existing read-only completion behavior.
Its optional `replaceable`, `icon`, `progress` and `actions` slot support the
shared file uploader without adding transport or business rules.

## Development

```bash
npm test
npm run typecheck
npm run build
npm run pack
```
