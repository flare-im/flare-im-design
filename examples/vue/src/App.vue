<script setup lang="ts">
import { computed, ref } from "vue";
import {
  FlareAppLayout,
  FlareConversationHeader,
  FlareUiProvider,
  FlareComposerSendButton,
  FlareContactList,
  FlareConversationList,
  FlareConversationListContainer,
  FlareConversationRow,
  FlareEmptyState,
  FlareFriendListContainer,
  FlareIMAppKit,
  FlareSearchBar,
  FlareSettingsList,
  FlareMessageList,
  FlareTextarea,
  useViewportProvider,
  useFlareAdaptiveProvider,
  type FlareContact,
  type FlareIMAppConfiguration,
  type FlareLayoutChange,
  type MessageLike,
} from "@flare-im/vue-ui";
import { useFlareI18nProvider } from "@flare-im/vue-ui/i18n";
import { backend } from "./backend";

useFlareI18nProvider("en-US");
useViewportProvider();
useFlareAdaptiveProvider();

const activeNavigationId = ref("chats");
const draft = ref("");
const query = ref("");
const conversationOpen = ref(false);
// What the chats frame reports: one pane (a phone, or a window too narrow for the list beside a usable chat) puts
// the conversation in the list's place, with a way back. The shell measures its own box; this app measures nothing.
const chatsSinglePane = ref(false);
function onChatsLayout(layout: FlareLayoutChange): void {
  chatsSinglePane.value = layout.paneMode === "singlePane";
}
const selectedContactId = ref("u1");

const contacts: FlareContact[] = [
  { id: "u1", name: "Henry Ford", signature: "Keep it simple.", presence: "online" },
  { id: "u2", name: "Ivy Chen", signature: "Design is communication.", presence: "busy" },
  { id: "u3", name: "Kai Wang", signature: "Building reliable systems.", presence: "offline" },
];

const settings = [
  { title: "Preferences", items: [
    { key: "notifications", label: "Notifications", kind: "toggle" as const, value: true },
    { key: "appearance", label: "Appearance", kind: "navigation" as const, valueText: "System" },
  ] },
  { title: "Account", items: [
    { key: "privacy", label: "Privacy", kind: "navigation" as const },
    { key: "devices", label: "Devices", kind: "navigation" as const },
  ] },
];

const configuration: FlareIMAppConfiguration = {
  features: { enabled: ["conversations", "contacts", "groups", "search", "media", "savedMessages", "settings"] },
  capabilities: { enabled: ["reply", "reaction", "forward", "thread", "media", "messageActions"] },
  navigation: [{
    id: "main",
    items: [
      { id: "chats", label: "Chats", icon: "comment", badge: { kind: "count", count: 2, label: "2 unread chats" } },
      { id: "contacts", label: "Contacts", icon: "people" },
      { id: "search", label: "Search", icon: "search" },
      { id: "settings", label: "Settings", icon: "settings" },
    ],
  }],
};

const selectedContact = computed(() => contacts.find((contact) => contact.id === selectedContactId.value));
const messages = computed<MessageLike[]>(() => backend.messages.map((message, index) => ({
  serverId: message.id,
  clientMsgId: message.id,
  senderId: message.self ? backend.me : backend.activeId,
  senderDisplayName: message.self ? "You" : backend.active?.displayName ?? "",
  conversationSeq: index + 1,
  createdAt: 0,
  clientCreatedAt: 0,
  messageType: 1,
  content: { contentType: "text", text: { text: message.text ?? "" } },
  status: "sent",
  isRecalled: false,
  isRead: false,
  timelineKey: message.id,
  timelineSortTs: index,
  attributes: {},
})));
const filteredConversations = computed(() => {
  const normalized = query.value.trim().toLowerCase();
  return normalized
    ? backend.conversations.filter((item) => `${item.displayName} ${item.lastMessagePreview ?? ""}`.toLowerCase().includes(normalized))
    : backend.conversations;
});

// A destination keeps its state while another is active, so switching back finds the conversation still open.
function navigate(id: string): void {
  activeNavigationId.value = id;
}
function openConversation(id: string): void {
  backend.select(id);
  conversationOpen.value = true;
}
function send(): void {
  const text = draft.value.trim();
  if (!text) return;
  backend.send(text);
  draft.value = "";
}

</script>

