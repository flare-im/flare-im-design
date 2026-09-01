import { readFileSync } from "node:fs";

import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import { NativeCallMap } from "@flare-im/sdk/contract";
import { ConversationType, MessageContentType, type Message, type MessageContent, type MessageLocalState } from "@flare-im/sdk/web";
import {
  buildMessageMenuDropdownOptions,
  buildMessageMenuSheetItems,
  buildMediaResolveRequest,
  configureMediaProxy,
  countAppendedItems,
  countPrependedItems,
  displayTextFromStoredPreview,
  hasRenderableMessageContent,
  isChromelessCardBubble,
  isChromelessMediaBubble,
  isStickerPlayAnimatedFromExtra,
  isMarkdown,
  listMessageMediaDownloadSources,
  markdownToPlainText,
  messageStateToNumber,
  normalizeMessageRowsForVirtualList,
  proxiedMediaUrl,
  previewVisualFromStoredPreview,
  previewTextFromMessageContent,
  renderMarkdown,
  restorePrependScrollTop,
  resolveMessageMenuAction,
} from "@flare-im/vue-ui/utils";
import { flareMessages, listI18nKeys } from "@flare-im/vue-ui/i18n";
import { buildFlareThemeStylesheet } from "@flare-im/vue-ui/theme";
import {
  bindFlareSessionEvents,
  flareSessionBridgeTesting,
  mapSdkError,
  reportSdkError,
} from "@flare-im/vue-ui/composables/sdk";
import { resolveWasmBindingAssetUrl } from "../../infrastructure/sdk/wasmLoader";
import {
  createMessageOperationAdapter,
} from "../../message-enhancements/messageOperations";
import {
  composerActions,
  resolveComposerAction,
  resolveMessageCapabilities,
  resolveMessageMenuActions,
} from "../../message-enhancements/messageTypeRegistry";
import type { MessageOperationSdk } from "../../message-enhancements/types";
import {
  isBestEffortControlOperationForTesting,
  mapWasmEventForTesting,
  encodeWasmRequestForTesting,
  WebProductionBridge,
} from "@flare-im/sdk/web";
import { createAppMediaResolver } from "../../infrastructure/media/appMediaResolver";
import {
  buildLoginTransportConfig,
  buildMessageDispatchParams,
  DEFAULT_MARK_COLOR,
  MARK_TYPE_IMPORTANT,
  desktopNotificationBodyForMessage,
  isRecoverableLoginTransportError,
  loginTransportDisplayName,
  loginTransportFallbackMessage,
  normalizeLoginTransportMode,
  normalizeLoginIdentityForSdk,
  presenceStatusFromCoreDto,
  readLoginEnvText,
  shouldRefreshTimelineAfterDispatch,
  useFlareCoreClient,
  // SDK 绑定层走独立子路径 —— 它们不在 `./composables` 主 barrel 上，
  // 否则会把 `@flare-im/sdk`（optional peer）拖进每个消费方的构建图。
} from "@flare-im/vue-ui/composables/sdk";
import { withTimeout } from "@flare-im/vue-ui/utils";
import { conversationTitle } from "../conversationTitle";

function messageFixture(overrides: Partial<Message> = {}): Message {
  return {
    attributes: {},
    channelId: "bob",
    clientCreatedAt: 200,
    clientMsgId: "client-1",
    conversationId: "conv-1",
    conversationSeq: 11,
    conversationType: 1,
    createdAt: 200,
    extensions: {},
    isEdited: false,
    isRead: false,
    isRecalled: false,
    mentionAll: false,
    mentionUsers: [],
    messageType: 1,
    reactions: [],
    senderAvatar: "",
    senderDisplayName: "hugo",
    senderId: "hugo",
    senderName: "hugo",
    serverId: "server-1",
    source: 1,
    status: 2,
    textPreview: "hello",
    timelineKey: "11:server-1",
    timelineSortTs: 200,
    updatedAt: 200,
    version: 1,
    ...overrides,
  };
}

function localState(
  overrides: Partial<MessageLocalState> = {},
): MessageLocalState {
  return {
    sending: false,
    failed: false,
    isLocal: false,
    uploading: false,
    uploadProgress: 0,
    sortTs: 0,
    ...overrides,
  };
}

describe("presenceStatusFromCoreDto", () => {
  it("uses the Core SDK camelCase presence contract", () => {
    expect(presenceStatusFromCoreDto({ userId: "bob", isOnline: true, status: "online" })).toBe("online");
    expect(presenceStatusFromCoreDto({ userId: "bob", isOnline: true, status: "" })).toBe("online");
    expect(presenceStatusFromCoreDto({ userId: "bob", isOnline: false, status: "" })).toBe("offline");
    expect(presenceStatusFromCoreDto({ userId: "bob", is_online: true })).toBe("offline");
  });
});

describe("desktop notification summaries", () => {
  it("shows only the message type instead of raw preview content", () => {
    expect(desktopNotificationBodyForMessage(messageFixture({
      textPreview: "hello from the actual message",
      content: {
        contentType: MessageContentType.Text,
        data: { text: "hello from the actual message" },
      },
    }))).toBe("发送了一条文本消息");

    expect(desktopNotificationBodyForMessage(messageFixture({
      textPreview: "{\"k\":\"im.preview.user_text\",\"a\":{\"t\":\"1111\"}}",
      content: undefined,
    }))).toBe("发送了一条文本消息");

    expect(desktopNotificationBodyForMessage(messageFixture({
      textPreview: "{\"k\":\"im.preview.image\",\"a\":{\"d\":\"private image title\"}}",
      content: undefined,
    }))).toBe("发送了一张图片");

    expect(desktopNotificationBodyForMessage(messageFixture({
      textPreview: "quarterly-report.pdf",
      content: {
        contentType: MessageContentType.File,
        data: { fileName: "quarterly-report.pdf" },
      },
    }))).toBe("发送了一个文件");
  });
});

describe("login transport selection", () => {
  it("maps login protocol choices to the typed SDK transport config", () => {
    expect(normalizeLoginTransportMode("quic")).toBe("quic");
    expect(normalizeLoginTransportMode("protocol_race")).toBe("race");
    expect(normalizeLoginTransportMode("unknown")).toBe("websocket");
    expect(loginTransportDisplayName("websocket")).toBe("WebSocket");
    expect(loginTransportDisplayName("quic")).toBe("QUIC");
    expect(loginTransportDisplayName("race")).toBe("QUIC → WebSocket");

    expect(buildLoginTransportConfig({
      transportMode: "websocket",
      wsUrl: " ws://127.0.0.1:60051/ws ",
      quicUrl: "quic://127.0.0.1:60052",
      tlsCaCertPath: "",
    })).toEqual({
      wsUrl: "ws://127.0.0.1:60051/ws",
      transportPolicy: "websocket_only",
      defaultTransport: "websocket",
    });

    expect(buildLoginTransportConfig({
      transportMode: "quic",
      wsUrl: "ws://127.0.0.1:60051/ws",
      quicUrl: " quic://127.0.0.1:60052 ",
      tlsCaCertPath: " /tmp/flare-server.crt ",
    })).toEqual({
      wsUrl: "ws://127.0.0.1:60051/ws",
      quicUrl: "quic://127.0.0.1:60052",
      tlsCaCertPath: "/tmp/flare-server.crt",
      transportPolicy: "auto",
      defaultTransport: "quic",
      protocolRaceOrder: ["quic"],
    });

    expect(buildLoginTransportConfig({
      transportMode: "race",
      wsUrl: "ws://127.0.0.1:60051/ws",
      quicUrl: "quic://127.0.0.1:60052",
      tlsCaCertPath: "",
    })).toEqual({
      wsUrl: "ws://127.0.0.1:60051/ws",
      quicUrl: "quic://127.0.0.1:60052",
      transportPolicy: "protocol_race",
      defaultTransport: "quic",
      protocolRaceOrder: ["quic", "websocket"],
    });
  });

  it("keeps native protocol choices behind an app-level opt-in instead of exposing them on web by default", () => {
    const appIndex = readFileSync(new URL("../../index.ts", import.meta.url), "utf8");
    const loginViewSource = readFileSync(new URL("../../components/FlareLoginScreen.vue", import.meta.url), "utf8");
    const authSource = readFileSync(new URL("../../../components/shell/FlareAuthScreen.vue", import.meta.url), "utf8");

    expect(appIndex).toContain("configureAppTransportSelector");
    expect(appIndex).toContain("appTransportSelectorTlsCaCertPath");
    expect(appIndex).toContain("isAppTransportSelectorEnabled");
    expect(loginViewSource).toContain("isAppTransportSelectorEnabled()");
    expect(loginViewSource).toContain("show-transport-selector");
    expect(authSource).toContain("showTransportSelector");
    expect(authSource).toContain('v-if="showTransportSelector"');
    expect(authSource).toContain("NSelect");
    expect(authSource).toContain("transportOptions");
    expect(authSource).toContain("show-on-focus");
    expect(authSource).toContain("update:transportMode");
    expect(authSource).toContain("update:quicUrl");
    expect(authSource).toContain("update:tlsCaCertPath");
    expect(authSource).not.toContain("NRadioGroup");
    expect(authSource).toContain("transport.websocket");
    expect(authSource).toContain("transport.quic");
    expect(authSource).toContain("transport.race");
  });

  it("shows the active transport protocol on the empty chat workspace", () => {
    const placeholderSource = readFileSync(new URL("../../components/FlareChatPlaceholder.vue", import.meta.url), "utf8");
    const chatStyles = readFileSync(new URL("../../styles/routes/chat.css", import.meta.url), "utf8");

    expect(placeholderSource).toContain("loginTransportDisplayName");
    expect(placeholderSource).toContain("activeTransportLabel");
    expect(placeholderSource).toContain("<span>protocol</span>");
    expect(placeholderSource).toContain("runtimeProductLabel");
    expect(chatStyles).toContain("grid-template-columns: repeat(4, minmax(0, 1fr));");
  });

  it("lets the SDK Lab route occupy the full main workspace width", () => {
    const appWorkbenchStyles = readFileSync(new URL("../../styles/workbench.css", import.meta.url), "utf8");
    const sharedWorkbenchStyles = readFileSync(new URL("../../../design-system/styles/workbench.css", import.meta.url), "utf8");
    const sdkLabStyles = readFileSync(new URL("../../styles/routes/sdk-lab.css", import.meta.url), "utf8");

    expect(appWorkbenchStyles).toContain(".workbench-shell--lab");
    expect(appWorkbenchStyles).toContain("minmax(0, 1fr)");
    expect(sharedWorkbenchStyles).toContain(".workbench-shell--lab");
    expect(sharedWorkbenchStyles).toContain("minmax(0, 1fr)");
    expect(sharedWorkbenchStyles).not.toContain("minmax(0, 920px)");
    expect(sdkLabStyles).toContain("width: 100%;");
    expect(sdkLabStyles).toContain("max-width: none;");
  });

  it("recognizes QUIC-disabled native errors as transport fallback candidates", () => {
    const error = Object.assign(
      new Error("错误 [CONNECTION_FAILED] 错误 [OPERATION_NOT_SUPPORTED] QUIC transport feature is disabled"),
      {
        code: "tauri.invoke_failed",
        operation: "sdk.init",
        details: { transport: "tauri-command" },
      },
    );

    expect(isRecoverableLoginTransportError(error, "quic")).toBe(true);
    expect(isRecoverableLoginTransportError(error, "race")).toBe(true);
    expect(isRecoverableLoginTransportError(error, "websocket")).toBe(false);
    expect(loginTransportFallbackMessage("quic", error)).toContain("WebSocket");
  });

  it("falls back to WebSocket when native QUIC is disabled during login", async () => {
    const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => undefined);
    const initCalls: Array<Record<string, unknown>> = [];
    const client = {
      init: vi.fn(async (config: Record<string, unknown>) => {
        initCalls.push(config);
        if (initCalls.length === 1) {
          throw Object.assign(
            new Error("错误 [CONNECTION_FAILED] 错误 [OPERATION_NOT_SUPPORTED] QUIC transport feature is disabled"),
            {
              code: "tauri.invoke_failed",
              operation: "sdk.init",
            },
          );
        }
      }),
      events: {
        addEventListener: vi.fn(() => ({ unsubscribe: vi.fn() })),
        subscribeEvents: vi.fn(async () => undefined),
        // 真实 EventsApi 上早就有这个方法（见 @flare-im/sdk 的 events.ts），
        // 替身漏了 —— 本文件因配置损坏长期没跑，替身停在旧接口上。
        onTypingAggregateChanged: vi.fn(() => ({ unsubscribe: vi.fn() })),
      },
      login: vi.fn(async () => undefined),
      connection: {
        getConnectionState: vi.fn(async () => "connected"),
      },
      messageBuilder: {
        listSupportedBuildOperations: vi.fn(async () => ({ entries: [] })),
      },
      diagnostics: {
        getSdkVersion: vi.fn(async () => ({ version: "test" })),
        getFfiContractVersion: vi.fn(async () => ({ version: "test" })),
        getDataRoot: vi.fn(async () => ({ dataUrl: "" })),
        getRuntimeHealth: vi.fn(async () => ({ ok: true })),
      },
      currentUserId: vi.fn(async () => "11"),
      sessionActive: vi.fn(async () => true),
      isConnected: vi.fn(async () => true),
      dispose: vi.fn(async () => undefined),
    };
    try {
      const sdk = useFlareCoreClient({
        createClient: () => client as never,
        nativeTransportSelectionEnabled: true,
        runtimeStatus: "tauri-native",
      });

      sdk.form.userId = "11";
      sdk.form.token = "token";
      sdk.form.transportMode = "quic";
      sdk.form.wsUrl = "ws://127.0.0.1:60051/ws";
      sdk.form.quicUrl = "quic://127.0.0.1:60052";
      sdk.form.tlsCaCertPath = "/tmp/flare-server.crt";

      await sdk.initializeAndLogin();

      expect(client.init).toHaveBeenCalledTimes(2);
      expect(initCalls[0]).toMatchObject({
        defaultTransport: "quic",
        protocolRaceOrder: ["quic"],
        tlsCaCertPath: "/tmp/flare-server.crt",
      });
      expect(initCalls[1]).toMatchObject({
        defaultTransport: "websocket",
        transportPolicy: "websocket_only",
      });
      expect(sdk.form.transportMode).toBe("websocket");
      expect(sdk.transportFallbackNotice.value).toContain("WebSocket");
      expect(sdk.sdkRuntimeStatus.value).toBe("tauri-native");
    } finally {
      warnSpy.mockRestore();
    }
  });
});

