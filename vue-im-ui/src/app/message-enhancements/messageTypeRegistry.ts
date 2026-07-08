import { MessageBuildOp, MessageContentType } from "flare-core-typescript-sdk/web";
import type { Message } from "flare-core-typescript-sdk/web";
import type {
  CapabilityContext,
  ComposerPayloadRequest,
  EnhancedMessageKind,
  MessageCapabilities,
  OperationAvailability,
} from "./types";
import { messageIsPinned, messageStableId } from "./types";

export type ComposerActionDefinition = {
  kind: EnhancedMessageKind;
  op: string;
  label: string;
  description: string;
  acceptsFiles?: boolean;
  multipleFiles?: boolean;
  maxFileBytes?: number;
  defaultParams: () => Record<string, unknown>;
  buildRequest: (params: Record<string, unknown>, files?: File[]) => ComposerPayloadRequest;
};

const MB = 1024 * 1024;

function payload(kind: EnhancedMessageKind, fields: Record<string, unknown>): Record<string, unknown> {
  return {
    kind,
    payloadVersion: 1,
    ...fields,
    ext: {
      source: "flare-core-web-app",
      ...(fields.ext && typeof fields.ext === "object" ? fields.ext as Record<string, unknown> : {}),
    },
  };
}

type ImageSourceParam = {
  imageId: string;
  fileName?: string;
  mimeType?: string;
  size?: number;
  width?: number;
  height?: number;
};

type ContentPayloadRequest = {
  op: MessageBuildOp.CreateWithContent;
  kind: EnhancedMessageKind;
  previewText: string;
  params: {
    contentType: MessageContentType;
    data: Record<string, unknown>;
  };
};

function mediaContentRequest(
  kind: EnhancedMessageKind,
  contentType: MessageContentType,
  data: Record<string, unknown>,
  previewText: string,
): ContentPayloadRequest {
  return {
    op: MessageBuildOp.CreateWithContent,
    kind,
    previewText,
    params: { contentType, data },
  };
}

function mediaSize(params: Record<string, unknown>): number {
  return optionalNumberParam(params, "fileSize") || optionalNumberParam(params, "size");
}

function firstSelectedFile(files: File[]): File | undefined {
  return files.find((file) =>
    typeof File === "undefined" ? Boolean(file?.name) : file instanceof File,
  );
}

function basenameFromPath(value: string): string {
  const raw = value.trim();
  if (!raw) return "";
  const normalized = raw.replace(/\\/g, "/");
  const name = normalized.split("/").filter(Boolean).pop() ?? "";
  try {
    return decodeURIComponent(name);
  } catch {
    return name;
  }
}

function mediaFileName(
  params: Record<string, unknown>,
  files: File[],
  sourcePath: string,
  fallback: string,
): string {
  return (
    textParam(params, "fileName") ||
    firstSelectedFile(files)?.name.trim() ||
    basenameFromPath(sourcePath) ||
    fallback
  );
}

function mediaMimeType(params: Record<string, unknown>, files: File[], fallback: string): string {
  return textParam(params, "mimeType") || firstSelectedFile(files)?.type || fallback;
}

function mediaFileSize(params: Record<string, unknown>, files: File[]): number {
  return mediaSize(params) || firstSelectedFile(files)?.size || 0;
}

function imageInfo(source: {
  sourcePath: string;
  fileName?: string;
  mimeType: string;
  size: number;
  width?: number;
  height?: number;
}): Record<string, unknown> {
  return {
    uuid: source.sourcePath,
    imageId: source.sourcePath,
    url: source.sourcePath,
    ...(source.fileName ? { fileName: source.fileName } : {}),
    mimeType: source.mimeType || "image/jpeg",
    size: source.size || 0,
    width: source.width ?? 0,
    height: source.height ?? 0,
  };
}

function mediaMeta(params: Record<string, unknown>): Record<string, unknown> {
  const fileName = textParam(params, "fileName");
  const mimeType = textParam(params, "mimeType");
  const fileSize = optionalNumberParam(params, "fileSize") || optionalNumberParam(params, "size");
  return {
    ...(fileName ? { fileName } : {}),
    ...(mimeType ? { mimeType } : {}),
    ...(fileSize > 0 ? { fileSize, size: fileSize } : {}),
  };
}

function textParam(params: Record<string, unknown>, key: string): string {
  return String(params[key] ?? "").trim();
}

