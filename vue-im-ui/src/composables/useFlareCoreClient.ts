import { computed, onBeforeUnmount, reactive, readonly, ref, watch } from "vue";
import { translateFlare } from "../shared/i18n/messages";
import type {
  AudioContentPayload,
  Conversation,
  FileContentPayload,
  FlareImClient,
  ImageGroupContentPayload,
  ImageContentPayload,
  Message,
  MessageBuildCatalogEntry,
  MessageContent,
  MessageSendCallback,
  MessageSearchKind,
  ReactionEntry,
  SendMessageResponse,
  SdkConfig,
  VideoContentPayload,
  ViewUpdate,
  WebFlareImClient,
} from "@flare-im/sdk/web";
import {
  FlareSdkException,
  HeartbeatAppState,
  MessageBuildOp,
  MessageContentType,
  NetworkInterfaceKind,
  conversationFromJson,
  messageFromJson,
} from "@flare-im/sdk/web";
import {
  bindFlareSessionEvents,
  reportSdkError,
  type IncomingMessageHint,
  type PresenceChangedHint,
  type ReactionChangedHint,
} from "./useFlareSessionBridge";
import {
  emitDesktopNotification,
  setDesktopUnreadCount,
  type DesktopNotificationKind,
} from "../app/infrastructure/desktop/desktopNotifications";
import { sdkMediaProxyFields } from "../shared/config/mediaProxy";
import { withTimeout } from "../utils/asyncTimeout";

export interface LoginFormState {
  userId: string;
  token: string;
  transportMode: LoginTransportMode;
  wsUrl: string;
  quicUrl: string;
  tlsCaCertPath: string;
  httpUrl: string;
  dataUrl: string;
  tenantId: string;
}

export type LoginTransportMode = "websocket" | "quic" | "race";
export type SdkRuntimeStatus = "browser-wasm" | "browser-unavailable" | "tauri-native" | "electron-native" | "uni-native";

type LoginTransportConfig = Pick<
  SdkConfig,
  "wsUrl" | "quicUrl" | "tlsCaCertPath" | "transportPolicy" | "defaultTransport" | "protocolRaceOrder"
>;

export interface LoginIdentity {
  userId: string;
  tenantId: string;
}

export interface RuntimeEventLogItem {
  id: number;
  label: string;
  detail: string;
  at: number;
}

export interface HomeSyncProgress {
  step: "idle" | "session" | "conversations" | "unread" | "history" | "preview" | "ready" | "failed";
  title: string;
  detail: string;
  percent: number;
}

export interface SdkLabState {
  buildOp: string;
  dispatchOp: string;
  messageText: string;
  messageId: string;
  query: string;
  peerUserId: string;
  userIds: string;
  fileId: string;
  reaction: string;
  capability: string;
  capabilityTargetUserId: string;
  mediaUrl: string;
  mediaCacheRoot: string;
  mediaCacheMaxBytes: number;
  downloadSubfolder: string;
  downloadKey: string;
  displayFileName: string;
  sourcePath: string;
  sourceUrl: string;
  remoteFileId: string;
  networkAvailable: boolean;
  networkInterface: NetworkInterfaceKind;
  networkExpensive: boolean;
  networkMetered: boolean;
  heartbeatAppState: "foreground" | "background";
  heartbeatNatTimeoutSecs: number;
  tokenTtlSecs: number;
  draft: string;
  jsonParams: string;
}

export type ConversationFilter = "all" | "unread" | "mention" | "pinned" | "muted" | "archived" | "draft";
type ConversationRefreshOptions = { silent?: boolean };
type MessageRefreshOptions = { silent?: boolean };
type LoadOlderMessagesOptions = { force?: boolean; limit?: number };

type BuildAndSendMessageRequest = {
  conversationId: string;
  op: MessageBuildOp | string;
  params?: Record<string, unknown>;
  callback?: MessageSendCallback;
};

type CoreSessionSnapshot = {
  initialized: boolean;
  loggedIn: boolean;
  userId: string;
  connectionState: string;
};

type CoreDiagnosticsSnapshot = {
  sdkVersion: Record<string, unknown>;
  ffiContract: Record<string, unknown>;
  dataRoot: Record<string, unknown>;
  runtimeHealth: Record<string, unknown>;
  currentUser: unknown;
  sessionActive: boolean;
  isConnected: boolean;
  connectionState: string;
};

type ViewDeltaPayload = NonNullable<ViewUpdate["delta"]>;
type ViewDeltaOperation = ViewDeltaPayload["ops"][number];

export interface ConversationFilterState {
  filter: ConversationFilter;
  includeArchived: boolean;
  conversationType: string;
}

// 会话打开/翻页一次取多少条。开窗越小，打开时主线程上的 WASM 取数(IndexedDB 读+protobuf 解码)
// 与 Vue 渲染(每条 MessageBubble ~4ms)成正比越少 → 打开更流畅(符合"首屏 <200ms"预算)。
// 更早的历史按需经 load-older(已验证可用)增量补齐,不丢可回溯性。
const MESSAGE_PAGE_SIZE = 40;
const INITIAL_HISTORY_REPAIR_SYNC_LIMIT = 200;
const INITIAL_HISTORY_REPAIR_MAX_PAGES = 8;
const FULL_HISTORY_BACKFILL_SYNC_LIMIT = 500;
const FULL_HISTORY_BACKFILL_MAX_PAGES_PER_CALL = 2;
const FULL_HISTORY_BACKFILL_MAX_ROUNDS = 128;
const HISTORY_BACKFILL_CONVERSATION_TIMEOUT_MS = 30_000;
const REALTIME_SAFETY_POLL_INTERVAL_MS = 12_000;
const REALTIME_SAFETY_POLL_BACKOFF_BASE_MS = 8_000;
const REALTIME_SAFETY_POLL_BACKOFF_MAX_MS = 60_000;
const REALTIME_SAFETY_POLL_AFTER_SEND_QUIET_MS = 30_000;
const INCOMING_CONVERSATION_REFRESH_DEBOUNCE_MS = 120;
// 活动会话的"事件提示"对账(syncConversation + 时间线重读)去抖窗口:实时显示由 core 观察视图增量
// (applyTimelineViewDelta)负责;此对账仅作安全网,合并消息突发为一次,避免每条消息全量重开时间线的抖动风暴。
const ACTIVE_CONVERSATION_REFRESH_DEBOUNCE_MS = 500;

export interface UseFlareCoreClientOptions {
  /** Host-provided client factory (e.g. web WASM bridge). */
  createClient: () => FlareImClient;
  /** Host environment record (e.g. Vite `import.meta.env`). */
  env?: Record<string, string | undefined>;
  /** Default HTTP base URL for the dev login form (host-resolved). */
  defaultHttpUrl?: string;
  /** Host-provided CA/self-signed certificate path for native QUIC TLS. */
  defaultTlsCaCertPath?: string;
  /** Native hosts can expose QUIC/protocol racing; browser Web/WASM stays WebSocket-only. */
  nativeTransportSelectionEnabled?: boolean;
  /** Host runtime label for diagnostics and login status. */
  runtimeStatus?: SdkRuntimeStatus;
}

/**
 * 归档筛选的取舍：只保留已归档的会话。
 *
 * SDK 侧只有 `includeArchived`，语义是"额外带上归档会话"而不是"只要归档会话"。
 * 拿它当归档筛选用，列表会原样返回全部——筛选看起来生效了（高亮切了），
 * 内容却一条没少。没有 archivedOnly 查询可用，只能取回后自己收窄。
 */
export function keepArchivedConversations<T extends { isArchived?: boolean }>(
  conversations: readonly T[],
): T[] {
  return conversations.filter((conversation) => Boolean(conversation.isArchived));
}

export function readLoginEnvText(value: string | undefined, fallback: string): string {
  const normalized = String(value ?? "").trim();
  return normalized || fallback;
}

export function normalizeLoginTransportMode(value: unknown): LoginTransportMode {
  const normalized = String(value ?? "").trim().toLowerCase().replace(/-/g, "_");
  if (normalized === "quic") return "quic";
  if (normalized === "race" || normalized === "protocol_race") return "race";
  return "websocket";
}

export function loginTransportDisplayName(value: unknown): string {
  const mode = normalizeLoginTransportMode(value);
  if (mode === "quic") return "QUIC";
  if (mode === "race") return "QUIC → WebSocket";
  return "WebSocket";
}

function requiredLoginUrl(value: string, label: string): string {
  const normalized = String(value ?? "").trim();
  if (!normalized) {
    throw new Error(`${label} is required for selected transport`);
  }
  return normalized;
}

function optionalLoginText(value: string | undefined): string | undefined {
  const normalized = String(value ?? "").trim();
  return normalized || undefined;
}

export function buildLoginTransportConfig(
  input: Pick<LoginFormState, "transportMode" | "wsUrl" | "quicUrl"> &
    Partial<Pick<LoginFormState, "tlsCaCertPath">>,
): LoginTransportConfig {
  const mode = normalizeLoginTransportMode(input.transportMode);
  const wsUrl = requiredLoginUrl(input.wsUrl, "WebSocket URL");
  const tlsCaCertPath = optionalLoginText(input.tlsCaCertPath);
  const tlsConfig = tlsCaCertPath ? { tlsCaCertPath } : {};
  if (mode === "websocket") {
    return {
      wsUrl,
      ...tlsConfig,
      transportPolicy: "websocket_only",
      defaultTransport: "websocket",
    };
  }

  const quicUrl = requiredLoginUrl(input.quicUrl, "QUIC URL");
  if (mode === "quic") {
    return {
      wsUrl,
      quicUrl,
      ...tlsConfig,
      transportPolicy: "auto",
      defaultTransport: "quic",
      protocolRaceOrder: ["quic"],
    };
  }

  return {
    wsUrl,
    quicUrl,
    ...tlsConfig,
    transportPolicy: "protocol_race",
    defaultTransport: "quic",
    protocolRaceOrder: ["quic", "websocket"],
  };
}

function transportErrorText(error: unknown): string {
  if (!error) return "";
  const parts: string[] = [];
  if (error instanceof Error) {
    parts.push(error.message);
  } else {
    parts.push(String(error));
  }
  if (typeof error === "object") {
    const shaped = error as {
      code?: unknown;
      operation?: unknown;
      details?: unknown;
      cause?: unknown;
    };
    for (const value of [shaped.code, shaped.operation]) {
      if (value !== undefined && value !== null) parts.push(String(value));
    }
    if (shaped.details !== undefined) {
      try {
        parts.push(JSON.stringify(shaped.details));
      } catch {
        parts.push(String(shaped.details));
      }
    }
    if (shaped.cause !== undefined) {
      parts.push(transportErrorText(shaped.cause));
    }
  }
  return parts.filter(Boolean).join(" ");
}

export function isRecoverableLoginTransportError(
  error: unknown,
  transportMode: LoginTransportMode,
): boolean {
  const mode = normalizeLoginTransportMode(transportMode);
  if (mode === "websocket") return false;
  const text = transportErrorText(error);
  if (!text) return false;
  const mentionsQuic = /\bquic\b/i.test(text);
  const unsupported = /OPERATION_NOT_SUPPORTED|not supported|feature is disabled/i.test(text);
  return mentionsQuic && unsupported;
}

function loginTransportLabel(transportMode: LoginTransportMode): string {
  return normalizeLoginTransportMode(transportMode) === "race" ? translateFlare("login.transport.race") : "QUIC";
}

function loginTransportFallbackReason(error: unknown): string {
  const text = transportErrorText(error);
  if (/QUIC transport feature is disabled/i.test(text)) {
    return "QUIC transport feature is disabled";
  }
  const codeMatch = text.match(/\[OPERATION_NOT_SUPPORTED\]/i);
  if (codeMatch) return codeMatch[0];
  return text.slice(0, 160);
}

export function loginTransportFallbackMessage(
  transportMode: LoginTransportMode,
  error: unknown,
): string {
  const reason = loginTransportFallbackReason(error);
  const suffix = reason ? translateFlare("transport.fallbackReason", { reason }) : translateFlare("transport.fallbackReasonGeneric");
  return translateFlare("transport.switchedToWebsocket", { label: loginTransportLabel(transportMode), suffix });
}

export function normalizeLoginIdentityForSdk(input: Pick<LoginFormState, "userId" | "tenantId">): LoginIdentity {
  const userId = String(input.userId ?? "").trim();
  if (!userId) {
    throw new Error("userId is required");
  }
  const tenantId = String(input.tenantId ?? "").trim() || "0";
  return { userId, tenantId };
}

export function presenceStatusFromCoreDto(input: unknown): string {
  const status = readStringField(input, "status");
  if (status) return status;
  const isOnline = readBooleanField(input, "isOnline");
  if (isOnline !== undefined) return isOnline ? "online" : "offline";
  return "offline";
}

function readStringField(input: unknown, field: string): string {
  if (!input || typeof input !== "object") return "";
  const value = (input as Record<string, unknown>)[field];
  return typeof value === "string" ? value.trim() : "";
}

function readBooleanField(input: unknown, field: string): boolean | undefined {
  if (!input || typeof input !== "object") return undefined;
  const value = (input as Record<string, unknown>)[field];
  return typeof value === "boolean" ? value : undefined;
}

function makeFormDefaults(
  env: Record<string, string | undefined>,
  defaultHttpUrl: string,
  nativeTransportSelectionEnabled = false,
  defaultTlsCaCertPath = "",
): LoginFormState {
  return {
    userId: readLoginEnvText(env.VITE_FLARE_USER_ID, ""),
    token: "",
    transportMode: nativeTransportSelectionEnabled
      ? normalizeLoginTransportMode(env.VITE_FLARE_TRANSPORT_MODE ?? env.VITE_FLARE_TRANSPORT_POLICY)
      : "websocket",
    wsUrl: readLoginEnvText(env.VITE_FLARE_WS_URL, "ws://127.0.0.1:60051/ws"),
    quicUrl: readLoginEnvText(env.VITE_FLARE_QUIC_URL, "quic://127.0.0.1:60052"),
    tlsCaCertPath: readLoginEnvText(env.VITE_FLARE_TLS_CA_CERT_PATH, defaultTlsCaCertPath),
    httpUrl: readLoginEnvText(env.VITE_FLARE_HTTP_URL, defaultHttpUrl),
    dataUrl: readLoginEnvText(env.VITE_FLARE_DATA_URL, ""),
    tenantId: readLoginEnvText(env.VITE_FLARE_TENANT_ID, "0"),
  };
}

/**
 * 热启动会话档案：登录成功后持久化，下次启动免登录直接
 * prepare(本地库) → 本地出图 → 后台 connect，实现秒级热启动。
 * 示例应用用 localStorage 存 dev token；生产应用应换安全存储。
 */
export interface SavedSessionProfile {
  userId: string;
  tenantId: string;
  token: string;
  transportMode: LoginTransportMode;
  wsUrl: string;
  quicUrl: string;
  tlsCaCertPath: string;
  httpUrl: string;
  dataUrl: string;
  savedAtMs: number;
}

const SAVED_SESSION_STORAGE_KEY = "flare-core:saved-session:v1";

function savedSessionStorage(): Storage | undefined {
  try {
    if (typeof window !== "undefined" && window.localStorage) {
      return window.localStorage;
    }
  } catch {
    // storage 被禁用（隐私模式等）时静默降级为无热启动
  }
  return undefined;
}

export function loadSavedSessionProfile(): SavedSessionProfile | undefined {
  const storage = savedSessionStorage();
  if (!storage) return undefined;
  try {
    const raw = storage.getItem(SAVED_SESSION_STORAGE_KEY);
    if (!raw) return undefined;
    const parsed = JSON.parse(raw) as Partial<SavedSessionProfile>;
    const userId = String(parsed.userId ?? "").trim();
    const token = String(parsed.token ?? "").trim();
    const wsUrl = String(parsed.wsUrl ?? "").trim();
    if (!userId || !token || !wsUrl) return undefined;
    return {
      userId,
      tenantId: String(parsed.tenantId ?? "").trim() || "0",
      token,
      transportMode: normalizeLoginTransportMode(parsed.transportMode),
      wsUrl,
      quicUrl: String(parsed.quicUrl ?? "").trim(),
      tlsCaCertPath: String(parsed.tlsCaCertPath ?? "").trim(),
      httpUrl: String(parsed.httpUrl ?? "").trim(),
      dataUrl: String(parsed.dataUrl ?? "").trim(),
      savedAtMs: Number(parsed.savedAtMs) || 0,
    };
  } catch {
    return undefined;
  }
}

export function persistSavedSessionProfile(profile: SavedSessionProfile): void {
  const storage = savedSessionStorage();
  if (!storage) return;
  try {
    storage.setItem(SAVED_SESSION_STORAGE_KEY, JSON.stringify(profile));
  } catch {
    // 配额满等写失败只影响下次热启动，不影响本次会话
  }
}

export function clearSavedSessionProfile(): void {
  const storage = savedSessionStorage();
  if (!storage) return;
  try {
    storage.removeItem(SAVED_SESSION_STORAGE_KEY);
  } catch {
    // 与写失败同理
  }
}

const sdkLabDefaults: SdkLabState = {
  buildOp: "create_text",
  dispatchOp: "search",
  messageText: "",
  messageId: "",
  query: "",
  peerUserId: "",
  userIds: "",
  fileId: "",
  reaction: "👍",
  capability: "rtc.call",
  capabilityTargetUserId: "",
  mediaUrl: "",
  mediaCacheRoot: "memory://flare-core-web-app/media-cache",
  mediaCacheMaxBytes: 134217728,
  downloadSubfolder: "flare-im",
  downloadKey: "",
  displayFileName: "",
  sourcePath: "",
  sourceUrl: "",
  remoteFileId: "",
  networkAvailable: true,
  networkInterface: NetworkInterfaceKind.Wifi,
  networkExpensive: false,
  networkMetered: false,
  heartbeatAppState: "foreground",
  heartbeatNatTimeoutSecs: 60,
  tokenTtlSecs: 3600,
  draft: "",
  jsonParams: "{}",
};

const sdkEventSources = [
  "lifecycle",
  "connection",
  "message",
  "conversation",
  "sync",
  "presence",
  "media",
  "capability",
  "view",
] as const;

const messageDispatchOptions = [
  { label: "Search", value: "search" },
  { label: "Search In Conversation", value: "search_in_conversation" },
  { label: "Get", value: "get" },
  { label: "Get Raw", value: "get_raw" },
  { label: "Edit Text", value: "edit_text_by_message_id" },
  { label: "Edit Rich Doc", value: "edit_rich_doc_by_message_id" },
  { label: "Delete Self", value: "delete_for_self" },
  { label: "Delete Everyone", value: "delete_for_everyone" },
  { label: "Add Reaction", value: "add_reaction" },
  { label: "Remove Reaction", value: "remove_reaction" },
  { label: "Pin Message", value: "pin_by_message_id" },
  { label: "Unpin Message", value: "unpin_by_message_id" },
  { label: "Mark Important", value: "mark_by_message_id" },
  { label: "Mark With Color", value: "mark_with_color" },
  { label: "Unmark", value: "unmark_by_message_id" },
  { label: "Typing", value: "typing" },
  { label: "Mark Read", value: "mark_read" },
  { label: "Mark Read And Burn", value: "mark_read_and_burn" },
];

export { getMessageText } from "../utils";

const timelineRefreshingDispatchOps = new Set([
  "edit_text_by_message_id",
  "edit_rich_doc_by_message_id",
  "delete_for_self",
  "delete_for_everyone",
  "add_reaction",
  "remove_reaction",
  "pin_by_message_id",
  "unpin_by_message_id",
  "mark_by_message_id",
  "mark_with_color",
  "unmark_by_message_id",
  "mark_read",
  "mark_read_and_burn",
]);

export function shouldRefreshTimelineAfterDispatch(op: string): boolean {
  return timelineRefreshingDispatchOps.has(op);
}

/** proto `MarkType`：0=UNSPECIFIED, 1=IMPORTANT, 2=TODO, 3=DONE, 4=CUSTOM。 */
export const MARK_TYPE_IMPORTANT = 1;