describe("startup home sync", () => {
  it("delegates cold/hot startup convergence to the core SDK", () => {
    const sdkSource = readFileSync(new URL("../../../composables/useFlareCoreClient.ts", import.meta.url), "utf8");

    expect(sdkSource).toContain("client.sync.bootstrapStartupHome");
    expect(sdkSource).toContain("sync.bootstrap_startup_home");
    expect(sdkSource).toContain("historyBackfillMaxPagesPerConversation");
    expect(sdkSource).toContain("void repairInitialTimelineHistoryIfNeeded(conversationId, reason)");
    expect(sdkSource).not.toContain("await backfillVisibleConversationHistories(\"home_sync\")");
    expect(sdkSource).not.toContain("await trySyncConversationSummaries(\"home_sync\")");
    expect(sdkSource).not.toContain("await repairInitialTimelineHistoryIfNeeded(conversationId, reason)");
  });

  it("keeps empty text mentions explicit for the core message builder", () => {
    const sdkSource = readFileSync(new URL("../../../composables/useFlareCoreClient.ts", import.meta.url), "utf8");
    // wireCodec 属 @flare-im/sdk 仓，本仓独立 clone 后没有那份源码 ——
    // 它的编码契约由该仓自己的 test/wire_codec_contract.test.ts 守（已覆盖
    // mentionUsers/mentionAll 恒发的语义）。这里只保留本仓能自证的部分。
    expect(sdkSource).toContain('mentionUsers: stringListParam(params, "mentionUsers")');
  });
});

describe("proxiedMediaUrl", () => {
  it("uses runtime host media proxy configuration after app bootstrap", () => {
    configureMediaProxy({
      storageProxyPrefix: "/__flare-storage",
      storageProxyTargets: ["http://127.0.0.1:29000"],
    });

    expect(
      proxiedMediaUrl("http://127.0.0.1:29000/flare-media/media/images/demo.png?token=1"),
    ).toBe("/__flare-storage/flare-media/media/images/demo.png?token=1");

    configureMediaProxy({});
  });

  it("rewrites signed storage URLs through the same-origin storage proxy", () => {
    configureMediaProxy({
      storageProxyPrefix: "/__flare-storage",
      storageProxyTargets: ["http://127.0.0.1:29000"],
    });

    const signedUrl =
      "http://127.0.0.1:29000/flare-media/media/images/demo.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=sig";
    expect(proxiedMediaUrl(signedUrl)).toBe(
      "/__flare-storage/flare-media/media/images/demo.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=sig",
    );

    configureMediaProxy({});
  });

  it("resolves SDK-owned media through core access API instead of private storage URLs", async () => {
    configureMediaProxy({
      storageProxyPrefix: "/__flare-storage",
      storageProxyTargets: ["http://127.0.0.1:29000"],
    });
    const resolveMediaAccess = vi.fn(async (request: Record<string, unknown>) => {
      expect(request).toMatchObject({
        fileId: "file-1",
        mediaUrl: "http://127.0.0.1:29000/private/image.png",
      });
      return {
        remote: {
          url: "http://127.0.0.1:29000/signed/image.png",
          cdnUrl: "http://127.0.0.1:29000/private/image.png",
        },
      };
    });
    const resolver = createAppMediaResolver({
      client: {
        media: { resolveMediaAccess },
      },
    } as never);

    await expect(
      resolver({
        kind: "image",
        fileId: "file-1",
        url: "http://127.0.0.1:29000/private/image.png",
      }),
    ).resolves.toBe("/__flare-storage/signed/image.png");
    expect(resolveMediaAccess).toHaveBeenCalledTimes(1);

    configureMediaProxy({});
  });

  it("derives core media file ids from stored object URLs before resolving access", async () => {
    configureMediaProxy({
      storageProxyPrefix: "/__flare-storage",
      storageProxyTargets: ["http://127.0.0.1:29000"],
    });
    const storedUrl =
      "http://127.0.0.1:29000/flare-media/media/images/2026/06/22/bd05cc75-828b-4869-9ad1-5c8f3db72894.png";
    const signedUrl =
      "http://127.0.0.1:29000/flare-media/media/images/2026/06/22/bd05cc75-828b-4869-9ad1-5c8f3db72894.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=sig";
    const resolveMediaAccess = vi.fn(async (request: Record<string, unknown>) => {
      expect(request).toMatchObject({
        fileId: "bd05cc75-828b-4869-9ad1-5c8f3db72894",
        mediaUrl: storedUrl,
      });
      return { url: signedUrl, cdnUrl: storedUrl };
    });
    const resolver = createAppMediaResolver({
      client: {
        media: { resolveMediaAccess },
      },
    } as never);

    await expect(
      resolver({
        kind: "image",
        url: storedUrl,
      }),
    ).resolves.toBe(
      "/__flare-storage/flare-media/media/images/2026/06/22/bd05cc75-828b-4869-9ad1-5c8f3db72894.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Signature=sig",
    );
    expect(resolveMediaAccess).toHaveBeenCalledTimes(1);

    configureMediaProxy({});
  });

  it("does not resolve legacy local placeholder media ids against the gateway", () => {
    expect(
      buildMediaResolveRequest({
        kind: "image",
        id: "local-image-EFE953BD-F473-4C72-AC38-6BC07CCE3D20",
      }),
    ).toBeNull();
  });

  it("builds audio media resolve requests from SDK file ids", () => {
    expect(
      buildMediaResolveRequest({
        kind: "audio",
        messageId: "message-voice-1",
        id: "remote-audio-file-1",
        url: "http://127.0.0.1:29000/flare-media/media/audio/remote-audio-file-1.m4a",
        mimeType: "audio/mp4",
        fileName: "voice.m4a",
      }),
    ).toMatchObject({
      kind: "audio",
      messageId: "message-voice-1",
      fileId: "remote-audio-file-1",
      url: "http://127.0.0.1:29000/flare-media/media/audio/remote-audio-file-1.m4a",
      mimeType: "audio/mp4",
      fileName: "voice.m4a",
    });
  });

  it("keeps remote file ids on file messages that also carry stored object URLs", () => {
    const storedUrl =
      "http://127.0.0.1:29000/flare-media/media/documents/2026/06/23/bd2f0ecf-a9c4-409c-b9af-75517f506d79.md";
    const [source] = listMessageMediaDownloadSources(
      messageFixture({
        content: {
          contentType: MessageContentType.File,
          data: {
            fileId: "bd2f0ecf-a9c4-409c-b9af-75517f506d79",
            fileName: "AGENTS.md",
            fileSize: 6200,
            url: storedUrl,
          },
        },
      }),
    );

    expect(source).toMatchObject({
      kind: "file",
      displayFileName: "AGENTS.md",
      sourceHttpUrl: storedUrl,
      remoteFileId: "bd2f0ecf-a9c4-409c-b9af-75517f506d79",
    });
  });
});

describe("media message bubbles", () => {
  it("renders image media as media cards even when a caption is present", () => {
    expect(
      isChromelessMediaBubble(
        messageFixture({
          content: {
            contentType: "image",
            image: {
              description: "caption",
              source: {
                fileId: "bd05cc75-828b-4869-9ad1-5c8f3db72894",
              },
            },
          } as unknown as MessageContent,
        }),
      ),
    ).toBe(true);
  });
});

