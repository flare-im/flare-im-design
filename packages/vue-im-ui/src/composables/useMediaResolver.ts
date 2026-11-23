import { computed, inject, provide, ref, watch, type InjectionKey, type Ref } from "vue";
import type { FlareMediaResolveRequest, FlareMediaResolver } from "../shared/contracts/media";
import { flareIsTauriAssetAddress } from "../shared/contracts/plugin-ui";
import { proxiedMediaUrl } from "../utils/proxiedMediaUrl";

export type FlareMediaResolverContext = {
  resolveMediaUrl: FlareMediaResolver;
};

const defaultMediaResolver: FlareMediaResolver = (request) =>
  request.url || request.localPath || "";

const flareMediaResolverKey: InjectionKey<FlareMediaResolverContext> = Symbol(
  "flare-media-resolver",
);

export function useFlareMediaProvider(mediaResolver?: FlareMediaResolver): FlareMediaResolverContext {
  const context: FlareMediaResolverContext = {
    resolveMediaUrl: mediaResolver ?? defaultMediaResolver,
  };
  provide(flareMediaResolverKey, context);
  return context;
}

export function useFlareMediaResolver(): FlareMediaResolverContext {
  return inject(flareMediaResolverKey, {
    resolveMediaUrl: defaultMediaResolver,
  });
}

/** What a resolve request asks for, as one comparable value: two requests with the same key resolve the same. */
function mediaRequestKey(request: FlareMediaResolveRequest | null): string {
  if (!request) return "";
  const { kind, messageId, mediaIndex, skipLocalPreview, fileId, url, localPath, mimeType, fileName } = request;
  return JSON.stringify([kind, messageId, mediaIndex, skipLocalPreview, fileId, url, localPath, mimeType, fileName]);
}

export function useResolvedMediaUrl(request: Ref<FlareMediaResolveRequest | null>) {
  const { resolveMediaUrl } = useFlareMediaResolver();
  const url = ref("");
  const loading = ref(false);
  const error = ref("");
  const requestKey = computed(() => mediaRequestKey(request.value));
  const failedPreviewRequest = ref("");
  let version = 0;

  // Keyed by what the request says, not by the object: a timeline refresh maps every message into new request
  // objects, and resolving on identity blanked every picture to its loading state and fetched a fresh address for it
  // on each refresh — while an upload reports progress, several times a second.
  watch(
    [requestKey, failedPreviewRequest],
    async ([key, failedKey]) => {
      const next = request.value;
      version += 1;
      const current = version;
      error.value = "";
      if (!next) {
        url.value = "";
        loading.value = false;
        return;
      }
      try {
        const result = resolveMediaUrl(key === failedKey ? { ...next, skipLocalPreview: true } : next);
        if (typeof result !== "string") {
          url.value = "";
          loading.value = true;
        }
        const resolved = typeof result === "string" ? result : await result;
        if (current !== version) return;
        url.value = proxiedMediaUrl(resolved || next.url || next.localPath || "");
      } catch (err) {
        if (current !== version) return;
        error.value = err instanceof Error ? err.message : String(err || "media resolve failed");
        url.value = proxiedMediaUrl(next.url || next.localPath || "");
      } finally {
        if (current === version) {
          loading.value = false;
        }
      }
    },
    { immediate: true },
  );

  function fallbackFromLocal(failedUrl: string): void {
    const source = request.value;
    if (failedUrl === url.value && (failedUrl.startsWith("blob:") || flareIsTauriAssetAddress(failedUrl)) &&
      (source?.fileId || (source?.url && source.url !== failedUrl))) {
      failedPreviewRequest.value = requestKey.value;
    }
  }

  return { url, loading, error, fallbackFromLocal };
}
