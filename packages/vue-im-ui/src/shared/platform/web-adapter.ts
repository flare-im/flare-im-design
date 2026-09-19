// The web implementation of the platform contract: the DOM file input for
// pickers, navigator.share for sharing, CSS env() safe-area insets and, when the
// host asks for it, the History API for the back action. This is the ONE place
// in the kit that reads pointer / hover media queries.
import {
  normalizePlatformError,
  platformErr,
  platformOk,
  type FlarePickedFile,
  type FlarePickFilesOptions,
  type FlarePickImagesOptions,
  type FlarePlatformAdapter,
  type FlarePlatformCapabilities,
  type FlarePlatformResult,
  type FlarePointerKind,
  type FlareSafeAreaInsets,
  type FlareSharePayload,
} from "./contract";

function matches(query: string): boolean {
  if (typeof window === "undefined" || typeof window.matchMedia !== "function") return false;
  return window.matchMedia(query).matches;
}

/** Pointer kind from the pointer / any-pointer media features. */
export function detectWebPointer(): FlarePointerKind {
  if (typeof window === "undefined" || typeof window.matchMedia !== "function") return "unknown";
  const fine = matches("(pointer: fine)");
  const coarse = matches("(pointer: coarse)");
  const anyFine = matches("(any-pointer: fine)");
  const anyCoarse = matches("(any-pointer: coarse)");
  if ((fine || anyFine) && (coarse || anyCoarse)) return "mixed";
  if (fine) return "fine";
  if (coarse) return "coarse";
  return "unknown";
}

/** Capabilities the browser itself determines (the host still decides `bottomSheet`). */
export function detectWebCapabilities(adapter?: FlarePlatformAdapter | null): Omit<FlarePlatformCapabilities, "bottomSheet"> {
  const pointer = detectWebPointer();
  const hover = matches("(hover: hover)") || matches("(any-hover: hover)");
  const fineInput = pointer === "fine" || pointer === "mixed";
  const canShare = typeof navigator !== "undefined" && typeof (navigator as Navigator & { share?: unknown }).share === "function";
  return {
    pointer,
    hover,
    contextMenu: fineInput,
    keyboardShortcut: fineInput || hover,
    nativeBack: typeof adapter?.onNativeBack === "function",
    safeArea: true,
    filePicker: typeof adapter?.pickFiles === "function" ? "supported" : "unsupported",
    imagePicker: typeof adapter?.pickImages === "function" ? "supported" : "unsupported",
    share: typeof adapter?.share !== "function" ? "unsupported" : canShare ? "supported" : "fallback",
  };
}

function toPicked(file: File): FlarePickedFile {
  return { name: file.name, size: file.size, mimeType: file.type || undefined, file };
}

function pickViaInput(options: { multiple?: boolean; accept?: string }): Promise<FlarePlatformResult<FlarePickedFile[]>> {
  if (typeof document === "undefined") return Promise.resolve(platformErr("UNSUPPORTED", "no document to host a file input"));
  return new Promise((resolve) => {
    const input = document.createElement("input");
    input.type = "file";
    input.hidden = true;
    input.multiple = Boolean(options.multiple);
    if (options.accept) input.accept = options.accept;
    input.dataset.flarePlatformPicker = "true";
    let settled = false;
    const done = (result: FlarePlatformResult<FlarePickedFile[]>) => {
      if (settled) return;
      settled = true;
      input.remove();
      resolve(result);
    };
    input.addEventListener("change", () => {
      const files = Array.from(input.files ?? []);
      done(files.length ? platformOk(files.map(toPicked)) : platformErr("CANCELLED", "no file selected"));
    }, { once: true });
    input.addEventListener("cancel", () => done(platformErr("CANCELLED", "picker dismissed")), { once: true });
    document.body.appendChild(input);
    try {
      input.click();
    } catch (error) {
      done({ ok: false, error: normalizePlatformError(error) });
    }
  });
}

/** The part of `Window` the history back listener uses (a test passes a fake). */
export type FlareHistoryWindow = Pick<Window, "addEventListener" | "setTimeout"> & { history: Pick<History, "state" | "pushState" | "back"> };