describe("messageStateToNumber", () => {
  it("rejects pending async work at the configured timeout boundary", async () => {
    vi.useFakeTimers();
    try {
      const promise = withTimeout(
        new Promise<string>(() => undefined),
        25,
        () => new Error("operation timed out"),
      );
      const observed = promise.catch((error: unknown) => error);

      vi.advanceTimersByTime(25);

      const error = await observed;
      expect(error).toBeInstanceOf(Error);
      expect((error as Error).message).toBe("operation timed out");
    } finally {
      vi.useRealTimers();
    }
  });

  it("bounds timeline opening and sync work so chat loading cannot hang forever", () => {
    const sdkSource = readFileSync(
      new URL("../../../composables/useFlareCoreClient.ts", import.meta.url),
      "utf8",
    );

    expect(sdkSource).toContain("TIMELINE_OPEN_TIMEOUT_MS");
    expect(sdkSource).toContain("MESSAGE_SYNC_TIMEOUT_MS");
    expect(sdkSource).toContain("withTimeout(");
    expect(sdkSource).toContain("sdkOperationTimeoutError(\"view.timeline.open\"");
    expect(sdkSource).toContain("sdkOperationTimeoutError(\"sync.messages\"");
  });

  it("subscribes to observable view events for realtime timeline updates", () => {
    const sdkSource = readFileSync(
      new URL("../../../composables/useFlareCoreClient.ts", import.meta.url),
      "utf8",
    );

    expect(sdkSource).toContain("\"view\",");
    expect(sdkSource).toContain("onViewUpdated: handleViewUpdate");
  });

  it("keeps a foreground realtime safety refresh for the active conversation", () => {
    const sdkSource = readFileSync(
      new URL("../../../composables/useFlareCoreClient.ts", import.meta.url),
      "utf8",
    );

    expect(sdkSource).toContain("REALTIME_SAFETY_POLL_INTERVAL_MS");
    expect(sdkSource).toContain("refreshActiveConversationFromServer");
    expect(sdkSource).toContain("syncMessagesFromKnownCursor(conversationId)");
  });

  it("does not render historical conversation hints as an infinite loading state", () => {
    const chatSource = readFileSync(
      new URL("../../components/FlareChatWorkspace.vue", import.meta.url),
      "utf8",
    );

    expect(chatSource).toContain("if (sdk.messageOpening.value || sdk.messageSyncing.value)");
    expect(chatSource).toContain("emptyHistoryUnavailable");
    expect(chatSource).not.toContain("sdk.messageOpening.value || sdk.messageSyncing.value || hasHistoryHint");
  });

  it("maps failed local messages to status 5", () => {
    const message = {
      clientMsgId: "c1",
      serverId: "",
      status: 1,
      localState: localState({ failed: true, isLocal: true }),
    } as unknown as Parameters<typeof messageStateToNumber>[0];
    expect(messageStateToNumber(message)).toBe(5);
  });

  it("ignores stale failed local state after the message has an authoritative id", () => {
    const message = {
      clientMsgId: "c1",
      serverId: "s1",
      conversationSeq: 18,
      status: 2,
      localState: localState({ failed: true, isLocal: true }),
    } as unknown as Parameters<typeof messageStateToNumber>[0];
    expect(messageStateToNumber(message)).toBe(2);
  });

  it("maps core read state to status 4", () => {
    const message = {
      clientMsgId: "c2",
      serverId: "s2",
      status: 2,
      isRead: true,
      localState: localState(),
    } as Parameters<typeof messageStateToNumber>[0];
    expect(messageStateToNumber(message)).toBe(4);
  });

  it("does not derive read state from shadow peer read seq", () => {
    const message = {
      clientMsgId: "c2",
      serverId: "s2",
      status: 2,
      conversationSeq: 7,
      attributes: { peerReadSeq: "7" },
      isRead: false,
      localState: localState({ isLocal: true }),
    } as unknown as Parameters<typeof messageStateToNumber>[0];
    expect(messageStateToNumber(message)).toBe(2);
  });

  it("maps active local sends to status 1", () => {
    const message = {
      clientMsgId: "c3",
      serverId: "",
      status: 0,
      localState: localState({ sending: true, isLocal: true }),
    } as Parameters<typeof messageStateToNumber>[0];
    expect(messageStateToNumber(message)).toBe(1);
  });

  it("preserves quote message type when sending built quote messages through WASM", () => {
    expect(
      encodeWasmRequestForTesting({
        message: {
          clientMsgId: "quote-1",
          conversationId: "conv-1",
          conversationType: 1,
          senderId: "hugo",
          source: 1,
          conversationSeq: 0,
          createdAt: 1000,
          clientCreatedAt: 1000,
          messageType: 13,
          content: {
            contentType: "quote",
            quotedMessageId: "source-1",
            quotedTextPreview: "hello",
            currentContent: {
              contentType: "text",
              text: "reply",
              mentions: [],
            },
          },
          status: 1,
          version: 1,
          updatedAt: 1000,
        },
      }),
    ).toMatchObject({
      message: {
        conversationType: 1,
        messageType: 13,
        content: {
          contentType: "quote",
          currentContent: {
            contentType: "text",
            text: "reply",
          },
          quotedMessageId: "source-1",
        },
      },
    });
  });

  it("does not run bridge-local message validation before core decoding", () => {
    expect(
      encodeWasmRequestForTesting({
        message: {
          clientMsgId: "missing-type",
          conversationId: "conv-1",
          conversationType: 1,
          senderId: "hugo",
          source: 1,
          conversationSeq: 0,
          createdAt: 1000,
          clientCreatedAt: 1000,
          content: {
            contentType: "text",
            text: "hello",
            mentions: [],
          },
          status: 1,
          version: 1,
          updatedAt: 1000,
        },
      }),
    ).toMatchObject({
      message: {
        clientMsgId: "missing-type",
        content: { contentType: "text", text: "hello", mentions: [] },
      },
    });
  });
});

describe("message list scroll anchoring", () => {
  const keyOf = (item: string) => item;

  it("classifies older history as prepend, not append", () => {
    const previous = ["m3", "m4", "m5"];
    const next = ["m1", "m2", "m3", "m4", "m5"];

    expect(countPrependedItems(previous, next, keyOf)).toBe(2);
    expect(countAppendedItems(previous, next, keyOf)).toBe(0);
  });

  it("classifies bottom growth only when the previous list remains the prefix", () => {
    const previous = ["m3", "m4", "m5"];
    const next = ["m3", "m4", "m5", "m6"];

    expect(countAppendedItems(previous, next, keyOf)).toBe(1);
    expect(countPrependedItems(previous, next, keyOf)).toBe(0);
  });

  it("classifies concurrent history prepend and live append around the previous window", () => {
    const previous = ["m3", "m4", "m5"];
    const next = ["m1", "m2", "m3", "m4", "m5", "m6"];

    expect(countPrependedItems(previous, next, keyOf)).toBe(2);
    expect(countAppendedItems(previous, next, keyOf)).toBe(1);
  });

  it("restores the same visible anchor after prepending measured rows", () => {
    expect(
      restorePrependScrollTop(
        {
          scrollTop: 24,
          scrollHeight: 1200,
        },
        1520,
      ),
    ).toBe(344);
  });
});

describe("shared message row normalization", () => {
  it("removes duplicate virtual-list keys before rendering", () => {
    const pending = messageFixture({
      clientMsgId: "client-row",
      serverId: "",
      conversationSeq: 0,
      timelineKey: "client:client-row",
      localState: localState({ sending: true, isLocal: true, sortTs: 1_000 }),
    });
    const acknowledged = messageFixture({
      clientMsgId: "client-row",
      serverId: "server-row",
      conversationSeq: 88,
      timelineKey: "client:client-row",
      localState: localState(),
    });

    const rows = normalizeMessageRowsForVirtualList([pending, acknowledged]);

    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({
      clientMsgId: "client-row",
      serverId: "server-row",
      conversationSeq: 88,
      timelineKey: "client:client-row",
      localState: {
        sending: false,
        failed: false,
      },
    });
  });
});

describe("message enhancement registry", () => {
  it("covers the enhanced composer message families", () => {
    expect(composerActions.map((action) => action.kind)).toEqual([
      "file",
      "image",
      "video",
      "audio",
      "location",
      "card",
      "schedule",
      "task",
      "linkCard",
      "richText",
      "imageGroup",
      "miniProgram",
      "vote",
      "thread",
      "notification",
      "announcement",
    ]);
  });

  it("builds structured composer requests with generated SDK builder fields", () => {
    const card = resolveComposerAction("create_card")!.buildRequest({
      id: "u-11",
      title: "Hugo",
      subtitle: "Flare IM",
      cardType: "user",
    });
    expect(card).toMatchObject({
      op: "create_card",
      params: {
        id: "u-11",
        cardType: "user",
        title: "Hugo",
        subtitle: "Flare IM",
      },
    });

    const schedule = resolveComposerAction("create_schedule")!.buildRequest({
      title: "Daily sync",
      time: "2026-06-23 10:00",
      location: "Room A",
    });
    expect(schedule).toMatchObject({
      op: "create_schedule",
      params: {
        title: "Daily sync",
        location: "Room A",
        participantUserIds: [],
      },
    });
    expect(schedule.params.scheduleId).toMatch(/^schedule-/);
    expect(schedule.params.startTimeMs).toBe(Date.parse("2026-06-23 10:00"));
    expect(schedule.params.endTimeMs).toBe(Date.parse("2026-06-23 11:00"));

    const notification = resolveComposerAction("create_notification")!.buildRequest({
      title: "提醒",
      text: "版本已发布",
    });
    expect(notification).toMatchObject({
      op: "create_notification",
      params: {
        title: "提醒",
        body: "版本已发布",
      },
    });

    const richText = resolveComposerAction("create_rich_doc")!.buildRequest({
      title: "发布说明",
      markdown: "## Release\n- Fixed resend state",
    });
    expect(richText).toMatchObject({
      op: "create_rich_doc",
      kind: "richText",
      previewText: "发布说明",
      params: {
        title: "发布说明",
        markdown: "## Release\n- Fixed resend state",
      },
    });
  });

  it("routes every structured composer op to the generated SDK message builder", () => {
    const sdkSource = readFileSync(
      new URL("../../../composables/useFlareCoreClient.ts", import.meta.url),
      "utf8",
    );
    const requiredCases = [
      "CreateLocation",
      "CreateLinkCard",
      "CreateCard",
      "CreateMiniProgram",
      "CreateRichDoc",
      "CreateThreadReply",
      "CreateNotification",
      "CreateVote",
      "CreateTask",
      "CreateSchedule",
      "CreateAnnouncement",
    ];

    for (const caseName of requiredCases) {
      expect(sdkSource).toContain(`case MessageBuildOp.${caseName}`);
    }
    expect(sdkSource).toContain("sourcePayload = markdownSource");
    expect(sdkSource).toContain("markdown: markdownSource");
  });

  it("does not map removed composer operation aliases", () => {
    const action = resolveComposerAction("create_rich_text");

    expect(action).toBeUndefined();
    expect(resolveComposerAction("create_markdown")).toBeUndefined();
  });

  it("disables risky actions for recalled messages and enables self edit for sent messages", () => {
    const base = {
      clientMsgId: "client-1",
      serverId: "server-1",
      senderId: "hugo",
      isRecalled: false,
      localState: localState(),
      attributes: {},
      extensions: {},
      reactions: [],
    } as unknown as Message;

    const selfCaps = resolveMessageCapabilities(base, {
      currentUserId: "hugo",
      connected: true,
    });
    expect(selfCaps.canEdit.enabled).toBe(true);
    expect(selfCaps.canPin.enabled).toBe(true);

    const recalledCaps = resolveMessageCapabilities(
      { ...base, isRecalled: true },
      {
        currentUserId: "hugo",
        connected: true,
      },
    );
    expect(recalledCaps.canReact.enabled).toBe(false);
    expect(recalledCaps.canForward.enabled).toBe(false);
  });

  it("maps operation capabilities into shared menu visibility", () => {
    const message = {
      clientMsgId: "client-1",
      serverId: "server-1",
      senderId: "hugo",
      isRecalled: false,
      localState: localState(),
      content: { contentType: "text", data: { text: "hello" } },
      messageType: 1,
      status: 2,
      attributes: {},
      extensions: {},
      reactions: [],
    } as unknown as Message;

    const actions = resolveMessageMenuActions(message, {
      currentUserId: "hugo",
      connected: false,
    });
    const keys = buildMessageMenuSheetItems(
      message as Parameters<typeof buildMessageMenuSheetItems>[0],
      "hugo",
      {
        resolveVisible: () => actions,
      },
    ).map((item) => item.key);

    expect(actions.delete).toBe(false);
    expect(actions.pin).toBe(false);
    expect(keys).not.toContain("delete");
    expect(keys).not.toContain("pin");
  });
});

