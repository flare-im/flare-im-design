<script setup lang="ts">
import { computed, ref, watch, onBeforeUnmount } from "vue";
import { describeSdkError } from "../../shared/errors/describeSdkError";
import {
  AddOutline,
  ArchiveOutline,
  AlertCircleOutline,
  ChatbubbleEllipsesOutline,
  CheckmarkDoneOutline,
  DocumentTextOutline,
  FileTrayOutline,
  ImageOutline,
  InformationCircleOutline,
  LogOutOutline,
  MailUnreadOutline,
  MicOutline,
  NotificationsOffOutline,
  PinOutline,
  SearchOutline,
  SettingsOutline,
  SyncOutline,
  TrashOutline,
  VideocamOutline,
} from "../../shared/icon-glyphs";
import {
  NButton,
  NIcon,
  NInput,
  NModal,
  NSelect,
  NTag,
  useMessage,
} from "naive-ui";
import { useRoute, useRouter } from "vue-router";
import { FlareDangerConfirm, FlareStartConversationDialog, FlareWorkbenchShell } from "@flare-im/vue-ui/components";
import type { FlareWorkbenchShellMode } from "@flare-im/vue-ui/contracts";
import { provideFlareWorkbenchUi } from "@flare-im/vue-ui/composables";
import { useFlareTheme, type FlareThemeMode, type FlareThemeVariant } from "@flare-im/vue-ui/theme";
import {
  displayTextFromStoredPreview,
  previewTextFromMessageContent,
} from "@flare-im/vue-ui/utils";
import {
  MessageSearchKind,
} from "@flare-im/sdk/web";
import {
  ConversationDetails,
  DeveloperConsole,
  MessageActionSheet,
  MessagePreviewModal,
} from "../ui/components";
import { useFlareSdk } from "../sdk/flareSdkContext";
import { conversationTitle } from "../shared/conversationTitle";
import { useFlareI18n, type FlareLocale } from "../shared/i18n";

type MessageIdentity = { readonly serverId: string; readonly clientMsgId: string };
type ChatSearchResultMessage = MessageIdentity & {
  readonly content?: {
    readonly contentType?: string;
    readonly data?: Record<string, unknown>;
  };
  readonly textPreview?: string;
  readonly senderDisplayName?: string;
  readonly senderName?: string;
  readonly senderId?: string;
  readonly createdAt?: number;
  readonly clientCreatedAt?: number;
  readonly conversationSeq?: number;
};
type ChatSearchKindValue = "all" | "text" | "media" | "image" | "video" | "audio" | "file";

const sdk = useFlareSdk();
const message = useMessage();
const router = useRouter();
const route = useRoute();
const { t, locale, setLocale } = useFlareI18n();
const { mode: themeMode, variant: themeVariant, setMode: setThemeMode, setVariant: setThemeVariant } =
  useFlareTheme();

const settingsOpen = ref(false);
const startChatOpen = ref(false);
const moreOpen = ref(false);
const sdkBuildOpen = ref(false);
const chatSearchOpen = ref(false);
const messageLocation = ref<{ conversationId: string; messageId: string } | null>(null);
const chatSearchQuery = ref("");
const chatSearchKind = ref<ChatSearchKindValue>("all");
const chatSearchLoading = ref(false);
let searchGeneration = 0;
function invalidateSearchPresentation() {
  messageLocation.value = null;
  searchGeneration += 1;
  chatSearchLoading.value = false;
  chatSearchError.value = '';
  chatSearchSearched.value = false;
}
watch([sdk.activeConversationId, sdk.currentUserId], invalidateSearchPresentation, { flush: 'sync' });
onBeforeUnmount(invalidateSearchPresentation);
const chatSearchSearched = ref(false);
const chatSearchError = ref("");
const chatSearchLastQuery = ref("");
const chatSearchLastKind = ref<ChatSearchKindValue>("all");
const previewOpen = ref(false);
const previewMessageId = ref("");
const startConversationType = ref<"single" | "group">("single");
const startPeerUserId = ref("");

watch(startChatOpen, (open) => {
  if (open) {
    startPeerUserId.value = sdk.sdkLab.peerUserId.trim() || "";
  }
});

