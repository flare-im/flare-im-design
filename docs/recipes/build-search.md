# Recipe: Build Search

Two searches, one pattern. Global search finds contacts, groups and messages from anywhere. In-conversation search finds messages in the open chat and jumps to them. This recipe follows the golden reference app (`GlobalSearch.vue`, `ConversationSearch.vue`, `ChatArea.vue`).

## Components

| Region | Vue | Flutter | iOS | Compose |
|---|---|---|---|---|
| Query input with loading and clear | `FlareSearchBar` | `FlareSearchBar` | `SearchBarView` | `SearchBar` |
| Search entry in a list header (opens search) | `FlareSearchBar` with `read-only` and `@activate` | `FlareSearchBar(readOnly: true, onActivate:)` | `SearchBarView(readOnly: true, onActivate:)` | `SearchBar(readOnly = true, onActivate =)` |
| Grouped results (contacts, groups, messages) | `FlareSearchResults` | `FlareSearchResults` | `SearchResultsView` | `SearchResults` |
| Query, filters, time ranges and result states | `FlareSearchPanel` | `FlareSearchPanel` | `SearchPanelView` | `SearchPanel` |
| Recent searches (idle state) | `FlareRecentSearches` | — | — | — |
| Page | `FlareScreen` | `FlareScreen` | `FlareScreen` | `FlareScreen` |

## Global search (Vue)

The panel is the page. On a phone it is a second-level screen, not a sheet: the keyboard is up on entry, and a sheet capped at 72vh would leave the results under 200px. On a wide window it is a centred dialog.

```vue
<script setup lang="ts">
import { computed, onBeforeUnmount } from "vue";
import { FlareBottomSheet, FlareRecentSearches, FlareScreen, FlareSearchPanel, useViewport, type FlareSearchResultItem } from "@flare-im/vue-ui";

const emit = defineEmits<{ (e: "open", item: FlareSearchResultItem): void; (e: "close"): void }>();
const { isDesktop } = useViewport();
// Type ids are the result kinds, so "查看更多" on a group is that kind's type: the panel switches itself.
const kinds = computed(() => ({ all: "全部", contact: "联系人", group: "群聊", message: "聊天记录" }));

// Remember a search that was used: a hit was opened, or the page was left with results on it.
function open(item: FlareSearchResultItem) { rememberSearch(searchSnapshot.value.criteria.query); emit("open", item); }
onBeforeUnmount(() => clearGlobalSearch()); // every opening starts idle
</script>

<template>
  <FlareScreen v-if="!isDesktop" surface="surface" :scroll="false" aria-label="全局搜索">
    <FlareSearchPanel layout="page" :snapshot="searchSnapshot" :filters="kinds" require-query autofocus
      search-text="搜索联系人、群聊、聊天记录" idle-text="输入关键字，搜索联系人、群聊和聊天记录"
      @search="searchGlobal" @open="open" @cancel="emit('close')">
      <template v-if="recentSearches.length" #idle="{ search, focusField }">
        <FlareRecentSearches :items="recentSearches" @pick="search" @clear="() => { clearRecentSearches(); focusField(); }" />
      </template>
    </FlareSearchPanel>
  </FlareScreen>
  <FlareBottomSheet v-else :open="true" presentation="dialog" title="搜索" title-hidden max-height="72vh" dialog-width="720px" @close="emit('close')">
    <!-- A sheet only caps its height; the page layout needs one, or the centred dialog re-centres with every result count. -->
    <div class="search-dialog-body"><FlareSearchPanel layout="page" … /></div>
  </FlareBottomSheet>
</template>
```

`layout="page"` keeps the field and the type row still and scrolls only the results; listening for `cancel` brings the search bar's own 取消 beside the field (the dialog does not listen, so it has none); `require-query` keeps a type alone from searching. The host owns the recent list (per signed-in user, in its own storage) and keeps it with `flareRememberSearch(list, term, max)`.

The search ops take a limit and return no count, so the store asks each source for one row more than it shows and sets `hasMore` on the group; a count is never made up. One source failing is `warning` over the results that did come back; only every asked source failing is `failure`.

```ts
const snapshot = computed<FlareSearchSnapshot>(() => ({
  criteria,                                   // exactly what the panel gave `search`
  state: loading ? "loading" : failedAll ? "failure" : "success",
  groups,                                     // [{ kind: "contact", label: "联系人", items, hasMore }, …]
  warning: failedSome ? "部分结果没有加载出来" : undefined,
}));
```