/** 标记默认色。核心侧要求 color 非空字符串，调用方不关心颜色时用它兜底。 */
export const DEFAULT_MARK_COLOR = "#F5A623";

export function buildMessageDispatchParams(input: {
  conversationId: string;
  messageId: string;
  text?: string;
  keyword?: string;
  emoji?: string;
  markType?: number;
  color?: string;
  jsonParams?: Record<string, unknown>;
}): Record<string, unknown> {
  return {
    conversationId: input.conversationId,
    messageId: input.messageId,
    clientMsgId: input.messageId,
    text: input.text ?? "",
    keyword: input.keyword ?? "",
    emoji: input.emoji ?? "",
    // 标记类操作的契约是 messageId + markType(i32) + color(string)，
    // 见 bindings/shared 的 mark_by_message_id 分支。此前这里两个都不产出，
    // 只能靠 SDK Lab 的自由 JSON 补，于是消息右键菜单里的"标记"必然失败，
    // 报 INVALID_PARAMETER。markType 走 json_i32，写成字符串同样会被拒。
    markType: input.markType ?? MARK_TYPE_IMPORTANT,
    color: input.color ?? DEFAULT_MARK_COLOR,
    ...(input.jsonParams ?? {}),
  };
}

function parseJsonParams(source: string): Record<string, unknown> {
  const raw = source.trim();
  if (!raw) return {};
  try {
    const value = JSON.parse(raw);
    return value && typeof value === "object" && !Array.isArray(value) ? value : {};
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    throw new Error(`jsonParams must be a valid JSON object: ${detail}`);
  }
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

const devTokenDefaults = {
  issuer: "flare-im-core",
  ttlSecs: 3600,
};

const DEFAULT_SEND_TIMEOUT_MS = 30_000;
const HOME_CONVERSATION_LOAD_TIMEOUT_MS = 8_000;
const STARTUP_HOME_SYNC_TIMEOUT_MS = 8_000;
const SYNC_CONVERSATION_SUMMARIES_TIMEOUT_MS = 8_000;
const CONVERSATION_LIST_VIEW_OPEN_TIMEOUT_MS = 8_000;
const LOGIN_SESSION_RESET_TIMEOUT_MS = 3_000;
const CORE_LOGIN_STEP_TIMEOUT_MS = 8_000;
const CORE_LOGIN_TIMEOUT_MS = 120_000;
const TIMELINE_OPEN_TIMEOUT_MS = 10_000;
const MESSAGE_SYNC_TIMEOUT_MS = 12_000;

function stringDetails(details: Record<string, unknown>): Record<string, string> {
  return Object.fromEntries(
    Object.entries(details).map(([key, value]) => [key, String(value ?? "")]),
  );
}

function sendTimeoutError(timeoutMs: number): Error {
  const error = new Error(`message.send timed out after ${timeoutMs}ms`);
  (error as Error & { code?: string }).code = "timeout";
  return error;
}

function sdkOperationTimeoutError(operation: string, timeoutMs: number): Error {
  const error = new Error(`${operation} timed out after ${timeoutMs}ms`);
  (error as Error & { code?: string; operation?: string }).code = "timeout";
  (error as Error & { code?: string; operation?: string }).operation = operation;
  return error;
}

function sendAckDetails(ack: SendMessageResponse): Record<string, string> {
  return {
    ackId: ack.ackId,
    clientMsgId: ack.clientMsgId,
    conversationId: ack.conversationId,
    errorCode: String(ack.errorCode),
    errorMessage: ack.errorMessage,
    seq: String(ack.seq),
    serverId: ack.serverId,
    success: String(ack.success),
    timestamp: String(ack.timestamp),
  };
}

function sendAckFailureError(ack: SendMessageResponse): Error {
  const message = ack.errorMessage || "message.send failed";
  const error = new Error(message);
  (error as Error & { code?: string; details?: SendMessageResponse }).code = String(ack.errorCode || "send_ack_failed");
  (error as Error & { code?: string; details?: SendMessageResponse }).details = ack;
  return error;
}

function isFinalSendAck(ack: SendMessageResponse): boolean {
  return ack.success === true && (ack.serverId.trim() !== "" || ack.seq > 0);
}

function isQueuedSendAck(ack: SendMessageResponse): boolean {
  return ack.success === false && ack.errorCode === 0 && ack.serverId.trim() === "" && ack.seq === 0;
}

function sendAckMatches(ack: SendMessageResponse, message: Message): boolean {
  const clientMsgId = message.clientMsgId.trim();
  if (clientMsgId && ack.clientMsgId === clientMsgId) return true;
  const serverId = message.serverId.trim();
  return Boolean(serverId && ack.serverId === serverId);
}

function sendAckFromEvent(event: unknown): SendMessageResponse | undefined {
  if (!event || typeof event !== "object") return undefined;
  const record = event as { ack?: unknown };
  return record.ack && typeof record.ack === "object"
    ? record.ack as SendMessageResponse
    : undefined;
}

function sendFailureFromEvent(event: unknown): { clientMsgId: string; reason: string } | undefined {
  if (!event || typeof event !== "object") return undefined;
  const record = event as { type?: unknown; event?: unknown; clientMsgId?: unknown; reason?: unknown; message?: unknown };
  const isSendFailedEnvelope = record.type === "message" && record.event === "send_failed";
  if (!isSendFailedEnvelope && record.clientMsgId === undefined) return undefined;
  const clientMsgId = typeof record.clientMsgId === "string" ? record.clientMsgId.trim() : "";
  if (!clientMsgId) return undefined;
  return {
    clientMsgId,
    reason: typeof record.reason === "string"
      ? record.reason
      : typeof record.message === "string"
        ? record.message
        : "message.send failed",
  };
}

function requiredStringParam(source: Record<string, unknown>, key: string): string {
  const value = source[key];
  if (typeof value === "string" && value.trim()) return value;
  throw new Error(`${key} is required`);
}

function optionalStringParam(source: Record<string, unknown>, key: string): string | undefined {
  const value = source[key];
  return typeof value === "string" && value.trim() ? value : undefined;
}

function recordParam(source: Record<string, unknown>, key: string): Record<string, unknown> {
  const value = source[key];
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

function optionalRecordParam<T extends object>(source: Record<string, unknown>, key: string): T | undefined {
  const value = recordParam(source, key);
  return Object.keys(value).length ? value as T : undefined;
}

function requiredNumberParam(source: Record<string, unknown>, key: string): number {
  const value = Number(source[key]);
  if (Number.isFinite(value)) return value;
  throw new Error(`${key} is required`);
}

function stringListParam(source: Record<string, unknown>, key: string): string[] {
  const value = source[key];
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item).trim()).filter(Boolean);
}

function stringMapParam(source: Record<string, unknown>, key: string): Record<string, string> | undefined {
  const value = recordParam(source, key);
  const entries = Object.entries(value)
    .map(([entryKey, entryValue]) => [entryKey, String(entryValue ?? "").trim()] as const)
    .filter(([, entryValue]) => entryValue);
  return entries.length ? Object.fromEntries(entries) : undefined;
}