describe("message operation adapter", () => {
  function sdkStub(overrides: Partial<MessageOperationSdk> = {}) {
    const calls: string[] = [];
    const sdk = {
      activeConversationId: ref("conv-1"),
      currentUserId: ref("hugo"),
      conversations: ref([]),
      messages: ref([]),
      addReaction: vi.fn(async () => undefined),
      removeReaction: vi.fn(async () => undefined),
      toggleReaction: vi.fn(async () => undefined),
      buildAndSendMessage: vi.fn(async () => undefined),
      forwardMessagesToConversation: vi.fn(async (request: { messageIds: string[] }) => {
        calls.push(request.messageIds.join(","));
        return {} as Message;
      }),
      deleteMessageForSelf: vi.fn(async () => undefined),
      setMessagePinned: vi.fn(async () => undefined),
      refreshActiveChat: vi.fn(async () => undefined),
      ...overrides,
    } as unknown as MessageOperationSdk;
    return { sdk, calls };
  }

  it("forwards selected messages one by one in stable order", async () => {
    const { sdk, calls } = sdkStub();
    const adapter = createMessageOperationAdapter(sdk);

    const result = await adapter.forwardMessages({
      mode: "separate",
      targetConversationId: "conv-2",
      messageIds: ["m1", "m2", "m3"],
    });

    expect(calls).toEqual(["m1", "m2", "m3"]);
    expect(result.succeeded).toEqual(["m1", "m2", "m3"]);
    expect(result.failed).toEqual([]);
  });

  it("returns per-message failures for batch deletes", async () => {
    const { sdk } = sdkStub({
      deleteMessageForSelf: vi.fn(async (messageId: string) => {
        if (messageId === "m2") throw new Error("permission denied");
      }),
    });
    const adapter = createMessageOperationAdapter(sdk);

    const result = await adapter.deleteMessagesForSelf(["m1", "m2"]);

    expect(result.succeeded).toEqual(["m1"]);
    expect(result.failed).toEqual([
      { messageId: "m2", reason: "permission denied" },
    ]);
  });

  it("passes message pin scope through to the SDK facade", async () => {
    const setMessagePinned = vi.fn(async () => undefined);
    const { sdk } = sdkStub({ setMessagePinned });
    const adapter = createMessageOperationAdapter(sdk);

    const result = await adapter.setMessagesPinned(["m1", "m2"], true, "self");

    expect(result.succeeded).toEqual(["m1", "m2"]);
    expect(result.failed).toEqual([]);
    expect(setMessagePinned).toHaveBeenNthCalledWith(1, "m1", true, {
      scope: "self",
    });
    expect(setMessagePinned).toHaveBeenNthCalledWith(2, "m2", true, {
      scope: "self",
    });
  });

  it("sends media requests directly to core without browser preupload", async () => {
    const { sdk } = sdkStub();
    const adapter = createMessageOperationAdapter(sdk);
    const action = resolveComposerAction("create_image");
    const sourcePath = "data:image/png;name=real.png;size=11;base64,aW1hZ2UtYnl0ZXM=";
    const request = action!.buildRequest({
      sourcePath,
      description: "real image",
      fileName: "real.png",
      mimeType: "image/png",
      fileSize: 11,
    }, []);

    await adapter.sendComposerPayload(request);

    expect(sdk.buildAndSendMessage).toHaveBeenCalledWith(
      "create_with_content",
      expect.objectContaining({
        contentType: "image",
      }),
    );
    const sentParams = (sdk.buildAndSendMessage as ReturnType<typeof vi.fn>).mock.calls[0]?.[1] as {
      data?: { source?: Record<string, unknown>; thumbnail?: Record<string, unknown> };
    };
    expect(sentParams.data).toMatchObject({
      source: {
        uuid: sourcePath,
        imageId: sourcePath,
        url: sourcePath,
        mimeType: "image/png",
        size: 11,
        fileName: "real.png",
        width: 0,
        height: 0,
      },
      thumbnail: {
        uuid: sourcePath,
        imageId: sourcePath,
        url: sourcePath,
        fileName: "real.png",
      },
    });
  });

  it("keeps native sourcePath media on the core send path without browser preupload", async () => {
    const { sdk } = sdkStub();
    const adapter = createMessageOperationAdapter(sdk);
    const action = resolveComposerAction("create_image");
    const sourcePath = "/Users/hg/Pictures/生成古风动漫图片.png";
    const request = action!.buildRequest({ sourcePath, description: "native image" }, []);

    await adapter.sendComposerPayload(request);

    expect(sdk.buildAndSendMessage).toHaveBeenCalledWith(
      "create_with_content",
      expect.objectContaining({
        contentType: "image",
        data: expect.objectContaining({
          source: expect.objectContaining({
            imageId: sourcePath,
            uuid: sourcePath,
            url: sourcePath,
          }),
        }),
      }),
    );
  });

  it("builds audio messages from uploaded media ids and resolve URL hints", async () => {
    const { sdk } = sdkStub();
    const adapter = createMessageOperationAdapter(sdk);
    const action = resolveComposerAction("create_audio");
    const request = action!.buildRequest({
      audioId: "remote-audio-file-1",
      sourceUrl: "http://127.0.0.1:29000/flare-media/media/audio/remote-audio-file-1.m4a",
      description: "语音消息",
      fileName: "voice.m4a",
      mimeType: "audio/mp4",
      fileSize: 2048,
      durationMs: 3200,
    }, []);

    await adapter.sendComposerPayload(request);

    expect(sdk.buildAndSendMessage).toHaveBeenCalledWith(
      "create_with_content",
      expect.objectContaining({
        contentType: "audio",
        data: expect.objectContaining({
          audioId: "remote-audio-file-1",
          source: expect.objectContaining({
            uuid: "remote-audio-file-1",
            url: "http://127.0.0.1:29000/flare-media/media/audio/remote-audio-file-1.m4a",
            fileName: "voice.m4a",
            mimeType: "audio/mp4",
            size: 2048,
            durationMs: 3200,
          }),
        }),
      }),
    );
  });

  it("opens media actions through direct picker and preview instead of payload forms", () => {
    const chatSource = readFileSync(
      new URL("../../components/FlareChatWorkspace.vue", import.meta.url),
      "utf8",
    );
    const payloadModalSource = readFileSync(
      new URL("../../message-enhancements/components/ComposerPayloadModal.vue", import.meta.url),
      "utf8",
    );
    // Tauri 示例 app 属 @flare-im/sdk 仓的 examples/，本仓独立 clone 后不存在。
    // 与之相关的断言随文件一并移除，避免这份测试再次变成「只能在单机全量
    // 工作区里跑」的假门禁。

    expect(chatSource).toContain("pickAppMediaSourcePaths");
    expect(chatSource).toContain("fileToCoreDataUrl");
    expect(chatSource).toContain("<MediaComposerPreviewModal");
    expect(chatSource).toContain("mediaFileInput");
    expect(chatSource).toContain("payloadComposerOpen");
    expect(payloadModalSource).toContain("resolved?.acceptsFiles ? undefined : resolved");
    expect(payloadModalSource).not.toContain("Image ID");
    expect(payloadModalSource).not.toContain("File ID");
    expect(payloadModalSource).not.toContain("Video ID");
    expect(payloadModalSource).not.toContain("Audio ID");
    expect(payloadModalSource).not.toContain("sourcePath");
  });

  it("passes canonical media payloads into the SDK message builders", () => {
    const sdkSource = readFileSync(
      new URL("../../../composables/useFlareCoreClient.ts", import.meta.url),
      "utf8",
    );

    expect(sdkSource).toContain("case MessageBuildOp.CreateWithContent");
    expect(sdkSource).toContain("client.messageBuilder.buildWithContent");
    expect(sdkSource).toContain("contentType: contentTypeParam(params)");
    expect(sdkSource).toContain("data: recordParam(params, \"data\")");
  });

  it("builds image groups from canonical media sources instead of upload side effects", () => {
    const action = resolveComposerAction("create_image_group");
    const source = "data:image/png;name=a.png;size=3;base64,QUJD";
    const request = action!.buildRequest({
      description: "album",
      imageSources: [{ imageId: source, fileName: "a.png", mimeType: "image/png", size: 3 }],
    });
    const payload = request.params.data as {
      images?: Array<{ imageId?: string; url?: string; mimeType?: string; size?: number }>;
      description?: string;
      metadata?: Record<string, string>;
    };

    expect(request.op).toBe("create_with_content");
    expect(request.params.contentType).toBe("image_group");
    expect(payload.description).toBe("album");
    expect(payload.images?.[0]).toMatchObject({
      imageId: source,
      url: source,
      fileName: "a.png",
      mimeType: "image/png",
      size: 3,
    });
    expect(payload.metadata).toMatchObject({ imageCount: "1" });
  });

  it("derives media download filenames from typed media sources", () => {
    const message = messageFixture({
      content: {
        contentType: "image_group",
        data: {
          images: [
            {
              imageId: "remote-image-id",
              source: {
                fileId: "remote-image-id",
                fileName: "生成古风动漫图片 (7).png",
                mimeType: "image/png",
              },
            },
          ],
        },
      } as unknown as MessageContent,
    });

    const sources = listMessageMediaDownloadSources(message);

    expect(sources).toHaveLength(1);
    expect(sources[0]).toMatchObject({
      kind: "image",
      remoteFileId: "remote-image-id",
      displayFileName: "生成古风动漫图片 (7).png",
      mimeType: "image/png",
    });
  });

  it("renders media descriptions from typed media payloads in shared UI", () => {
    const imageView = readFileSync(
      new URL(
        "../../../components/messages/MessagesView/views/ImageView.vue",
        import.meta.url,
      ),
      "utf8",
    );
    const fileView = readFileSync(
      new URL(
        "../../../components/messages/MessagesView/views/FileView.vue",
        import.meta.url,
      ),
      "utf8",
    );
    const imageGroupView = readFileSync(
      new URL(
        "../../../components/messages/MessagesView/views/ImageGroupView.vue",
        import.meta.url,
      ),
      "utf8",
    );
    const imageGroupCell = readFileSync(
      new URL(
        "../../../components/messages/MessagesView/views/ImageGroupCell.vue",
        import.meta.url,
      ),
      "utf8",
    );
    const videoView = readFileSync(
      new URL(
        "../../../components/messages/MessagesView/views/VideoView.vue",
        import.meta.url,
      ),
      "utf8",
    );

    expect(imageView).toContain('readString(payload.value, "description", "caption", "title")');
    expect(imageView).toContain("im-image__media");
    expect(imageView).toContain("im-media-caption im-image__desc");
    expect(imageView).toContain("min-height: 132px");
    expect(fileView).toContain('readString(payload.value, "description")');
    expect(fileView).toContain('v-if="description"');
    expect(fileView).toContain("im-file__description");
    expect(imageGroupView).toContain('readString(payload.value, "description")');
    expect(imageGroupView).toContain('class="im-media-caption im-image-group__desc"');
    expect(imageGroupView).toContain("overflow-wrap: anywhere");
    expect(imageGroupCell).toContain("ImagePreviewModal");
    expect(imageGroupCell).toContain("downloadUrlWithFileName");
    expect(imageGroupCell).toContain('kind: "imageGroupItem"');
    expect(videoView).toContain("capturePosterFromVideo");
    expect(videoView).toContain("canvas.toDataURL");
    expect(videoView).toContain("displayPosterUrl");
  });
});