<template>
  <FlareUiProvider>
    <FlareIMAppKit
      class="reference-app"
      data-reference-app="complete-im"
      :configuration="configuration"
      :active-navigation-id="activeNavigationId"
      label="Reference IM application"
      @navigate="navigate"
    >
      <template #destination="{ id }">
        <FlareAppLayout
          v-if="id === 'chats'"
          pane-mode="dualPane"
          :active-pane="conversationOpen ? 'content' : 'primary'"
          label="Chats"
          @layout-change="onChatsLayout"
        >
          <template #primary>
            <FlareConversationListContainer
              :state="{ status: 'ready', data: backend.conversations }"
              retry-label="Retry conversations"
              load-more-label="Load more conversations"
              label="Conversations"
            >
              <template #header><h1 class="pane-title">{{ chatsSinglePane ? "Chats" : "Flare" }}</h1></template>
              <template #search><div class="pane-search"><FlareSearchBar v-model="query" placeholder="Search conversations" /></div></template>
              <FlareConversationList :items="filteredConversations" :active-id="backend.activeId">
                <template #item="{ item, active }">
                  <FlareConversationRow :item="item" :active="active" @select="openConversation(item.id)" />
                </template>
              </FlareConversationList>
            </FlareConversationListContainer>
          </template>
          <template #content>
            <section class="chat-workspace" aria-label="Conversation">
              <FlareConversationHeader
                :identity="{ id: backend.activeId, title: backend.active?.displayName ?? 'Conversation', kind: 'direct' }"
                :show-back="chatsSinglePane"
                @back="conversationOpen = false"
              />
              <FlareMessageList
                :conversation-id="backend.activeId"
                :messages="messages"
                :current-user-id="backend.me"
                :has-older="false"
                :show-incoming-avatar="false"
              />
              <footer class="composer-row">
                <FlareTextarea v-model="draft" :rows="1" :max-rows="5" placeholder="Type a message" @enter="send" />
                <FlareComposerSendButton :active="Boolean(draft.trim())" @send="send" />
              </footer>
            </section>
          </template>
        </FlareAppLayout>

        <FlareAppLayout v-else-if="id === 'contacts'" pane-mode="dualPane" active-pane="primary" label="Contacts">
          <template #primary>
            <FlareFriendListContainer :state="{ status: 'ready', data: contacts }" label="Contacts">
              <template #header><h1 class="pane-title">Contacts</h1></template>
              <FlareContactList :items="contacts" @select="selectedContactId = $event.id" />
            </FlareFriendListContainer>
          </template>
          <template #content>
            <FlareEmptyState title="Contact selected" :description="selectedContact?.name" icon="people" />
          </template>
        </FlareAppLayout>

        <section v-else-if="id === 'search'" class="single-workspace" aria-label="Search">
          <h1 class="workspace-title">Search</h1>
          <FlareSearchBar v-model="query" placeholder="Search messages and people" />
          <FlareConversationList v-if="query" :items="filteredConversations" :active-id="backend.activeId">
            <template #item="{ item, active }"><FlareConversationRow :item="item" :active="active" @select="openConversation(item.id)" /></template>
          </FlareConversationList>
          <FlareEmptyState v-else title="Search across Flare" description="Find conversations, messages, contacts, and groups." icon="search" />
        </section>

        <section v-else class="single-workspace" aria-label="Settings">
          <h1 class="workspace-title">Settings</h1>
          <FlareSettingsList :sections="settings" />
        </section>
      </template>
    </FlareIMAppKit>
  </FlareUiProvider>
</template>

<style scoped>
.reference-app { width: 100%; height: 100dvh; color: var(--flare-color-text-primary); background: var(--flare-color-bg-primary); font: var(--flare-size-font-size-lg)/var(--flare-size-line-height-normal) -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
.pane-title, .workspace-title { margin: 0; letter-spacing: 0; color: var(--flare-color-text-primary); }
.pane-title { padding: var(--flare-size-spacing-lg); font-size: var(--flare-size-font-size-xl); border-bottom: 1px solid var(--flare-color-border-primary); }
.pane-search { padding: var(--flare-size-spacing-sm); }
.chat-workspace { display: flex; flex-direction: column; width: 100%; height: 100%; min-height: 0; background: var(--flare-color-bg-secondary); }
.composer-row { display: flex; align-items: flex-end; gap: var(--flare-size-spacing-sm); padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg); border-top: 1px solid var(--flare-color-border-primary); background: var(--flare-color-bg-primary); }
.composer-row :deep(.flare-textarea) { flex: 1; }
.single-workspace { display: flex; flex-direction: column; gap: var(--flare-size-spacing-lg); width: min(100%, 760px); min-height: 100%; margin-inline: auto; padding: var(--flare-size-spacing-xl); box-sizing: border-box; }
.workspace-title { font-size: var(--flare-size-font-size-3xl); }
@media (max-width: 599px) {
  .composer-row { padding: var(--flare-size-spacing-sm); padding-bottom: max(var(--flare-size-spacing-sm), env(safe-area-inset-bottom)); }
  .single-workspace { padding: var(--flare-size-spacing-lg); }
}
</style>
