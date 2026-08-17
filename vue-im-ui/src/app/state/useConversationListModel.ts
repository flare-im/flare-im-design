import { computed, onBeforeUnmount, ref, watch } from "vue";
import type { ConversationListItemModel } from "../ui/components";
import { useFlareSdk } from "../sdk/flareSdkContext";
import type { ConversationFilter } from "@flare-im/vue-ui/composables/sdk";
import { conversationTitle } from "../shared/conversationTitle";
import { useFlareI18n } from "../shared/i18n";

export function useConversationListModel() {
  const sdk = useFlareSdk();
  const { t } = useFlareI18n();
  const conversationSearchOpen = ref(false);
  const conversationSearchQuery = ref("");
  let searchDebounceTimer: number | undefined;

  watch(conversationSearchQuery, (query) => {
    if (searchDebounceTimer) window.clearTimeout(searchDebounceTimer);
    searchDebounceTimer = window.setTimeout(() => {
      searchDebounceTimer = undefined;
      void sdk.searchConversationsWithKeyword(query).catch((error) => {
        console.warn("[flare-web] conversation_search_failed", error);
      });
    }, 320);
  });

  onBeforeUnmount(() => {
    if (searchDebounceTimer !== undefined) {
      window.clearTimeout(searchDebounceTimer);
      searchDebounceTimer = undefined;
    }
  });

  const filterOptions = computed(() => ([
    { label: t("conversation.filterAll"), value: "all" as ConversationFilter },
    { label: t("conversation.filterUnread"), value: "unread" as ConversationFilter },
    { label: t("conversation.filterMention"), value: "mention" as ConversationFilter },
    { label: t("conversation.filterPinned"), value: "pinned" as ConversationFilter },
    { label: t("conversation.filterMuted"), value: "muted" as ConversationFilter },
    { label: t("conversation.filterArchived"), value: "archived" as ConversationFilter },
    { label: t("conversation.filterDraft"), value: "draft" as ConversationFilter },
  ]));

  const conversationItems = computed<ConversationListItemModel[]>(() =>
    sdk.conversations.value.map((item) => ({
      id: item.conversationId,
      displayName: conversationTitle(item, sdk.form.userId),
      avatarUrl: item.avatarUrl,
      updatedAt: item.updatedAtTs ?? item.updatedAt,
      unreadCount: item.unreadCount,
      draft: item.draft ?? "",
      lastMessagePreview: item.lastMessagePreview?.trim() ?? "",
      lastMessage: item.lastMessage ? { text: item.lastMessage.text, time: item.lastMessage.time } : null,
      previewPending: false,
      pinned: item.isPinned,
      muted: item.isMuted,
      archived: item.isArchived,
    })),
  );

  const visibleConversations = computed(() => {
    const list = conversationItems.value;
    return {
      pinned: list.filter((item) => item.pinned),
      rest: list.filter((item) => !item.pinned),
    };
  });

  const runtimeStatus = computed(() => {
    const state = sdk.connectionState.value;
    if (sdk.conversationSyncError.value) {
      return {
        show: true,
        title: t("connection.syncFailed"),
        detail: sdk.conversationSyncError.value,
        busy: sdk.conversationSyncing.value,
        tone: "error" as const,
      };
    }
    if (sdk.conversationSyncing.value) {
      return {
        show: true,
        title: t("connection.syncConversations"),
        detail: t("connection.syncDetail"),
        busy: true,
        tone: "warning" as const,
      };
    }
    if (state === "ready" || state === "connected") {
      return { show: false, title: t("connection.stable"), detail: t("connection.ready"), busy: false, tone: "success" as const };
    }
    if (state === "connecting") {
      return { show: true, title: t("connection.connecting"), detail: t("connection.syncDetail"), busy: true, tone: "warning" as const };
    }
    if (state === "reconnecting") {
      return { show: true, title: t("connection.reconnecting"), detail: t("connection.retryHint"), busy: true, tone: "warning" as const };
    }
    return { show: false, title: t("connection.disconnected"), detail: t("connection.retryHint"), busy: false, tone: "default" as const };
  });

  async function applyFilter(filter: ConversationFilter): Promise<void> {
    await sdk.setConversationFilter(filter);
  }

  return {
    sdk,
    conversationSearchOpen,
    conversationSearchQuery,
    filterOptions,
    activeFilter: computed(() => sdk.conversationFilters.filter),
    visibleConversations,
    runtimeStatus,
    applyFilter,
  };
}