describe("message menu contract", () => {
  type MenuMessage = Parameters<typeof buildMessageMenuSheetItems>[0];

  function menuMessage(overrides: Partial<MenuMessage> = {}): MenuMessage {
    return {
      clientMsgId: "client-1",
      serverId: "server-1",
      senderId: "hugo",
      senderDisplayName: "Hugo",
      messageType: 1,
      status: 2,
      isRead: true,
      isRecalled: false,
      isEdited: false,
      conversationSeq: 1,
      createdAt: 10,
      clientCreatedAt: 10,
      content: { contentType: "text", data: { text: "hello" } },
      attributes: {},
      extensions: {},
      reactions: [],
      ...overrides,
    } as MenuMessage;
  }

  it("keeps reply available for self messages so quoted sends work consistently", () => {
    const keys = buildMessageMenuSheetItems(
      menuMessage({ senderId: "hugo" }),
      "hugo",
    ).map((item) => item.key);

    expect(keys).toContain("reply");
    expect(resolveMessageMenuAction(menuMessage(), "reply")).toEqual({
      type: "emit",
      event: "reply",
      payload: "client-1",
    });
  });

  it("surfaces resend for failed self messages and resolves it with clientMsgId", () => {
    const failed = menuMessage({
      clientMsgId: "client-failed",
      serverId: "",
      conversationSeq: 0,
      status: 1,
      localState: localState({ failed: true, isLocal: true }),
    });
    const sheetKeys = buildMessageMenuSheetItems(failed, "hugo").map(
      (item) => item.key,
    );
    const dropdownKeys = buildMessageMenuDropdownOptions(failed, "hugo").map(
      (item) => item.key,
    );

    expect(sheetKeys).toContain("resend");
    expect(dropdownKeys).toContain("resend");
    expect(resolveMessageMenuAction(failed, "resend")).toEqual({
      type: "emit",
      event: "resend",
      payload: "client-failed",
    });
  });

  it("keeps recall reachable from the desktop more menu for sent self messages", () => {
    const sent = menuMessage({ senderId: "hugo", status: 2 });
    const dropdownKeys = buildMessageMenuDropdownOptions(sent, "hugo").map(
      (item) => item.key,
    );

    expect(dropdownKeys).toContain("recall");
    expect(resolveMessageMenuAction(sent, "recall")).toEqual({
      type: "emit",
      event: "recall",
      payload: "client-1",
    });
  });

  it("resolves conversation and personal pin menu actions with explicit scopes", () => {
    const sent = menuMessage({ senderId: "hugo", status: 2 });

    expect(resolveMessageMenuAction(sent, "pin")).toEqual({
      type: "emit",
      event: "pin",
      payload: { id: "client-1", pinned: true, scope: "conversation" },
    });
    expect(resolveMessageMenuAction(sent, "pinSelf")).toEqual({
      type: "emit",
      event: "pin",
      payload: { id: "client-1", pinned: true, scope: "self" },
    });
  });
});

describe("message content renderability", () => {
  it("keeps real text messages renderable when text is stored in SDK data fields", () => {
    expect(
      hasRenderableMessageContent({
        contentType: "text",
        data: { text: "1111" },
      }),
    ).toBe(true);
    expect(
      hasRenderableMessageContent({
        contentType: "text",
        data: { body: "历史消息" },
      }),
    ).toBe(true);
    expect(
      hasRenderableMessageContent({
        contentType: "text",
        data: { plainText: "sent message" },
      }),
    ).toBe(true);
    expect(
      hasRenderableMessageContent({
        contentType: "text",
        data: { t: "短字段消息" },
      }),
    ).toBe(true);
    expect(
      hasRenderableMessageContent({
        contentType: "text",
        data: { args: { t: "参数消息" } },
      }),
    ).toBe(true);
    expect(
      hasRenderableMessageContent({
        contentType: "text",
        data: { text: JSON.stringify({ t: "JSON 包装消息" }) },
      }),
    ).toBe(true);
    expect(
      previewTextFromMessageContent({
        contentType: "text",
        data: { text: "1111" },
      }),
    ).toBe("1111");
    expect(
      previewTextFromMessageContent({
        contentType: "text",
        data: { t: "短字段消息" },
      }),
    ).toBe("短字段消息");
  });

  it("filters only truly empty text messages", () => {
    expect(
      hasRenderableMessageContent({ contentType: "text", data: { text: "" } }),
    ).toBe(false);
    expect(hasRenderableMessageContent({ contentType: "text", data: {} })).toBe(
      false,
    );
  });
});

describe("mapSdkError", () => {
  it("loads wasm bindings from app-local asset URLs", () => {
    const moduleUrl = resolveWasmBindingAssetUrl("flare_im_core_sdk.js");
    const wasmUrl = resolveWasmBindingAssetUrl("flare_im_core_sdk_bg.wasm");

    expect(moduleUrl).toBe("/flare-core-wasm/flare_im_core_sdk.js");
    expect(wasmUrl).toBe("/flare-core-wasm/flare_im_core_sdk_bg.wasm");
    expect(moduleUrl).not.toContain("@fs");
    expect(wasmUrl).not.toContain("@fs");
  });

  it("preserves typed sdk error shape", () => {
    const mapped = mapSdkError(
      Object.assign(new Error("wasm missing"), {
        code: "runtimeUnavailable",
        operation: "wasm.load",
        retryable: true,
        details: { source: "bindings/wasm/pkg" },
      }),
      "wasm.load",
    );
    expect(mapped.code).toBe("runtimeUnavailable");
    expect(mapped.operation).toBe("wasm.load");
    expect(mapped.retryable).toBe(true);
  });

  it("reports sdk errors to the browser console with structured payload", () => {
    const spy = vi.spyOn(console, "error").mockImplementation(() => undefined);
    const raw = Object.assign(new Error("login failed"), {
      code: "sdk.error",
      operation: "sdk.login",
      retryable: false,
      details: { wsUrl: "ws://127.0.0.1:50051" },
    });

    const mapped = reportSdkError(raw, "sdk.login");

    expect(mapped.code).toBe("sdk.error");
    expect(mapped.operation).toBe("sdk.login");
    expect(mapped.message).toBe("login failed");
    expect(spy).toHaveBeenCalledWith(
      "[flare-core-web-app] SDK operation failed",
      mapped,
      raw,
    );
    spy.mockRestore();
  });

  it("unwraps json sdk errors from wasm bridge exception messages", () => {
    const mapped = mapSdkError(
      Object.assign(
        new Error(
          JSON.stringify({
            code: "sdk.error",
            message: "错误 [CONNECTION_FAILED]",
            operation: "sdk.login",
          }),
        ),
        {
          code: "wasm.invoke_failed",
          operation: "sdk.login",
        },
      ),
      "sdk.login",
    );

    expect(mapped.code).toBe("sdk.error");
    expect(mapped.operation).toBe("sdk.login");
    expect(mapped.message).toBe("错误 [CONNECTION_FAILED]");
  });
});

describe("WASM connection events", () => {
  it("maps core connected events to typed connection payloads", () => {
    expect(mapWasmEventForTesting("im://connected", {})).toEqual({
      type: "connection",
      event: "connected",
      name: "connected",
      state: "connected",
    });
    expect(mapWasmEventForTesting("im://state", { state: "Ready" })).toEqual({
      type: "connection",
      event: "state_changed",
      name: "ready",
      state: "ready",
    });
  });

  it("rejects unknown core connection states instead of downgrading them", () => {
    expect(() =>
      mapWasmEventForTesting("im://state", { state: "half_open" }),
    ).toThrow("invalid connection state: half_open");
  });

  it("returns runtime connection state without stale ready fallback", async () => {
    const bridge = new WebProductionBridge();
    const internals = bridge as unknown as {
      runtime: { invoke: ReturnType<typeof vi.fn> };
      lastConnectionState: string;
    };
    internals.runtime = {
      invoke: vi.fn(async () => "disconnected"),
    };
    internals.lastConnectionState = "ready";

    await expect(bridge.invoke(NativeCallMap.connectionGetState)).resolves.toBe("disconnected");
    expect(internals.lastConnectionState).toBe("disconnected");
  });

  it("rejects unknown runtime connection state from get_state", async () => {
    const bridge = new WebProductionBridge();
    const internals = bridge as unknown as {
      runtime: { invoke: ReturnType<typeof vi.fn> };
    };
    internals.runtime = {
      invoke: vi.fn(async () => "half_open"),
    };

    await expect(bridge.invoke(NativeCallMap.connectionGetState)).rejects.toThrow(
      "invalid connection state: half_open",
    );
  });

  it("does not let a stale snapshot downgrade a live connection", () => {
    expect(
      flareSessionBridgeTesting.applySnapshotConnectionState(
        "ready",
        "disconnected",
      ),
    ).toBe("ready");
    expect(
      flareSessionBridgeTesting.applySnapshotConnectionState(
        "connected",
        "disconnected",
      ),
    ).toBe("connected");
    expect(
      flareSessionBridgeTesting.applySnapshotConnectionState(
        "reconnecting",
        "disconnected",
      ),
    ).toBe("disconnected");
  });

  it("extracts conversation ids from canonical camelCase mutation payloads only", () => {
    expect(
      flareSessionBridgeTesting.conversationIdFromPayload({
        conversationId: "c1",
      }),
    ).toBe("c1");
    expect(
      flareSessionBridgeTesting.conversationIdFromPayload({
        conversation_id: "c2",
      }),
    ).toBeUndefined();
    expect(
      flareSessionBridgeTesting.conversationIdFromPayload({
        conversationIds: ["", "c3"],
      }),
    ).toBe("c3");
    expect(
      flareSessionBridgeTesting.conversationIdFromPayload({
        conversation_ids: ["", "c4"],
      }),
    ).toBeUndefined();
  });

  it("routes scoped conversation events without scheduling pull refreshes", () => {
    let emit: (payload: unknown) => void = () => undefined;
    const appClient = {
      events: {
        addEventListener: (handler: (payload: unknown) => void) => {
          emit = handler;
          return { unsubscribe: vi.fn() };
        },
      },
    } as never;
    const onIncomingMessage = vi.fn();
    const dispose = bindFlareSessionEvents({
      appClient,
      events: ref([]),
      connectionState: ref("disconnected"),
      loggedIn: ref(true),
      onIncomingMessage,
    });

    emit({ type: "connection", name: "ready", state: "ready" });
    emit({ type: "conversation", name: "created", conversationId: "c1" });
    emit({ type: "conversation", name: "updated", conversationId: "c1" });
    emit({
      type: "conversation",
      name: "unread_count_changed",
      conversationId: "c1",
    });
    emit({ type: "sync", name: "finished" });

    expect(onIncomingMessage).toHaveBeenCalledTimes(4);
    expect(onIncomingMessage).toHaveBeenNthCalledWith(1, {
      conversationId: "c1",
    });
    expect(onIncomingMessage).toHaveBeenNthCalledWith(2, {
      conversationId: "c1",
    });
    expect(onIncomingMessage).toHaveBeenNthCalledWith(3, {
      conversationId: "c1",
    });
    expect(onIncomingMessage).toHaveBeenNthCalledWith(4, {});
    dispose();
  });
});