function requireTextParam(params: Record<string, unknown>, key: string, label: string): string {
  const value = textParam(params, key);
  if (!value) throw new Error(`${label} is required`);
  return value;
}

function requireFileOrTextParam(
  params: Record<string, unknown>,
  key: string,
  label: string,
): string {
  const value = textParam(params, key);
  const sourcePath = textParam(params, "sourcePath");
  if (!value && !sourcePath) throw new Error(`请选择真实文件或填写真实 ${label}`);
  return sourcePath || value;
}

function optionalNumberParam(params: Record<string, unknown>, key: string): number {
  const raw = params[key];
  if (raw === "" || raw === undefined || raw === null) return 0;
  const value = Number(raw);
  if (!Number.isFinite(value)) throw new Error(`${key} must be a finite number`);
  return value;
}

function generatedId(prefix: string): string {
  return `${prefix}-${Date.now()}`;
}

function scheduleTimeMs(params: Record<string, unknown>): number {
  const raw = textParam(params, "time");
  if (!raw) throw new Error("日程时间 is required");
  const numeric = Number(raw);
  if (Number.isFinite(numeric) && numeric > 0) {
    return numeric > 10_000_000_000 ? Math.trunc(numeric) : Math.trunc(numeric * 1000);
  }
  const parsed = Date.parse(raw);
  if (!Number.isFinite(parsed)) throw new Error("日程时间 must be a valid date/time");
  return parsed;
}

