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
  flareMessages,
  resolveFlareMessage,
  setFlareRuntimeLocale,
  type FlareLocale,
} from "./messages";

export type { FlareLocale };

const STORAGE_KEY = "flare-web-locale";

export type FlareI18nContext = {
  locale: Readonly<Ref<FlareLocale>>;
  naiveLocale: Readonly<Ref<typeof zhCN>>;
  naiveDateLocale: Readonly<Ref<typeof dateZhCN>>;
  setLocale: (locale: FlareLocale) => void;
  t: (key: string, params?: Record<string, string | number>) => string;
  hasKey: (key: string) => boolean;
};

const flareI18nKey: InjectionKey<FlareI18nContext> = Symbol("flare-i18n");

function readStoredLocale(): FlareLocale {
  if (typeof localStorage === "undefined") return "zh-CN";
  const raw = localStorage.getItem(STORAGE_KEY);
  return raw === "en-US" ? "en-US" : "zh-CN";
}

function hasMessage(locale: FlareLocale, key: string): boolean {
  let cursor: unknown = flareMessages[locale];
  for (const part of key.split(".")) {
    if (!cursor || typeof cursor !== "object" || !(part in (cursor as Record<string, unknown>))) {
      return false;
    }
    cursor = (cursor as Record<string, unknown>)[part];
  }
  return typeof cursor === "string";
}

export function useFlareI18nProvider(initialLocale: FlareLocale = readStoredLocale()): FlareI18nContext {
  const locale = ref<FlareLocale>(initialLocale);
  setFlareRuntimeLocale(initialLocale);

  const naiveLocale = computed(() => (locale.value === "en-US" ? enUS : zhCN));
  const naiveDateLocale = computed(() => (locale.value === "en-US" ? dateEnUS : dateZhCN));

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
    if (typeof document !== "undefined") {
      document.documentElement.lang = next === "en-US" ? "en" : "zh-CN";
    }
  }

  if (typeof document !== "undefined") {
    document.documentElement.lang = locale.value === "en-US" ? "en" : "zh-CN";
  }

  const ctx: FlareI18nContext = {
    locale: readonly(locale),
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
    throw new Error("useFlareI18n() requires useFlareI18nProvider() in App.vue");
  }
  return ctx;
}

export function listI18nKeys(locale: FlareLocale = "zh-CN"): string[] {
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
  walk(flareMessages[locale] as Record<string, unknown>);
  return keys.sort();
}
