import { downloadUrlWithFileName } from "flare-core-vue-im-ui/utils";

export type NativeDownloadedMediaActions = {
  revealDownloadedFile?: (path: string) => boolean | Promise<boolean>;
};

declare global {
  interface Window {
    flareNativeMediaActions?: NativeDownloadedMediaActions;
  }
}

export function canRevealDownloadedMedia(): boolean {
  return (
    typeof window !== "undefined" &&
    typeof window.flareNativeMediaActions?.revealDownloadedFile === "function"
  );
}

export async function revealDownloadedMediaFile(path: string): Promise<boolean> {
  const normalized = path.trim();
  if (!normalized || !canRevealDownloadedMedia()) return false;
  try {
    const result = await window.flareNativeMediaActions?.revealDownloadedFile?.(normalized);
    return result !== false;
  } catch {
    return false;
  }
}

export async function startBrowserDownload(url: string, fileName: string): Promise<boolean> {
  return downloadUrlWithFileName(url, fileName);
}