const HISTORY_BACK_MARK = "flareNativeBack";

/**
 * The browser's back button as the platform back action. While a handler is registered, the page
 * sits on a same-URL history entry marked in `history.state` (the existing state is spread into it,
 * so a router's own fields survive). Going back off that entry calls the handler registered last;
 * when it consumes the action the mark is restored for the layers still open, otherwise the browser
 * continues back. A marked entry left behind by layers that closed on their own is passed through
 * the same way on the next back, so one press still leaves the page.
 */
export function createHistoryBackListener(win: FlareHistoryWindow): (handler: () => boolean) => () => void {
  const handlers: Array<() => boolean> = [];
  const marked = () => Boolean((win.history.state as Record<string, unknown> | null)?.[HISTORY_BACK_MARK]);
  let onMarkedEntry = marked();

  function mark(): void {
    if (!marked()) win.history.pushState({ ...(win.history.state ?? {}), [HISTORY_BACK_MARK]: true }, "");
    onMarkedEntry = true;
  }

  win.addEventListener("popstate", () => {
    const leftMarkedEntry = onMarkedEntry;
    onMarkedEntry = marked();
    if (onMarkedEntry || !leftMarkedEntry) return;
    const handler = handlers[handlers.length - 1];
    if (handler?.()) {
      // The consumed layer closes on the next render; mark again for whatever is still open.
      win.setTimeout(() => {
        if (handlers.length) mark();
      }, 0);
      return;
    }
    win.history.back();
  });

  return (handler) => {
    handlers.push(handler);
    mark();
    return () => {
      const index = handlers.lastIndexOf(handler);
      if (index !== -1) handlers.splice(index, 1);
    };
  };
}

function readInset(side: "top" | "right" | "bottom" | "left"): number {
  if (typeof document === "undefined") return 0;
  const value = getComputedStyle(document.documentElement).getPropertyValue(`--flare-safe-area-${side}`).trim();
  const parsed = Number.parseFloat(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

export interface FlareWebPlatformAdapterOptions {
  /**
   * Let the browser's back close the open kit layer (a page with a back control, a sheet, a
   * preview) instead of leaving the page. Off by default: it adds a history entry while a layer is
   * open, which a host with its own history handling may not want.
   */
  historyBack?: boolean;
}

/**
 * `createWebPlatformAdapter()` — pickers through a transient `<input type=file>`
 * (an empty or dismissed selection is CANCELLED), sharing through
 * `navigator.share` (missing → UNSUPPORTED, AbortError → CANCELLED,
 * NotAllowedError → PERMISSION_DENIED), safe-area insets from the
 * `--flare-safe-area-*` custom properties the host mirrors from `env()`, and
 * with `historyBack` the browser's back as `onNativeBack`.
 */
export function createWebPlatformAdapter(options: FlareWebPlatformAdapterOptions = {}): FlarePlatformAdapter {
  const onNativeBack = options.historyBack && typeof window !== "undefined" ? createHistoryBackListener(window) : undefined;
  return {
    ...(onNativeBack ? { onNativeBack } : {}),
    pickFiles(options: FlarePickFilesOptions = {}) {
      return pickViaInput({ multiple: options.multiple, accept: options.accept?.join(",") });
    },
    pickImages(options: FlarePickImagesOptions = {}) {
      return pickViaInput({ multiple: options.multiple, accept: options.video ? "image/*,video/*" : "image/*" });
    },
    async share(payload: FlareSharePayload) {
      const nav = typeof navigator === "undefined" ? undefined : (navigator as Navigator & { share?: (data: ShareData) => Promise<void> });
      if (!nav || typeof nav.share !== "function") return platformErr("UNSUPPORTED", "navigator.share is unavailable");
      try {
        await nav.share({ title: payload.title, text: payload.text, url: payload.url });
        return platformOk(undefined);
      } catch (error) {
        return { ok: false, error: normalizePlatformError(error) };
      }
    },
    safeAreaInsets(): FlareSafeAreaInsets {
      return { top: readInset("top"), right: readInset("right"), bottom: readInset("bottom"), left: readInset("left") };
    },
  };
}