describe("WASM bridge control operation policy", () => {
  it("keeps typing best-effort so it cannot block reliable sends", () => {
    expect(isBestEffortControlOperationForTesting("message.typing")).toBe(true);
    expect(isBestEffortControlOperationForTesting("message.send")).toBe(false);
    expect(isBestEffortControlOperationForTesting("sync.messages")).toBe(false);
  });
});

describe("message dispatch timeline refresh policy", () => {
  it("inserts outgoing messages into the active timeline before the remote ack", () => {
    const sdkSource = readFileSync(
      new URL("../../../composables/useFlareCoreClient.ts", import.meta.url),
      "utf8",
    );
    expect(sdkSource).toContain("function upsertOutgoingMessageInActiveTimeline");
    expect(sdkSource).toContain("messages.value = [...messages.value, nextMessage]");
    expect(sdkSource).toContain("patchConversationLastOutgoing(nextMessage)");
    expect(sdkSource).toContain("patchConversationDraft(conversationId, draft);");
  });

  it("refreshes local timeline after visible message mutations", () => {
    expect(shouldRefreshTimelineAfterDispatch("add_reaction")).toBe(true);
    expect(shouldRefreshTimelineAfterDispatch("edit_text_by_message_id")).toBe(
      true,
    );
    expect(shouldRefreshTimelineAfterDispatch("pin_by_message_id")).toBe(true);
    expect(shouldRefreshTimelineAfterDispatch("delete_for_self")).toBe(true);
    expect(shouldRefreshTimelineAfterDispatch("search")).toBe(false);
    expect(shouldRefreshTimelineAfterDispatch("typing")).toBe(false);
  });

  it("passes only canonical camelCase ids to generated message dispatch operations", () => {
    expect(
      buildMessageDispatchParams({
        conversationId: "c1",
        messageId: "m1",
        text: "updated",
        jsonParams: { reason: "test" },
      }),
    ).toEqual({
      conversationId: "c1",
      messageId: "m1",
      clientMsgId: "m1",
      text: "updated",
      reason: "test",
      keyword: "",
      emoji: "",
      // 标记类 dispatchOp 的必填项：核心侧 mark_by_message_id 走
      // json_i32("markType") + json_string("color")，缺任一个直接
      // INVALID_PARAMETER，右键菜单的"标记"因此曾经必然失败。
      markType: MARK_TYPE_IMPORTANT,
      color: DEFAULT_MARK_COLOR,
    });
  });

  it("does not synthesize snake_case aliases for WASM SDK requests", () => {
    expect(
      encodeWasmRequestForTesting({
        userId: "hugo",
        tenantId: "flare",
      }),
    ).toEqual({
      userId: "hugo",
      tenantId: "flare",
    });
  });

  it("normalizes login identity without adding legacy field aliases", () => {
    expect(readLoginEnvText(undefined, "hugo")).toBe("hugo");
    expect(readLoginEnvText("   ", "hugo")).toBe("hugo");
    expect(readLoginEnvText(" alice ", "hugo")).toBe("alice");
    expect(normalizeLoginIdentityForSdk({ userId: " bob ", tenantId: " " })).toEqual({
      userId: "bob",
      tenantId: "0",
    });
    expect(() => normalizeLoginIdentityForSdk({ userId: " ", tenantId: "0" })).toThrow("userId is required");
  });
});

describe("conversation title resolution", () => {
  it("uses the peer identity for single chats before generic display names", () => {
    expect(
      conversationTitle(
        {
          conversationType: ConversationType.Single,
          conversationId: "1AKXGVD",
          channelId: "12",
          displayName: "聊天",
          memberPreview: [
            { userId: "hugo", nickname: "Hugo" },
            { userId: "12", nickname: "" },
          ],
        },
        "hugo",
      ),
    ).toBe("12");
  });

  it("keeps explicit group display names as the primary title", () => {
    expect(
      conversationTitle(
        {
          conversationType: ConversationType.Group,
          conversationId: "group-1",
          channelId: "team-channel",
          displayName: "研发群",
          memberPreview: [{ userId: "12", nickname: "12" }],
        },
        "hugo",
      ),
    ).toBe("研发群");
  });

  it("does not collapse multi-member group titles to a single participant", () => {
    expect(
      conversationTitle(
        {
          conversationType: ConversationType.Group,
          conversationId: "group-2",
          channelId: "users:11,12,13",
          displayName: "12",
          memberPreview: [
            { userId: "11", nickname: "11" },
            { userId: "12", nickname: "12" },
            { userId: "13", nickname: "13" },
          ],
        },
        "11",
      ),
    ).toBe("群聊(11、12、13)");
  });
});

describe("WASM request encoding", () => {
  it("encodes canonical TypeScript message DTOs through the generated core codec", () => {
    expect(
      encodeWasmRequestForTesting({
        message: {
          clientMsgId: "c1",
          conversationId: "conv-1",
          conversationType: 1,
          channelId: "bob",
          senderId: "hugo",
          source: 1,
          conversationSeq: 7,
          createdAt: 1000,
          clientCreatedAt: 900,
          messageType: 1,
          content: {
            contentType: "text",
            text: "hello",
            mentions: [],
          },
          senderName: "hugo",
          senderAvatar: "",
          senderDisplayName: "hugo",
          status: 1,
          isRead: false,
          isRecalled: false,
          isEdited: false,
          mentionUsers: [],
          mentionAll: false,
          attributes: { trace: "web" },
          extensions: {},
          version: 1,
          updatedAt: 1001,
        },
      }),
    ).toMatchObject({
      message: {
        conversationSeq: 7,
        createdAt: 1000,
        clientCreatedAt: 900,
        content: { contentType: "text", text: "hello", mentions: [] },
        attributes: { trace: "web" },
      },
    });
  });

  it("leaves invalid content fields to the core wire decoder", () => {
    expect(
      encodeWasmRequestForTesting({
        message: {
          clientMsgId: "c1",
          conversationId: "conv-1",
          conversationType: 1,
          channelId: "bob",
          senderId: "hugo",
          source: 1,
          conversationSeq: 7,
          createdAt: 1000,
          clientCreatedAt: 900,
          messageType: 1,
          content: {
            contentType: 0,
            text: "hello",
            mentions: [],
          },
          status: 1,
          version: 1,
          updatedAt: 1001,
        },
      }),
    ).toMatchObject({
      message: {
        content: { contentType: 0, text: "hello", mentions: [] },
      },
    });
  });

  it("does not coerce or reject unsigned integer fields in the bridge", () => {
    expect(
      encodeWasmRequestForTesting({
        message: {
          clientMsgId: "c1",
          conversationId: "conv-1",
          conversationType: 1,
          channelId: "bob",
          senderId: "hugo",
          source: 1,
          conversationSeq: "7",
          createdAt: 1000,
          clientCreatedAt: 900,
          messageType: 1,
          content: {
            contentType: "text",
            text: "hello",
            mentions: [],
          },
          status: 1,
          version: 1,
          updatedAt: 1001,
        },
      }),
    ).toMatchObject({
      message: { conversationSeq: "7" },
    });
    expect(
      encodeWasmRequestForTesting({
        message: {
          clientMsgId: "c1",
          conversationId: "conv-1",
          conversationType: 1,
          channelId: "bob",
          senderId: "hugo",
          source: 1,
          conversationSeq: 7,
          createdAt: 1000,
          clientCreatedAt: 900,
          messageType: 1,
          content: {
            contentType: "text",
            text: "hello",
            mentions: [],
          },
          status: 1,
          version: -1,
          updatedAt: 1001,
        },
      }),
    ).toMatchObject({
      message: { version: -1 },
    });
  });
});

describe("stored conversation preview rendering", () => {
  it("renders core preview storage payloads as display text", () => {
    expect(displayTextFromStoredPreview('{"k":"im.preview.user_text","a":{"t":"111"}}')).toBe("111");
    expect(displayTextFromStoredPreview('{"k":"im.preview.image","a":{"m":true}}')).toBe("[动图]");
    expect(displayTextFromStoredPreview("plain legacy preview")).toBe("plain legacy preview");
  });

  it("strips markdown control syntax from conversation previews", () => {
    const markdown = "![图片描述](https://example.invalid/a.png) 但是**撒大法师** ~~短发~~ <u>重点</u> `code`";
    expect(displayTextFromStoredPreview(JSON.stringify({ k: "im.preview.user_text", a: { t: markdown } }))).toBe(
      "[图片] 图片描述 但是撒大法师 短发 重点 code",
    );
    expect(previewTextFromMessageContent({ contentType: "text", data: { text: markdown } })).toBe(
      "[图片] 图片描述 但是撒大法师 短发 重点 code",
    );
    expect(
      previewTextFromMessageContent({
        contentType: "rich_text",
        data: {
          rich_text: {
            title: "发布说明",
            plainText: "fallback",
            sourcePayload: {
              markdown: "#### ~~**<u>发布</u>**~~\n- Fixed resend state",
            },
          },
        },
      }),
    ).toBe("发布\nFixed resend state");
    expect(previewVisualFromStoredPreview(JSON.stringify({ k: "im.preview.user_text", a: { t: markdown } }))).toEqual({
      kind: "text",
      text: "[图片] 图片描述 但是撒大法师 短发 重点 code",
    });
  });
});

describe("message bubble chrome", () => {
  it("keeps rich text inside the normal message bubble", () => {
    const message = messageFixture({
      content: {
        contentType: "rich_text",
        data: {
          rich_text: {
            plainText: "富文本内容",
            sourcePayload: {
              markdown: "## 富文本内容\n~~**重点**~~",
            },
          },
        },
      } as unknown as MessageContent,
    });

    expect(isChromelessCardBubble(message)).toBe(false);
  });
});

