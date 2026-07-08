import type {
  FlareMediaResolveRequest,
  FlareMediaResolver,
} from "flare-core-vue-im-ui/contracts";
import { proxiedMediaUrl, sdkMediaProxyFields } from "flare-core-vue-im-ui/utils";
import type { FlareSdkContext } from "../../sdk/flareSdkContext";

type LocalPathResolver = (path: string) => string;

const CORE_MEDIA_PATH_SEGMENT = "/flare-media/media/";
const UUID_FILE_ID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

let localPathResolver: LocalPathResolver | undefined;

export function configureAppMediaLocalPathResolver(resolver?: LocalPathResolver): void {
  localPathResolver = resolver;
}

export function resolveAppMediaLocalPath(path: string): string {
  const value = path.trim();
  if (!value) return "";
  return localPathResolver ? localPathResolver(value) : value;
}

function readString(source: unknown, key: string): string {
  if (!source || typeof source !== "object") return "";
  const value = (source as Record<string, unknown>)[key];
  return typeof value === "string" ? value.trim() : "";
}

function pickRemoteUrl(resolved: unknown): string {
  if (!resolved || typeof resolved !== "object") return "";
  const topLevel = readString(resolved, "url") || readString(resolved, "cdnUrl");
  if (topLevel) return topLevel;
  const remote = (resolved as Record<string, unknown>).remote;
  if (!remote || typeof remote !== "object") return "";
  return readString(remote, "url") || readString(remote, "cdnUrl");
}

function pickLocalPath(resolved: unknown): string {
  return readString(resolved, "localPath");
}

function coreMediaFileIdFromUrl(url: string | undefined): string {
  const raw = url?.trim();
  if (!raw) return "";
  try {
    const parsed = new URL(raw, "http://flare.local");
    let path = parsed.pathname;
    const proxyPrefix = sdkMediaProxyFields().storageProxyPrefix?.replace(/\/$/, "");
    if (proxyPrefix && path.startsWith(`${proxyPrefix}/`)) {
      path = path.slice(proxyPrefix.length);
    }
    if (!path.includes(CORE_MEDIA_PATH_SEGMENT)) return "";
    const filename = decodeURIComponent(path.split("/").pop() ?? "").trim();
    const dotIndex = filename.lastIndexOf(".");
    const fileId = dotIndex > 0 ? filename.slice(0, dotIndex) : filename;
    return UUID_FILE_ID_RE.test(fileId) ? fileId : "";
  } catch {
    return "";
  }
}

function cacheKey(request: FlareMediaResolveRequest, fileId: string): string {
  return [
    request.kind,
    fileId,
    request.url ?? "",
    request.localPath ?? "",
  ].join("|");
}

export function createAppMediaResolver(sdk: FlareSdkContext): FlareMediaResolver {
  const cache = new Map<string, Promise<string>>();

  return async (request) => {
    const directUrl = request.url?.trim();
    const localPath = request.localPath?.trim();
    if (localPath) {
      return localPathResolver ? localPathResolver(localPath) : localPath;
    }

    const fileId = request.fileId?.trim() || coreMediaFileIdFromUrl(directUrl);
    if (!fileId) return directUrl ? proxiedMediaUrl(directUrl) : "";

    const key = cacheKey(request, fileId);
    const cached = cache.get(key);
    if (cached) return cached;

    const task = sdk.client.media
      .resolveMediaAccess({
        fileId,
        mediaUrl: directUrl ?? "",
      })
      .then((resolved) => {
        const remoteUrl = pickRemoteUrl(resolved);
        if (remoteUrl) return proxiedMediaUrl(remoteUrl);
        const resolvedLocalPath = pickLocalPath(resolved);
        if (resolvedLocalPath && localPathResolver) {
          return localPathResolver(resolvedLocalPath);
        }
        return "";
      })
      .catch((error) => {
        cache.delete(key);
        throw error;
      });
    cache.set(key, task);
    return task;
  };
}
