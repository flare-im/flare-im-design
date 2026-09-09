---
title: SearchPanel
---

# SearchPanel

A composed search field, type selector, result list and recovery state. All four implementations accept `snapshot(criteria, state, groups, error)` and filter labels. Criteria contain `query` and `filterId`.

<div class="flare-demo flare-demo--stack"><SearchPanelDemo /></div>

<ComponentApi name="SearchPanel" />

Changing a filter submits the trimmed draft query and hides results belonging to different criteria. Editing a draft alone does not change result highlighting. Failure exposes retry with the submitted criteria. Empty queries support type-only search when the host supports it.

The host maps stable filter IDs to SDK message types, publishes loading synchronously, and accepts only the latest request using a generation counter. Matching criteria alone cannot distinguish repeated requests with identical criteria. Remount the panel and invalidate pending requests when the conversation changes. Error text must be user-facing, never raw SDK JSON.

Entries: `FlareSearchPanel` (Vue/Flutter), `SearchPanelView` (SwiftUI), `SearchPanel` (Compose). Events: search, open and viewAll. Result navigation, unloaded-message lookup, pagination and network requests remain host responsibilities.

Use bounded groups and an outer scroll container on native platforms. Filter controls wrap and use 48 logical-unit touch targets. Swift dictionaries are sorted by key; use shared ordered IDs when a fixed cross-platform order is required. See the [full integration contract](/components/search-panel).