provideFlareWorkbenchUi({
  messageLocation,
  openMore: () => {
    moreOpen.value = true;
  },
  openStartChat: () => {
    startChatOpen.value = true;
  },
  openSdkBuild: () => {
    sdkBuildOpen.value = true;
  },
  openChatSearch: () => {
    chatSearchOpen.value = true;
  },
  openPreview: (messageId: string) => {
    previewMessageId.value = messageId;
    previewOpen.value = true;
  },
});

const shellMode = computed<FlareWorkbenchShellMode>(() => {
  if (route.name === "chat") return "chat";
  if (route.name === "sdk-lab") return "lab";
  return "conversations";
});

const moreActionCount = computed(() => {
  if (route.name === "chat") return 11;
  if (route.name === "conversations") return 5;
  return 3;
});

const themeModeValue = computed({
  get: () => themeMode.value,
  set: (value: FlareThemeMode) => setThemeMode(value),
});

const themeVariantValue = computed({
  get: () => themeVariant.value,
  set: (value: FlareThemeVariant) => setThemeVariant(value),
});

const localeValue = computed({
  get: () => locale.value,
  set: (value: FlareLocale) => setLocale(value),
});

const moreDrawerTitle = computed(() => (route.name === "chat" ? t("workbench.chatActions") : t("workbench.more")));
const activeConversation = computed(() => sdk.activeConversation.value);
const activeConversationUnread = computed(() => Math.max(0, Number(activeConversation.value?.unreadCount ?? 0) || 0));
const activeConversationPinned = computed(() => Boolean(activeConversation.value?.isPinned));
const activeConversationMuted = computed(() => Boolean(activeConversation.value?.isMuted));
const activeConversationArchived = computed(() => Boolean(activeConversation.value?.isArchived));
const chatSearchResults = computed(() => sdk.messageSearchResults.value);
const chatSearchCanSubmit = computed(() =>
  Boolean(sdk.activeConversationId.value && chatSearchQuery.value.trim() && !chatSearchLoading.value),
);
const chatSearchLastKindLabel = computed(() =>
  chatSearchKindOptions.find((option) => option.value === chatSearchLastKind.value)?.label ?? t("workbench.kind.all"),
);

const chatSearchKindOptions = [
  { label: t("workbench.kind.all"), value: "all", icon: ChatbubbleEllipsesOutline },
  { label: t("workbench.kind.text"), value: "text", icon: DocumentTextOutline },
  { label: t("workbench.kind.media"), value: "media", icon: FileTrayOutline },
  { label: t("workbench.kind.image"), value: "image", icon: ImageOutline },
  { label: t("workbench.kind.video"), value: "video", icon: VideocamOutline },
  { label: t("workbench.kind.audio"), value: "audio", icon: MicOutline },
  { label: t("workbench.kind.file"), value: "file", icon: FileTrayOutline },
] satisfies Array<{ label: string; value: ChatSearchKindValue; icon: typeof SearchOutline }>;

const connectionTone = computed(() => {
  if (sdk.connectionState.value === "ready" || sdk.connectionState.value === "connected") return "success";
  if (sdk.connectionState.value === "connecting" || sdk.connectionState.value === "reconnecting") return "warning";
  return "default";
});

const connectionText = computed(() => {
  const state = sdk.connectionState.value;
  if (state === "ready") return "Ready";
  if (state === "connected") return "Connected";
  if (state === "connecting") return "Connecting";
  if (state === "reconnecting") return "Reconnecting";
  return "Disconnected";
});

const diagnosticsText = computed(() => JSON.stringify(sdk.diagnostics.value, null, 2));
const labResultText = computed(() => JSON.stringify(sdk.labResult.value, null, 2));
const previewMessage = computed(() => findMessage(previewMessageId.value));

function findMessage(id: string) {
  if (!id) return null;
  return (
    sdk.messages.value.find((m) => m.serverId === id || m.clientMsgId === id) ??
    chatSearchResults.value.find((m) => m.serverId === id || m.clientMsgId === id) ??
    null
  );
}

function messageId(message: MessageIdentity): string {
  return message.clientMsgId || message.serverId;
}

function chatSearchResultText(message: ChatSearchResultMessage): string {
  const contentText = previewTextFromMessageContent(message.content, locale.value).trim();
  if (contentText) return contentText;
  const storedPreview = displayTextFromStoredPreview(message.textPreview ?? "", locale.value).trim();
  if (storedPreview) return storedPreview;
  return chatSearchResultKindLabel(message);
}

