import type { FlareLocationCoordinate } from "../shared/contracts/location";

/**
 * The browser (or webview) side of FlareLocationPicker's two location callbacks, so a Web or Tauri host passes
 * `ensurePermission` and `requestCurrentLocation` instead of writing its own geolocation adapter:
 *
 * - `ensurePermission()` answers from the Permissions API when it knows (granted true, denied false). While the
 *   answer is prompt — or the browser cannot say — it shows the browser's own prompt through one position request,
 *   and only a refusal is false: a fix, no fix in time or an unavailable position are true, and the picker then
 *   asks for the position. A page without a secure context, or without `navigator.geolocation`, is false at once.
 * - `requestCurrentLocation()` reads `navigator.geolocation`, first taking the fix the prompt step already got. It
 *   rejects on an insecure page, without the API, on a refusal and on no fix in time, and the picker turns to
 *   manual search.
 *
 * Nothing is read at import: the navigator is looked up on each call, so the module is safe to load during SSR.
 */
export interface FlareBrowserLocationHost {
  ensurePermission(): Promise<boolean>;
  requestCurrentLocation(): Promise<FlareLocationCoordinate>;
}

export interface FlareBrowserLocationHostOptions {
  /** The geolocation API; `navigator.geolocation` when omitted. */
  geolocation?: Pick<Geolocation, "getCurrentPosition"> | null;
  /** The Permissions API; `navigator.permissions` when omitted. */
  permissions?: Pick<Permissions, "query"> | null;
  /** Whether the page is a secure context; `globalThis.isSecureContext` when omitted (true where it is not defined). */
  secureContext?: boolean;
  /** How long one position request may take, in milliseconds (default 10000; the picker falls back after its own 5 s). */
  timeoutMs?: number;
  /** How old a cached position may be, in milliseconds (default 60000). */
  maximumAgeMs?: number;
}

const DEFAULT_TIMEOUT_MS = 10_000;
const DEFAULT_MAXIMUM_AGE_MS = 60_000;
/** `GeolocationPositionError.PERMISSION_DENIED`, for environments without the constant. */
const PERMISSION_DENIED = 1;

function browserNavigator(): Navigator | undefined {
  return typeof navigator === "undefined" ? undefined : navigator;
}

export function createFlareBrowserLocationHost(options: FlareBrowserLocationHostOptions = {}): FlareBrowserLocationHost {
  const timeout = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const maximumAge = options.maximumAgeMs ?? DEFAULT_MAXIMUM_AGE_MS;
  const geolocation = () =>
    (options.geolocation === undefined ? browserNavigator()?.geolocation : options.geolocation) ?? undefined;
  const permissions = () =>
    (options.permissions === undefined ? browserNavigator()?.permissions : options.permissions) ?? undefined;
  const secure = () =>
    options.secureContext ?? (typeof globalThis.isSecureContext === "boolean" ? globalThis.isSecureContext : true);
  // The fix the prompt step got, handed to the next position request instead of asking twice.
  let primed: FlareLocationCoordinate | null = null;

  // Both steps ask for the same accuracy, so the fix the prompt step gets is as good as a second request's.
  const position = (api: Pick<Geolocation, "getCurrentPosition">) =>
    new Promise<GeolocationPosition>((resolve, reject) => {
      api.getCurrentPosition(resolve, reject, { enableHighAccuracy: true, timeout, maximumAge });
    });

  return {
    async ensurePermission() {
      primed = null;
      const api = geolocation();
      if (!secure() || !api) return false;
      try {
        const state = (await permissions()?.query({ name: "geolocation" as PermissionName }))?.state;
        if (state === "granted") return true;
        if (state === "denied") return false;
      } catch {
        // A browser that cannot answer for geolocation: its prompt answers below.
      }
      try {
        const fix = await position(api);
        primed = { latitude: fix.coords.latitude, longitude: fix.coords.longitude };
        return true;
      } catch (error) {
        const code = (error as Partial<GeolocationPositionError> | null)?.code;
        const denied = (error as Partial<GeolocationPositionError> | null)?.PERMISSION_DENIED ?? PERMISSION_DENIED;
        return code !== denied;
      }
    },
    async requestCurrentLocation() {
      const ready = primed;
      primed = null;
      if (ready) return ready;
      const api = geolocation();
      if (!secure()) throw new Error("geolocation needs a secure context");
      if (!api) throw new Error("geolocation unavailable");
      const fix = await position(api);
      return { latitude: fix.coords.latitude, longitude: fix.coords.longitude };
    },
  };
}
