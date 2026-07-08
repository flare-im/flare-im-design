import type { FlareMediaKind, FlareMediaResolveRequest } from "../shared/contracts/media";
import { readString } from "./contentData";

const WINDOWS_ABSOLUTE_PATH = /^[A-Za-z]:[\\/]/;

export function isLocalMediaPath(value: string): boolean {
  const v = value.trim();
  return (
    v.startsWith("/") ||
    v.startsWith("~/") ||
    v.startsWith("file://") ||
    WINDOWS_ABSOLUTE_PATH.test(v)
  );
}

export function mediaPathFromId(value: string): string {
  const v = value.trim();
  if (!v) return "";
  if (!v.startsWith("file://")) return v;
  try {
    return decodeURIComponent(new URL(v).pathname);
  } catch {
    return v.replace(/^file:\/\//, "");
  }
}

export function isInlineBrowserMediaUrl(value: string): boolean {
  const v = value.trim();
  return v.startsWith("data:") || v.startsWith("blob:");
}

export function isLocalPlaceholderMediaId(value: string): boolean {
  return /^local-(image|audio|video|file)-[a-z0-9-]+$/i.test(value.trim());
}

export function buildMediaResolveRequest(input: {
  kind: FlareMediaKind;
  messageId?: string;
  url?: string;
  id?: string;
  localPath?: string;
  mimeType?: string;
  fileName?: string;
}): FlareMediaResolveRequest | null {
  const id = input.id?.trim() ?? "";
  const inlineUrl = id && isInlineBrowserMediaUrl(id) ? id : "";
  const url = input.url?.trim() || inlineUrl;
  const explicitLocalPath = input.localPath?.trim() ?? "";
  const localPath = inlineUrl
    ? ""
    : explicitLocalPath || (id && isLocalMediaPath(id) ? mediaPathFromId(id) : "");
  const fileId = localPath || inlineUrl || isLocalPlaceholderMediaId(id) ? "" : id;
  if (!url && !localPath && !fileId) return null;
  return {
    kind: input.kind,
    ...(input.messageId ? { messageId: input.messageId } : {}),
    ...(url ? { url } : {}),
    ...(localPath ? { localPath } : {}),
    ...(fileId ? { fileId } : {}),
    ...(input.mimeType ? { mimeType: input.mimeType } : {}),
    ...(input.fileName ? { fileName: input.fileName } : {}),
  };
}

export function readMediaLocalPath(source: Record<string, unknown>, root: Record<string, unknown>): string {
  return (
    readString(source, "localPath", "sourcePath", "localPreviewPath") ||
    readString(root, "localPath", "sourcePath", "localPreviewPath")
  );
}
