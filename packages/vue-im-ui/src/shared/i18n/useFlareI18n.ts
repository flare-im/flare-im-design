import {
  computed,
  inject,
  provide,
  readonly,
  ref,
  type InjectionKey,
  type Ref,
} from "vue";
import { enUS, dateEnUS, zhCN, dateZhCN } from "naive-ui";
import {
  FLARE_DEFAULT_LOCALE,
  flareMessages,
  resolveFlareLocale,
  resolveFlareMessage,
  setFlareRuntimeLocale,
  currentFlareRuntimeLocale,
  translateFlare,
  type FlareLocale,
} from "./messages";

export type { FlareLocale };

const STORAGE_KEY = "flare-web-locale";

export type FlareI18nContext = {
  locale: Readonly<Ref<FlareLocale>>;
  /** Text direction for the current locale (RTL for ar/he/fa/ur/…), mirrored to <html dir>. */
  direction: Readonly<Ref<"ltr" | "rtl">>;
  naiveLocale: Readonly<Ref<typeof zhCN>>;
  naiveDateLocale: Readonly<Ref<typeof dateZhCN>>;
  setLocale: (locale: FlareLocale) => void;
  t: (key: string, params?: Record<string, string | number>) => string;
  hasKey: (key: string) => boolean;
};

const flareI18nKey: InjectionKey<FlareI18nContext> = Symbol("flare-i18n");

const RTL_LANGUAGES = new Set(["ar", "he", "fa", "ur", "ps", "sd", "ug", "yi", "dv", "ku"]);

/** "rtl" for right-to-left languages, by primary language subtag. */
export function flareTextDirection(locale: FlareLocale | string): "ltr" | "rtl" {
  const lang = String(locale).toLowerCase().split(/[-_]/)[0];
  return RTL_LANGUAGES.has(lang) ? "rtl" : "ltr";
}

/** Any stored tag is honoured (the host may have registered it); empty → default. */
function readStoredLocale(): FlareLocale {
  if (typeof localStorage === "undefined") return FLARE_DEFAULT_LOCALE;
  const raw = localStorage.getItem(STORAGE_KEY)?.trim();
  return raw ? raw : FLARE_DEFAULT_LOCALE;
}

function applyDocumentLocale(locale: FlareLocale): void {
  if (typeof document === "undefined") return;
  document.documentElement.lang = locale;
  document.documentElement.dir = flareTextDirection(locale);
}

function hasMessage(locale: FlareLocale, key: string): boolean {
  let cursor: unknown = flareMessages[resolveFlareLocale(locale)];
  for (const part of key.split(".")) {
    if (!cursor || typeof cursor !== "object" || !(part in (cursor as Record<string, unknown>))) {
      return false;
    }
    cursor = (cursor as Record<string, unknown>)[part];
  }
  return typeof cursor === "string";
}

export function useFlareI18nProvider(initialLocale?: FlareLocale): FlareI18nContext {
  // A provider nested under another one — FlareUiProvider mounted inside a host
  // that already set the language — inherits it. Minting a fresh context here
  // would silently reset the host's locale to the stored default, and the host
  // would have no way to notice.
  const inherited = inject(flareI18nKey, null);
  if (initialLocale === undefined && inherited) return inherited;

  const resolved = initialLocale ?? readStoredLocale();
  const locale = ref<FlareLocale>(resolved);
  setFlareRuntimeLocale(resolved);

  // Naive UI ships its own locale packs; zh* keeps zhCN, everything else gets enUS.
  const isZh = computed(() => locale.value.toLowerCase().startsWith("zh"));
  const naiveLocale = computed(() => (isZh.value ? zhCN : enUS));
  const naiveDateLocale = computed(() => (isZh.value ? dateZhCN : dateEnUS));
  const direction = computed(() => flareTextDirection(locale.value));

  function t(key: string, params?: Record<string, string | number>): string {
    return resolveFlareMessage(locale.value, key, params);
  }

  function hasKey(key: string): boolean {
    return hasMessage(locale.value, key);
  }

  function setLocale(next: FlareLocale): void {
    locale.value = next;
    setFlareRuntimeLocale(next);
    if (typeof localStorage !== "undefined") {
      localStorage.setItem(STORAGE_KEY, next);
    }
    applyDocumentLocale(next);
  }

  applyDocumentLocale(locale.value);

  const ctx: FlareI18nContext = {
    locale: readonly(locale),
    direction: readonly(direction),
    naiveLocale: readonly(naiveLocale),
    naiveDateLocale: readonly(naiveDateLocale),
    setLocale,
    t,
    hasKey,
  };
  provide(flareI18nKey, ctx);
  return ctx;
}

export function useFlareI18n(): FlareI18nContext {
  const ctx = inject(flareI18nKey);
  if (!ctx) {
    throw new Error("useFlareI18n() requires useFlareI18nProvider() in an ancestor component.");
  }
  return ctx;
}

const runtimeI18n: Pick<FlareI18nContext, "t" | "hasKey"> = {
  t: (key, params) => translateFlare(key, params),
  hasKey: (key) => hasMessage(currentFlareRuntimeLocale(), key),
};

/**
 * For decoupled leaf components (the standalone message bodies): the provider's
 * context when one is mounted above, otherwise translation against the runtime
 * locale so the component still renders in a host that has no provider.
 */
export function useFlareI18nOptional(): Pick<FlareI18nContext, "t" | "hasKey"> {
  return inject(flareI18nKey, null) ?? runtimeI18n;
}

export function listI18nKeys(locale: FlareLocale = FLARE_DEFAULT_LOCALE): string[] {
  const keys: string[] = [];
  function walk(node: Record<string, unknown>, prefix = ""): void {
    for (const [key, value] of Object.entries(node)) {
      const path = prefix ? `${prefix}.${key}` : key;
      if (typeof value === "string") {
        keys.push(path);
      } else if (value && typeof value === "object") {
        walk(value as Record<string, unknown>, path);
      }
    }
  }
  walk(flareMessages[resolveFlareLocale(locale)] as Record<string, unknown>);
  return keys.sort();
}