export const composerActions: ComposerActionDefinition[] = [
  {
    kind: "file",
    op: "create_file",
    label: "文件",
    description: "发送文件并展示名称、大小、类型和下载入口",
    acceptsFiles: true,
    maxFileBytes: 100 * MB,
    defaultParams: () => ({ sourcePath: "", fileId: "", fileName: "", mimeType: "", fileSize: 0 }),
    buildRequest: (params, files = []) => {
      const sourcePath = requireFileOrTextParam(params, "fileId", "fileId");
      const fileName = mediaFileName(params, files, sourcePath, "文件");
      const mimeType = mediaMimeType(params, files, "application/octet-stream");
      const fileSize = mediaFileSize(params, files);
      return mediaContentRequest(
        "file",
        MessageContentType.File,
        {
          fileId: sourcePath,
          fileName,
          mimeType,
          fileSize,
          url: sourcePath,
          description: String(params.description ?? ""),
        },
        fileName,
      );
    },
  },
  {
    kind: "image",
    op: "create_image",
    label: "照片",
    description: "发送单张图片，支持加载失败占位和预览",
    acceptsFiles: true,
    maxFileBytes: 30 * MB,
    defaultParams: () => ({ sourcePath: "", imageId: "", description: "", url: "", mimeType: "", width: 0, height: 0 }),
    buildRequest: (params, files = []) => {
      const sourcePath = requireFileOrTextParam(params, "imageId", "imageId");
      const mimeType = mediaMimeType(params, files, "image/jpeg");
      const fileName = mediaFileName(params, files, sourcePath, "");
      const source = imageInfo({
        sourcePath,
        fileName,
        mimeType,
        size: mediaFileSize(params, files),
        width: optionalNumberParam(params, "width"),
        height: optionalNumberParam(params, "height"),
      });
      return mediaContentRequest(
        "image",
        MessageContentType.Image,
        {
          source,
          thumbnail: source,
          description: String(params.description ?? ""),
        },
        String(params.description || "图片"),
      );
    },
  },
  {
    kind: "video",
    op: "create_video",
    label: "视频",
    description: "发送视频并保留封面、时长和文件限制状态",
    acceptsFiles: true,
    maxFileBytes: 500 * MB,
    defaultParams: () => ({ sourcePath: "", videoId: "", description: "", durationMs: 0, mimeType: "" }),
    buildRequest: (params, files = []) => {
      const sourcePath = requireFileOrTextParam(params, "videoId", "videoId");
      const mimeType = mediaMimeType(params, files, "video/mp4");
      const fileName = mediaFileName(params, files, sourcePath, "视频");
      const description = textParam(params, "description") || fileName;
      const durationMs = optionalNumberParam(params, "durationMs");
      return mediaContentRequest(
        "video",
        MessageContentType.Video,
        {
          videoId: sourcePath,
          source: {
            uuid: sourcePath,
            url: sourcePath,
            fileName,
            mimeType,
            size: mediaFileSize(params, files),
            durationMs,
            width: optionalNumberParam(params, "width"),
            height: optionalNumberParam(params, "height"),
          },
          cover: null,
          fileName,
          title: fileName,
          description,
        },
        description,
      );
    },
  },
  {
    kind: "audio",
    op: "create_audio",
    label: "语音",
    description: "发送语音，展示时长、播放和已播放状态",
    acceptsFiles: true,
    maxFileBytes: 50 * MB,
    defaultParams: () => ({ sourcePath: "", audioId: "", sourceUrl: "", description: "", durationMs: 0, mimeType: "" }),
    buildRequest: (params, files = []) => {
      void files;
      const fallbackSource = requireFileOrTextParam(params, "audioId", "audioId");
      const audioId = textParam(params, "audioId") || fallbackSource;
      const sourceUrl = textParam(params, "sourceUrl") || textParam(params, "mediaUrl") || textParam(params, "downloadUrl") || textParam(params, "url") || fallbackSource;
      const mimeType = textParam(params, "mimeType") || "audio/webm";
      return mediaContentRequest(
        "audio",
        MessageContentType.Audio,
        {
          audioId,
          source: {
            uuid: audioId,
            url: sourceUrl,
            ...(textParam(params, "fileName") ? { fileName: textParam(params, "fileName") } : {}),
            mimeType,
            size: mediaSize(params),
            durationMs: optionalNumberParam(params, "durationMs"),
          },
          description: String(params.description ?? ""),
        },
        String(params.description || "语音"),
      );
    },
  },
  {
    kind: "location",
    op: "create_location",
    label: "位置",
    description: "发送地点名称、地址、坐标和地图缩略图",
    defaultParams: () => ({ title: "", address: "", latitude: "", longitude: "" }),
    buildRequest: (params) => ({
      op: "create_location",
      kind: "location",
      previewText: requireTextParam(params, "title", "位置名称"),
      params: {
        latitude: requireTextParam(params, "latitude", "纬度"),
        longitude: requireTextParam(params, "longitude", "经度"),
        title: requireTextParam(params, "title", "位置名称"),
        address: textParam(params, "address"),
      },
    }),
  },
  {
    kind: "card",
    op: "create_card",
    label: "名片",
    description: "发送联系人名片，支持查看详情和转发",
    defaultParams: () => ({ id: "", cardType: "user", title: "", subtitle: "", avatar: "" }),
    buildRequest: (params) => ({
      op: "create_card",
      kind: "card",
      previewText: requireTextParam(params, "title", "名片标题"),
      params: {
        id: requireTextParam(params, "id", "名片 ID"),
        cardType: textParam(params, "cardType") || "user",
        title: requireTextParam(params, "title", "名片标题"),
        subtitle: textParam(params, "subtitle"),
        avatar: textParam(params, "avatar"),
      },
    }),
  },
  {
    kind: "schedule",
    op: "create_schedule",
    label: "日程",
    description: "发送标题、时间、地点和参与人",
    defaultParams: () => ({ scheduleId: generatedId("schedule"), title: "", time: "", location: "", participantUserIds: [] }),
    buildRequest: (params) => {
      const startTimeMs = scheduleTimeMs(params);
      return {
        op: "create_schedule",
        kind: "schedule",
        previewText: requireTextParam(params, "title", "日程标题"),
        params: {
          scheduleId: textParam(params, "scheduleId") || generatedId("schedule"),
          title: requireTextParam(params, "title", "日程标题"),
          startTimeMs,
          endTimeMs: startTimeMs + 60 * 60 * 1000,
          participantUserIds: Array.isArray(params.participantUserIds) ? params.participantUserIds : [],
          location: textParam(params, "location"),
        },
      };
    },
  },
  {
    kind: "task",
    op: "create_task",
    label: "任务",
    description: "发送负责人、截止时间和状态",
    defaultParams: () => ({ taskId: generatedId("task"), title: "", assignee: "", dueTime: "", status: "todo", participantUserIds: [] }),
    buildRequest: (params) => ({
      op: "create_task",
      kind: "task",
        previewText: requireTextParam(params, "title", "任务标题"),
        params: {
        taskId: textParam(params, "taskId") || generatedId("task"),
        title: requireTextParam(params, "title", "任务标题"),
        status: textParam(params, "status") || "todo",
        participantUserIds: Array.isArray(params.participantUserIds) ? params.participantUserIds : [],
      },
    }),
  },
  {
    kind: "linkCard",
    op: "create_link_card",
    label: "链接",
    description: "自动识别链接并生成标题、描述、封面和域名预览",
    defaultParams: () => ({ url: "", title: "", description: "", domain: "" }),
    buildRequest: (params) => ({
      op: "create_link_card",
      kind: "linkCard",
      previewText: textParam(params, "title") || requireTextParam(params, "url", "链接地址"),
      params: {
        url: requireTextParam(params, "url", "链接地址"),
        title: textParam(params, "title"),
        description: textParam(params, "description"),
        thumbnailUrl: textParam(params, "thumbnailUrl"),
        siteName: textParam(params, "domain") || textParam(params, "siteName"),
      },
    }),
  },
  {
    kind: "richText",
    op: "create_rich_doc",
    label: "富文本",
    description: "发送结构化富文本，支持标题、正文、列表、引用、链接和代码块",
    defaultParams: () => ({ title: "", markdown: "" }),
    buildRequest: (params) => ({
      op: "create_rich_doc",
      kind: "richText",
      previewText: requireTextParam(params, "title", "富文本标题"),
      params: {
        markdown: requireTextParam(params, "markdown", "富文本 Markdown"),
        title: requireTextParam(params, "title", "富文本标题"),
      },
    }),
  },
  {
    kind: "imageGroup",
    op: "create_image_group",
    label: "多图",
    description: "一次选择多张图片，按顺序九宫格展示",
    acceptsFiles: true,
    multipleFiles: true,
    maxFileBytes: 80 * MB,
    defaultParams: () => ({ description: "", imageSources: [] }),
    buildRequest: (params, files = []) => {
      void files;
      const imageSources = Array.isArray(params.imageSources)
        ? params.imageSources as ImageSourceParam[]
        : [];
      if (!imageSources.length) throw new Error("请选择真实图片文件");
      const description = String(params.description ?? "");
      return mediaContentRequest(
        "imageGroup",
        MessageContentType.ImageGroup,
        {
          images: imageSources.map((item) => imageInfo({
            sourcePath: item.imageId,
            fileName: item.fileName,
            mimeType: item.mimeType || "image/jpeg",
            size: item.size ?? 0,
            width: item.width ?? 0,
            height: item.height ?? 0,
          })),
          description,
          metadata: {
            source: "flare-core-web-app",
            imageCount: String(imageSources.length),
          },
        },
        description || imageSources.map((item) => item.fileName || "图片").join("、"),
      );
    },
  },
  {
    kind: "miniProgram",
    op: "create_mini_program",
    label: "小程序",
    description: "发送小程序名称、图标、标题、描述和入口路径",
    defaultParams: () => ({ appId: "", appName: "", pagePath: "", title: "", description: "", thumbnailUrl: "" }),
    buildRequest: (params) => ({
      op: "create_mini_program",
      kind: "miniProgram",
      previewText: requireTextParam(params, "title", "小程序标题"),
      params: {
        appId: requireTextParam(params, "appId", "小程序 App ID"),
        pagePath: textParam(params, "pagePath"),
        title: requireTextParam(params, "title", "小程序标题"),
        thumbnailUrl: textParam(params, "thumbnailUrl"),
        extra: {
          appName: textParam(params, "appName"),
          description: textParam(params, "description"),
        },
      },
    }),
  },
  {
    kind: "vote",
    op: "create_vote",
    label: "投票",
    description: "创建单选/多选投票，支持截止时间和匿名配置",
    defaultParams: () => ({ voteId: generatedId("vote"), title: "", options: [], multiple: false, anonymous: false, deadline: "", participantUserIds: [] }),
    buildRequest: (params) => {
      if (!Array.isArray(params.options) || params.options.length === 0) {
        throw new Error("投票选项 is required");
      }
      return {
        op: "create_vote",
          kind: "vote",
          previewText: requireTextParam(params, "title", "投票标题"),
          params: {
          voteId: textParam(params, "voteId") || generatedId("vote"),
          title: requireTextParam(params, "title", "投票标题"),
          options: params.options,
          participantUserIds: Array.isArray(params.participantUserIds) ? params.participantUserIds : [],
        },
      };
    },
  },
  {
    kind: "thread",
    op: "create_thread_reply",
    label: "话题",
    description: "从消息引用创建话题或线程入口",
    defaultParams: () => ({ threadId: "", text: "", title: "", summary: "" }),
    buildRequest: (params) => {
      const text =
        textParam(params, "text") ||
        textParam(params, "title") ||
        textParam(params, "summary");
      if (!text) throw new Error("话题回复 is required");
      return {
        op: "create_thread_reply",
        kind: "thread",
        previewText: text,
        params: {
          threadId: requireTextParam(params, "threadId", "Thread ID"),
          text,
        },
      };
    },
  },
  {
    kind: "notification",
    op: "create_notification",
    label: "通知",
    description: "发送会话内通知消息",
    defaultParams: () => ({ title: "", text: "" }),
    buildRequest: (params) => ({
      op: "create_notification",
      kind: "notification",
      previewText: requireTextParam(params, "text", "通知内容"),
      params: {
        title: textParam(params, "title") || "通知",
        body: requireTextParam(params, "text", "通知内容"),
      },
    }),
  },
  {
    kind: "announcement",
    op: "create_announcement",
    label: "公告",
    description: "发送会话公告",
    defaultParams: () => ({ title: "", text: "" }),
    buildRequest: (params) => ({
      op: "create_announcement",
      kind: "announcement",
      previewText: textParam(params, "title") || requireTextParam(params, "text", "公告内容"),
      params: {
        title: textParam(params, "title") || "公告",
        body: requireTextParam(params, "text", "公告内容"),
      },
    }),
  },
];