function chatSearchResultKindLabel(message: ChatSearchResultMessage & { readonly content?: { readonly contentType?: string } }): string {
  const type = message.content?.contentType ?? "";
  if (type === "image") return t("workbench.kind.image");
  if (type === "video") return t("workbench.kind.video");
  if (type === "audio") return t("workbench.kind.audio");
  if (type === "file") return t("workbench.kind.file");
  if (type === "sticker") return t("workbench.kind.sticker");
  if (type === "emoji") return t("workbench.kind.emoji");
  return t("workbench.kind.message");
}

function chatSearchResultIcon(message: ChatSearchResultMessage): typeof SearchOutline {
  const type = message.content?.contentType ?? "";
  if (type === "image") return ImageOutline;
  if (type === "video") return VideocamOutline;
  if (type === "audio") return MicOutline;
  if (type === "file") return FileTrayOutline;
  return DocumentTextOutline;
}

function chatSearchResultSender(message: ChatSearchResultMessage): string {
  return message.senderDisplayName?.trim() || message.senderName?.trim() || message.senderId || t("workbench.unknownMember");
}

function chatSearchResultTime(message: ChatSearchResultMessage): string {
  const timestamp = Number(message.createdAt || message.clientCreatedAt || 0);
  if (!Number.isFinite(timestamp) || timestamp <= 0) return t("workbench.justNow");
  const date = new Date(timestamp);
  const now = new Date();
  const sameDay =
    date.getFullYear() === now.getFullYear() &&
    date.getMonth() === now.getMonth() &&
    date.getDate() === now.getDate();
  const time = new Intl.DateTimeFormat("zh-CN", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).format(date);
  if (sameDay) return time;
  return t("workbench.monthDayTime", { month: date.getMonth() + 1, day: date.getDate(), time });
}

function searchHighlight(text: string): Array<{ text: string; match: boolean }> {
  const query = chatSearchLastQuery.value.trim();
  if (!query) return [{ text, match: false }];
  const parts: Array<{ text: string; match: boolean }> = [];
  let cursor = 0;
  let at = text.toLowerCase().indexOf(query.toLowerCase());
  while (at !== -1) {
    if (at > cursor) parts.push({ text: text.slice(cursor, at), match: false });
    parts.push({ text: text.slice(at, at + query.length), match: true });
    cursor = at + query.length;
    at = text.toLowerCase().indexOf(query.toLowerCase(), cursor);
  }
  if (cursor < text.length) parts.push({ text: text.slice(cursor), match: false });
  return parts;
}

function openSearchResult(message: ChatSearchResultMessage): void {
  const id = messageId(message);
  if (!id || !sdk.activeConversationId.value) return;
  messageLocation.value = { conversationId: sdk.activeConversationId.value, messageId: id };
  chatSearchOpen.value = false;
  void router.push({ name: 'chat' });
}

function selectChatSearchKind(value: ChatSearchKindValue): void {
  chatSearchKind.value = value;
  if (!chatSearchQuery.value.trim()) return;
  void searchMessages();
}

function navigate(name: "conversations" | "chat" | "sdk-lab"): void {
  void router.push({ name });
}

async function logout(): Promise<void> {
  await sdk.logout();
  await router.replace({ name: "login" });
}

async function conversationOpenChat(): Promise<void> {
  const peerUserId = startPeerUserId.value.trim();
  if (!peerUserId) return;
  await sdk.openPeerConversation(startConversationType.value, peerUserId);
  startChatOpen.value = false;
  await router.push({ name: "chat" });
}

const dangerOperation = ref<{ kind: 'delete' | 'clear_history'; conversationId: string; userId: string; target: string }>();
const dangerBusy = ref(false);
const dangerError = ref('');
function requestConversationDanger(kind: 'delete' | 'clear_history'): void {
  const conversationId = sdk.activeConversationId.value;
  if (!conversationId) return;
  dangerError.value = '';
  dangerOperation.value = { kind, conversationId, userId: sdk.currentUserId.value,
    target: sdk.activeConversation.value ? conversationTitle(sdk.activeConversation.value) : conversationId };
}
async function confirmConversationDanger(): Promise<void> {
  const request = dangerOperation.value;
  if (!request || dangerBusy.value) return;
  if (request.conversationId !== sdk.activeConversationId.value || request.userId !== sdk.currentUserId.value) {
    dangerError.value = '当前会话已切换，请关闭并重新确认';
    return;
  }
  dangerBusy.value = true;
  dangerError.value = '';
  try {
    await sdk.runConversationOperation(request.kind);
    dangerOperation.value = undefined;
    if (request.kind === 'delete') await router.replace({ name: 'conversations' });
  } catch (error) {
    dangerError.value = operationErrorText(error, '操作未完成，请重试');
  } finally { dangerBusy.value = false; }
}
async function conversationDelete(): Promise<void> {
  requestConversationDanger('delete');
}

