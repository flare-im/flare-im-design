import { flareDesignTokens } from "./dist/tokens.js";

export const flareThemeNames = Object.freeze([
  "violet",
  "ocean",
  "forest",
  "sunset",
  "rose",
  "graphite",
]);

export const flareBuiltInThemes = flareDesignTokens.themes;

const customRequiredPaths = [
  "colors.primary",
  "colors.bg.primary",
  "colors.text.primary",
  "colors.border.primary",
  "colors.focusRing",
  "colors.message.outgoing.background",
  "colors.message.outgoing.foreground",
  "colors.message.status.read",
  "colors.error",
];

const appliedVariables = new WeakMap();

function deepClone(value) {
  if (!value || typeof value !== "object") return value;
  return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, deepClone(item)]));
}

function deepMerge(base, override) {
  const result = deepClone(base);
  for (const [key, value] of Object.entries(override ?? {})) {
    result[key] = value && typeof value === "object" && !Array.isArray(value)
      ? deepMerge(result[key] ?? {}, value)
      : value;
  }
  return result;
}

function getPath(value, path) {
  return path.split(".").reduce((current, key) => current?.[key], value);
}

function flattenColors(colors, prefix = []) {
  const result = {};
  for (const [key, value] of Object.entries(colors)) {
    const next = [...prefix, key];
    if (value && typeof value === "object") Object.assign(result, flattenColors(value, next));
    else {
      const suffix = next
        .map((part) => part.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase())
        .join("-");
      result[`--flare-color-${suffix}`] = value;
    }
  }
  return result;
}

export function createFlareCustomTheme(input) {
  if (!input || !input.name || !input.light || !input.dark) {
    throw new TypeError("CustomTheme requires name, light, and dark semantic maps");
  }
  for (const mode of ["light", "dark"]) {
    for (const path of customRequiredPaths) {
      if (getPath(input[mode], path) === undefined) {
        throw new TypeError(`CustomTheme ${input.name}.${mode} is missing ${path}`);
      }
    }
  }
  return Object.freeze({ name: input.name, light: input.light, dark: input.dark });
}

export function resolveFlareTheme(theme = "violet", mode = "light") {
  const normalizedMode = mode === "dark" ? "dark" : "light";
  if (typeof theme === "string") {
    const builtIn = flareBuiltInThemes[theme];
    if (!builtIn) throw new RangeError(`Unknown Flare theme: ${theme}`);
    return deepClone(builtIn[normalizedMode]);
  }
  return deepMerge(flareBuiltInThemes.violet[normalizedMode], theme[normalizedMode]);
}

export function flareThemeVars(theme = "violet", mode = "light") {
  return flattenColors(resolveFlareTheme(theme, mode).colors);
}

export function applyFlareTheme(theme = "violet", mode = "light", element) {
  const target = element || (typeof document !== "undefined" ? document.documentElement : null);
  if (!target) return;

  for (const name of appliedVariables.get(target) ?? []) target.style.removeProperty(name);
  target.dataset.flareBrand = typeof theme === "string" ? theme : theme.name;
  target.dataset.flareTheme = mode === "dark" ? "dark" : "light";

  if (typeof theme === "string") {
    appliedVariables.set(target, []);
    return;
  }
  const variables = flareThemeVars(theme, mode);
  for (const [name, value] of Object.entries(variables)) target.style.setProperty(name, value);
  appliedVariables.set(target, Object.keys(variables));
}