function messageContentParam(source: Record<string, unknown>, key: string): MessageContent {
  const value = source[key];
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${key} is required`);
  }
  const content = value as Partial<MessageContent>;
  if (!content.contentType || !Object.values(MessageContentType).includes(content.contentType as MessageContentType)) {
    throw new Error(`${key}.contentType is invalid`);
  }
  return {
    contentType: content.contentType as MessageContentType,
    data: recordParam(value as Record<string, unknown>, "data"),
  };
}

function contentTypeParam(source: Record<string, unknown>): MessageContentType {
  const raw = requiredStringParam(source, "contentType");
  if (!Object.values(MessageContentType).includes(raw as MessageContentType)) {
    throw new Error("contentType is invalid");
  }
  return raw as MessageContentType;
}

function devCoreTokenRequest(
  env: Record<string, string | undefined>,
  userId: string,
  tenantId: string,
) {
  const secret = env.VITE_FLARE_TOKEN_SECRET?.trim();
  if (!secret) {
    throw new Error("missing token secret: set VITE_FLARE_TOKEN_SECRET in the current Vite app .env.local");
  }
  return {
    userId,
    tenantId,
    secret,
    issuer: env.VITE_FLARE_TOKEN_ISSUER ?? devTokenDefaults.issuer,
    ttlSecs: Number(env.VITE_FLARE_TOKEN_TTL_SECS ?? devTokenDefaults.ttlSecs),
  };
}

export function desktopNotificationBodyForMessage(message: Message): string {
  switch (message.content?.contentType ?? messageContentTypeFromPreview(message.textPreview)) {
    case MessageContentType.Text:
      return translateFlare("notify.sent.text");
    case MessageContentType.Image:
      return translateFlare("notify.sent.image");
    case MessageContentType.ImageGroup:
      return translateFlare("notify.sent.imageGroup");
    case MessageContentType.Video:
      return translateFlare("notify.sent.video");
    case MessageContentType.Audio:
      return translateFlare("notify.sent.audio");
    case MessageContentType.File:
      return translateFlare("notify.sent.file");
    case MessageContentType.Sticker:
    case MessageContentType.Emoji:
      return translateFlare("notify.sent.emoji");
    case MessageContentType.Location:
      return translateFlare("notify.sent.location");
    case MessageContentType.Card:
      return translateFlare("notify.sent.card");
    case MessageContentType.Schedule:
      return translateFlare("notify.sent.schedule");
    case MessageContentType.Task:
      return translateFlare("notify.sent.task");
    case MessageContentType.Vote:
      return translateFlare("notify.sent.vote");
    case MessageContentType.Notification:
      return translateFlare("notify.sent.notification");
    case MessageContentType.Announcement:
      return translateFlare("notify.sent.announcement");
    case MessageContentType.RichText:
      return translateFlare("notify.sent.richText");
    case MessageContentType.LinkCard:
      return translateFlare("notify.sent.link");
    case MessageContentType.Forward:
      return translateFlare("notify.sent.forward");
    case MessageContentType.Thread:
      return translateFlare("notify.sent.thread");
    case MessageContentType.MiniProgram:
      return translateFlare("notify.sent.miniProgram");
    case MessageContentType.System:
      return translateFlare("notify.sent.system");
    case MessageContentType.Quote:
      return translateFlare("notify.sent.quote");
    default:
      return message.textPreview.trim() ? translateFlare("notify.sent.text") : translateFlare("notify.sent.generic");
  }
}

function messageContentTypeFromPreview(preview: string): MessageContentType | undefined {
  const key = storedPreviewKey(preview);
  switch (key) {
    case "im.preview.user_text":
      return MessageContentType.Text;
    case "im.preview.rich_text":
      return MessageContentType.RichText;
    case "im.preview.file":
      return MessageContentType.File;
    case "im.preview.image":
      return MessageContentType.Image;
    case "im.preview.video":
      return MessageContentType.Video;
    case "im.preview.audio":
      return MessageContentType.Audio;
    case "im.preview.location":
      return MessageContentType.Location;
    case "im.preview.card":
      return MessageContentType.Card;
    case "im.preview.sticker":
      return MessageContentType.Sticker;
    case "im.preview.emoji":
      return MessageContentType.Emoji;
    case "im.preview.quote":
      return MessageContentType.Quote;
    case "im.preview.link":
      return MessageContentType.LinkCard;
    case "im.preview.forward_empty":
    case "im.preview.forward_many":
      return MessageContentType.Forward;
    case "im.preview.thread":
      return MessageContentType.Thread;
    case "im.preview.mini_program":
      return MessageContentType.MiniProgram;
    case "im.preview.image_group":
      return MessageContentType.ImageGroup;
    case "im.preview.system":
      return MessageContentType.System;
    case "im.preview.notification":
      return MessageContentType.Notification;
    case "im.preview.vote":
      return MessageContentType.Vote;
    case "im.preview.task":
      return MessageContentType.Task;
    case "im.preview.schedule":
      return MessageContentType.Schedule;
    case "im.preview.announcement":
      return MessageContentType.Announcement;
    case "im.preview.custom":
      return MessageContentType.Custom;
    case "im.preview.placeholder":
      return MessageContentType.Placeholder;
    default:
      return undefined;
  }
}

function storedPreviewKey(preview: string): string {
  const trimmed = preview.trim();
  if (!trimmed.startsWith("{")) return "";
  try {
    const parsed = JSON.parse(trimmed) as unknown;
    if (!parsed || typeof parsed !== "object") return "";
    const key = (parsed as Record<string, unknown>).k;
    return typeof key === "string" ? key : "";
  } catch {
    return "";
  }
}

export function useFlareCoreClient(options: UseFlareCoreClientOptions) {
  const env = options.env ?? {};
  const defaultSdkRuntimeStatus = options.runtimeStatus ?? "browser-wasm";
  const appClient = options.createClient();
  const client = appClient;
  const form = reactive({
    ...makeFormDefaults(
      env,
      options.defaultHttpUrl ?? "",
      options.nativeTransportSelectionEnabled === true,
      options.defaultTlsCaCertPath ?? "",
    ),
  });
  const sdkLab = reactive({ ...sdkLabDefaults });
  const conversationFilters = reactive<ConversationFilterState>({
    filter: "all",
    includeArchived: false,
    conversationType: "",
  });

  const initialized = ref(false);
  const loggedIn = ref(false);
  const busy = ref(false);
  const connectionState = ref("disconnected");
  const currentUserId = ref("");
  const sessionActive = ref(false);
  const isConnected = ref(false);
  const homeSyncing = ref(false);
  const homeSyncReady = ref(false);
  const homeSyncError = ref("");
  const homeSyncProgress = ref<HomeSyncProgress>({
    step: "idle",
    title: translateFlare("sync.prepareTitle"),
    detail: translateFlare("sync.prepareDetail"),
    percent: 0,
  });
  const sdkRuntimeStatus = ref<SdkRuntimeStatus>(defaultSdkRuntimeStatus);
  const transportFallbackNotice = ref("");
  const activeConversationId = ref("");
  const conversations = ref<Conversation[]>([]);
  const messages = ref<Message[]>([]);
  const messageSearchResults = ref<Message[]>([]);
  const diagnostics = ref<Record<string, unknown>>({});
  const events = ref<RuntimeEventLogItem[]>([]);
  const conversationSyncing = ref(false);
  const conversationSyncError = ref("");
  const messageSyncing = ref(false);
  const messageOpening = ref(false);
  const messageSyncError = ref("");
  const labBusy = ref(false);
  const labResult = ref<Record<string, unknown>>({});
  const activeConversation = ref<Conversation>();

  // Receive-side typing indicator. The Rust core aggregates inbound per-user typing into
  // TypingAggregate events (with TTL + auto-expiry), so here we only mirror the latest live
  // set per conversation; no client-side timer needed.
  const typingUsersByConversation = ref<Map<string, string[]>>(new Map());
  const activeConversationTypingUsers = computed<string[]>(() => {
    const list = typingUsersByConversation.value.get(activeConversationId.value) ?? [];
    const self = currentUserId.value;
    return self ? list.filter((id) => id !== self) : list;
  });
  const typingAggregateSub = client.events.onTypingAggregateChanged((event) => {
    const next = new Map(typingUsersByConversation.value);
    const ids = event.typingUserIds ?? [];
    if (ids.length > 0) {
      next.set(event.conversationId, ids);
    } else {
      next.delete(event.conversationId);
    }
    typingUsersByConversation.value = next;
  });
  onBeforeUnmount(() => typingAggregateSub.unsubscribe());
  const peerPresence = ref<Record<string, string>>({});
  const totalUnread = ref(0);
  const activeLatestMessageId = ref("");
  const pinnedMessages = ref<Message[]>([]);
  const messageBuildCatalog = ref<MessageBuildCatalogEntry[]>([]);
  const messageHasMore = ref(true);
  const loadingOlderMessages = ref(false);
  const messageBuildOptions = computed(() => {
    return messageBuildCatalog.value.map((entry) => ({
      label: `${entry.method} · ${entry.contentType}${entry.stability === "stable" ? "" : ` · ${entry.stability}`}`,
      value: String(entry.op),
    }));
  });

  // WASM 运行时预热：app 挂载（登录屏渲染）即后台加载+实例化 3.2MB 运行时，
  // 用户输入账号期间完成下载/编译，登录点击不再背 wasm 冷加载。
  // sdk.version 是无会话直连操作；失败静默（登录路径会正常重试加载）。
  if (typeof window !== "undefined") {
    void Promise.resolve()
      .then(() => client.diagnostics.getSdkVersion())
      .catch(() => {});
  }

  let eventId = 1;
  let messageOpeningTimer: ReturnType<typeof setTimeout> | undefined;
  let generatedTokenOwner: { userId: string; tenantId: string; token: string } | undefined;
  // Dev tokens are short-lived JWTs (VITE_FLARE_TOKEN_TTL_SECS, default 3600s). Refresh a bit
  // before expiry so the core always reconnects with a valid token instead of looping forever
  // on AUTHENTICATION_FAILED with a stale one.
  const TOKEN_REFRESH_BUFFER_MS = 5 * 60 * 1000;
  let tokenRefreshTimer: ReturnType<typeof setTimeout> | undefined;
  function decodeJwtExpMs(token: string): number | undefined {
    const parts = token.split(".");
    if (parts.length < 2) return undefined;
    try {
      const payload = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/"))) as { exp?: number };
      return typeof payload.exp === "number" ? payload.exp * 1000 : undefined;
    } catch {
      return undefined;
    }
  }
  let pendingConversationSummarySync: Promise<void> | undefined;
  let conversationListViewId = "";
  let activeTimelineView: { conversationId: string; viewId: string } | null = null;
  let markReadTimer: ReturnType<typeof setTimeout> | undefined;
  let markReadInFlight: Promise<void> | undefined;
  let realtimeSafetyPollTimer: number | undefined;
  let realtimeSafetyPollInFlight = false;
  let realtimeSafetyPollFailureCount = 0;
  let realtimeSafetyPollNextAt = 0;
  let lastOutgoingSendAt = 0;
  let incomingConversationRefreshTimer: number | undefined;
  let activeConversationRefreshTimer: number | undefined;
  let incomingConversationRefreshInFlight = false;
  let activeOutgoingSends = 0;
  const activeTimelineAtBottom = ref(true);
  const lastMarkedReadSeqByConversation = new Map<string, number>();
  const initialHistoryRepairTried = new Set<string>();

  function messageMatchesId(message: Message, id: string): boolean {
    return Boolean(id && (message.serverId === id || message.clientMsgId === id));
  }

  function isPinnedMessage(message: Message): boolean {
    return message.attributes?.pinned === "true";
  }

  function currentSnapshotReadSeq(conversationId: string): number {
    const conversationSeq = conversations.value.find((item) => item.conversationId === conversationId)?.maxSeq ?? 0;
    const messageSeq = messages.value
      .filter((message) => message.conversationId === conversationId)
      .reduce((max, message) => Math.max(max, Number(message.conversationSeq) || 0), 0);
    return Math.max(conversationSeq, messageSeq);
  }

  async function listConversations(options: {
    query?: string;
    includeArchived?: boolean;
    offset?: number;
    limit?: number;
  } = {}): Promise<readonly Conversation[]> {
    if (options.query) {
      const response = await client.conversations.listConversationsByQuery({
        keyword: options.query,
        includeArchived: options.includeArchived ?? false,
        unreadOnly: false,
        mentionMeOnly: false,
        pinnedOnly: false,
        hasDraftOnly: false,
        hasMarkedMessages: false,
        conversationTypes: [],
        limit: options.limit,
      });
      return response.conversations;
    }
    if (options.offset !== undefined || options.limit !== undefined) {
      const response = await client.conversations.listConversationsPaginated({
        offset: options.offset ?? 0,
        limit: options.limit ?? 50,
        includeArchived: options.includeArchived ?? false,
      });
      return response.conversations;
    }
    const response = options.includeArchived
      ? await client.conversations.listConversationsIncludingArchived()
      : await client.conversations.listConversations();
    return response.conversations;
  }

  async function bootstrapHome(conversationLimit = 100) {
    return await client.conversations.bootstrapHomeTimeline({ conversationLimit });
  }

  async function loadHomeConversations(conversationLimit = 100): Promise<Conversation[]> {
    try {
      const homeSnapshot = await withTimeout(
        Promise.resolve().then(() => bootstrapHome(conversationLimit)),
        HOME_CONVERSATION_LOAD_TIMEOUT_MS,
        () => sdkOperationTimeoutError("conversation.bootstrap_home", HOME_CONVERSATION_LOAD_TIMEOUT_MS),
      );
      return [...homeSnapshot.conversations];
    } catch (error) {
      log("home_bootstrap_degraded", errorMessage(error));
    }
    try {
      const fallbackConversations = await withTimeout(
        Promise.resolve().then(() => listConversations({ limit: conversationLimit })),
        HOME_CONVERSATION_LOAD_TIMEOUT_MS,
        () => sdkOperationTimeoutError("conversation.list", HOME_CONVERSATION_LOAD_TIMEOUT_MS),
      );
      return [...fallbackConversations];
    } catch (error) {
      log("home_conversations_degraded", errorMessage(error));
      return [...conversations.value];
    }
  }

  async function openPeerConversationRaw(peerUserId: string): Promise<Conversation> {
    return await client.conversations.getOneConversation({
      sourceId: peerUserId,
      conversationType: "single",
    });
  }

  async function openGroupConversationRaw(userIds: readonly string[]): Promise<Conversation> {
    return await client.conversations.getGroupConversationByUserIds({
      userIds: [...userIds],
    });
  }

  function parseGroupMemberIds(raw: string): string[] {
    const ids = raw
      .split(/[\s,，、;；|]+/)
      .map((id) => id.trim())
      .filter((id) => id.length > 0);
    const current = currentUserId.value.trim();
    if (current) {
      ids.unshift(current);
    }
    return [...new Set(ids)];
  }

  async function listMessages(request: {
    conversationId: string;
    beforeSeq?: number;
    limit?: number;
  }): Promise<readonly Message[]> {
    const response = await client.messages.listMessages({
      conversationId: request.conversationId,
      beforeSeq: request.beforeSeq ?? 0,
      limit: request.limit ?? MESSAGE_PAGE_SIZE,
    });
    return response.messages;
  }

  async function sendMessageWithTimeout(
    message: Message,
    callback?: MessageSendCallback,
  ): Promise<SendMessageResponse> {
    return await new Promise<SendMessageResponse>((resolve, reject) => {
      let settled = false;
      let timeout: ReturnType<typeof setTimeout> | undefined;
      let subscription: { unsubscribe(): void } | undefined;

      const cleanup = () => {
        if (timeout) {
          clearTimeout(timeout);
          timeout = undefined;
        }
        subscription?.unsubscribe();
        subscription = undefined;
      };

      const fail = (error: Error, details: Record<string, unknown> = {}) => {
        if (settled) return;
        settled = true;
        cleanup();
        callback?.onFailure?.({
          clientMsgId: message.clientMsgId,
          reason: error.message,
          error: {
            code: (error as Error & { code?: string }).code ?? "send_failed",
            message: error.message,
            operation: "message.send",
            details: stringDetails(details),
          },
        });
        reject(error);
      };

      const succeed = (ack: SendMessageResponse) => {
        if (settled) return;
        settled = true;
        cleanup();
        callback?.onSuccess?.({ ack });
        resolve(ack);
      };

      subscription = client.events.addEventListener(((event: unknown) => {
        const ack = sendAckFromEvent(event);
        if (ack && sendAckMatches(ack, message)) {
          if (isFinalSendAck(ack)) {
            succeed(ack);
          } else if (!isQueuedSendAck(ack)) {
            fail(sendAckFailureError(ack), sendAckDetails(ack));
          }
          return;
        }
        const failure = sendFailureFromEvent(event);
        if (failure?.clientMsgId === message.clientMsgId) {
          fail(new Error(failure.reason), failure);
        }
      }) as never);

      timeout = setTimeout(() => {
        fail(sendTimeoutError(DEFAULT_SEND_TIMEOUT_MS));
      }, DEFAULT_SEND_TIMEOUT_MS);

      void client.messages.sendMessage({ message })
        .then((ack) => {
          if (settled) return;
          if (isFinalSendAck(ack)) {
            succeed(ack);
          } else if (!isQueuedSendAck(ack)) {
            fail(sendAckFailureError(ack), sendAckDetails(ack));
          }
        })
        .catch((error: unknown) => {
          const normalized = error instanceof Error ? error : new Error(String(error));
          fail(normalized);
        });
    });
  }

  async function buildTypedMessage(request: BuildAndSendMessageRequest): Promise<Message> {
    const params = request.params ?? {};
    const op = String(request.op);
    switch (op) {
      case MessageBuildOp.CreateText:
        return client.messageBuilder.buildText({
          conversationId: request.conversationId,
          text: requiredStringParam(params, "text"),
          mentionUsers: stringListParam(params, "mentionUsers"),
        });
      case MessageBuildOp.CreateEmoji:
        return client.messageBuilder.buildEmoji({
          conversationId: request.conversationId,
          emoji: requiredStringParam(params, "emoji"),
        });
      case MessageBuildOp.CreateSticker:
        return client.messageBuilder.buildSticker({
          conversationId: request.conversationId,
          stickerId: requiredStringParam(params, "stickerId"),
          packageId: optionalStringParam(params, "packageId"),
        });
      case MessageBuildOp.CreateImage:
        return client.messageBuilder.buildImage({
          conversationId: request.conversationId,
          imageId: requiredStringParam(params, "imageId"),
          payload: optionalRecordParam<ImageContentPayload>(params, "payload"),
        });
      case MessageBuildOp.CreateImageGroup:
        {
          const payload = recordParam(params, "payload") as Partial<ImageGroupContentPayload>;
          if (!Array.isArray(payload.images) || payload.images.length === 0) {
            throw new Error("payload.images is required");
          }
          return client.messageBuilder.buildImageGroup({
            conversationId: request.conversationId,
            payload: payload as ImageGroupContentPayload,
          });
        }
      case MessageBuildOp.CreateVideo:
        return client.messageBuilder.buildVideo({
          conversationId: request.conversationId,
          videoId: requiredStringParam(params, "videoId"),
          payload: optionalRecordParam<VideoContentPayload>(params, "payload"),
        });
      case MessageBuildOp.CreateAudio:
        return client.messageBuilder.buildAudio({
          conversationId: request.conversationId,
          audioId: requiredStringParam(params, "audioId"),
          payload: optionalRecordParam<AudioContentPayload>(params, "payload"),
        });
      case MessageBuildOp.CreateFile:
        return client.messageBuilder.buildFile({
          conversationId: request.conversationId,
          fileId: requiredStringParam(params, "fileId"),
          payload: optionalRecordParam<FileContentPayload>(params, "payload"),
        });
      case MessageBuildOp.CreateLocation:
        return client.messageBuilder.buildLocation({
          conversationId: request.conversationId,
          latitude: requiredNumberParam(params, "latitude"),
          longitude: requiredNumberParam(params, "longitude"),
          title: optionalStringParam(params, "title"),
          address: optionalStringParam(params, "address"),
        });
      case MessageBuildOp.CreateLinkCard:
        return client.messageBuilder.buildLinkCard({
          conversationId: request.conversationId,
          url: requiredStringParam(params, "url"),
          title: optionalStringParam(params, "title"),
          description: optionalStringParam(params, "description"),
          thumbnailUrl: optionalStringParam(params, "thumbnailUrl"),
          siteName: optionalStringParam(params, "siteName"),
        });
      case MessageBuildOp.CreateCard:
        return client.messageBuilder.buildCard({
          conversationId: request.conversationId,
          id: requiredStringParam(params, "id"),
          cardType: optionalStringParam(params, "cardType"),
          title: optionalStringParam(params, "title"),
          subtitle: optionalStringParam(params, "subtitle"),
          avatar: optionalStringParam(params, "avatar"),
        });
      case MessageBuildOp.CreateMiniProgram:
        return client.messageBuilder.buildMiniProgram({
          conversationId: request.conversationId,
          appId: requiredStringParam(params, "appId"),
          pagePath: optionalStringParam(params, "pagePath"),
          title: optionalStringParam(params, "title"),
          thumbnailUrl: optionalStringParam(params, "thumbnailUrl"),
          extra: stringMapParam(params, "extra"),
        });
      case MessageBuildOp.CreateRichDoc:
        {
          const markdownSource = optionalStringParam(params, "markdown");
          const docJsonSource = optionalStringParam(params, "docJson");
          const htmlSource = optionalStringParam(params, "html");
          const normalized = docJsonSource
            ? await client.messageBuilder.normalizeRichDocFromDocJson({
              docJson: docJsonSource,
            })
            : htmlSource
              ? await client.messageBuilder.normalizeRichDocFromHtml({
                html: htmlSource,
              })
              : await client.messageBuilder.normalizeRichDocFromMarkdown({
                markdown: markdownSource ?? requiredStringParam(params, "markdown"),
              });
          const sourcePayloadBase = normalized.sourcePayload
            ? Object.fromEntries(
              Object.entries(normalized.sourcePayload)
                .map(([entryKey, entryValue]) => [entryKey, String(entryValue ?? "")] as const),
            )
            : {};
          const sourcePayload = markdownSource
            ? { ...sourcePayloadBase, markdown: markdownSource }
            : Object.keys(sourcePayloadBase).length
              ? sourcePayloadBase
              : undefined;
          return client.messageBuilder.buildRichDoc({
            conversationId: request.conversationId,
            docJson: normalized.docJson,
            contentSchema: normalized.contentSchema,
            plainText: normalized.plainText,
            inputFormat: normalized.inputFormat,
            sourcePayload,
            title: optionalStringParam(params, "title"),
            searchText: normalized.searchText,
            renderHintsJson: JSON.stringify(normalized.renderHints),
          });
        }
      case MessageBuildOp.CreateQuote:
        return client.messageBuilder.buildQuote({
          conversationId: request.conversationId,
          quotedMessageId: requiredStringParam(params, "quotedMessageId"),
          text: requiredStringParam(params, "text"),
          quotedSenderId: optionalStringParam(params, "quotedSenderId"),
          quotedTextPreview: optionalStringParam(params, "quotedTextPreview"),
          quotedContent: messageContentParam(params, "quotedContent"),
        });
      case MessageBuildOp.CreateThreadReply:
        return client.messageBuilder.buildThreadReply({
          conversationId: request.conversationId,
          threadId: requiredStringParam(params, "threadId"),
          text: requiredStringParam(params, "text"),
        });
      case MessageBuildOp.CreateSystem:
        return client.messageBuilder.buildSystem({
          conversationId: request.conversationId,
          eventKind: requiredStringParam(params, "eventKind"),
          body: requiredStringParam(params, "body"),
        });
      case MessageBuildOp.CreateNotification:
        return client.messageBuilder.buildNotification({
          conversationId: request.conversationId,
          title: requiredStringParam(params, "title"),
          body: requiredStringParam(params, "body"),
        });
      case MessageBuildOp.CreateVote:
        return client.messageBuilder.buildVote({
          conversationId: request.conversationId,
          voteId: requiredStringParam(params, "voteId"),
          title: requiredStringParam(params, "title"),
          options: stringListParam(params, "options"),
          participantUserIds: stringListParam(params, "participantUserIds"),
        });
      case MessageBuildOp.CreateTask:
        return client.messageBuilder.buildTask({
          conversationId: request.conversationId,
          taskId: requiredStringParam(params, "taskId"),
          title: requiredStringParam(params, "title"),
          status: optionalStringParam(params, "status"),
          participantUserIds: stringListParam(params, "participantUserIds"),
        });
      case MessageBuildOp.CreateSchedule:
        return client.messageBuilder.buildSchedule({
          conversationId: request.conversationId,
          scheduleId: requiredStringParam(params, "scheduleId"),
          title: requiredStringParam(params, "title"),
          startTimeMs: requiredNumberParam(params, "startTimeMs"),
          endTimeMs: requiredNumberParam(params, "endTimeMs"),
          participantUserIds: stringListParam(params, "participantUserIds"),
        });
      case MessageBuildOp.CreateAnnouncement:
        return client.messageBuilder.buildAnnouncement({
          conversationId: request.conversationId,
          title: requiredStringParam(params, "title"),
          body: requiredStringParam(params, "body"),
        });
      case MessageBuildOp.CreateCustom:
        return client.messageBuilder.buildCustom({
          conversationId: request.conversationId,
          type: requiredStringParam(params, "type"),
        });
      case MessageBuildOp.CreatePlaceholder:
        return client.messageBuilder.buildPlaceholder({
          conversationId: request.conversationId,
          reason: requiredStringParam(params, "reason"),
        });
      case MessageBuildOp.CreateWithContent:
        return client.messageBuilder.buildWithContent({
          conversationId: request.conversationId,
          content: {
            contentType: contentTypeParam(params),
            data: recordParam(params, "data"),
          },
        });
      default:
        throw new FlareSdkException(
          "invalidParameter",
          `unsupported message builder op: ${op}`,
          "message_builder.build",
          { op },
        );
    }
  }

  async function searchMessages(request: {
    conversationId?: string;
    keyword: string;
    kinds?: readonly MessageSearchKind[];
    limit?: number;
    includeRecalled?: boolean;
  }): Promise<readonly Message[]> {
    const query = {
      conversationId: request.conversationId,
      keyword: request.keyword,
      kinds: request.kinds ? [...request.kinds] : [],
      limit: request.limit ?? 50,
      includeRecalled: request.includeRecalled ?? false,
    };
    const response = request.conversationId
      ? await client.messages.searchMessagesInConversation(query)
      : await client.messages.searchMessagesByQuery(query);
    return response.messages;
  }

  async function dispatchMessage(op: string, params: Record<string, unknown>): Promise<Record<string, unknown>> {
    return await client.messages.dispatchMessage({ op, params }) as Record<string, unknown>;
  }

  async function refreshCoreDiagnostics(): Promise<CoreDiagnosticsSnapshot> {
    const [
      sdkVersion,
      ffiContract,
      dataRoot,
      runtimeHealth,
      currentUser,
      active,
      connected,
      state,
    ] = await Promise.all([
      client.diagnostics.getSdkVersion(),
      client.diagnostics.getFfiContractVersion(),
      client.diagnostics.getDataRoot(),
      client.diagnostics.getRuntimeHealth(),
      client.currentUserId(),
      client.sessionActive(),
      client.isConnected(),
      client.connection.getConnectionState(),
    ]);
    return {
      sdkVersion: sdkVersion as Record<string, unknown>,
      ffiContract: ffiContract as Record<string, unknown>,
      dataRoot: dataRoot as Record<string, unknown>,
      runtimeHealth: runtimeHealth as unknown as Record<string, unknown>,
      currentUser,
      sessionActive: active,
      isConnected: connected,
      connectionState: state,
    };
  }

  async function refreshCoreMessageBuildCatalog(): Promise<readonly MessageBuildCatalogEntry[]> {
    const response = await client.messageBuilder.listSupportedBuildOperations();
    return response.entries;
  }

  async function resetCoreSessionForLogin(): Promise<void> {
    await withTimeout(
      closeOpenViews("login_reset"),
      LOGIN_SESSION_RESET_TIMEOUT_MS,
      () => sdkOperationTimeoutError("login.reset_views", LOGIN_SESSION_RESET_TIMEOUT_MS),
    ).catch((error) => {
      log("login_reset_views_failed", errorMessage(error));
    });
    const logout = (client as FlareImClient & { logout?: () => Promise<void> }).logout;
    if (!logout) {
      log("login_logout_previous_skipped", "unsupported");
      return;
    }
    const hasActiveSession = loggedIn.value || sessionActive.value || await withTimeout(
      client.sessionActive(),
      LOGIN_SESSION_RESET_TIMEOUT_MS,
      () => sdkOperationTimeoutError("login.session_active_probe", LOGIN_SESSION_RESET_TIMEOUT_MS),
    ).catch((error) => {
      log("login_session_active_probe_failed", errorMessage(error));
      return false;
    });
    if (!hasActiveSession) {
      log("login_logout_previous_skipped", "inactive");
      return;
    }
    await withTimeout(
      Promise.resolve().then(() => logout.call(client)),
      LOGIN_SESSION_RESET_TIMEOUT_MS,
      () => sdkOperationTimeoutError("login.logout_previous", LOGIN_SESSION_RESET_TIMEOUT_MS),
    ).catch((error) => {
      log("login_logout_previous_failed", errorMessage(error));
    });
  }

  async function initAndLoginCore(request: {
    transportMode: LoginTransportMode;
    wsUrl: string;
    quicUrl: string;
    tlsCaCertPath: string;
    dataUrl: string;
    tenantId: string;
    userId: string;
    token: string;
    httpUrl: string;
  }): Promise<{ session: CoreSessionSnapshot; diagnostics: CoreDiagnosticsSnapshot; messageBuildCatalog: readonly MessageBuildCatalogEntry[] }> {
    const token = request.token.trim();
    if (!token) {
      throw new Error("token is required for initAndLogin");
    }
    const mediaProxy = sdkMediaProxyFields();
    await resetCoreSessionForLogin();
    await withTimeout(
      client.init({
        ...buildLoginTransportConfig(request),
        dataUrl: request.dataUrl,
        tenantId: request.tenantId,
        httpUrl: request.httpUrl,
        mediaStorageProxyPrefix: mediaProxy.storageProxyPrefix,
        mediaStorageProxyTargets: mediaProxy.storageProxyTargets,
      }),
      CORE_LOGIN_STEP_TIMEOUT_MS,
      () => sdkOperationTimeoutError("login.init", CORE_LOGIN_STEP_TIMEOUT_MS),
    );
    await withTimeout(
      client.events.subscribeEvents({ sources: [...sdkEventSources] }),
      CORE_LOGIN_STEP_TIMEOUT_MS,
      () => sdkOperationTimeoutError("login.subscribe_events", CORE_LOGIN_STEP_TIMEOUT_MS),
    );
    await withTimeout(
      client.login({ userId: request.userId, token }),
      CORE_LOGIN_TIMEOUT_MS,
      () => sdkOperationTimeoutError("login.core", CORE_LOGIN_TIMEOUT_MS),
    );
    const [state, catalog, coreDiagnostics] = await withTimeout(
      Promise.all([
        client.connection.getConnectionState(),
        refreshCoreMessageBuildCatalog(),
        refreshCoreDiagnostics(),
      ]),
      CORE_LOGIN_STEP_TIMEOUT_MS,
      () => sdkOperationTimeoutError("login.diagnostics", CORE_LOGIN_STEP_TIMEOUT_MS),
    );
    return {
      session: {
        initialized: true,
        loggedIn: true,
        userId: request.userId,
        connectionState: state,
      },
      diagnostics: coreDiagnostics,
      messageBuildCatalog: catalog,
    };
  }

  function canApplyConversationListView(): boolean {
    return conversationFilters.filter === "all"
      && !conversationFilters.includeArchived
      && !conversationFilters.conversationType;
  }

  function applyConversationListViewSnapshot(snapshot: {
    conversations: readonly Conversation[];
    totalUnread?: number;
  }): void {
    if (!canApplyConversationListView()) return;
    const authoritative = snapshot.conversations
      .filter((item) => item.conversationId.trim())
      .map((item) => ({ ...item }));
    conversations.value = authoritative;
    ensureActiveConversationSelection();
    refreshDerivedState();
    if (snapshot.totalUnread !== undefined) {
      totalUnread.value = Math.max(0, Number(snapshot.totalUnread) || 0);
    }
  }

  function applyTimelineViewSnapshot(viewId: string, snapshot: {
    conversation?: Conversation;
    messages: readonly Message[];
    hasMore?: boolean;
  }): void {
    const activeView = activeTimelineView;
    if (!activeView || viewId !== activeView.viewId) return;
    const conversationId = (
      snapshot.conversation?.conversationId
      ?? snapshot.messages.find((message) => message.conversationId?.trim())?.conversationId
      ?? ""
    ).trim();
    const targetId = activeView.conversationId;
    if (conversationId && conversationId !== targetId) return;
    if (targetId !== activeConversationId.value.trim()) return;

    messages.value = [...snapshot.messages];
    messageHasMore.value = Boolean(snapshot.hasMore);
    refreshDerivedState();
    scheduleVisibleMarkRead("timeline_snapshot");
  }

  function applyViewSnapshot(viewId: string, snapshot: ViewUpdate["snapshot"]): void {
    if (!snapshot) return;
    if (snapshot.viewType === "conversationList") {
      if (viewId !== conversationListViewId) return;
      applyConversationListViewSnapshot(snapshot.data);
      return;
    }
    if (snapshot.viewType === "timeline") {
      applyTimelineViewSnapshot(viewId, snapshot.data);
    }
  }

  function boundedDeltaIndex(index: number, length: number): number {
    if (!Number.isFinite(index)) return length;
    return Math.max(0, Math.min(Math.trunc(index), length));
  }

  function applyIndexedDeltaOps<T>(
    current: readonly T[],
    ops: readonly ViewDeltaOperation[],
    keyOf: (item: T) => string,
    decodeItem: (op: ViewDeltaOperation) => T | undefined,
    /**
     * 行 key 在消息生命周期中会**变形**：核心的 `timeline_key()` 在
     * server_id 为空时给 `client:<id>`，一旦有了 server_id 就变成 `server:<id>`
     * （发送队列的乐观消息还会先把 server_id 置成 client_msg_id）。
     *
     * 于是同一条消息在不同阶段的 key 不同，按 key 找不到行时 update op 会被
     * **整个丢弃**——线上表现就是媒体上传期间核心已置 uploading:true，
     * 而界面上那一行始终停在旧状态、进度条永远不出现。
     *
     * 给一个稳定身份（消息用 clientMsgId）做兜底匹配。
     */
    identityOf?: (item: T) => string,
    identityOfOp?: (op: ViewDeltaOperation) => string,
  ): T[] {
    const next = [...current];
    const indexByKey = (key: string, op?: ViewDeltaOperation) => {
      const byKey = next.findIndex((item) => keyOf(item) === key);
      if (byKey >= 0 || !identityOf || !identityOfOp || !op) return byKey;
      const identity = identityOfOp(op).trim();
      if (!identity) return -1;
      return next.findIndex((item) => identityOf(item).trim() === identity);
    };
    for (const op of ops) {
      const key = op.key.trim();
      if (!key) continue;
      if (op.op === "remove") {
        const existingIndex = indexByKey(key, op);
        if (existingIndex >= 0) next.splice(existingIndex, 1);
        continue;
      }
      if (op.op === "move") {
        const existingIndex = indexByKey(key, op);
        if (existingIndex < 0) continue;
        const [item] = next.splice(existingIndex, 1);
        next.splice(boundedDeltaIndex(op.index, next.length), 0, item);
        continue;
      }
      const item = decodeItem(op);
      if (!item) continue;
      const existingIndex = indexByKey(key, op);
      if (op.op === "insert") {
        if (existingIndex >= 0) next.splice(existingIndex, 1);
        next.splice(boundedDeltaIndex(op.index, next.length), 0, item);
        continue;
      }
      if (op.op === "update" && existingIndex >= 0) {
        next[existingIndex] = item;
      }
    }
    return next;
  }

  function decodeConversationDeltaItem(op: ViewDeltaOperation): Conversation | undefined {
    if (!op.item) return undefined;
    const item = conversationFromJson(op.item);
    return item.conversationId.trim() === op.key.trim() ? { ...item } : undefined;
  }

  function decodeMessageDeltaItem(op: ViewDeltaOperation, conversationId: string): Message | undefined {
    if (!op.item) return undefined;
    const item = messageFromJson(op.item);
    return item.timelineKey.trim() === op.key.trim() && item.conversationId.trim() === conversationId
      ? { ...item }
      : undefined;
  }

  function applyConversationListViewDelta(viewId: string, delta: ViewDeltaPayload): void {
    if (viewId !== conversationListViewId || delta.viewType !== "conversationList") return;
    if (!canApplyConversationListView()) return;
    conversations.value = applyIndexedDeltaOps(
      conversations.value,
      delta.ops,
      (item) => item.conversationId.trim(),
      decodeConversationDeltaItem,
    );
    ensureActiveConversationSelection();
    refreshDerivedState();
    if (delta.totalUnread !== undefined) {
      totalUnread.value = Math.max(0, Number(delta.totalUnread) || 0);
    }
  }

  function applyTimelineViewDelta(viewId: string, delta: ViewDeltaPayload): void {
    const activeView = activeTimelineView;
    if (!activeView || viewId !== activeView.viewId || delta.viewType !== "timeline") return;
    const targetId = activeView.conversationId;
    if (targetId !== activeConversationId.value.trim()) return;
    const deltaConversationId = delta.conversation?.conversationId.trim() ?? "";
    if (deltaConversationId && deltaConversationId !== targetId) return;
    messages.value = applyIndexedDeltaOps(
      messages.value,
      delta.ops,
      (item) => item.timelineKey.trim(),
      (op) => decodeMessageDeltaItem(op, targetId),
      (item) => item.clientMsgId,
      (op) => {
        const decoded = op.item ? messageFromJson(op.item) : undefined;
        return decoded?.clientMsgId ?? "";
      },
    );
    if (delta.hasMore !== undefined) {
      messageHasMore.value = Boolean(delta.hasMore);
    }
    refreshDerivedState();
    scheduleVisibleMarkRead("timeline_delta");
  }

  function applyViewDelta(viewId: string, delta: ViewUpdate["delta"]): void {
    if (!delta) return;
    if (delta.viewType === "conversationList") {
      applyConversationListViewDelta(viewId, delta);
      return;
    }
    if (delta.viewType === "timeline") {
      applyTimelineViewDelta(viewId, delta);
    }
  }

  function handleViewUpdate(update: ViewUpdate): void {
    if (update.kind === "delta") {
      applyViewDelta(update.viewId, update.delta);
      return;
    }
    applyViewSnapshot(update.viewId, update.snapshot);
  }

  async function openConversationListView(reason: string): Promise<void> {
    if (conversationListViewId || !canApplyConversationListView()) return;
    try {
      const response = await withTimeout(
        Promise.resolve().then(() => client.views.openConversationList({ conversationLimit: 100 })),
        CONVERSATION_LIST_VIEW_OPEN_TIMEOUT_MS,
        () => sdkOperationTimeoutError("view.conversation_list.open", CONVERSATION_LIST_VIEW_OPEN_TIMEOUT_MS),
      );
      conversationListViewId = response.viewId;
      applyViewSnapshot(response.viewId, response.snapshot);
      log("view_conversations_open", `${reason}:${conversationListViewId}`);
    } catch (error) {
      log("view_conversations_open_failed", `${reason}: ${errorMessage(error)}`);
    }
  }

  async function openTimelineView(conversationId: string, reason: string, options: { force?: boolean } = {}): Promise<void> {
    const targetId = conversationId.trim();
    if (!targetId) return;
    if (activeTimelineView?.conversationId === targetId && !options.force) return;
    const replacingDifferentConversation = Boolean(
      activeTimelineView?.conversationId && activeTimelineView.conversationId !== targetId,
    );
    await closeActiveTimelineView(`replace:${reason}`);
    if (replacingDifferentConversation && activeConversationId.value.trim() === targetId) {
      messages.value = [];
      pinnedMessages.value = [];
      messageHasMore.value = true;
      refreshDerivedState();
    }
    try {
      const response = await withTimeout(
        client.views.openTimeline({
          conversationId: targetId,
          messageLimit: MESSAGE_PAGE_SIZE,
        }),
        TIMELINE_OPEN_TIMEOUT_MS,
        () => sdkOperationTimeoutError("view.timeline.open", TIMELINE_OPEN_TIMEOUT_MS),
      );
      activeTimelineView = { conversationId: targetId, viewId: response.viewId };
      applyViewSnapshot(response.viewId, response.snapshot);
      log("view_timeline_open", `${reason}:${targetId}:${response.viewId}`);
    } catch (error) {
      log("view_timeline_open_failed", `${reason}:${targetId}: ${errorMessage(error)}`);
      throw error;
    }
  }

  function activeTimelineSeqStats(conversationId: string): { count: number; minSeq: number } {
    const targetId = conversationId.trim();
    if (!targetId) return { count: 0, minSeq: Number.POSITIVE_INFINITY };
    const activeMessages = messages.value.filter((message) => message.conversationId === targetId);
    const minSeq = activeMessages.reduce((min, message) => {
      const seq = Number(message.conversationSeq) || 0;
      return seq > 0 ? Math.min(min, seq) : min;
    }, Number.POSITIVE_INFINITY);
    return { count: activeMessages.length, minSeq };
  }

  function shouldRepairInitialTimelineHistory(conversationId: string): boolean {
    const targetId = conversationId.trim();
    if (!targetId || initialHistoryRepairTried.has(targetId)) return false;
    const stats = activeTimelineSeqStats(targetId);
    if (stats.count === 0) return false;
    return Number.isFinite(stats.minSeq) && stats.minSeq > 1;
  }

  async function repairInitialTimelineHistoryIfNeeded(conversationId: string, reason: string): Promise<void> {
    const targetId = conversationId.trim();
    if (!shouldRepairInitialTimelineHistory(targetId)) return;
    initialHistoryRepairTried.add(targetId);
    try {
      let repairedPages = 0;
      for (let page = 0; page < INITIAL_HISTORY_REPAIR_MAX_PAGES; page += 1) {
        const before = activeTimelineSeqStats(targetId);
        if (!Number.isFinite(before.minSeq) || before.minSeq <= 1) break;
        await loadOlderMessages({ force: true, limit: INITIAL_HISTORY_REPAIR_SYNC_LIMIT });
        const after = activeTimelineSeqStats(targetId);
        if (after.count <= before.count && after.minSeq >= before.minSeq) break;
        repairedPages += 1;
        if (!messageHasMore.value) break;
      }
      if (repairedPages > 0) {
        const stats = activeTimelineSeqStats(targetId);
        log("view_timeline_history_repair", `${targetId}:min_seq_gap:${repairedPages}:${stats.count}`);
      }
    } catch (error) {
      log("view_timeline_history_repair_failed", `${targetId}: ${errorMessage(error)}`);
    }
  }

  async function closeActiveTimelineView(reason: string): Promise<void> {
    const current = activeTimelineView;
    if (!current) return;
    activeTimelineView = null;
    try {
      await client.views.close({ viewId: current.viewId });
      log("view_timeline_close", `${reason}:${current.conversationId}:${current.viewId}`);
    } catch (error) {
      log("view_timeline_close_failed", `${reason}:${current.conversationId}: ${errorMessage(error)}`);
    }
  }

  async function closeConversationListView(reason: string): Promise<void> {
    const viewId = conversationListViewId;
    if (!viewId) return;
    conversationListViewId = "";
    try {
      await client.views.close({ viewId });
      log("view_conversations_close", `${reason}:${viewId}`);
    } catch (error) {
      log("view_conversations_close_failed", `${reason}:${viewId}: ${errorMessage(error)}`);
    }
  }

  async function unsubscribeAllEvents(reason: string): Promise<void> {
    try {
      await client.events.unsubscribeAll();
      log("events_unsubscribe_all", reason);
    } catch (error) {
      log("events_unsubscribe_all_failed", `${reason}: ${errorMessage(error)}`);
    }
  }

  async function closeOpenViews(reason: string): Promise<void> {
    await closeActiveTimelineView(reason);
    await closeConversationListView(reason);
  }

  async function disposeOpenViewsAndEvents(reason: string): Promise<void> {
    await closeOpenViews(reason);
    await unsubscribeAllEvents(reason);
  }

  function ensureActiveConversationSelection(): void {
    const current = activeConversationId.value.trim();
    if (!current) {
      return;
    }
    if (!conversations.value.some((item) => item.conversationId === current)) {
      activeConversationId.value = "";
    }
  }

  async function markConversationRead(conversationId: string): Promise<number> {
    const targetId = conversationId.trim();
    if (!targetId) return 0;
    const readSeq = currentSnapshotReadSeq(targetId);
    if (readSeq <= 0) return 0;
    await client.conversations.markConversationRead({ conversationId: targetId, readSeq });
    return readSeq;
  }

  function patchConversationReadState(conversationId: string, readSeq: number): void {
    let changed = false;
    conversations.value = conversations.value.map((item) => {
      if (item.conversationId !== conversationId) return item;
      changed = true;
      return {
        ...item,
        unreadCount: 0,
        lastReadSeq: Math.max(Number(item.lastReadSeq) || 0, readSeq),
      };
    });
    if (changed) {
      refreshDerivedState();
    }
  }

  function setActiveTimelineAtBottom(atBottom: boolean): void {
    activeTimelineAtBottom.value = atBottom;
    if (atBottom) {
      scheduleVisibleMarkRead("bottom_visible");
    }
  }

  function scheduleVisibleMarkRead(reason: string): void {
    if (!activeTimelineAtBottom.value || !activeConversationId.value.trim()) return;
    if (markReadTimer) clearTimeout(markReadTimer);
    markReadTimer = setTimeout(() => {
      markReadTimer = undefined;
      void markActiveConversationVisibleRead(reason);
    }, 80);
  }

  async function markActiveConversationVisibleRead(reason: string): Promise<void> {
    if (markReadInFlight) {
      await markReadInFlight;
    }
    if (!activeTimelineAtBottom.value) return;
    const conversationId = activeConversationId.value.trim();
    if (!conversationId) return;
    const readSeq = currentSnapshotReadSeq(conversationId);
    if (readSeq <= 0) return;
    if ((lastMarkedReadSeqByConversation.get(conversationId) ?? 0) >= readSeq) return;
    markReadInFlight = (async () => {
      const appliedSeq = await markConversationRead(conversationId);
      lastMarkedReadSeqByConversation.set(conversationId, appliedSeq);
      patchConversationReadState(conversationId, appliedSeq);
      log("mark_read_visible", `${reason}:${conversationId}:${appliedSeq}`);
    })().catch((error) => {
      log("mark_read_visible_failed", `${reason}: ${errorMessage(error)}`);
    }).finally(() => {
      markReadInFlight = undefined;
    });
    await markReadInFlight;
  }

  async function enterActiveConversation(reason: string): Promise<void> {
    const conversationId = activeConversationId.value.trim();
    if (!conversationId) return;
    beginMessageOpening();
    messageSyncing.value = true;
    messageSyncError.value = "";
    try {
      await openTimelineView(conversationId, reason);
      void repairInitialTimelineHistoryIfNeeded(conversationId, reason);
    } catch (error) {
      messageSyncError.value = errorMessage(error);
      log("message_open_failed", `${reason}:${conversationId}: ${messageSyncError.value}`);
    } finally {
      finishMessageOpening(conversationId);
      messageSyncing.value = false;
    }
    await markConversationRead(conversationId).catch((error) => {
      log("mark_read_failed", `${reason}: ${errorMessage(error)}`);
    });
    scheduleVisibleMarkRead(reason);
  }

  async function syncMessagesFromKnownCursor(conversationId: string, limit = MESSAGE_PAGE_SIZE): Promise<void> {
    if (!conversationId) return;
    await withTimeout(
      client.sync.syncMessages({ conversationId, lastSeq: 0, limit }),
      MESSAGE_SYNC_TIMEOUT_MS,
      () => sdkOperationTimeoutError("sync.messages", MESSAGE_SYNC_TIMEOUT_MS),
    );
  }

  function syncConversationSummaries(): Promise<void> {
    if (!pendingConversationSummarySync) {
      pendingConversationSummarySync = withTimeout(
        Promise.resolve().then(() => client.sync.syncConversationSummaries()),
        SYNC_CONVERSATION_SUMMARIES_TIMEOUT_MS,
        () => sdkOperationTimeoutError("sync.conversation_summaries", SYNC_CONVERSATION_SUMMARIES_TIMEOUT_MS),
      )
        .finally(() => {
          pendingConversationSummarySync = undefined;
        });
    }
    return pendingConversationSummarySync;
  }

  async function trySyncConversationSummaries(reason: string): Promise<boolean> {
    try {
      await syncConversationSummaries();
      return true;
    } catch (error) {
      log("sync_conversation_summaries_degraded", `${reason}:${errorMessage(error)}`);
      return false;
    }
  }

  async function backfillVisibleConversationHistories(reason: string): Promise<void> {
    const historyConversations = await listConversations({ includeArchived: true });
    const conversationIds = [
      ...new Set(historyConversations.map((item) => item.conversationId.trim()).filter(Boolean)),
    ];
    if (conversationIds.length === 0) return;

    const strict = reason === "manual_sync";
    let totalPages = 0;
    let completed = 0;
    const failures: string[] = [];

    for (const [index, conversationId] of conversationIds.entries()) {
      try {
        let round = 0;
        let response: Awaited<ReturnType<typeof client.sync.backfillConversationHistory>> | undefined;
        do {
          round += 1;
          if (homeSyncing.value) {
            setHomeSyncProgress({
              step: "history",
              title: translateFlare("sync.backfillTitle"),
              detail: translateFlare("sync.backfillDetail", { index: index + 1, total: conversationIds.length, round }),
              percent: Math.min(92, 72 + Math.round(((index + 1) / conversationIds.length) * 18)),
            });
          }
          const current = await withTimeout(
            Promise.resolve().then(() => client.sync.backfillConversationHistory({
              conversationId,
              limit: FULL_HISTORY_BACKFILL_SYNC_LIMIT,
              maxPages: FULL_HISTORY_BACKFILL_MAX_PAGES_PER_CALL,
            })),
            HISTORY_BACKFILL_CONVERSATION_TIMEOUT_MS,
            () => sdkOperationTimeoutError("sync.conversation_history_backfill", HISTORY_BACKFILL_CONVERSATION_TIMEOUT_MS),
          );
          response = current;
          totalPages += Number(current.pagesLoaded) || 0;
          if (current.completed || current.pagesLoaded <= 0) {
            break;
          }
        } while (round < FULL_HISTORY_BACKFILL_MAX_ROUNDS);

        if (!response?.completed) {
          const detail = `${conversationId}: history backfill incomplete after ${round} rounds`;
          failures.push(detail);
          log("history_backfill_incomplete", `${reason}:${detail}`);
          if (strict) {
            throw new Error(detail);
          }
          continue;
        }

        completed += 1;
        log(
          "history_backfill",
          `${reason}:${conversationId}:rounds=${round}:oldest=${response.oldestSeqAfter}:done=${response.completed}`,
        );
      } catch (error) {
        const detail = `${conversationId}: ${errorMessage(error)}`;
        failures.push(detail);
        log("history_backfill_failed", `${reason}:${detail}`);
        if (strict) {
          throw error;
        }
      }
    }

    if (failures.length > 0) {
      const detail = translateFlare("sync.backfillIncomplete", { failed: failures.length, total: conversationIds.length, detail: failures.slice(0, 3).join("; ") });
      if (strict) {
        throw new Error(detail);
      }
      log("history_backfill_degraded", `${reason}:${detail}`);
      return;
    }

    log("history_backfill_done", `${reason}:${completed}/${conversationIds.length}:pages=${totalPages}`);
  }

  function log(label: string, detail = ""): void {
    events.value = [{ id: eventId++, label, detail, at: Date.now() }, ...events.value].slice(0, 24);
    if (typeof console !== "undefined") {
      console.info("[flare-web]", label, detail);
    }
  }

  function nowMs(): number {
    return typeof performance !== "undefined" ? performance.now() : Date.now();
  }

  function logDuration(label: string, start: number): void {
    const detail = `${Math.round(nowMs() - start)}ms`;
    log(label, detail);
    if (typeof console !== "undefined") {
      console.info("[flare-web]", label, detail);
    }
  }

  function refreshDerivedState(): void {
    const activeId = activeConversationId.value.trim();
    totalUnread.value = conversations.value.reduce(
      (sum, item) => sum + Math.max(0, Number(item.unreadCount) || 0),
      0,
    );
    activeConversation.value = conversations.value.find((item) => item.conversationId === activeId);
    const activeMessages = messages.value.filter((message) => message.conversationId === activeId);
    const latest = activeMessages.reduce<Message | undefined>((current, message) => {
      if (!current) return message;
      const messageSeq = Number(message.conversationSeq) || 0;
      const currentSeq = Number(current.conversationSeq) || 0;
      if (messageSeq !== currentSeq) return messageSeq > currentSeq ? message : current;
      return (Number(message.createdAt) || 0) >= (Number(current.createdAt) || 0) ? message : current;
    }, undefined);
    activeLatestMessageId.value =
      activeConversation.value?.lastMessageId || latest?.serverId || latest?.clientMsgId || "";
    pinnedMessages.value = activeMessages.filter(isPinnedMessage);
    setDesktopUnreadCount(totalUnread.value);
  }

  function isDocumentForeground(): boolean {
    if (typeof document === "undefined") return true;
    return document.visibilityState === "visible" && document.hasFocus();
  }

  function isDocumentVisible(): boolean {
    if (typeof document === "undefined") return true;
    return document.visibilityState === "visible";
  }

  function isRealtimeRefreshConnectionReady(): boolean {
    return connectionState.value === "ready" || connectionState.value === "connected";
  }

  function startRealtimeSafetyPoll(): void {
    if (typeof window === "undefined" || realtimeSafetyPollTimer) return;
    realtimeSafetyPollTimer = window.setInterval(() => {
      void refreshActiveConversationFromServer("safety_poll");
    }, REALTIME_SAFETY_POLL_INTERVAL_MS);
  }

  async function refreshActiveConversationFromServer(reason: string): Promise<void> {
    if (realtimeSafetyPollInFlight) return;
    if (activeOutgoingSends > 0) return;
    if (Date.now() - lastOutgoingSendAt < REALTIME_SAFETY_POLL_AFTER_SEND_QUIET_MS) return;
    if (Date.now() < realtimeSafetyPollNextAt) return;
    if (!loggedIn.value || !isRealtimeRefreshConnectionReady()) return;
    if (!isDocumentVisible()) return;
    const conversationId = activeConversationId.value.trim();
    if (!conversationId) return;
    if (messageOpening.value || messageSyncing.value || loadingOlderMessages.value) return;
    realtimeSafetyPollInFlight = true;
    try {
      await client.sync.syncConversation({ conversationId });
      await syncMessagesFromKnownCursor(conversationId);
      await refreshConversations({ silent: true });
      await refreshMessages(conversationId, { silent: true });
      realtimeSafetyPollFailureCount = 0;
      realtimeSafetyPollNextAt = 0;
    } catch (error) {
      realtimeSafetyPollFailureCount += 1;
      realtimeSafetyPollNextAt = Date.now() + Math.min(
        REALTIME_SAFETY_POLL_BACKOFF_MAX_MS,
        REALTIME_SAFETY_POLL_BACKOFF_BASE_MS * (2 ** Math.min(realtimeSafetyPollFailureCount - 1, 4)),
      );
      log("realtime_refresh_failed", `${reason}:${conversationId}: ${errorMessage(error)}`);
    } finally {
      realtimeSafetyPollInFlight = false;
    }
  }

  function scheduleIncomingConversationRefresh(reason: string): void {
    if (!loggedIn.value) return;
    if (typeof window === "undefined") {
      void refreshIncomingConversationSummary(reason);
      return;
    }
    if (incomingConversationRefreshTimer !== undefined) {
      window.clearTimeout(incomingConversationRefreshTimer);
    }
    incomingConversationRefreshTimer = window.setTimeout(() => {
      incomingConversationRefreshTimer = undefined;
      void refreshIncomingConversationSummary(reason);
    }, INCOMING_CONVERSATION_REFRESH_DEBOUNCE_MS);
  }

  async function refreshIncomingConversationSummary(reason: string): Promise<void> {
    if (incomingConversationRefreshInFlight) return;
    incomingConversationRefreshInFlight = true;
    try {
      await refreshConversations({ silent: true });
    } catch (error) {
      log("incoming_conversation_refresh_failed", `${reason}: ${errorMessage(error)}`);
    } finally {
      incomingConversationRefreshInFlight = false;
    }
  }

  /// 去抖的活动会话对账:把消息突发合并成一次 syncConversation+时间线重读(安全网);
  /// 实时增量显示由 core 观察视图 delta 负责,避免每条消息全量重开时间线导致的抖动风暴。
  function scheduleActiveConversationRefresh(reason: string): void {
    if (typeof window === "undefined") {
      void refreshActiveConversationFromServer(reason);
      return;
    }
    if (activeConversationRefreshTimer !== undefined) {
      window.clearTimeout(activeConversationRefreshTimer);
    }
    activeConversationRefreshTimer = window.setTimeout(() => {
      activeConversationRefreshTimer = undefined;
      void refreshActiveConversationFromServer(reason);
    }, ACTIVE_CONVERSATION_REFRESH_DEBOUNCE_MS);
  }

  function handleIncomingMessageNotification(hint: IncomingMessageHint): void {
    scheduleIncomingConversationRefresh("incoming_message");
    // 活动会话的时间线由 core 观察视图 delta(applyTimelineViewDelta)实时增量渲染,不在这里做
    // 全量重开(close+open)——那会撕毁/重建视图造成抖动与消息闪烁。对账交给 12s 安全轮询兜底。
    // scheduleActiveConversationRefresh("event_hint"); // removed: redundant churn vs view delta

    const message = hint.message;
    if (!message) return;
    const senderId = message.senderId.trim();
    const selfUserId = (currentUserId.value || form.userId).trim();
    if (senderId && selfUserId && senderId === selfUserId) return;

    const conversationId = message.conversationId.trim();
    const conversation = conversations.value.find((item) => item.conversationId === conversationId);
    if (conversation?.isMuted) return;

    const kind = desktopNotificationKindForMessage(message);
    const foregroundInActiveConversation =
      kind !== "call" &&
      isDocumentForeground() &&
      conversationId &&
      conversationId === activeConversationId.value.trim();
    if (foregroundInActiveConversation) return;

    const senderLabel = message.senderDisplayName.trim() || message.senderName.trim() || senderId || "Flare IM";
    const title = kind === "call" ? translateFlare("call.startedBy", { sender: senderLabel }) : senderLabel;
    const body = kind === "call" ? callNotificationBody(message) : desktopNotificationBodyForMessage(message);
    emitDesktopNotification({
      kind,
      title,
      body,
      conversationId,
      messageId: message.serverId || message.clientMsgId,
      senderId,
      unreadCount: Math.max(1, totalUnread.value),
      requireAttention: true,
      playSound: true,
      dedupeKey: message.serverId || message.clientMsgId || `${conversationId}:${message.conversationSeq}`,
    });
  }

  function handleCapabilityDesktopNotification(payload: unknown): void {
    if (!isCallSignalPayload(payload)) return;
    const event = payload && typeof payload === "object" ? payload as Record<string, unknown> : {};
    const conversationId = readStringField(event, "conversationId");
    emitDesktopNotification({
      kind: "call",
      title: translateFlare("call.title"),
      body: translateFlare("call.incoming"),
      conversationId,
      unreadCount: Math.max(1, totalUnread.value),
      requireAttention: true,
      playSound: true,
      dedupeKey: `call:${stableNotificationKey(payload)}`,
    });
  }

  function desktopNotificationKindForMessage(message: Message): DesktopNotificationKind {
    return looksLikeCallMessage(message) ? "call" : "message";
  }

  function looksLikeCallMessage(message: Message): boolean {
    const text = [
      message.textPreview,
      message.content?.contentType,
      ...Object.values(message.attributes ?? {}),
      ...Object.values(message.content?.data ?? {}).map((value) => String(value ?? "")),
    ].join(" ").toLowerCase();
    return /\brtc\.call\b|\bcall\b|\bwebrtc\b|\bsfu\b/.test(text);
  }

  function isCallSignalPayload(payload: unknown): boolean {
    const text = stableNotificationKey(payload).toLowerCase();
    return (
      /\brtc\.call\b|\bcall\b|\bwebrtc\b|\bsfu\b/.test(text) &&
      /\binvite\b|\binvited\b|\boffer\b|\bring\b|\bincoming\b|\bsignal\b|call_signal/.test(text)
    );
  }

  function callNotificationBody(message: Message): string {
    return firstNonEmpty(
      message.textPreview,
      readStringField(message.content?.data, "title"),
      readStringField(message.content?.data, "body"),
    ) || translateFlare("call.incoming");
  }

  function firstNonEmpty(...values: Array<string | undefined>): string {
    return values.map((value) => value?.trim() ?? "").find(Boolean) ?? "";
  }

  function readStringField(record: unknown, field: string): string | undefined {
    if (!record || typeof record !== "object") return undefined;
    const value = (record as Record<string, unknown>)[field];
    return typeof value === "string" ? value : undefined;
  }

  function stableNotificationKey(payload: unknown): string {
    try {
      return JSON.stringify(payload) || "";
    } catch {
      return String(payload ?? "");
    }
  }

  function patchMessageById(
    messageId: string,
    patcher: (message: Message) => Message,
  ): void {
    let changed = false;
    messages.value = messages.value.map((message) => {
      if (!messageMatchesId(message, messageId)) return message;
      changed = true;
      return patcher(message);
    });
    if (changed) {
      refreshDerivedState();
    }
  }

  function removeMessageById(messageId: string): void {
    const next = messages.value.filter((message) => !messageMatchesId(message, messageId));
    if (next.length === messages.value.length) return;
    messages.value = next;
    refreshDerivedState();
  }

  function applyReactionChanged(hint: ReactionChangedHint): void {
    const conversationId = (hint.conversationId ?? "").trim();
    const messageId = (hint.serverMsgId ?? "").trim();
    const emoji = (hint.emoji ?? "").trim();
    const userId = (hint.userId ?? "").trim();
    const action = Number(hint.action ?? 0);
    if (
      !conversationId ||
      conversationId !== activeConversationId.value.trim() ||
      !messageId ||
      !emoji ||
      !userId ||
      (action !== 1 && action !== 2)
    ) {
      return;
    }
    patchLocalReaction(messageId, emoji, userId, action);
  }

  function patchLocalReaction(messageId: string, emoji: string, userId: string, action: number): void {
    if (!messageId || !emoji || !userId || (action !== 1 && action !== 2)) return;

    let changed = false;
    messages.value = messages.value.map((message) => {
      if (!messageMatchesId(message, messageId)) return message;
      const reactions: ReactionEntry[] = (message.reactions ?? []).map((reaction) => ({
        ...reaction,
        userIds: [...(reaction.userIds ?? [])],
      }));
      const index = reactions.findIndex((reaction) => reaction.emoji === emoji);
      if (action === 1) {
        if (index >= 0) {
          const reaction = reactions[index];
          if (!reaction.userIds.includes(userId)) {
            reaction.userIds.push(userId);
            changed = true;
          }
          const nextCount = Math.max(Number(reaction.count) || 0, reaction.userIds.length);
          if (reaction.count !== nextCount) {
            reaction.count = nextCount;
            changed = true;
          }
        } else {
          reactions.push({ emoji, count: 1, userIds: [userId] });
          changed = true;
        }
      } else if (index >= 0) {
        const reaction = reactions[index];
        const nextUserIds = reaction.userIds.filter((id) => id !== userId);
        if (nextUserIds.length !== reaction.userIds.length || reaction.count !== nextUserIds.length) {
          changed = true;
        }
        reaction.userIds = nextUserIds;
        reaction.count = nextUserIds.length;
        if (reaction.count <= 0) {
          reactions.splice(index, 1);
        }
      }
      return { ...message, reactions };
    });
    if (changed) {
      refreshDerivedState();
    }
  }

  function beginMessageOpening(): void {
    if (messageOpeningTimer) {
      clearTimeout(messageOpeningTimer);
      messageOpeningTimer = undefined;
    }
    messageOpening.value = true;
  }

  function finishMessageOpening(conversationId: string): void {
    if (messageOpeningTimer) {
      clearTimeout(messageOpeningTimer);
    }
    messageOpeningTimer = setTimeout(() => {
      if (activeConversationId.value === conversationId) {
        messageOpening.value = false;
      }
      messageOpeningTimer = undefined;
    }, 240);
  }

  function resetMessageOpening(): void {
    if (messageOpeningTimer) {
      clearTimeout(messageOpeningTimer);
      messageOpeningTimer = undefined;
    }
    messageOpening.value = false;
  }

  async function refreshConnectionState(): Promise<void> {
    connectionState.value = await client.connection.getConnectionState();
  }

  async function refreshConnectionStateSafely(reason: string): Promise<void> {
    try {
      await refreshConnectionState();
    } catch (error) {
      log("connection_state_refresh_failed", `${reason}: ${errorMessage(error)}`);
    }
  }

  function setHomeSyncProgress(progress: HomeSyncProgress): void {
    homeSyncProgress.value = progress;
  }

  function errorMessage(error: unknown): string {
    return error instanceof Error ? error.message : String(error);
  }

  function isDatabaseLockedError(error: unknown): boolean {
    return /database is locked|code:\s*(5|517)\b/i.test(errorMessage(error));
  }

  function isTimeoutError(error: unknown): boolean {
    const code = error && typeof error === "object"
      ? (error as { code?: unknown }).code
      : undefined;
    return code === "timeout" || /timed out|invoke_timeout/i.test(errorMessage(error));
  }

  function wait(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  function errorPayload(error: unknown, operation: string): Record<string, unknown> {
    return reportSdkError(error, operation);
  }

  function isRuntimeUnavailableError(error: unknown): boolean {
    if (!error || typeof error !== "object") {
      return false;
    }
    const shaped = error as { code?: unknown; operation?: unknown };
    return shaped.code === "runtimeUnavailable" || shaped.operation === "wasm.load";
  }

  async function runLab<T extends Record<string, unknown> | unknown[] | void>(
    operation: string,
    action: () => Promise<T>,
  ): Promise<void> {
    labBusy.value = true;
    try {
      const result = await action();
      labResult.value = result === undefined ? { ok: true, operation } : ({ operation, result } as Record<string, unknown>);
      log(operation, "ok");
    } catch (error) {
      labResult.value = errorPayload(error, operation);
      log(`${operation}_failed`, errorMessage(error));
    } finally {
      labBusy.value = false;
    }
  }

  async function refreshConversations(options: ConversationRefreshOptions = {}): Promise<void> {
    if (!options.silent) {
      conversationSyncing.value = true;
      conversationSyncError.value = "";
    }
    try {
      const filter = conversationFilters.filter;
      let nextConversations: Conversation[];
      if (filter === "archived") {
        // includeArchived 的语义是"额外带上归档会话"，不是"只要归档会话"。
        // 直接拿它当归档筛选用，列表会原样返回全部会话——筛选看起来生效了
        // （高亮切了），内容却一条没少。SDK 没有 archivedOnly 查询，所以在
        // 取回后按 isArchived 收窄。
        nextConversations = keepArchivedConversations(
          await listConversations({ includeArchived: true }),
        );
      } else if (conversationFilters.includeArchived) {
        nextConversations = [...await listConversations({ includeArchived: true })];
      } else if (conversationFilters.conversationType) {
        const response = await client.conversations.listConversationsByQuery({
          keyword: "",
          includeArchived: conversationFilters.includeArchived,
          unreadOnly: filter === "unread",
          mentionMeOnly: filter === "mention",
          pinnedOnly: filter === "pinned",
          hasDraftOnly: filter === "draft",
          hasMarkedMessages: false,
          conversationTypes: conversationFilters.conversationType ? [conversationFilters.conversationType as never] : [],
          limit: 100,
        });
        nextConversations = [...response.conversations];
      } else if (filter !== "all") {
        const response = await client.conversations.listConversationsByQuery({
          keyword: "",
          includeArchived: conversationFilters.includeArchived,
          unreadOnly: filter === "unread",
          mentionMeOnly: filter === "mention",
          pinnedOnly: filter === "pinned",
          hasDraftOnly: filter === "draft",
          hasMarkedMessages: false,
          conversationTypes: [],
          limit: 100,
        });
        nextConversations = [...response.conversations];
      } else {
        const snapshot = await bootstrapHome(100);
        nextConversations = [...snapshot.conversations];
      }
      if (filter === "unread") {
        nextConversations = nextConversations.filter((item) => Number(item.unreadCount) > 0);
      }
      if (filter === "muted") {
        nextConversations = nextConversations.filter((item) => item.isMuted);
      }
      conversations.value = nextConversations.filter((item) => item.conversationId.trim());
      if (!activeConversationId.value) {
        ensureActiveConversationSelection();
      }
      refreshDerivedState();
      await openConversationListView("refresh");
    } catch (error) {
      if (!options.silent) {
        conversationSyncError.value = errorMessage(error);
        log("conversation_sync_failed", conversationSyncError.value);
      }
      throw error;
    } finally {
      if (!options.silent) {
        conversationSyncing.value = false;
      }
    }
  }

  async function setConversationFilter(filter: ConversationFilter): Promise<void> {
    conversationFilters.filter = filter;
    conversationFilters.includeArchived = filter === "archived";
    await refreshConversations();
  }

  async function refreshMessages(
    conversationId = activeConversationId.value,
    options: MessageRefreshOptions = {},
  ): Promise<void> {
    messageSyncError.value = "";
    const targetId = conversationId.trim();
    if (!targetId) {
      messages.value = [];
      messageHasMore.value = false;
      refreshDerivedState();
      return;
    }
    if (!options.silent) {
      messageSyncing.value = true;
    }
    try {
      if (activeConversationId.value.trim() !== targetId) return;
      await openTimelineView(targetId, options.silent ? "silent_refresh" : "refresh", { force: true });
    } catch (error) {
      const detail = errorMessage(error);
      log("message_sync_failed", detail);
      messageSyncError.value = detail;
      throw error;
    } finally {
      if (!options.silent) {
        messageSyncing.value = false;
      }
    }
  }

  async function loadOlderMessages(options: LoadOlderMessagesOptions = {}): Promise<void> {
    const conversationId = activeConversationId.value.trim();
    const activeView = activeTimelineView;
    if (
      !conversationId
      || !activeView
      || activeView.conversationId !== conversationId
      || loadingOlderMessages.value
      || (!options.force && !messageHasMore.value)
    ) {
      return;
    }
    loadingOlderMessages.value = true;
    messageSyncError.value = "";
    try {
      const response = await client.views.loadOlderTimeline({
        viewId: activeView.viewId,
        messageLimit: options.limit ?? MESSAGE_PAGE_SIZE,
      });
      if (
        activeConversationId.value.trim() !== conversationId
        || activeTimelineView?.viewId !== response.viewId
      ) {
        return;
      }
      messageHasMore.value = response.hasMore;
      if (response.update) {
        handleViewUpdate(response.update);
      } else {
        refreshDerivedState();
      }
      log("view_timeline_load_older", `${conversationId}:${response.loadedCount}:${response.hasMore}`);
    } catch (error) {
      messageSyncError.value = errorMessage(error);
      log("message_sync_failed", messageSyncError.value);
      throw error;
    } finally {
      loadingOlderMessages.value = false;
    }
  }

  async function searchConversationsWithKeyword(keyword: string): Promise<void> {
    const query = keyword.trim();
    conversationSyncing.value = true;
    conversationSyncError.value = "";
    try {
      if (!query) {
        await refreshConversations();
        return;
      }
      const response = await client.conversations.listConversationsByQuery({
        keyword: query,
        includeArchived: conversationFilters.includeArchived,
        unreadOnly: false,
        mentionMeOnly: false,
        pinnedOnly: false,
        hasDraftOnly: false,
        hasMarkedMessages: false,
        conversationTypes: [],
        limit: 100,
      });
      conversations.value = [...response.conversations];
      refreshDerivedState();
    } catch (error) {
      conversationSyncError.value = errorMessage(error);
      throw error;
    } finally {
      conversationSyncing.value = false;
    }
  }

  async function refreshActivePeerPresence(peerUserId: string): Promise<string> {
    if (!peerUserId) return "offline";
    try {
      const dto = await client.presence.getUserPresence({ userId: peerUserId });
      await client.presence.subscribeUserPresence({ userIds: [peerUserId] });
      const status = presenceStatusFromCoreDto(dto);
      peerPresence.value = { ...peerPresence.value, [peerUserId]: status };
      if (/busy|dnd/i.test(status)) return "busy";
      if (/offline|away|invisible/i.test(status)) return "offline";
      return "online";
    } catch (error) {
      log("presence_refresh_failed", `${peerUserId}: ${errorMessage(error)}`);
      return peerPresence.value[peerUserId] ?? "offline";
    }
  }

  function applyPresenceChanged(event: PresenceChangedHint): void {
    const userId = String(event.userId ?? "").trim();
    if (!userId) return;
    const status = presenceStatusFromCoreDto(event);
    peerPresence.value = { ...peerPresence.value, [userId]: status };
  }

  async function runSessionDiagnostics(): Promise<void> {
    labBusy.value = true;
    try {
      const appDiagnostics = await refreshCoreDiagnostics();
      diagnostics.value = {
        sdkVersion: {
          ...appDiagnostics.sdkVersion,
          coreSdk: "flare-im-core-sdk",
          adapterBoundary: "TypeScript SDK -> flare-im-core-sdk/bindings/wasm (real IMClient)",
          wasmBinding: {
            status: sdkRuntimeStatus.value,
            source: "flare-im-core-sdk/bindings/wasm",
          },
        },
        ffi: appDiagnostics.ffiContract,
        dataRoot: appDiagnostics.dataRoot,
        runtimeHealth: appDiagnostics.runtimeHealth,
        currentUser: appDiagnostics.currentUser,
        sessionActive: appDiagnostics.sessionActive,
        isConnected: appDiagnostics.isConnected,
        connectionState: appDiagnostics.connectionState,
      };
      labResult.value = diagnostics.value;
      log("diagnostics", appDiagnostics.connectionState);
      messageBuildCatalog.value = [...await refreshCoreMessageBuildCatalog()];
    } finally {
      labBusy.value = false;
    }
  }

  async function refreshMessageBuildCatalog(): Promise<void> {
    messageBuildCatalog.value = [...await refreshCoreMessageBuildCatalog()];
    if (!messageBuildCatalog.value.some((entry) => String(entry.op) === sdkLab.buildOp)) {
      sdkLab.buildOp = String(messageBuildCatalog.value[0]?.op ?? "create_text");
    }
  }

  async function initializeAndLogin(): Promise<void> {
    busy.value = true;
    const loginStartedAt = nowMs();
    homeSyncReady.value = false;
    homeSyncError.value = "";
    transportFallbackNotice.value = "";
    setHomeSyncProgress({
      step: "session",
      title: translateFlare("sync.connectTitle"),
      detail: translateFlare("sync.connectDetail"),
      percent: 8,
    });
    try {
      const tokenStartedAt = nowMs();
      const identity = await ensureLoginToken();
      logDuration("login_token_ready", tokenStartedAt);
      const token = String(form.token ?? "").trim();
      if (!token) {
        throw new Error("token is required for initAndLogin");
      }
      const coreLoginStartedAt = nowMs();
      const selectedTransportMode = normalizeLoginTransportMode(form.transportMode);
      const loginRequest = (transportMode: LoginTransportMode) => ({
        transportMode,
        wsUrl: form.wsUrl,
        quicUrl: form.quicUrl,
        tlsCaCertPath: form.tlsCaCertPath,
        dataUrl: form.dataUrl,
        tenantId: identity.tenantId,
        userId: identity.userId,
        token,
        httpUrl: form.httpUrl,
      });
      let snapshot: Awaited<ReturnType<typeof initAndLoginCore>>;
      try {
        snapshot = await initAndLoginCore(loginRequest(selectedTransportMode));
      } catch (error) {
        if (!isRecoverableLoginTransportError(error, selectedTransportMode)) {
          throw error;
        }
        const notice = loginTransportFallbackMessage(selectedTransportMode, error);
        transportFallbackNotice.value = notice;
        form.transportMode = "websocket";
        log("login_transport_fallback", notice);
        setHomeSyncProgress({
          step: "session",
          title: translateFlare("sync.switchWsTitle"),
          detail: notice,
          percent: 10,
        });
        snapshot = await initAndLoginCore(loginRequest("websocket"));
      }
      logDuration("login_core_ready", coreLoginStartedAt);
      initialized.value = snapshot.session.initialized;
      loggedIn.value = snapshot.session.loggedIn;
      connectionState.value = snapshot.session.connectionState;
      currentUserId.value = snapshot.session.userId ?? identity.userId;
      sessionActive.value = Boolean(snapshot.diagnostics?.sessionActive);
      isConnected.value = Boolean(snapshot.diagnostics?.isConnected);
      sdkRuntimeStatus.value = defaultSdkRuntimeStatus;
      messageBuildCatalog.value = [...snapshot.messageBuildCatalog];
      setHomeSyncProgress({
        step: "session",
        title: translateFlare("sync.sessionReadyTitle"),
        detail: translateFlare("sync.sessionReadyDetail"),
        percent: 18,
      });
      persistSavedSessionProfile(savedSessionProfileFromForm(identity, token));
      startPlatformSignalBridge();
      log("login", `${identity.userId} connected`);
      logDuration("login_route_ready", loginStartedAt);
    } catch (error) {
      loggedIn.value = false;
      homeSyncReady.value = false;
      sdkRuntimeStatus.value = isRuntimeUnavailableError(error)
        ? "browser-unavailable"
        : defaultSdkRuntimeStatus;
      const detail = errorMessage(error);
      errorPayload(error, "sdk.login");
      log("login_failed", detail);
      throw error;
    } finally {
      busy.value = false;
    }
  }

  function savedSessionProfileFromForm(identity: LoginIdentity, token: string): SavedSessionProfile {
    return {
      userId: identity.userId,
      tenantId: identity.tenantId,
      token,
      transportMode: normalizeLoginTransportMode(form.transportMode),
      wsUrl: form.wsUrl,
      quicUrl: form.quicUrl,
      tlsCaCertPath: form.tlsCaCertPath,
      httpUrl: form.httpUrl,
      dataUrl: form.dataUrl,
      savedAtMs: Date.now(),
    };
  }

  function applySavedSessionToForm(profile: SavedSessionProfile): void {
    form.userId = profile.userId;
    form.tenantId = profile.tenantId;
    form.token = profile.token;
    form.transportMode = profile.transportMode;
    form.wsUrl = profile.wsUrl;
    if (profile.quicUrl) form.quicUrl = profile.quicUrl;
    if (profile.tlsCaCertPath) form.tlsCaCertPath = profile.tlsCaCertPath;
    if (profile.httpUrl) form.httpUrl = profile.httpUrl;
    if (profile.dataUrl) form.dataUrl = profile.dataUrl;
    generatedTokenOwner = {
      userId: profile.userId,
      tenantId: profile.tenantId,
      token: profile.token,
    };
  }

  function hasSavedSession(): boolean {
    return loadSavedSessionProfile() !== undefined;
  }

  let sessionResumeInFlight: Promise<boolean> | undefined;

  /**
   * 热启动路径：本地库直出首屏（prepare + bootstrapStartupHome，不等网络），
   * 连接与增量同步在后台补齐。成功返回 true 时 UI 可直接进入工作台。
   */
  function resumeSavedSession(): Promise<boolean> {
    if (loggedIn.value) return Promise.resolve(true);
    sessionResumeInFlight ??= resumeSavedSessionInner().finally(() => {
      sessionResumeInFlight = undefined;
    });
    return sessionResumeInFlight;
  }

  async function resumeSavedSessionInner(): Promise<boolean> {
    const profile = loadSavedSessionProfile();
    if (!profile) return false;
    const resumeStartedAt = nowMs();
    busy.value = true;
    setHomeSyncProgress({
      step: "session",
      title: translateFlare("sync.restoreTitle"),
      detail: translateFlare("sync.restoreDetail"),
      percent: 30,
    });
    try {
      applySavedSessionToForm(profile);
      const mediaProxy = sdkMediaProxyFields();
      await client.init({
        ...buildLoginTransportConfig(form),
        dataUrl: form.dataUrl,
        tenantId: profile.tenantId,
        httpUrl: form.httpUrl,
        mediaStorageProxyPrefix: mediaProxy.storageProxyPrefix,
        mediaStorageProxyTargets: mediaProxy.storageProxyTargets,
      });
      await client.events.subscribeEvents({ sources: [...sdkEventSources] });
      await withTimeout(
        client.prepare({ userId: profile.userId, token: profile.token }),
        CORE_LOGIN_STEP_TIMEOUT_MS,
        () => sdkOperationTimeoutError("login.prepare", CORE_LOGIN_STEP_TIMEOUT_MS),
      );
      initialized.value = true;
      loggedIn.value = true;
      currentUserId.value = profile.userId;
      sdkRuntimeStatus.value = defaultSdkRuntimeStatus;
      // T0 本地水合：后台收敛等 connect 成功后再启动，避免离线时空转
      const startupHome = await withTimeout(
        client.sync.bootstrapStartupHome({
          conversationLimit: 100,
          startBackgroundConvergence: false,
          backfillVisibleHistories: false,
          historyBackfillLimit: FULL_HISTORY_BACKFILL_SYNC_LIMIT,
          historyBackfillMaxPagesPerConversation: FULL_HISTORY_BACKFILL_MAX_ROUNDS,
          historyBackfillMaxConversations: 100,
        }),
        STARTUP_HOME_SYNC_TIMEOUT_MS,
        () => sdkOperationTimeoutError("sync.bootstrap_startup_home", STARTUP_HOME_SYNC_TIMEOUT_MS),
      );
      applyConversationListViewSnapshot(startupHome.snapshot);
      await openConversationListView("hot_resume");
      ensureActiveConversationSelection();
      refreshDerivedState();
      homeSyncReady.value = true;
      setHomeSyncProgress({
        step: "ready",
        title: translateFlare("sync.localReadyTitle"),
        detail: translateFlare("sync.localReadyDetail"),
        percent: 100,
      });
      log("session_resume_local_ready", `${conversations.value.length} conversations`);
      logDuration("session_resume_local_ready", resumeStartedAt);
      startPlatformSignalBridge();
      void connectResumedSessionInBackground(profile);
      return true;
    } catch (error) {
      log("session_resume_failed", errorMessage(error));
      clearSavedSessionProfile();
      loggedIn.value = false;
      homeSyncReady.value = false;
      setHomeSyncProgress({
        step: "idle",
        title: translateFlare("sync.prepareTitle"),
        detail: translateFlare("sync.prepareDetail"),
        percent: 0,
      });
      return false;
    } finally {
      busy.value = false;
    }
  }

  async function connectResumedSessionInBackground(profile: SavedSessionProfile): Promise<void> {
    const connectStartedAt = nowMs();
    try {
      try {
        await client.connect({ userId: profile.userId, token: profile.token });
      } catch (error) {
        // token 过期/失效：重新生成 dev token 后单次重试（需要 HTTP 网关可达）
        log("session_resume_connect_retry", errorMessage(error));
        await generateToken();
        await client.connect({ userId: profile.userId, token: form.token });
        persistSavedSessionProfile(
          savedSessionProfileFromForm(
            { userId: profile.userId, tenantId: profile.tenantId },
            form.token,
          ),
        );
      }
      isConnected.value = true;
      sessionActive.value = true;
      await refreshConnectionStateSafely("session_resume");
      logDuration("session_resume_connected", connectStartedAt);
      // 连接建立后启动前台收敛，把离线期间的增量补齐（core 内部静默去重）
      void client.sync.bootstrapStartupHome({
        conversationLimit: 100,
        startBackgroundConvergence: true,
        backfillVisibleHistories: false,
        historyBackfillLimit: FULL_HISTORY_BACKFILL_SYNC_LIMIT,
        historyBackfillMaxPagesPerConversation: FULL_HISTORY_BACKFILL_MAX_ROUNDS,
        historyBackfillMaxConversations: 100,
      }).then((startupHome) => {
        applyConversationListViewSnapshot(startupHome.snapshot);
        refreshDerivedState();
      }).catch((error) => {
        log("session_resume_convergence_failed", errorMessage(error));
      });
      try {
        messageBuildCatalog.value = [...await refreshCoreMessageBuildCatalog()];
      } catch (error) {
        log("session_resume_catalog_failed", errorMessage(error));
      }
    } catch (error) {
      // 离线也保持本地视图可用；连接状态交由 connection watcher 呈现
      log("session_resume_connect_failed", errorMessage(error));
      await refreshConnectionStateSafely("session_resume_offline");
    }
  }

  /**
   * 平台原始信号桥：浏览器 online/offline → SDK 网络变化（core 主动重连，不等心跳超时）、
   * 页面可见性 → 心跳前后台（core 前台立即收敛/后台降配）。策略全在 core，这里只喂信号。
   */
  let platformSignalCleanup: (() => void) | undefined;

  function browserNetworkInterface(): NetworkInterfaceKind {
    const type = (navigator as { connection?: { type?: string; effectiveType?: string } })
      .connection?.type;
    switch (type) {
      case "wifi": return NetworkInterfaceKind.Wifi;
      case "cellular": return NetworkInterfaceKind.Cellular;
      case "ethernet": return NetworkInterfaceKind.Ethernet;
      case undefined: return NetworkInterfaceKind.Unknown;
      default: return NetworkInterfaceKind.Other;
    }
  }

  function startPlatformSignalBridge(): void {
    if (platformSignalCleanup || typeof window === "undefined" || typeof document === "undefined") {
      return;
    }
    const notifyNetwork = (available: boolean, reason: string) => {
      void client.connection.notifyNetworkChange({
        available,
        interface: browserNetworkInterface(),
        reason,
      }).then((response) => {
        log("network_change", `${reason} reconnected=${response.reconnected}`);
      }).catch((error) => {
        log("network_change_failed", `${reason}: ${errorMessage(error)}`);
      });
    };
    const onOnline = () => notifyNetwork(true, "browser_online");
    const onOffline = () => notifyNetwork(false, "browser_offline");
    const onVisibility = () => {
      const appState = document.visibilityState === "visible"
        ? HeartbeatAppState.Foreground
        : HeartbeatAppState.Background;
      void client.setHeartbeatAppState({ appState }).catch((error) => {
        log("heartbeat_app_state_failed", `${appState}: ${errorMessage(error)}`);
      });
    };
    window.addEventListener("online", onOnline);
    window.addEventListener("offline", onOffline);
    document.addEventListener("visibilitychange", onVisibility);
    platformSignalCleanup = () => {
      window.removeEventListener("online", onOnline);
      window.removeEventListener("offline", onOffline);
      document.removeEventListener("visibilitychange", onVisibility);
    };
    log("platform_signals", "bridge started");
  }

  function stopPlatformSignalBridge(): void {
    platformSignalCleanup?.();
    platformSignalCleanup = undefined;
  }

  async function syncHomeBeforeEnter(): Promise<void> {
    if (!loggedIn.value) {
      throw new Error(translateFlare("error.loginBeforeSync"));
    }
    if (homeSyncReady.value && conversations.value.length) {
      return;
    }
    homeSyncing.value = true;
    homeSyncError.value = "";
    const syncStartedAt = nowMs();
    try {
      setHomeSyncProgress({
        step: "session",
        title: translateFlare("sync.checkTitle"),
        detail: translateFlare("sync.checkDetail"),
        percent: 20,
      });
      await refreshConnectionStateSafely("home_sync");
      setHomeSyncProgress({
        step: "conversations",
        title: translateFlare("sync.syncTitle"),
        detail: translateFlare("sync.syncDetail"),
        percent: 45,
      });
      const startupHome = await withTimeout(
        Promise.resolve().then(() => client.sync.bootstrapStartupHome({
          conversationLimit: 100,
          startBackgroundConvergence: true,
          backfillVisibleHistories: false,
          historyBackfillLimit: FULL_HISTORY_BACKFILL_SYNC_LIMIT,
          historyBackfillMaxPagesPerConversation: FULL_HISTORY_BACKFILL_MAX_ROUNDS,
          historyBackfillMaxConversations: 100,
        })),
        STARTUP_HOME_SYNC_TIMEOUT_MS,
        () => sdkOperationTimeoutError("sync.bootstrap_startup_home", STARTUP_HOME_SYNC_TIMEOUT_MS),
      );
      setHomeSyncProgress({
        step: "unread",
        title: translateFlare("sync.applyTitle"),
        detail: translateFlare("sync.applyDetail"),
        percent: 70,
      });
      applyConversationListViewSnapshot(startupHome.snapshot);
      await openConversationListView("home_sync");
      ensureActiveConversationSelection();
      refreshDerivedState();
      if (startupHome.degradedReason) {
        log("home_startup_sync_degraded", startupHome.degradedReason);
      }
      setHomeSyncProgress({
        step: "preview",
        title: translateFlare("sync.previewTitle"),
        detail: startupHome.backgroundConvergenceStarted
          ? translateFlare("sync.previewDetailBackground")
          : translateFlare("sync.previewDetail"),
        percent: 90,
      });
      homeSyncReady.value = true;
      setHomeSyncProgress({
        step: "ready",
        title: translateFlare("sync.doneTitle"),
        detail: translateFlare("sync.doneDetail"),
        percent: 100,
      });
      log("home_sync_ready", `${conversations.value.length} conversations`);
      logDuration("home_sync_ready", syncStartedAt);
    } catch (error) {
      homeSyncReady.value = false;
      homeSyncError.value = errorMessage(error);
      setHomeSyncProgress({
        step: "failed",
        title: translateFlare("sync.failedTitle"),
        detail: homeSyncError.value || translateFlare("sync.failedDetail"),
        percent: 100,
      });
      log("home_sync_failed", homeSyncError.value);
      throw error;
    } finally {
      homeSyncing.value = false;
    }
  }

  function applyLoginIdentity(): LoginIdentity {
    const identity = normalizeLoginIdentityForSdk(form);
    form.userId = identity.userId;
    form.tenantId = identity.tenantId;
    return identity;
  }

  /**
   * 业务端推送用户资料(名称/头像)到本地身份缓存。读路径(消息/会话)批量 join 缓存渲染
   * 当前身份;缓存 miss 回退消息内嵌的发送时快照。业务同步好友/用户/群有变化时调用。
   */
  async function upsertUserProfiles(
    profiles: Array<{ userId: string; nickname?: string; avatarUrl?: string }>,
  ): Promise<void> {
    const sanitized = profiles
      .map((p) => ({
        userId: String(p.userId ?? "").trim(),
        nickname: String(p.nickname ?? ""),
        avatarUrl: String(p.avatarUrl ?? ""),
      }))
      .filter((p) => p.userId.length > 0);
    if (sanitized.length === 0) return;
    await client.user.upsertUserProfiles({ profiles: sanitized });
    log("user", `upsert_profiles:${sanitized.length}`);
  }

  // DEV-only 调试钩子:便于在浏览器/E2E 中验证身份缓存写入口(生产构建不挂载)。
  if (typeof window !== "undefined" && import.meta.env?.DEV) {
    (window as unknown as Record<string, unknown>).__flareUpsertUserProfiles =
      upsertUserProfiles;
  }

  async function generateToken(): Promise<void> {
    const identity = applyLoginIdentity();
    const response = await client.generateCoreToken(
      devCoreTokenRequest(env, identity.userId, identity.tenantId),
    );
    const token = String(response?.token ?? "").trim();
    if (!token) {
      throw new Error("generateCoreToken returned an empty token");
    }
    form.token = token;
    generatedTokenOwner = {
      userId: identity.userId,
      tenantId: identity.tenantId,
      token,
    };
    log("token", "generated");
  }

  function scheduleTokenRefresh(): void {
    clearTokenRefresh();
    const expMs = decodeJwtExpMs(form.token);
    if (expMs === undefined) return;
    const delay = Math.max(0, expMs - Date.now() - TOKEN_REFRESH_BUFFER_MS);
    tokenRefreshTimer = setTimeout(() => {
      void refreshAccessToken();
    }, delay);
  }

  function clearTokenRefresh(): void {
    if (tokenRefreshTimer !== undefined) {
      clearTimeout(tokenRefreshTimer);
      tokenRefreshTimer = undefined;
    }
  }

  // Regenerate the token and push it into the core so its autonomous reconnects use a fresh one.
  // generateCoreToken is a local dev generation, so this works even while offline/reconnecting.
  async function refreshAccessToken(): Promise<void> {
    try {
      await generateToken();
      await client.updateAccessToken({ accessToken: form.token, tenantId: form.tenantId });
      log("token", "refreshed before expiry");
    } catch (error) {
      log("token_refresh_failed", errorMessage(error));
    }
    scheduleTokenRefresh();
  }

  // Reactive recovery: if the connection drops into reconnecting/disconnected while the token has
  // already expired (e.g. the app was suspended past expiry, or the proactive push failed),
  // regenerate it immediately so the core's next reconnect authenticates instead of looping on
  // AUTHENTICATION_FAILED. The freshly minted token is no longer near expiry, so this fires at
  // most once per expiry rather than every reconnect tick.
  watch(connectionState, (state) => {
    if (state !== "reconnecting" && state !== "disconnected") return;
    const expMs = decodeJwtExpMs(form.token);
    if (expMs !== undefined && expMs - Date.now() <= TOKEN_REFRESH_BUFFER_MS) {
      void refreshAccessToken();
    }
  });

  async function ensureLoginToken(): Promise<LoginIdentity> {
    form.token = String(form.token ?? "");
    const identity = applyLoginIdentity();
    const usingGeneratedToken = generatedTokenOwner?.token === form.token;
    const generatedForCurrentIdentity = generatedTokenOwner?.userId === identity.userId
      && generatedTokenOwner?.tenantId === identity.tenantId;
    const expMs = decodeJwtExpMs(form.token);
    const staleGeneratedToken = usingGeneratedToken
      && expMs !== undefined
      && expMs - Date.now() <= TOKEN_REFRESH_BUFFER_MS;
    if (!form.token || (usingGeneratedToken && !generatedForCurrentIdentity) || staleGeneratedToken) {
      await generateToken();
    }
    scheduleTokenRefresh();
    return applyLoginIdentity();
  }

  async function logout(): Promise<void> {
    clearTokenRefresh();
    clearSavedSessionProfile();
    stopPlatformSignalBridge();
    await disposeOpenViewsAndEvents("logout");
    await client.logout();
    loggedIn.value = false;
    homeSyncReady.value = false;
    homeSyncing.value = false;
    resetMessageOpening();
    messageSyncing.value = false;
    conversationListViewId = "";
    activeTimelineView = null;
    homeSyncError.value = "";
    setHomeSyncProgress({
      step: "idle",
      title: translateFlare("sync.prepareTitle"),
      detail: translateFlare("sync.prepareDetail"),
      percent: 0,
    });
    try {
      connectionState.value = await client.connection.getConnectionState();
    } catch (error) {
      connectionState.value = "disconnected";
      log("connection_state_refresh_failed", `logout: ${errorMessage(error)}`);
    }
    log("logout", "session closed");
  }

  async function selectConversation(conversationId: string): Promise<void> {
    activeConversationId.value = conversationId;
    refreshDerivedState();
    await enterActiveConversation("select");
  }

  function localStateForMessage(
    message: Message,
    patch: Partial<NonNullable<Message["localState"]>>,
  ): NonNullable<Message["localState"]> {
    return {
      failed: false,
      isLocal: false,
      sending: false,
      sortTs: message.localState?.sortTs ?? message.clientCreatedAt ?? Date.now(),
      uploadProgress: 0,
      uploading: false,
      ...message.localState,
      ...patch,
    };
  }

  function patchMessageByClientId(
    clientMsgId: string,
    update: (message: Message) => Message,
  ): boolean {
    const id = clientMsgId.trim();
    if (!id) return false;
    let changed = false;
    messages.value = messages.value.map((item) => {
      if (item.clientMsgId !== id) return item;
      changed = true;
      return update(item);
    });
    return changed;
  }

  function localTimelineSortTs(message: Message): number {
    return message.timelineSortTs || message.clientCreatedAt || message.createdAt || Date.now();
  }

  function outgoingTimelineKey(message: Message): string {
    return message.timelineKey.trim()
      || (message.clientMsgId ? `client:${message.clientMsgId}` : "")
      || message.serverId.trim();
  }

  function patchConversationLastOutgoing(message: Message): void {
    const conversationId = message.conversationId.trim();
    if (!conversationId) return;
    const preview = message.textPreview.trim();
    const at = localTimelineSortTs(message);
    const lastMessageId = message.serverId.trim() || message.clientMsgId.trim();
    let changed = false;
    const patch = (item: Conversation): Conversation => {
      if (item.conversationId !== conversationId) return item;
      changed = true;
      return {
        ...item,
        draft: "",
        lastMessageAt: at,
        lastMessageId: lastMessageId || item.lastMessageId,
        lastMessagePreview: preview || item.lastMessagePreview,
        lastSenderId: message.senderId || currentUserId.value || item.lastSenderId,
        lastSenderNickname: message.senderDisplayName || message.senderName || item.lastSenderNickname,
        updatedAt: Math.max(Number(item.updatedAt) || 0, at),
        updatedAtTs: Math.max(Number(item.updatedAtTs ?? item.updatedAt) || 0, at),
      };
    };
    conversations.value = conversations.value.map(patch);
    if (activeConversation.value?.conversationId === conversationId) {
      activeConversation.value = patch(activeConversation.value);
    }
    if (changed) {
      refreshDerivedState();
    }
  }

  function upsertOutgoingMessageInActiveTimeline(
    message: Message,
    localStatePatch: Partial<NonNullable<Message["localState"]>>,
  ): void {
    const conversationId = message.conversationId.trim();
    if (!conversationId || conversationId !== activeConversationId.value.trim()) return;
    const timelineKey = outgoingTimelineKey(message);
    const timelineSortTs = localTimelineSortTs(message);
    const nextMessage: Message = {
      ...message,
      timelineKey,
      timelineSortTs,
      createdAt: message.createdAt || timelineSortTs,
      updatedAt: message.updatedAt || timelineSortTs,
      status: message.status > 0 ? message.status : 1,
      localState: localStateForMessage(
        { ...message, timelineKey, timelineSortTs },
        localStatePatch,
      ),
    };
    const clientMsgId = nextMessage.clientMsgId.trim();
    const serverId = nextMessage.serverId.trim();
    const existingIndex = messages.value.findIndex((item) =>
      (clientMsgId && item.clientMsgId === clientMsgId)
      || (timelineKey && item.timelineKey === timelineKey)
      || (serverId && item.serverId === serverId),
    );
    if (existingIndex >= 0) {
      const next = [...messages.value];
      next[existingIndex] = {
        ...next[existingIndex],
        ...nextMessage,
        localState: localStateForMessage(nextMessage, localStatePatch),
      };
      messages.value = next;
    } else {
      messages.value = [...messages.value, nextMessage];
    }
    patchConversationLastOutgoing(nextMessage);
  }

  function markMessageSending(message: Message): void {
    upsertOutgoingMessageInActiveTimeline(message, {
      failed: false,
      isLocal: true,
      sending: true,
      // 不要在这里写死 uploading: false。
      //
      // 带本地媒体的消息由**核心**置为 uploading 并按字节回填 upload_progress
      // （send_with_media 在上传前就落库并发总线）。这里一刀切成 false 会把核心的
      // 上传态盖掉，气泡上的进度覆盖层就永远不显示——线上实测 8MB 图片上传约 1.2s，
      // 核心存储里确实是 uploading:true，而 UI 全程 uploading:0。
      //
      // 保留消息自身的上传态：纯文本本来就没有，媒体则跟随核心。
      uploading: message.localState?.uploading ?? false,
      uploadProgress: message.localState?.uploadProgress ?? 0,
    });
  }

  function markMessageSent(message: Message, ack: SendMessageResponse): void {
    patchMessageByClientId(ack.clientMsgId || message.clientMsgId, (item) => ({
      ...item,
      serverId: ack.serverId || item.serverId,
      conversationSeq: ack.seq > 0 ? ack.seq : item.conversationSeq,
      updatedAt: ack.timestamp > 0 ? ack.timestamp : item.updatedAt,
      status: Math.max(item.status, 2),
      localState: localStateForMessage(item, {
        failed: false,
        isLocal: true,
        sending: false,
        uploading: false,
        uploadProgress: 100,
      }),
    }));
  }

  function markMessageFailed(message: Message): void {
    patchMessageByClientId(message.clientMsgId, (item) => ({
      ...item,
      localState: localStateForMessage(item, {
        failed: true,
        isLocal: true,
        sending: false,
        uploading: false,
      }),
    }));
  }

  async function sendBuiltMessage(message: Message, callback?: MessageSendCallback): Promise<void> {
    markMessageSending(message);
    activeOutgoingSends += 1;
    lastOutgoingSendAt = Date.now();
    try {
      await sendMessageWithTimeout(message, {
        onSuccess: ({ ack }) => {
          markMessageSent(message, ack);
          log("send_ack", `${ack.conversationId}#${ack.seq}`);
          callback?.onSuccess?.({ ack });
        },
        onFailure: (failure) => {
          markMessageFailed(message);
          log("send_failed", failure.reason);
          callback?.onFailure?.(failure);
        },
      });
    } catch (error) {
      markMessageFailed(message);
      throw error;
    } finally {
      activeOutgoingSends = Math.max(0, activeOutgoingSends - 1);
      lastOutgoingSendAt = Date.now();
    }
  }

  function conversationMentionUserIds(conversation: Conversation | null | undefined): string[] {
    if (!conversation) return [];
    const currentUserId = form.userId.trim();
    const ids = new Set<string>();
    const add = (value: unknown): void => {
      if (typeof value !== "string") return;
      const id = value.trim();
      if (!id || id === currentUserId) return;
      ids.add(id);
    };
    for (const participant of conversation.participants ?? []) add(participant.userId);
    for (const participant of conversation.memberPreview ?? []) add(participant.userId);
    const channel = conversation.channelId?.trim() ?? "";
    if (channel.startsWith("users:")) {
      for (const item of channel.slice("users:".length).split(/[,\s，、;；|]+/)) add(item);
    }
    return [...ids];
  }

  function inferMentionUsers(text: string, explicitMentionUsers: readonly string[] = []): string[] {
    const candidates = new Set(conversationMentionUserIds(activeConversation.value));
    const mentioned = new Set<string>();
    const addMention = (value: unknown): void => {
      if (typeof value !== "string") return;
      const id = value.trim();
      if (!id || !candidates.has(id)) return;
      mentioned.add(id);
    };
    for (const userId of explicitMentionUsers) addMention(userId);
    const matcher = /@([A-Za-z0-9_.-]+)/g;
    let match: RegExpExecArray | null;
    while ((match = matcher.exec(text)) !== null) {
      addMention(match[1]);
    }
    return [...mentioned];
  }

  async function sendText(text: string, mentionUsers: readonly string[] = []): Promise<void> {
    if (!activeConversationId.value) {
      throw new Error(translateFlare("error.openConversationBeforeSend"));
    }
    const conversationId = activeConversationId.value;
    const resolvedMentionUsers = inferMentionUsers(text, mentionUsers);
    try {
      const draft = await client.messageBuilder.buildText({
        conversationId,
        text,
        mentionUsers: resolvedMentionUsers,
        mentionAll: /(^|\s)@all(\s|$)/i.test(text),
      });
      await sendBuiltMessage(draft);
      void clearConversationDraft(conversationId).catch((error) => {
        log("draft_clear_failed", errorMessage(error));
      });
    } catch (error) {
      log("send_failed", errorMessage(error));
      throw error;
    }
  }

  async function sendTypedMessage(request: Omit<BuildAndSendMessageRequest, "conversationId"> & { conversationId?: string }): Promise<void> {
    const conversationId = request.conversationId ?? activeConversationId.value;
    if (!conversationId) return;
    const draft = await buildTypedMessage({
      conversationId,
      op: request.op,
      params: request.params ?? {},
      callback: request.callback,
    });
    await sendBuiltMessage(draft, request.callback);
    log("send_message", draft.clientMsgId || draft.serverId || conversationId);
  }

  async function buildAndSendMessage(op = sdkLab.buildOp, overrides: Record<string, unknown> = {}): Promise<void> {
    if (!activeConversationId.value) {
      throw new Error(translateFlare("error.openConversationBeforeSend"));
    }
    const conversationId = activeConversationId.value;
    const params = {
      text: sdkLab.messageText,
      emoji: sdkLab.messageText || sdkLab.reaction,
      ...parseJsonParams(sdkLab.jsonParams),
      ...overrides,
    };
    try {
      const draft = await buildTypedMessage({
        op,
        conversationId,
        params,
      });
      await sendBuiltMessage(draft);
      void clearConversationDraft(conversationId).catch((error) => {
        log("draft_clear_failed", errorMessage(error));
      });
      log("send_message", draft.clientMsgId || draft.serverId || conversationId);
    } catch (error) {
      throw error;
    }
  }

  async function buildFromComposerAction(op: string, composerText = ""): Promise<void> {
    if (op === "create_text") {
      await sendText(composerText || sdkLab.messageText);
      return;
    }
    await buildAndSendMessage(op, { text: composerText || sdkLab.messageText });
  }

  async function resendFailedMessage(clientMsgId: string): Promise<void> {
    const message = messages.value.find((item) => item.clientMsgId === clientMsgId);
    if (!message) return;
    await sendBuiltMessage(message);
  }

  async function forwardMessagesToConversation(request: {
    conversationId: string;
    messageIds: string[];
    merge?: boolean;
    title?: string;
  }): Promise<Message> {
    // 必须传完整消息而不是 id 存根：转发的载荷要把原文内容嵌进去，核心侧的
    // forward_item_from_source 会读 content / senderId / conversationId。
    // 早先按契约传 { sourceMessageId }，反序列化成 IMMessage 时缺必填字段直接
    // INVALID_PARAMETER，转发每次都失败——契约本身写错了，已在 spec 侧改为
    // MessageList。
    const sources = request.messageIds.map((messageId) => {
      const found = messages.value.find((row) => messageMatchesId(row, messageId));
      if (!found) {
        throw new Error(translateFlare("error.forwardSourceMissing", { id: messageId }));
      }
      return found;
    });
    const draft = await client.messageBuilder.buildForward({
      conversationId: request.conversationId,
      sourceMessages: sources,
      merge: request.merge ?? false,
      title: request.title ?? "",
    });
    await sendBuiltMessage(draft);
    return draft;
  }

  async function sendEmoji(emoji: string): Promise<void> {
    await buildAndSendMessage("create_emoji", { emoji });
  }

  async function sendSticker(sticker: string | {
    stickerId: string;
    packageId?: string;
    url?: string;
    width?: number;
    height?: number;
    stickerFormat?: string;
    format?: string;
  }): Promise<void> {
    const payload = typeof sticker === "string" ? { stickerId: sticker } : sticker;
    await buildAndSendMessage("create_sticker", payload);
  }

  async function addReaction(messageId: string, emoji: string): Promise<void> {
    const conversationId = activeConversationId.value.trim();
    const target = messages.value.find((message) => messageMatchesId(message, messageId));
    if (!conversationId || !messageId || !emoji) return;
    const wireMessageId = target?.serverId?.trim() || messageId;
    const clientMsgId = target?.clientMsgId?.trim() || messageId;
    await client.messages.addReaction({
      conversationId,
      messageId: wireMessageId,
      clientMsgId,
      emoji,
    });
    patchLocalReaction(messageId, emoji, currentUserId.value.trim(), 1);
  }

  async function removeReaction(messageId: string, emoji: string): Promise<void> {
    const conversationId = activeConversationId.value.trim();
    const target = messages.value.find((message) => messageMatchesId(message, messageId));
    if (!conversationId || !messageId || !emoji) return;
    const wireMessageId = target?.serverId?.trim() || messageId;
    const clientMsgId = target?.clientMsgId?.trim() || messageId;
    await client.messages.removeReaction({
      conversationId,
      messageId: wireMessageId,
      clientMsgId,
      emoji,
    });
    patchLocalReaction(messageId, emoji, currentUserId.value.trim(), 2);
  }

  async function toggleReaction(messageId: string, emoji: string): Promise<void> {
    const userId = currentUserId.value.trim();
    const target = messages.value.find((message) => messageMatchesId(message, messageId));
    const active = target?.reactions?.some((reaction) =>
      reaction.emoji === emoji && (reaction.userIds ?? []).includes(userId),
    );
    if (active) {
      await removeReaction(messageId, emoji);
      return;
    }
    await addReaction(messageId, emoji);
  }

  async function saveActiveDraft(draft: string): Promise<void> {
    if (!activeConversationId.value) return;
    await clearConversationDraft(activeConversationId.value, draft);
  }

  function patchConversationDraft(conversationId: string, draft: string): void {
    const targetId = conversationId.trim();
    if (!targetId) return;
    let changed = false;
    conversations.value = conversations.value.map((item) => {
      if (item.conversationId !== targetId || item.draft === draft) return item;
      changed = true;
      return { ...item, draft };
    });
    if (activeConversation.value?.conversationId === targetId && activeConversation.value.draft !== draft) {
      activeConversation.value = { ...activeConversation.value, draft };
      changed = true;
    }
    if (changed) {
      refreshDerivedState();
    }
  }

  async function clearConversationDraft(conversationId: string, draft = ""): Promise<void> {
    if (!conversationId) return;
    patchConversationDraft(conversationId, draft);
    const retryDelays = [180, 420, 900] as const;
    for (let attempt = 0; attempt <= retryDelays.length; attempt += 1) {
      try {
        await client.conversations.updateConversationDraft({ conversationId, draft });
        patchConversationDraft(conversationId, draft);
        return;
      } catch (error) {
        const delay = retryDelays[attempt];
        if (!isDatabaseLockedError(error) || delay === undefined) {
          if (!draft && isTimeoutError(error)) return;
          log("draft_clear_failed", errorMessage(error));
          return;
        }
        await wait(delay);
      }
    }
  }

  async function sendTyping(typing = true): Promise<void> {
    if (!activeConversationId.value) return;
    if (connectionState.value !== "ready" && connectionState.value !== "connected") return;
    try {
      await client.messages.setTyping({ conversationId: activeConversationId.value, typing });
    } catch (error) {
      const detail = errorMessage(error);
      if (/OPERATION_TIMEOUT|NOT_CONNECTED|CLOSING|CLOSED|typing|realtime control/i.test(detail)) {
        if (/NOT_CONNECTED|CLOSING|CLOSED/i.test(detail)) {
          connectionState.value = "reconnecting";
        }
        return;
      }
      throw error;
    }
  }

  async function searchActiveMessages(
    keyword: string,
    kinds: readonly MessageSearchKind[],
  ): Promise<void> {
    const query = keyword.trim();
    if (!query) {
      messageSearchResults.value = [];
      return;
    }
    messageSearchResults.value = [...await searchMessages({
      conversationId: activeConversationId.value,
      keyword: query,
      kinds: [...kinds],
      limit: 50,
      includeRecalled: false,
    })];
  }

  async function editMessageText(messageId: string, text: string): Promise<void> {
    const targetId = messageId.trim();
    const nextText = text.trim();
    if (!targetId || !nextText) return;
    try {
      await client.messages.editTextByMessageId({
        messageId: targetId,
        text: nextText,
      });
    } catch (error) {
      log("edit.failed", errorMessage(error));
      throw error;
    }
  }

  async function setMessagePinned(
    messageId: string,
    pinned: boolean,
    options: { scope?: "conversation" | "self" } = {},
  ): Promise<void> {
    const targetId = messageId.trim();
    if (!targetId) return;
    const request = {
      messageId: targetId,
      scope: options.scope === "self" ? 1 : 0,
    };
    const call = pinned
      ? client.messages.pinMessageById(request)
      : client.messages.unpinMessageById(request);
    try {
      await call;
    } catch (error) {
      log(pinned ? "pin.failed" : "unpin.failed", errorMessage(error));
      throw error;
    }
  }

  async function deleteMessageForSelf(messageId: string): Promise<void> {
    const targetId = messageId.trim();
    if (!targetId) return;
    try {
      await client.messages.deleteMessageForSelf({
        messageId: targetId,
      });
      removeMessageById(targetId);
    } catch (error) {
      log("delete.failed", errorMessage(error));
      throw error;
    }
  }

  async function recallMessageById(messageId: string): Promise<void> {
    const targetId = messageId.trim();
    if (!targetId) return;
    try {
      await client.messages.recallMessage({
        messageId: targetId,
      });
    } catch (error) {
      log("recall.failed", errorMessage(error));
      throw error;
    }
  }

  async function runDispatch(op = sdkLab.dispatchOp): Promise<void> {
    // 走 runLab：此前这里既不捕获异常也不管 labBusy，dispatchMessage 一旦 reject，
    // labResult 的赋值根本不会发生，异常直接冲出点击处理器变成 unhandled rejection。
    // 界面上于是完全没有反馈——结果面板停在上一次的输出，既没有报错也没有 loading，
    // 看起来就像"按钮没反应"。消息右键菜单里的标记等操作同样经由这里，一并失声。
    await runLab("message.dispatch", async () => {
      const messageIdValue = sdkLab.messageId || activeLatestMessageId.value;
      const params = buildMessageDispatchParams({
        conversationId: activeConversationId.value,
        messageId: messageIdValue,
        text: sdkLab.messageText,
        keyword: sdkLab.query,
        emoji: sdkLab.reaction,
        jsonParams: parseJsonParams(sdkLab.jsonParams),
      });
      const result = await dispatchMessage(op, params);
      if (shouldRefreshTimelineAfterDispatch(op)) {
        await refreshActiveChat();
      }
      return result as Record<string, unknown>;
    });
  }

  async function syncActiveConversation(): Promise<void> {
    conversationSyncing.value = true;
    conversationSyncError.value = "";
    try {
      if (activeConversationId.value) {
        await client.sync.syncConversation({ conversationId: activeConversationId.value });
        await syncMessagesFromKnownCursor(activeConversationId.value);
      }
      await refreshActiveChat();
      log("sync", activeConversationId.value || "all");
    } catch (error) {
      conversationSyncError.value = errorMessage(error);
      log("sync_failed", conversationSyncError.value);
      throw error;
    } finally {
      conversationSyncing.value = false;
    }
  }

  async function refreshActiveChat(): Promise<void> {
    await refreshConversations();
    await refreshMessages();
  }

  async function deleteActiveConversation(): Promise<boolean> {
    const conversationId = activeConversationId.value;
    if (!conversationId) return false;
    await client.conversations.deleteConversation({ conversationId });
    activeConversationId.value = "";
    resetMessageOpening();
    refreshDerivedState();
    messages.value = [];
    await refreshConversations();
    return true;
  }

  async function syncConversationsFromServer(): Promise<void> {
    conversationSyncing.value = true;
    conversationSyncError.value = "";
    try {
      await syncConversationSummaries();
      await refreshConversations();
      await backfillVisibleConversationHistories("manual_sync");
      if (activeConversationId.value) {
        await client.sync.syncConversation({ conversationId: activeConversationId.value });
        await syncMessagesFromKnownCursor(activeConversationId.value);
        await refreshMessages();
      }
      log("sync_conversations", activeConversationId.value || "list");
    } catch (error) {
      conversationSyncError.value = errorMessage(error);
      log("sync_failed", conversationSyncError.value);
      throw error;
    } finally {
      conversationSyncing.value = false;
    }
  }

  async function runConversationOperation(kind: string): Promise<void> {
    const conversationId = activeConversationId.value;
    if (kind === "mark_unread") {
      await client.conversations.markConversationUnread({ conversationId });
    } else if (kind === "mark_read") {
      await markConversationRead(conversationId);
    } else if (kind === "pin" || kind === "unpin") {
      await client.conversations.setConversationPinned({ conversationId, pinned: kind === "pin" });
    } else if (kind === "mute" || kind === "unmute") {
      await client.conversations.setConversationMuted({ conversationId, muted: kind === "mute" });
    } else if (kind === "archive" || kind === "unarchive") {
      await client.conversations.setConversationArchived({ conversationId, archived: kind === "archive" });
    } else if (kind === "clear_history") {
      await client.conversations.clearLocalChatHistory({ conversationId });
    } else if (kind === "draft") {
      await client.conversations.updateConversationDraft({ conversationId, draft: sdkLab.draft });
    } else if (kind === "delete") {
      await deleteActiveConversation();
    } else {
      labResult.value = { conversations: await listConversations() };
    }
    await refreshConversations();
    if (activeConversationId.value) {
      await refreshMessages();
    }
  }

  async function runSyncOperation(kind: string): Promise<void> {
    if (kind === "read") {
      await markConversationRead(activeConversationId.value);
    } else if (kind === "messages") {
      messageSyncing.value = true;
      messageSyncError.value = "";
      try {
        await syncMessagesFromKnownCursor(activeConversationId.value);
      } catch (error) {
        messageSyncError.value = errorMessage(error);
        log("message_sync_failed", messageSyncError.value);
        throw error;
      } finally {
        messageSyncing.value = false;
      }
    } else {
      await client.sync.syncConversation({ conversationId: activeConversationId.value });
    }
    await refreshConversations();
    await refreshMessages();
  }

  async function runPresenceOperation(kind: string): Promise<void> {
    await runLab(`presence.${kind}`, async () => {
      const userIds = sdkLab.userIds.split(",").map((item) => item.trim()).filter(Boolean);
      if (kind === "get") {
        return await client.presence.getUserPresence({ userId: userIds[0] ?? form.userId });
      }
      if (kind === "subscribe") {
        await client.presence.subscribeUserPresence({ userIds });
        return { subscribed: userIds };
      }
      return await client.presence.batchGetUserPresence({ userIds });
    });
  }

  async function runMediaOperation(kind: string): Promise<void> {
    await runLab(`media.${kind}`, async () => {
      const params = parseJsonParams(sdkLab.jsonParams);
      if (kind === "clear") {
        await client.media.clearMediaCache();
        return { cleared: true };
      }
      if (kind === "upload_file" || kind === "upload_image" || kind === "upload_video") {
        const payload = {
          path: sdkLab.sourcePath,
          fileId: sdkLab.fileId,
          fileName: sdkLab.displayFileName,
          ...params,
        };
        if (kind === "upload_image") return await client.media.uploadImage(payload);
        if (kind === "upload_video") return await client.media.uploadVideo(payload);
        return await client.media.uploadFile(payload);
      }
      if (kind === "upload_bytes") {
        const bytes = new TextEncoder().encode(`Flare Web SDK Lab ${new Date().toISOString()}`);
        return await client.media.uploadBytes({
          bytes: Array.from(bytes),
          fileName: sdkLab.displayFileName,
          mimeType: "text/plain",
          ...params,
        });
      }
      if (kind === "delete_file") {
        return await client.media.deleteFile({
          fileId: sdkLab.fileId,
          hardDelete: Boolean(params.hardDelete),
          ...params,
        });
      }
      if (kind === "url") {
        return await client.media.getMediaUrl({ fileId: sdkLab.fileId, mediaUrl: sdkLab.mediaUrl });
      }
      if (kind === "temp_url") {
        return await client.media.getTempDownloadUrl({ fileId: sdkLab.fileId, expiresInSeconds: 900 });
      }
      if (kind === "resolve") {
        return await client.media.resolveMediaAccess({ fileId: sdkLab.fileId, mediaUrl: sdkLab.mediaUrl });
      }
      if (kind === "cache_remote") {
        return await client.media.cacheRemoteMedia({ fileId: sdkLab.fileId, mediaUrl: sdkLab.mediaUrl });
      }
      if (kind === "display_url") {
        return {
          displayUrl: await client.media.resolveDisplayUrl({ fileId: sdkLab.fileId, mediaUrl: sdkLab.mediaUrl }),
        };
      }
      if (kind === "set_root") {
        await client.media.setMediaCacheRoot({ root: sdkLab.mediaCacheRoot });
        return { cacheRoot: sdkLab.mediaCacheRoot };
      }
      if (kind === "set_max") {
        await client.media.setMediaCacheMaxBytes({ maxBytes: sdkLab.mediaCacheMaxBytes });
        return { maxBytes: sdkLab.mediaCacheMaxBytes };
      }
      if (kind === "download_subfolder") {
        await client.media.setUserDownloadSubfolder({ subfolder: sdkLab.downloadSubfolder });
        return await client.media.getUserDownloadSubfolder();
      }
      if (kind === "saved_path") {
        return await client.media.getUserDownloadSavedPath({ downloadKey: sdkLab.downloadKey, fileId: sdkLab.fileId });
      }
      if (kind === "delete_download") {
        await client.media.deleteUserDownloadRecord({ downloadKey: sdkLab.downloadKey, fileId: sdkLab.fileId });
        return { deleted: sdkLab.downloadKey || sdkLab.fileId };
      }
      if (kind === "cancel_download") {
        const cancelled = await client.media.cancelUserFileDownload({ downloadKey: sdkLab.downloadKey, fileId: sdkLab.fileId });
        return { cancelled };
      }
      if (kind === "download_file") {
        return await client.media.downloadFileToDownloads({
          downloadKey: sdkLab.downloadKey,
          fileId: sdkLab.fileId,
          displayFileName: sdkLab.displayFileName,
          sourcePath: sdkLab.sourcePath || undefined,
          sourceHttpUrl: sdkLab.sourceUrl || undefined,
          remoteFileId: sdkLab.remoteFileId || sdkLab.fileId || undefined,
          expiresIn: 900,
        });
      }
      if (kind === "stats") {
        return await client.media.getMediaCacheStats();
      }
      throw new FlareSdkException(
        "invalidParameter",
        `unsupported media operation: ${kind}`,
        "media.lab",
        { kind },
      );
    });
  }

  async function runCapabilityOperation(kind: string): Promise<void> {
    await runLab(`capability.${kind}`, async () => {
      if (kind === "list") {
        return await client.capabilities.listCapabilities({});
      }
      if (kind === "list_user") {
        return await client.capabilities.listUserCapabilities({ userId: form.userId });
      }
      if (kind === "grant") {
        await client.capabilities.grantCapability({
          userId: sdkLab.capabilityTargetUserId,
          capability: sdkLab.capability,
          payload: parseJsonParams(sdkLab.jsonParams),
        });
        return { granted: sdkLab.capability, userId: sdkLab.capabilityTargetUserId };
      }
      if (kind === "revoke") {
        await client.capabilities.revokeCapability({
          userId: sdkLab.capabilityTargetUserId,
          capability: sdkLab.capability,
          payload: parseJsonParams(sdkLab.jsonParams),
        });
        return { revoked: sdkLab.capability, userId: sdkLab.capabilityTargetUserId };
      }
      if (kind === "call_signal") {
        await client.capabilities.sendCallSignal({
          conversationId: activeConversationId.value,
          signalType: "offer",
          payload: { source: "web-wasm" },
        });
        return { sent: true, capability: sdkLab.capability };
      }
      return await client.capabilities.dispatchCapability({
        operation: "web.echo",
        capability: sdkLab.capability,
        payload: parseJsonParams(sdkLab.jsonParams),
      });
    });
  }

  async function runConnectionOperation(kind: string): Promise<void> {
    await runLab(`connection.${kind}`, async () => {
      if (kind === "state") {
        const state = await client.connection.getConnectionState();
        connectionState.value = state;
        return { state };
      }
      if (kind === "disconnect") {
        await client.connection.disconnect();
        await refreshConnectionStateSafely("lab.disconnect");
        return { disconnected: true, state: connectionState.value };
      }
      if (kind === "network_change") {
        const response = await client.connection.notifyNetworkChange({
          available: sdkLab.networkAvailable,
          interface: sdkLab.networkInterface,
          expensive: sdkLab.networkExpensive,
          metered: sdkLab.networkMetered,
          reason: "web-sdk-lab",
        });
        await refreshConnectionStateSafely("lab.network_change");
        return { ...response, state: connectionState.value };
      }
      return { state: await client.connection.getConnectionState() };
    });
  }

  async function runSessionOperation(kind: string): Promise<void> {
    await runLab(`session.${kind}`, async () => {
      if (kind === "runtime_health") {
        return { ...await client.diagnostics.getRuntimeHealth() };
      }
      if (kind === "heartbeat_interval") {
        return { ...await client.heartbeatEffectiveInterval() };
      }
      if (kind === "heartbeat_app_state") {
        await client.setHeartbeatAppState({
          appState: sdkLab.heartbeatAppState === "background"
            ? HeartbeatAppState.Background
            : HeartbeatAppState.Foreground,
        });
        return { ...await client.heartbeatEffectiveInterval() };
      }
      if (kind === "heartbeat_nat_timeout") {
        await client.setHeartbeatNatTimeout({
          natTimeoutSecs: sdkLab.heartbeatNatTimeoutSecs > 0 ? sdkLab.heartbeatNatTimeoutSecs : undefined,
        });
        return { ...await client.heartbeatEffectiveInterval() };
      }
      if (kind === "update_access_token") {
        const response = await client.generateCoreToken({
          ...devCoreTokenRequest(env, form.userId, form.tenantId),
          ttlSecs: sdkLab.tokenTtlSecs,
        });
        const accessToken = String(response.token ?? "").trim();
        await client.updateAccessToken({ accessToken, tenantId: form.tenantId });
        form.token = accessToken;
        return { updated: true, tokenLength: accessToken.length, ttlSecs: sdkLab.tokenTtlSecs };
      }
      if (kind === "current_user") {
        return await client.currentUserId();
      }
      if (kind === "session_active") {
        return {
          active: await client.sessionActive(),
          connected: await client.isConnected(),
        };
      }
      if (kind === "prepare") {
        // sdk.prepare：登录前预热（已 init 后可单独触发；LoginRequest = { userId, token }）。
        const prepareUserId = (currentUserId.value || form.userId).trim();
        await client.prepare({
          userId: prepareUserId,
          token: String(form.token ?? "").trim(),
        });
        return { prepared: true, userId: prepareUserId };
      }
      if (kind === "uninit") {
        // sdk.uninit：释放底层 runtime（破坏性，需重新 init/login）。
        await client.uninit();
        initialized.value = false;
        loggedIn.value = false;
        return { uninit: true };
      }
      if (kind === "hard_reset") {
        // sdk.hard_reset：进程级硬重置（清空本地状态）。
        await client.hardReset();
        initialized.value = false;
        loggedIn.value = false;
        return { hardReset: true };
      }
      if (kind === "send_no_oss") {
        // message.send_no_oss：不走 OSS 上传的直发（文本探针）。
        if (!activeConversationId.value) {
          throw new Error(translateFlare("error.openConversationBeforeSend"));
        }
        const draft = await client.messageBuilder.buildText({
          conversationId: activeConversationId.value,
          text: "send_no_oss lab probe",
        });
        const ack = await client.messages.sendMessageNoOss({ message: draft });
        return { sentNoOss: true, ack };
      }
      return await refreshCoreDiagnostics();
    });
  }

  async function runEventOperation(): Promise<void> {
    await runLab("events.subscribe", async () => await client.events.subscribeEvents({
      sources: [...sdkEventSources],
    }) as unknown as Record<string, unknown>);
  }

  async function openPeerConversation(conversationType: "single" | "group" = "single", peerUserId?: string): Promise<void> {
    const resolvedPeer = (peerUserId ?? sdkLab.peerUserId).trim();
    if (!resolvedPeer) return;
    sdkLab.peerUserId = resolvedPeer;
    const conversation = conversationType === "group"
      ? await openGroupConversationRaw(parseGroupMemberIds(resolvedPeer))
      : await openPeerConversationRaw(resolvedPeer);
    activeConversationId.value = conversation.conversationId;
    await refreshConversations();
    await openTimelineView(conversation.conversationId, "open_peer");
    refreshDerivedState();
  }

  let disposeSessionBridge: (() => void) | undefined;
  if (appClient) {
    disposeSessionBridge = bindFlareSessionEvents({
      appClient,
      events,
      connectionState,
      loggedIn,
      onIncomingMessage: handleIncomingMessageNotification,
      onPresenceChanged: applyPresenceChanged,
      onReactionChanged: applyReactionChanged,
      onViewUpdated: handleViewUpdate,
      onCapabilityChanged: handleCapabilityDesktopNotification,
    });
  }

  startRealtimeSafetyPoll();

  onBeforeUnmount(() => {
    clearTokenRefresh();
    if (incomingConversationRefreshTimer !== undefined) {
      clearTimeout(incomingConversationRefreshTimer);
      incomingConversationRefreshTimer = undefined;
    }
    if (activeConversationRefreshTimer !== undefined) {
      clearTimeout(activeConversationRefreshTimer);
      activeConversationRefreshTimer = undefined;
    }
    if (realtimeSafetyPollTimer) {
      clearInterval(realtimeSafetyPollTimer);
      realtimeSafetyPollTimer = undefined;
    }
    disposeSessionBridge?.();
    stopPlatformSignalBridge();
    resetMessageOpening();
    if (markReadTimer) {
      clearTimeout(markReadTimer);
      markReadTimer = undefined;
    }
    void (async () => {
      await disposeOpenViewsAndEvents("unmount");
      await appClient?.dispose();
    })().catch((error) => {
      log("sdk_dispose_failed", errorMessage(error));
    });
  });

  return {
    appClient,
    client: client as FlareImClient,
    form,
    conversationFilters,
    initialized: readonly(initialized),
    loggedIn: readonly(loggedIn),
    busy: readonly(busy),
    connectionState: readonly(connectionState),
    currentUserId: readonly(currentUserId),
    sessionActive: readonly(sessionActive),
    isConnected: readonly(isConnected),
    homeSyncing: readonly(homeSyncing),
    homeSyncReady: readonly(homeSyncReady),
    homeSyncError: readonly(homeSyncError),
    homeSyncProgress: readonly(homeSyncProgress),
    sdkRuntimeStatus: readonly(sdkRuntimeStatus),
    transportFallbackNotice: readonly(transportFallbackNotice),
    activeConversationId: readonly(activeConversationId),
    activeConversation,
    peerPresence: readonly(peerPresence),
    conversations: readonly(conversations),
    messages: readonly(messages),
    messageSearchResults: readonly(messageSearchResults),
    pinnedMessages: readonly(pinnedMessages),
    messageBuildCatalog: readonly(messageBuildCatalog),
    messageBuildOptions,
    messageDispatchOptions,
    diagnostics: readonly(diagnostics),
    events: readonly(events),
    conversationSyncing: readonly(conversationSyncing),
    conversationSyncError: readonly(conversationSyncError),
    messageSyncing: readonly(messageSyncing),
    messageOpening: readonly(messageOpening),
    messageSyncError: readonly(messageSyncError),
    messageHasMore: readonly(messageHasMore),
    loadingOlderMessages: readonly(loadingOlderMessages),
    sdkLab,
    labBusy: readonly(labBusy),
    labResult: readonly(labResult),
    totalUnread: readonly(totalUnread),
    activeLatestMessageId: readonly(activeLatestMessageId),
    initializeAndLogin,
    resumeSavedSession,
    hasSavedSession,
    syncHomeBeforeEnter,
    generateToken,
    upsertUserProfiles,
    logout,
    selectConversation,
    setConversationFilter,
    sendText,
    sendTypedMessage,
    buildAndSendMessage,
    buildFromComposerAction,
    resendFailedMessage,
    forwardMessagesToConversation,
    sendEmoji,
    sendSticker,
    addReaction,
    removeReaction,
    toggleReaction,
    editMessageText,
    setMessagePinned,
    deleteMessageForSelf,
    recallMessageById,
    saveActiveDraft,
    clearConversationDraft,
    sendTyping,
    activeConversationTypingUsers,
    searchActiveMessages,
    runDispatch,
    syncActiveConversation,
    syncConversationsFromServer,
    refreshActiveChat,
    enterActiveConversation,
    setActiveTimelineAtBottom,
    loadOlderMessages,
    searchConversationsWithKeyword,
    refreshActivePeerPresence,
    deleteActiveConversation,
    runSessionDiagnostics,
    openPeerConversation,
    runConversationOperation,
    runSyncOperation,
    runPresenceOperation,
    runMediaOperation,
    runCapabilityOperation,
    runConnectionOperation,
    runSessionOperation,
    runEventOperation,
    contentTypes: MessageContentType,
  };
}