async function conversationPullFromServer(): Promise<void> {
  if (route.name === "chat") {
    await sdk.syncActiveConversation();
    await sdk.runSyncOperation("read");
    return;
  }
  await sdk.syncConversationsFromServer();
}

async function chatEnterLoadAndMarkRead(): Promise<void> {
  await conversationPullFromServer();
}

async function runActiveConversationAction(kind: string): Promise<void> {
  if (!sdk.activeConversationId.value) return;
  if (kind === "delete") {
    await conversationDelete();
  } else if (kind === 'clear_history') {
    requestConversationDanger('clear_history');
  } else {
    await sdk.runConversationOperation(kind);
  }
  moreOpen.value = false;
}

async function searchMessages(): Promise<void> {
  const own = ++searchGeneration;
  const query = chatSearchQuery.value.trim();
  chatSearchLoading.value = false;
  chatSearchError.value = "";
  chatSearchSearched.value = Boolean(query);
  if (!query) {
    await sdk.searchActiveMessages("", []);
    return;
  }
  if (!sdk.activeConversationId.value) {
    chatSearchError.value = t("workbench.selectOneConvFirst");
    return;
  }
  chatSearchLoading.value = true;
  chatSearchLastQuery.value = query;
  chatSearchLastKind.value = chatSearchKind.value;
  try {
    await sdk.searchActiveMessages(query, selectedChatSearchKinds());
  } catch (error) {
    if (own === searchGeneration) chatSearchError.value = searchErrorText(error);
  } finally {
    if (own === searchGeneration) chatSearchLoading.value = false;
  }
}

function selectedChatSearchKinds(): MessageSearchKind[] {
  switch (chatSearchKind.value) {
    case "text":
      return [MessageSearchKind.Text];
    case "media":
      return [MessageSearchKind.Media];
    case "image":
      return [MessageSearchKind.Image];
    case "video":
      return [MessageSearchKind.Video];
    case "audio":
      return [MessageSearchKind.Audio];
    case "file":
      return [MessageSearchKind.File];
    default:
      return [MessageSearchKind.Message];
  }
}

function operationErrorText(error: unknown, fallback: string): string {
  // 直接透 error.message 会把 wasm 桥的 JSON 信封和核心的 i18n key 甩给用户，
  // 例如 {"code":"sdk.error","message":"… sdk.message.card.avatar.invalid_url"}。
  return describeSdkError(error, fallback);
}

function searchErrorText(error: unknown): string {
  return operationErrorText(error, t("workbench.searchUnavailable"));
}

async function buildFromAction(op: string): Promise<void> {
  try {
    await sdk.buildFromComposerAction(op, "");
    sdkBuildOpen.value = false;
  } catch (error) {
    message.error(operationErrorText(error, t("toast.sendFailed")));
  }
}
</script>

