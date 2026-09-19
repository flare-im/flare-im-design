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

export function useResolvedMediaUrl(request: Ref<FlareMediaResolveRequest | null>) {
  const { resolveMediaUrl } = useFlareMediaResolver();
  const url = ref("");
  const loading = ref(false);
  const error = ref("");
  let version = 0;

  watch(
    computed(() => request.value),
    async (next) => {
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
