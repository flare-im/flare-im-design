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

/**
 * Where a message's picture, video or file stands on this device, as the host knows it. `openFolder`: saved, and the
 * host can show it in its folder — the key becomes a folder. `downloaded` is drawn the same way (the save just
 * finished). A host that finds the saved file gone passes `idle` again, and the key is a download once more.
 */
export type MessageMediaDownloadUiState = "idle" | "downloading" | "downloaded" | "openFolder";

export type FlareMediaResolver = (
  request: FlareMediaResolveRequest,
) => string | Promise<string>;

/** One image in an adaptive album grid (九宫格). */
export interface FlareGridImage {
  url?: string;
  alt?: string;
}

/** A selectable chat wallpaper — a solid/gradient color or an image. */
export interface FlareWallpaperOption {
  id: string;
  /** CSS color or gradient (native: a color/hex). Rendered when imageUrl is absent. */
  color?: string;
  /** Thumbnail image for image-backed wallpapers. */
  imageUrl?: string;
  label?: string;
}