<template>
  <FlareDangerConfirm :open="Boolean(dangerOperation)"
    :title="dangerOperation?.kind === 'delete' ? '删除会话' : '清空聊天记录'"
    description="请确认操作对象。此操作会更改会话或聊天记录。"
    :target="dangerOperation?.target || ''" :busy="dangerBusy" :error="dangerError"
    :confirm-text="dangerOperation?.kind === 'delete' ? '删除会话' : '清空记录'"
    @confirm="confirmConversationDanger" @cancel="dangerOperation = undefined" />
  <FlareWorkbenchShell
    v-model:more-open="moreOpen"
    v-model:chat-search-open="chatSearchOpen"
    v-model:sdk-build-open="sdkBuildOpen"
    v-model:preview-open="previewOpen"
    :mode="shellMode"
    :more-title="moreDrawerTitle"
    :more-action-count="moreActionCount"
    :message-unread-count="sdk.totalUnread.value"
    @navigate-messages="navigate('conversations')"
    @navigate-lab="navigate('sdk-lab')"
    @logout="logout"
  >
    <template #conversation>
      <router-view name="conversation" />
    </template>

    <template #main>
      <router-view name="main" />
    </template>

    <template #details>
      <ConversationDetails
        :conversation="sdk.activeConversation.value"
        :connection-text="connectionText"
        :connection-tone="connectionTone"
        :message-count="sdk.messages.value.length"
        :latest-message-id="sdk.activeLatestMessageId.value"
        @sync="chatEnterLoadAndMarkRead"
        @mark-read="sdk.runSyncOperation('read')"
        @mark-unread="sdk.runConversationOperation('mark_unread')"
        @pin="(pinned) => sdk.runConversationOperation(pinned ? 'pin' : 'unpin')"
        @mute="(muted) => sdk.runConversationOperation(muted ? 'mute' : 'unmute')"
        @archive="(archived) => sdk.runConversationOperation(archived ? 'archive' : 'unarchive')"
        @clear-history="requestConversationDanger('clear_history')"
        @delete="conversationDelete"
        @open-devtools="navigate('sdk-lab')"
      />
    </template>

    <template #more>
      <section v-if="route.name === 'conversations'" class="account-sheet-header">
        <div class="account-avatar">{{ sdk.form.userId.slice(0, 1).toUpperCase() }}</div>
        <div>
          <span>{{ t('workbench.account') }}</span>
          <strong>{{ sdk.form.userId }}</strong>
        </div>
        <n-tag :type="connectionTone" round>{{ connectionText }}</n-tag>
      </section>
      <div class="more-action-list">
        <button v-if="route.name === 'conversations'" type="button" @click="startChatOpen = true; moreOpen = false">
          <n-icon :component="AddOutline" /> {{ t('workbench.newChat') }}
        </button>
        <button v-if="route.name === 'chat'" type="button" @click="chatSearchOpen = true; moreOpen = false">
          <n-icon :component="SearchOutline" /> {{ t('workbench.searchMessages') }}
        </button>
        <button v-if="route.name === 'conversations'" type="button" @click="conversationPullFromServer(); moreOpen = false">
          <n-icon :component="SyncOutline" /> {{ t('workbench.pullFromServer') }}
        </button>
        <button v-if="route.name === 'chat'" type="button" @click="chatEnterLoadAndMarkRead(); moreOpen = false">
          <n-icon :component="SyncOutline" /> {{ t('workbench.syncAndMarkRead') }}
        </button>
      </div>
      <div v-if="route.name === 'chat' && activeConversation" class="more-action-list more-action-list--grouped">
        <button type="button" @click="runActiveConversationAction(activeConversationUnread ? 'mark_read' : 'mark_unread')">
          <n-icon :component="activeConversationUnread ? CheckmarkDoneOutline : MailUnreadOutline" />
          {{ activeConversationUnread ? t('conversation.markRead') : t('conversation.markUnread') }}
        </button>
        <button type="button" @click="runActiveConversationAction(activeConversationPinned ? 'unpin' : 'pin')">
          <n-icon :component="PinOutline" /> {{ activeConversationPinned ? t('conversation.unpin') : t('workbench.pinConv') }}
        </button>
        <button type="button" @click="runActiveConversationAction(activeConversationMuted ? 'unmute' : 'mute')">
          <n-icon :component="NotificationsOffOutline" /> {{ activeConversationMuted ? t('conversation.unmute') : t('conversation.mute') }}
        </button>
        <button type="button" @click="runActiveConversationAction(activeConversationArchived ? 'unarchive' : 'archive')">
          <n-icon :component="ArchiveOutline" /> {{ activeConversationArchived ? t('conversation.unarchive') : t('workbench.archiveConv') }}
        </button>
        <button type="button" @click="runActiveConversationAction('clear_history')">
          <n-icon :component="TrashOutline" /> {{ t('conversation.clearHistory') }}
        </button>
        <button type="button" class="more-action-danger" @click="runActiveConversationAction('delete')">
          <n-icon :component="TrashOutline" /> {{ t('conversation.delete') }}
        </button>
      </div>
      <div class="more-action-list more-action-list--grouped">
        <button type="button" @click="navigate('sdk-lab'); moreOpen = false">
          <n-icon :component="InformationCircleOutline" /> {{ t('workbench.sdkRuntimeStatus') }}
        </button>
        <button type="button" @click="settingsOpen = true; moreOpen = false">
          <n-icon :component="SettingsOutline" /> {{ t("nav.settings") }}
        </button>
        <button type="button" class="more-action-danger" @click="logout(); moreOpen = false">
          <n-icon :component="LogOutOutline" /> {{ t('common.logout') }}
        </button>
      </div>
    </template>

    <template #chat-search>
      <form class="chat-search-panel" @submit.prevent="searchMessages" @keydown.enter="($event.isComposing || $event.keyCode === 229) && $event.preventDefault()">
        <div class="chat-search-panel__field">
          <n-input
            v-model:value="chatSearchQuery"
            clearable
            :input-props="{ 'aria-label': locale.startsWith('en') ? 'Search messages' : '搜索聊天记录' }"
            :disabled="!sdk.activeConversationId.value"
            :placeholder="t('workbench.searchChatHistory')"
          >
            <template #prefix><n-icon :component="SearchOutline" /></template>
          </n-input>
          <n-button
            class="chat-search-submit"
            :title="locale.startsWith('en') ? 'Search' : '搜索'"
            :aria-label="locale.startsWith('en') ? 'Search' : '搜索'"
            type="primary"
            attr-type="submit"
            :loading="chatSearchLoading"
            :disabled="!chatSearchCanSubmit"
          >
            <n-icon :size="18" :component="SearchOutline" />
          </n-button>
        </div>

        <div class="chat-search-panel__filters" role="group" :aria-label="t('workbench.searchTypeAria')">
          <button
            v-for="option in chatSearchKindOptions"
            :key="option.value"
            type="button"
            :aria-pressed="chatSearchKind === option.value"
            :class="{ 'is-active': chatSearchKind === option.value }"
            @click="selectChatSearchKind(option.value)"
          >
            <n-icon :component="option.icon" />
            {{ option.label }}
          </button>
        </div>

        <div v-if="chatSearchSearched && !chatSearchError && !chatSearchLoading" class="chat-search-panel__meta" role="status">
          <span>{{ chatSearchLastKindLabel }}</span>
          <strong>{{ chatSearchLastQuery }}</strong><span class="chat-search-count">{{ chatSearchResults.length }} {{ locale.startsWith('en') ? 'results' : '条结果' }}</span>
        </div>

        <div v-if="!sdk.activeConversationId.value" class="chat-search-panel__state">
          <n-icon :component="ChatbubbleEllipsesOutline" />
          <strong>{{ t('workbench.noConvSelected') }}</strong>
          <span>{{ t('workbench.searchNoContent') }}</span>
        </div>
        <div v-else-if="chatSearchError" class="chat-search-panel__state chat-search-panel__state--error">
          <n-icon :component="AlertCircleOutline" />
          <strong>{{ t('workbench.searchFailed') }}</strong>
          <span>{{ chatSearchError }}</span><button type="button" class="chat-search-retry" @click="searchMessages">{{ locale.startsWith('en') ? 'Retry' : '重新搜索' }}</button>
        </div>
        <div v-else-if="chatSearchLoading" class="chat-search-panel__state">
          <span class="chat-search-panel__spinner" />
          <strong>{{ t('workbench.searchingTitle') }}</strong>
          <span>{{ t('workbench.searchingHint') }}</span>
        </div>
        <div v-else-if="!chatSearchSearched" class="chat-search-panel__state chat-search-panel__state--idle">
          <n-icon :component="SearchOutline" />
          <strong>{{ t('workbench.searchCurrentConvTitle') }}</strong>
          <span>{{ t('workbench.searchStartHint') }}</span>
        </div>
        <div v-else-if="!chatSearchResults.length" class="chat-search-panel__state">
          <n-icon :component="SearchOutline" />
          <strong>{{ t('workbench.noRelatedMsg') }}</strong>
          <span>{{ t('workbench.tryOtherKeyword') }}</span>
        </div>
        <div v-else class="chat-search-results">
          <button
            v-for="message in chatSearchResults"
            :key="messageId(message)"
            type="button"
            class="chat-search-result-card"
            @click="openSearchResult(message)"
          >
            <span class="chat-search-result-card__icon">
              <n-icon :component="chatSearchResultIcon(message)" />
            </span>
            <div class="chat-search-result-card__content">
              <div class="chat-search-result-card__topline">
                <strong>{{ chatSearchResultSender(message) }}</strong>
                <span>{{ chatSearchResultTime(message) }}</span>
              </div>
              <p><template v-for="(part, index) in searchHighlight(chatSearchResultText(message))" :key="index"><mark v-if="part.match">{{ part.text }}</mark><template v-else>{{ part.text }}</template></template></p>
              <div class="chat-search-result-card__meta">
                <span>{{ chatSearchResultKindLabel(message) }}</span>
              </div>
            </div>
          </button>
        </div>
      </form>
    </template>

    <template #sdk-build>
      <MessageActionSheet @build="buildFromAction" />
      <DeveloperConsole
        class="sdk-build-console"
        :diagnostics-text="diagnosticsText"
        :lab-result-text="labResultText"
        :lab-busy="sdk.labBusy.value"
        :build-options="sdk.messageBuildOptions.value"
        :dispatch-options="sdk.messageDispatchOptions"
        :sdk-lab="sdk.sdkLab"
        :events="sdk.events.value"
        @session="sdk.runSessionDiagnostics"
        @events="sdk.runEventOperation"
        @open-peer="sdk.openPeerConversation"
        @build-send="sdk.buildAndSendMessage()"
        @dispatch="sdk.runDispatch()"
        @conversation="sdk.runConversationOperation"
        @sync="sdk.runSyncOperation"
        @presence="sdk.runPresenceOperation"
        @media="sdk.runMediaOperation"
        @capability="sdk.runCapabilityOperation"
      />
    </template>

    <template #preview>
      <MessagePreviewModal :message="previewMessage" />
    </template>
  </FlareWorkbenchShell>

  <FlareStartConversationDialog
    v-model:open="startChatOpen"
    v-model:peer-user-id="startPeerUserId"
    v-model:conversation-type="startConversationType"
    :busy="sdk.labBusy.value"
    @confirm="conversationOpenChat"
  />

  <n-modal v-model:show="settingsOpen" preset="card" :title="t('nav.settings')" style="max-width: 420px">
    <div class="settings-form">
      <label class="settings-field">
        <span>{{ t('workbench.themeMode') }}</span>
        <n-select
          v-model:value="themeModeValue"
          :options="[
            { label: t('workbench.themeOpt.system'), value: 'system' },
            { label: t('workbench.themeOpt.light'), value: 'light' },
            { label: t('workbench.themeOpt.dark'), value: 'dark' },
          ]"
        />
      </label>
      <label class="settings-field">
        <span>{{ t('workbench.themeVariant') }}</span>
        <n-select
          v-model:value="themeVariantValue"
          :options="[
            { label: t('workbench.variantOpt.default'), value: 'default' },
            { label: t('workbench.variantOpt.compact'), value: 'compact' },
            { label: t('workbench.variantOpt.callDark'), value: 'callDark' },
            { label: t('workbench.variantOpt.highContrast'), value: 'highContrast' },
          ]"
        />
      </label>
      <label class="settings-field">
        <span>{{ t('workbench.language') }}</span>
        <n-select
          v-model:value="localeValue"
          :options="[
            { label: '简体中文', value: 'zh-CN' },
            { label: 'English', value: 'en-US' },
          ]"
        />
      </label>
    </div>
  </n-modal>
</template>

<style scoped>

.settings-form {
  display: grid;
  gap: 14px;
}

.settings-field {
  display: grid;
  gap: 6px;
  font-size: 13px;
  color: var(--text-secondary);
}

:global(.workbench-search-sheet.mobile-sheet .n-drawer-body-content-wrapper) {
  background:
    linear-gradient(180deg, color-mix(in srgb, var(--im-primary) 7%, transparent), transparent 132px),
    var(--im-bg-app);
}

:global(.workbench-search-sheet .n-drawer-content) {
  background: transparent;
}

:global(.workbench-search-sheet .n-drawer-header) {
  border-bottom: 1px solid color-mix(in srgb, var(--im-border) 74%, transparent);
  background: color-mix(in srgb, var(--im-bg-surface) 92%, transparent);
}

:global(.workbench-search-sheet .n-drawer-header__main) {
  color: var(--im-text-primary);
  font-size: 16px;
  font-weight: 800;
}

:global(.workbench-search-sheet.n-drawer--bottom .n-drawer-content::before) {
  background: color-mix(in srgb, var(--im-text-tertiary) 56%, transparent);
}
</style>

<style scoped src="../styles/chat-search.css"></style>