The app runs contacts, groups and messages in parallel (`social.relation.search_contacts`, `social.group.search_groups`, `message.search`) and fills one group per kind. A backend that cannot answer one kind returns an empty group for it rather than failing the whole search.

Each result's `id` is its own identity within its kind (user id, group id, message id); rows are keyed by kind and id, so two hits in one conversation stay two rows. A message hit also carries `target: { conversationId, messageId }`:

```ts
const messageItems = hits.map((m): FlareSearchResultItem => {
  const messageId = resolveMessageId({ clientMsgId: m.clientMsgId ?? "", serverId: m.serverId ?? "" });
  return { id: messageId, kind: "message", title: senderName(m), subtitle: previewText(m), target: { conversationId: m.conversationId, messageId } };
});

async function onSearchOpen(item: FlareSearchResultItem) {
  if (item.kind === "contact") await openPeerConversation(item.id);
  else if (item.kind === "group") await openGroupConversationByGroupId(item.id);
  else if (item.target?.messageId) await openConversationAtMessage(item.target.conversationId, item.target.messageId);
}
```

`openConversationAtMessage` opens the conversation and records the message; the chat locates it once that timeline has loaded, the same way an in-conversation hit does.

## In-conversation search and jump (Vue)

```vue
<script setup lang="ts">
import { ref } from "vue";
import {
  FlareScreen,
  FlareSearchPanel,
  resolveMessageId,
  type FlareSearchCriteria,
  type FlareSearchResultItem,
  type FlareSearchSnapshot,
} from "@flare-im/vue-ui";

const snapshot = ref<FlareSearchSnapshot>({ criteria: { query: "", filterId: "all" }, state: "idle", groups: [] });
let generation = 0;

async function search(criteria: FlareSearchCriteria) {
  const request = ++generation;
  snapshot.value = { criteria, state: "loading", groups: [] };
  try {
    const results = await im.searchInConversation(props.conversationId, criteria);
    if (request !== generation) return; // a newer query won
    const items = results.map((raw): FlareSearchResultItem => {
      const message = coreMessageToLike(raw);
      // Jump targets use the timeline's identity (client id first); a server id never matches.
      return { id: resolveMessageId(message), kind: "message", title: message.senderDisplayName || "消息", subtitle: previewOf(message) };
    });
    snapshot.value = { criteria, state: "success", groups: [{ kind: "message", label: "聊天记录", items }] };
  } catch (error) {
    console.warn("[search] failed", error); // the technical reason goes to the console
    if (request === generation) snapshot.value = { criteria, state: "failure", groups: [], error: "搜索失败，请重试" };
  }
}
</script>

<template>
  <FlareScreen title="搜索聊天记录" back surface="surface" padded @back="emit('close')">
    <FlareSearchPanel :snapshot="snapshot" :filters="filters" :time-ranges="ranges" @search="search" @open="emit('open', $event.id)" />
  </FlareScreen>
</template>
```

Opening a hit hands the id to the chat, which pages older history until the message is loaded and then scrolls to it through the timeline handle (`scrollToMessage(id)`). The chat reports "未能定位消息" only when the message never appears.

## States

| State | Behaviour |
|---|---|
| Idle | One line that says what can be searched, or the recent searches in its place; empty criteria never call the host |
| Typing | The panel searches 300 ms after typing stops and not while an IME is composing; Enter, clear, a type filter and a time range search at once |
| Loading | The search bar shows progress; the previous results stay on screen, dimmed and `aria-busy`, until the new ones arrive |
| No results | "No results" for the query, distinct from failure |
| Failure | A danger banner with the host's product copy (`error`) and 重试; the query stays in the input. Never pass the raw error |
| Partial | Results stay; a warning banner (`warning`) above them with 重试 |
| Truncated | A countless "查看更多" row (`hasMore`); it leads to that kind's type, where the row is gone |
| Stale response | A late response for an older query is ignored (generation counter) |
| Hit not loaded | Page older history, then scroll; report missing only at the end |

## Do and don't

- Do give result ids the timeline identity. In-conversation search in the golden app passed server ids and could never locate a message; that bug was fixed on 2026-09-14.
- Don't lay a clickable overlay over an inert search field to make it open search; use the read-only entry mode, which is one button for assistive technology.
- Do ignore late responses; typing fast otherwise shows results for an old query.
- Don't show "no results" when the request failed.
- Do give message hits a `target`; a hit whose id is its conversation id collides with every other hit in that conversation and cannot jump.
