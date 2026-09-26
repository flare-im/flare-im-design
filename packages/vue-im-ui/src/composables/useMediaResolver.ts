import { computed, inject, provide, ref, watch, type InjectionKey, type Ref } from "vue";
import type { FlareMediaResolveRequest, FlareMediaResolver } from "../shared/contracts/media";
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
  const { kind, messageId, fileId, url, localPath, mimeType, fileName } = request;
  return JSON.stringify([kind, messageId, fileId, url, localPath, mimeType, fileName]);
}

export function useResolvedMediaUrl(request: Ref<FlareMediaResolveRequest | null>) {
  const { resolveMediaUrl } = useFlareMediaResolver();
  const url = ref("");
  const loading = ref(false);
  const error = ref("");
  let version = 0;

  // Keyed by what the request says, not by the object: a timeline refresh maps every message into new request
  // objects, and resolving on identity blanked every picture to its loading state and fetched a fresh address for it
  // on each refresh — while an upload reports progress, several times a second.
  watch(
    computed(() => mediaRequestKey(request.value)),
    async () => {
      const next = request.value;
      version += 1;
      const current = version;
      url.value = "";
      error.value = "";
      if (!next) {
        loading.value = false;
        return;
      }
      loading.value = true;
      try {
        const resolved = await resolveMediaUrl(next);
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

  return { url, loading, error };
}