describe("sticker playback", () => {
  it("plays sticker web animations by default unless explicitly disabled", () => {
    expect(isStickerPlayAnimatedFromExtra(undefined)).toBe(true);
    expect(isStickerPlayAnimatedFromExtra({})).toBe(true);
    expect(isStickerPlayAnimatedFromExtra({ sticker_play_animated: "1" })).toBe(true);
    expect(isStickerPlayAnimatedFromExtra({ sticker_play_animated: "true" })).toBe(true);
    expect(isStickerPlayAnimatedFromExtra({ sticker_play_animated: "0" })).toBe(false);
    expect(isStickerPlayAnimatedFromExtra({ sticker_play_animated: "false" })).toBe(false);
  });
});

describe("markdown rich text semantics", () => {
  it("recognizes and renders every composer-supported markdown family", () => {
    const samples = [
      "#### 标题",
      "**加粗**",
      "*斜体*",
      "~~删除线~~",
      "<u>下划线</u>",
      "`code`",
      "[链接](https://example.invalid)",
      "![图片描述](https://example.invalid/a.png)",
      "> 引用",
      "- 列表项",
      "1. 列表项",
      "---",
    ];
    for (const sample of samples) {
      expect(isMarkdown(sample), sample).toBe(true);
    }

    const markdown = "#### ~~**<u>发布</u>**~~\n![图片描述](https://example.invalid/a.png)\n[链接](https://example.invalid)\n`code`\n---";
    const html = renderMarkdown(markdown);
    expect(html).toContain("<h4>");
    expect(html).toContain("<u>发布</u>");
    expect(html).toContain("<img");
    expect(html).toContain("<s><strong><u>发布</u></strong></s>");
    expect(html).not.toContain("**");
    expect(html).not.toContain("&lt;u&gt;");
    expect(markdownToPlainText(markdown)).toBe("发布\n[图片] 图片描述\n链接\ncode");
  });

  it("does not treat emoji pack snake_case tokens as markdown emphasis", () => {
    const emojiTokens = "[face_with_open_mouth][face_with_open_eyes_and_hand_over_mouth]";
    expect(isMarkdown(emojiTokens)).toBe(false);
    expect(markdownToPlainText(emojiTokens)).toBe(emojiTokens);
    expect(isMarkdown("hello _italic_")).toBe(true);
    expect(isMarkdown("hello snake_case_text")).toBe(false);
  });
});

describe("i18n parity keys", () => {
  it("keeps zh-CN and en-US key sets aligned", () => {
    const zhKeys = listI18nKeys("zh-CN");
    const enKeys = listI18nKeys("en-US");
    const zhChat = flareMessages["zh-CN"].chat as Record<string, string>;
    const enChat = flareMessages["en-US"].chat as Record<string, string>;
    expect(enKeys).toEqual(zhKeys);
    expect(zhKeys).toContain("nav.conversations");
    expect(zhKeys).toContain("composer.offline");
    expect(zhKeys).toContain("diagnostics.title");
    expect(zhKeys).toContain("chat.noMoreMessages");
    expect(zhChat.noMoreMessages).toBe("没有更多消息了");
    expect(enChat.noMoreMessages).toBe("No earlier messages");
    expect(zhKeys).toContain("state.runtimeUnavailable");
  });
});