export function resolveComposerAction(op: string): ComposerActionDefinition | undefined {
  return composerActions.find((action) => action.op === op);
}

function available(enabled: boolean, reason?: string): OperationAvailability {
  return enabled ? { enabled: true } : { enabled: false, reason };
}

function hasAuthoritativeIdentity(message: Message): boolean {
  return message.conversationSeq > 0 || message.serverId.trim().length > 0;
}

function isLocalSending(message: Message): boolean {
  return Boolean(message.localState?.sending) && !hasAuthoritativeIdentity(message);
}

function isLocalFailed(message: Message): boolean {
  return Boolean(message.localState?.failed) && !hasAuthoritativeIdentity(message);
}

export function resolveMessageCapabilities(message: Message, context: CapabilityContext): MessageCapabilities {
  const id = messageStableId(message);
  const recalled = Boolean(message.isRecalled);
  const sending = isLocalSending(message);
  const failed = isLocalFailed(message);
  const deleted = !id;
  const offlineReason = context.connected ? undefined : "当前连接不可用";
  const active = context.connected && !recalled && !deleted;
  const self = message.senderId === context.currentUserId;

  return {
    canReact: available(active && !sending, sending ? "消息发送中" : offlineReason || "消息不可回应"),
    canReply: available(!context.multiSelectMode && !recalled && !deleted, "多选模式或消息不可回复"),
    canForward: available(!recalled && !deleted && !sending, "消息不可转发"),
    canCopy: available(!recalled && !deleted, "消息不可复制"),
    canEdit: available(!context.multiSelectMode && self && active && !sending && !failed, "只能编辑自己已发送的消息"),
    canDelete: available(active, offlineReason || "消息不可删除"),
    canRecall: available(!context.multiSelectMode && self && active && !failed, "只能撤回自己已发送的消息"),
    canPin: available(active && !sending, sending ? "消息发送中" : offlineReason || "消息不可置顶"),
    canMultiSelect: available(!recalled && !deleted, "消息不可多选"),
  };
}

export function messagePinnedLabel(message: Message): string {
  return messageIsPinned(message) ? "取消置顶" : "置顶消息";
}

export function resolveMessageMenuActions(
  message: Message,
  context: CapabilityContext,
): Record<string, boolean> {
  const capabilities = resolveMessageCapabilities(message, context);
  const self = message.senderId === context.currentUserId;
  const failed = isLocalFailed(message);
  const pinned = messageIsPinned(message);
  return {
    reply: capabilities.canReply.enabled,
    forward: capabilities.canForward.enabled,
    multiSelect: capabilities.canMultiSelect.enabled,
    edit: capabilities.canEdit.enabled,
    recall: capabilities.canRecall.enabled,
    resend: context.connected && self && failed,
    pin: capabilities.canPin.enabled && !pinned,
    unpin: capabilities.canPin.enabled && pinned,
    preview: !message.isRecalled,
    copy: capabilities.canCopy.enabled,
    mark: context.connected && !message.isRecalled,
    delete: capabilities.canDelete.enabled,
  };
}
