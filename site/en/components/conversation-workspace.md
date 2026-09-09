---
title: ConversationWorkspace
---

# ConversationWorkspace

Composes the list / chat / detail panes over ResponsiveLayout and resolves loading, empty and failure for each pane in ONE place, so hosts stop writing a near-identical blank card per app and per pane. It owns no data, issues no request and never retries on a timer; pane content still comes from host slots and pane splitting still belongs to ResponsiveLayout.

<div class="flare-demo flare-demo--stack"><ConversationWorkspaceDemo /></div>

<ComponentApi name="ConversationWorkspace" />

Each pane takes a `{ status, message?, actionLabel? }` snapshot. `ready` renders the host slot; `loading` renders a labelled skeleton (rows / bubbles / card) and never an empty list; `empty` renders EmptyState titled with `message`; `failure` renders an error-toned StatusBanner naming the reason. The recovery button appears only when the failure carries a non-blank `actionLabel` **and** the host bound a retry handler — a button the host cannot service is never shown. A missing or unrecognised status degrades to the host content instead of throwing or blanking the pane.

Panes are independent: a failing timeline never turns an already loaded inbox into a failure, so partial failure keeps the successful panes readable. The cross-pane `banner` (offline / reconnecting / session expired) renders above all three and may coexist with any pane state; a blank or whitespace-only message renders nothing. Narrow-screen back order (detail → chat → list) and the 720 / 1100 breakpoints stay in ResponsiveLayout — `activePane`, `hasDetail`, `listWidth`, `detailWidth`, `hideMobileBar` and `backLabel` are forwarded verbatim.

The detail pane still renders when the host passed no detail content but its state is not ready: having nothing to show yet is exactly when the loading or failure panel earns its place, so natives need no placeholder widget for it. All three build the pane when the detail slot is non-nil **or** detailState is not ready.

Entries: FlareConversationWorkspace (Vue/Flutter), ConversationWorkspaceView (SwiftUI), ConversationWorkspace (Compose). Native callbacks: onPaneChange(pane), onRetry(pane), onBannerAction(). Vue emits pane-change, retry, banner-action. Retry scheduling, backoff, idempotency and account switching belong to the host and the SDK. See the [full integration guide](/components/conversation-workspace).
