export type FlareMediaKind =
  | "image"
  | "imageThumbnail"
  | "imageGroupItem"
  | "video"
  | "videoCover"
  | "audio"
  | "file"
  | string;

export interface FlareMediaResolveRequest {
  kind: FlareMediaKind;
  messageId?: string;
  fileId?: string;
  url?: string;
  localPath?: string;
  mimeType?: string;
  fileName?: string;
}

export type FlareMediaResolver = (
  request: FlareMediaResolveRequest,
) => string | Promise<string>;
