# Recipe: Build Search

Two searches, one pattern. Global search finds contacts, groups and messages from anywhere. In-conversation search finds messages in the open chat and jumps to them. This recipe follows the golden reference app (`GlobalSearch.vue`, `ConversationSearch.vue`, `ChatArea.vue`).

## Components

| Region | Vue | Flutter | iOS | Compose |
|---|---|---|---|---|
| Query input with loading and clear | `FlareSearchBar` | `FlareSearchBar` | `SearchBarView` | `SearchBar` |
| Search entry in a list header (opens search) | `FlareSearchBar` with `read-only` and `@activate` | `FlareSearchBar(readOnly: true, onActivate:)` | `SearchBarView(readOnly: true, onActivate:)` | `SearchBar(readOnly = true, onActivate =)` |
| Grouped results (contacts, groups, messages) | `FlareSearchResults` | `FlareSearchResults` | `SearchResultsView` | `SearchResults` |
| Query, filters, time ranges and result states | `FlareSearchPanel` | `FlareSearchPanel` | `SearchPanelView` | `SearchPanel` |
| Page | `FlareScreen` | `FlareScreen` | `FlareScreen` | `FlareScreen` |

## Global search (Vue)

```vue
<script setup lang="ts">
import { ref } from "vue";
import { FlareButton, FlareEmptyState, FlareScreen, FlareSearchBar, FlareSearchResults, type FlareSearchResultItem } from "@flare-im/vue-ui";

const emit = defineEmits<{ (e: "open", item: FlareSearchResultItem): void; (e: "close"): void }>();
const keyword = ref("");
let debounce: ReturnType<typeof setTimeout> | null = null;

// Debounce typing; submit runs immediately.
function onInput(value: string) {
  keyword.value = value;
  if (debounce) clearTimeout(debounce);
  debounce = setTimeout(() => void runGlobalSearch(value), 300);
}
</script>

<template>
  <FlareScreen surface="surface" aria-label="全局搜索">
    <template #header>
      <FlareSearchBar :model-value="keyword" placeholder="搜索消息、联系人、群" :loading="searchingGlobal"
        @update:model-value="onInput" @submit="runGlobalSearch(keyword)" @clear="clearGlobalSearch()" />
      <FlareButton variant="text" @click="emit('close')">取消</FlareButton>
    </template>
    <FlareSearchResults v-if="searchQuery.trim()" :groups="searchResults" :query="searchQuery" @open="emit('open', $event)" />
    <FlareEmptyState v-else icon="search" title="搜索" description="查找消息、联系人和群聊。" />
  </FlareScreen>
</template>
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
| Idle | Empty state that says what can be searched; empty criteria never call the host |
| Typing | The panel searches 300 ms after typing stops and not while an IME is composing; Enter, clear, a type filter and a time range search at once |
| Loading | The search bar shows progress; the previous results stay on screen, dimmed and `aria-busy`, until the new ones arrive |
| No results | "No results" for the query, distinct from failure |
| Failure | A danger banner with the host's product copy (`error`) and 重试; the query stays in the input. Never pass the raw error |
| Stale response | A late response for an older query is ignored (generation counter) |
| Hit not loaded | Page older history, then scroll; report missing only at the end |

## Do and don't

- Do give result ids the timeline identity. In-conversation search in the golden app passed server ids and could never locate a message; that bug was fixed on 2026-09-14.
- Don't lay a clickable overlay over an inert search field to make it open search; use the read-only entry mode, which is one button for assistive technology.
- Do ignore late responses; typing fast otherwise shows results for an old query.
- Don't show "no results" when the request failed.
- Do give message hits a `target`; a hit whose id is its conversation id collides with every other hit in that conversation and cannot jump.