describe("shared message bubble skin", () => {
  it("keeps grouped bubbles on the shared Telegram-like tail geometry", () => {
    const bubbleCss = readFileSync(
      new URL(
        "../../../design-system/styles/chat/message-bubble.css",
        import.meta.url,
      ),
      "utf8",
    );

    expect(bubbleCss).toContain("border-radius: 14px 14px 14px 10px");
    expect(bubbleCss).toContain("border-radius: 14px 14px 10px 14px");
    expect(bubbleCss).toContain("border-bottom-left-radius: 7px");
    expect(bubbleCss).toContain("border-bottom-right-radius: 7px");
    expect(bubbleCss).toContain('clip-path: path("M18 1 C14 7 9 10 0 12 C5 15 13 15 18 9 Z")');
    expect(bubbleCss).toContain('clip-path: path("M0 1 C4 7 9 10 18 12 C13 15 5 15 0 9 Z")');
    expect(bubbleCss).not.toContain("transform: skew");
    expect(bubbleCss).not.toContain("rotate(45deg)");
  });

  it("keeps multi-select lightweight and hides avatars in select/recalled rows", () => {
    const bubbleCss = readFileSync(
      new URL(
        "../../../design-system/styles/chat/message-bubble.css",
        import.meta.url,
      ),
      "utf8",
    );
    const bubbleSource = readFileSync(
      new URL(
        "../../../components/messages/MessageBubble.vue",
        import.meta.url,
      ),
      "utf8",
    );

    expect(bubbleSource).toContain("&& !props.multiSelectMode");
    expect(bubbleSource).toContain("&& !isRecalled.value");
    expect(bubbleSource).toContain("message-select__check");
    expect(bubbleCss).toContain("width: 20px");
    expect(bubbleCss).toContain("background: var(--im-primary)");
    expect(bubbleCss).toContain(".message-select__check");
    expect(bubbleCss).not.toContain("radial-gradient(circle at 35% 28%");
  });

  it("发送不得等待 ack 才放行输入区：否则后续点击被 sending 守卫静默丢弃", () => {
    const workspace = readFileSync(
      new URL("../../components/FlareChatWorkspace.vue", import.meta.url),
      "utf8",
    );

    // 线上实测：ack 迟迟不回（一直到 30s 超时），而 `sending` 守卫覆盖同一段时间，
    // 期间用户的每一次点击都被 `if (sending.value) return;` 静默丢弃——
    // 没有气泡、没有提示、也没有进入核心，看起来就像发送键坏了。
    //
    // 发送本身已经是有状态的（核心入队前就以 sending 落库并发总线，
    // 失败翻 failed 并由气泡呈现重发），所以提交后必须立刻放行输入区。
    const awaited = workspace.match(/await withComposerSendDeadline\(/g) ?? [];
    expect(
      awaited.length,
      "发送路径不应 await withComposerSendDeadline；改为 void ... .catch(...) 让输入区立刻可用",
    ).toBe(0);

    // 失败仍要有反馈，不能默默吞掉
    expect(workspace).toContain("withComposerSendDeadline(");
    expect(workspace).toContain("toast.sendFailed");
  });

  it("媒体发送不得由应用自己上传：上传/进度/乐观物化归 SDK 核心", () => {
    const workspace = readFileSync(
      new URL("../../components/FlareChatWorkspace.vue", import.meta.url),
      "utf8",
    );

    // 核心的 send_with_media 把 data: / blob: / ph:// / 小程序临时路径当作待上传的
    // 本地媒体：先以 uploading 状态落库并发总线（气泡立刻出现），再上传并按字节回填
    // 进度，最后发送。应用若自己先调 media.upload_*，上传期间既没有气泡也没有进度，
    // 消息要等整段上传结束才出现——音频曾经就是这么做的。
    expect(workspace).not.toContain("uploadMediaInput");
    expect(workspace).not.toContain("client.media.upload");
    // 交给核心的方式：把 Blob 转成 data: 定位符
    expect(workspace).toContain("blobToCoreDataUrl");

    // https:// 不被核心视为本地媒体，是「应用自己上传后用资源地址发送」的口子，
    // 走 message.send_no_oss；这条边界不能反过来被当成默认路径。
    expect(workspace).not.toContain("send_no_oss");
  });

  it("renders media upload progress as an overlay on the media bubble", () => {
    const bubbleSource = readFileSync(
      new URL(
        "../../../components/messages/MessageBubble.vue",
        import.meta.url,
      ),
      "utf8",
    );
    const bubbleCss = readFileSync(
      new URL(
        "../../../design-system/styles/chat/message-bubble.css",
        import.meta.url,
      ),
      "utf8",
    );

    expect(bubbleSource).toContain("uploadProgressOnMedia");
    expect(bubbleSource).toContain("message-upload-progress--media");
    expect(bubbleCss).toContain(".message-upload-progress--media");
    expect(bubbleCss).toContain("position: absolute");
    expect(bubbleCss).toContain("backdrop-filter: blur(10px)");
  });

  it("surfaces file download/open-folder as the file card primary action", () => {
    const bubbleSource = readFileSync(
      new URL(
        "../../../components/messages/MessageBubble.vue",
        import.meta.url,
      ),
      "utf8",
    );
    const fileSource = readFileSync(
      new URL(
        "../../../components/messages/MessagesView/views/FileView.vue",
        import.meta.url,
      ),
      "utf8",
    );

    expect(bubbleSource).toContain("fileInlineMediaAction");
    expect(bubbleSource).toContain(":media-action=\"fileInlineMediaAction?.action\"");
    expect(bubbleSource).toContain("MessageMediaDownloadUiState");
    expect(bubbleSource).toContain(":media-state=\"fileInlineMediaAction?.state\"");
    expect(fileSource).toContain("CloudDownloadOutline");
    expect(fileSource).toContain("FolderOpenOutline");
    expect(fileSource).toContain("CloudDoneOutline");
    expect(fileSource).toContain("RefreshOutline");
    expect(fileSource).toContain("class=\"im-file__action\"");
    expect(fileSource).toContain("isDownloading");
    expect(fileSource).toContain("isDownloaded");
    expect(fileSource).toContain("im-file__progress");
    expect(fileSource).toContain("im-file__action--downloaded");
    expect(fileSource).toContain("emit(\"media-action\", props.mediaAction)");
    expect(fileSource).not.toContain(":title=\"primaryActionTitle\"");
  });

  it("keeps browser-downloaded media repeat-downloadable when local reveal is unavailable", () => {
    const chatSource = readFileSync(
      new URL("../../components/FlareChatWorkspace.vue", import.meta.url),
      "utf8",
    );
    const listSource = readFileSync(
      new URL(
        "../../../components/messages/MessageList.vue",
        import.meta.url,
      ),
      "utf8",
    );

    expect(chatSource).toContain("type MessageMediaDownloadUiState");
    expect(chatSource).toContain("messageMediaDownloadUiStates");
    expect(chatSource).toContain("states[mediaMessageId(messageRow)] = \"openFolder\"");
    expect(chatSource).toContain("return canRevealDownloadedMedia() ? \"openMediaFolder\" : \"downloadMedia\"");
    expect(chatSource).toContain("await startBrowserDownload(browserUrl, source.displayFileName)");
    expect(chatSource).toContain("setMediaDownloadState(source, \"notDownloaded\")");
    expect(chatSource).toContain(":media-download-states=\"messageMediaDownloadUiStates\"");
    expect(listSource).toContain("mediaDownloadStates?: Record<string, MessageMediaDownloadUiState>");
    expect(listSource).toContain(":media-download-state=\"mediaDownloadStates?.[messageActionId(item.message)] ?? 'idle'\"");
  });

  it("keeps media hover download controls icon-only and avoids multi-image overlays", () => {
    const bubbleSource = readFileSync(
      new URL(
        "../../../components/messages/MessageBubble.vue",
        import.meta.url,
      ),
      "utf8",
    );
    const bubbleCss = readFileSync(
      new URL(
        "../../../design-system/styles/chat/message-bubble.css",
        import.meta.url,
      ),
      "utf8",
    );

    expect(bubbleSource).toContain("if (![\"image\", \"video\"].includes(contentType.value))");
    expect(bubbleSource).toContain("mediaStateModel(props.mediaDownloadState ?? \"idle\")");
    expect(bubbleSource).toContain(":aria-label=\"mediaHoverAction.label\"");
    expect(bubbleSource).toContain(":disabled=\"!mediaHoverAction.action\"");
    expect(bubbleSource).not.toContain("<span>{{ mediaHoverAction.label }}</span>");
    expect(bubbleCss).toContain("width: 38px");
    expect(bubbleCss).toContain("font-size: 23px");
    expect(bubbleCss).toContain(".message-media-hover-action--downloading");
    expect(bubbleCss).toContain(".message-media-hover-action--downloaded");
    expect(bubbleCss).toContain(".message-bubble:focus-within .message-media-hover-action--folder:not(:focus-visible)");
    expect(bubbleCss).toContain(".message-bubble:hover .message-media-hover-action--folder");
    expect(bubbleCss).not.toContain(".message-media-hover-action span");
  });

  it("keeps sent rich message descriptions readable on outgoing bubbles", () => {
    const messageViewCss = readFileSync(
      new URL(
        "../../../design-system/styles/messages-view.css",
        import.meta.url,
      ),
      "utf8",
    );

    expect(messageViewCss).toContain(".message-bubble-self:not(.message-bubble--chromeless-media):not(.message-bubble--chromeless-card) .business-message-view__title");
    expect(messageViewCss).toContain("rgba(255, 255, 255, 0.78)");
    expect(messageViewCss).toContain(".business-detail-block");
  });

  it("prefers resolved remote media over stored object URLs for downloads", () => {
    const chatSource = readFileSync(
      new URL("../../components/FlareChatWorkspace.vue", import.meta.url),
      "utf8",
    );

    expect(chatSource).toContain("...(!source.remoteFileId && source.sourceHttpUrl ? { sourceHttpUrl: source.sourceHttpUrl } : {})");
    expect(chatSource.indexOf("if (source.remoteFileId)")).toBeLessThan(
      chatSource.indexOf("if (source.browserUrl)"),
    );
    expect(chatSource).toContain("if (typeof response === \"string\") return response.trim()");
  });
});

describe("chat route pinned content", () => {
  it("uses compact tabs only when pinned messages exist", () => {
    const chatSource = readFileSync(
      new URL("../../components/FlareChatWorkspace.vue", import.meta.url),
      "utf8",
    );
    const shellCss = readFileSync(
      new URL(
        "../../../design-system/styles/flutter-shell.css",
        import.meta.url,
      ),
      "utf8",
    );
    const routeCss = readFileSync(
      new URL("../../styles/routes/chat.css", import.meta.url),
      "utf8",
    );

    expect(chatSource).toContain("const showContentTabs = computed");
    expect(chatSource).toContain("pinnedCount.value > 0");
    expect(chatSource).toContain("chat-content-tabs");
    expect(chatSource).toContain("showingPinnedTab");
    expect(chatSource).toContain("chatContentTab === 'messages'");
    expect(chatSource).not.toContain("pinTabDisabled");
    expect(shellCss).toContain(".pinned-panel");
    expect(shellCss).not.toContain(".pinned-bar");
    expect(routeCss).toContain(".chat-content-tab--active");
    expect(routeCss).toContain("min-height: 28px");
    expect(routeCss).not.toContain(".pinned-bar");
  });

  it("marks pinned bubbles and keeps message pin state sourced from core pinned attributes", () => {
    const bubbleSource = readFileSync(
      new URL(
        "../../../components/messages/MessageBubble.vue",
        import.meta.url,
      ),
      "utf8",
    );
    const bubbleCss = readFileSync(
      new URL(
        "../../../design-system/styles/chat/message-bubble.css",
        import.meta.url,
      ),
      "utf8",
    );
    const sdkSource = readFileSync(
      new URL("../../../composables/useFlareCoreClient.ts", import.meta.url),
      "utf8",
    );

    expect(bubbleSource).toContain("message-pin-marker");
    expect(bubbleCss).toContain(".message-pin-marker");
    expect(sdkSource).toContain("message.attributes?.pinned === \"true\"");
    expect(sdkSource).not.toContain("message.attributes?.isPinned");
    expect(sdkSource).not.toContain("isPinned: pinned");
  });
});

describe("responsive web app theme contract", () => {
  it("exposes stable shell, message, and composer tokens for the SDK example app", () => {
    const css = buildFlareThemeStylesheet(false);

    // 断言别名关系而不是字面 hex：token 单源迁移后色值只在 tokens.json 里有一份，
    // --im-* 是指向 --flare-* 的兼容别名。写死 hex 等于把刚拆掉的耦合焊回来。
    expect(css).toContain("--im-brand-primary: var(--flare-color-primary");
    expect(css).toContain("--im-message-pinned-bg: #FFF7DE");
    expect(css).toContain(
      "--im-workbench-conversation-width: clamp(300px, 24vw, 360px)",
    );
    expect(css).toContain("--im-workbench-details-width: 320px");
    expect(css).toContain("--im-composer-desktop-height: 46px");
  });
});

describe("conversation navigation unread and actions", () => {
  it("keeps total unread on the rail message icon and off the conversation heading", () => {
    const shellSource = readFileSync(
      new URL("../../../components/shell/FlareWorkbenchShell.vue", import.meta.url),
      "utf8",
    );
    const layoutSource = readFileSync(new URL("../../components/FlareWorkbenchLayout.vue", import.meta.url), "utf8");
    const panelSource = readFileSync(new URL("../../components/FlareConversationsPanel.vue", import.meta.url), "utf8");

    expect(shellSource).toContain("messageUnreadCount");
    expect(shellSource).toContain("workbench-rail__badge");
    expect(layoutSource).toContain(":message-unread-count=\"sdk.totalUnread.value\"");
    expect(panelSource).not.toContain("<n-badge");
    expect(panelSource).not.toContain("stats.unread");
  });

  it("exposes per-conversation operations from the conversation row menu", () => {
    const rowSource = readFileSync(
      new URL("../../../components/conversation/FlareConversationRow.vue", import.meta.url),
      "utf8",
    );
    const panelSource = readFileSync(new URL("../../components/FlareConversationsPanel.vue", import.meta.url), "utf8");

    expect(rowSource).toContain("NDropdown");
    expect(rowSource).toContain("FlareConversationAction");
    expect(rowSource).toContain("clear_history");
    expect(rowSource).toContain("menuIcon(PinOutline)");
    expect(rowSource).toContain("im-conv-item__pin");
    expect(rowSource).toContain("trigger=\"manual\"");
    expect(rowSource).toContain("@contextmenu=\"openContextMenu\"");
    expect(rowSource).toContain("openMenuAt(event.clientX, event.clientY)");
    expect(rowSource).toContain("class=\"im-conv-item__menu-anchor\"");
    // 只断言锚点存在且被定位；不再断言 bottom/width 的具体像素 —— 那是视觉微调，
    // 焊进测试的结果是每次调版式都要改测试，而测试本身并不保护任何行为。
    expect(rowSource).toContain(".im-conv-item__menu-anchor {");
    expect(rowSource).not.toContain("{{ t(\"conversation.pinTag\") }}</span>");
    expect(rowSource).not.toContain("EllipsisHorizontalOutline");
    expect(rowSource).not.toContain("class=\"im-conv-item__menu\"");
    expect(rowSource).not.toContain("openMenuFromButton");
    expect(rowSource).not.toContain("trigger=\"click\"");
    expect(rowSource).toContain("im-conv-menu-option--danger");
    expect(rowSource).toContain(":global(.im-conv-dropdown .n-dropdown-option-body)");
    expect(rowSource).toContain("align-items: center !important");
    expect(panelSource).toContain("@action=\"runConversationAction\"");
    expect(panelSource).toContain("sdk.runConversationOperation(action)");
    expect(panelSource).toContain("v-if=\"visibleConversations.rest.length\"");
  });
});

describe("chat message search drawer", () => {
  it("uses the SDK search flow with a dedicated responsive drawer surface", () => {
    const shellSource = readFileSync(
      new URL("../../../components/shell/FlareWorkbenchShell.vue", import.meta.url),
      "utf8",
    );
    const layoutSource = readFileSync(new URL("../../components/FlareWorkbenchLayout.vue", import.meta.url), "utf8");
    const sdkSource = readFileSync(new URL("../../../composables/useFlareCoreClient.ts", import.meta.url), "utf8");

    expect(shellSource).toContain("chatSearchDrawerClass");
    expect(shellSource).toContain("workbench-search-sheet");
    expect(shellSource).toContain(":class=\"chatSearchDrawerClass\"");
    expect(layoutSource).toContain("chatSearchLoading");
    expect(layoutSource).toContain("chatSearchError");
    expect(layoutSource).toContain("chatSearchSearched");
    expect(layoutSource).toContain("sdk.searchActiveMessages(query");
    expect(layoutSource).toContain("chatSearchResults.value.find");
    expect(layoutSource).toContain("class=\"chat-search-result-card\"");
    expect(layoutSource).toContain(".chat-search-panel__state");
    expect(layoutSource).toContain("chat-search-panel__state--idle");
    expect(layoutSource).toContain("selectChatSearchKind(option.value)");
    expect(layoutSource).toContain("displayTextFromStoredPreview");
    expect(layoutSource).toContain("previewTextFromMessageContent");
    expect(layoutSource).toContain("height: 44px");
    expect(layoutSource).toContain(":global(.workbench-search-sheet.mobile-sheet .n-drawer-body-content-wrapper)");
    expect(layoutSource).not.toContain("class=\"sheet-list chat-search-results\"");
    expect(layoutSource).not.toContain("message.textPreview?.trim() || chatSearchResultKindLabel");
    expect(sdkSource).toContain("client.messages.searchMessagesInConversation(query)");
    expect(sdkSource).toContain("client.messages.searchMessagesByQuery(query)");
  });

  it("maps search filters to typed SDK search kinds", () => {
    const layoutSource = readFileSync(new URL("../../components/FlareWorkbenchLayout.vue", import.meta.url), "utf8");

    expect(layoutSource).toContain("case \"text\":");
    expect(layoutSource).toContain("return [MessageSearchKind.Text]");
    expect(layoutSource).toContain("case \"media\":");
    expect(layoutSource).toContain("return [MessageSearchKind.Media]");
    expect(layoutSource).toContain("case \"image\":");
    expect(layoutSource).toContain("return [MessageSearchKind.Image]");
    expect(layoutSource).toContain("case \"video\":");
    expect(layoutSource).toContain("return [MessageSearchKind.Video]");
    expect(layoutSource).toContain("case \"audio\":");
    expect(layoutSource).toContain("return [MessageSearchKind.Audio]");
    expect(layoutSource).toContain("case \"file\":");
    expect(layoutSource).toContain("return [MessageSearchKind.File]");
    expect(layoutSource).toContain("return [MessageSearchKind.Message]");
  });
});
