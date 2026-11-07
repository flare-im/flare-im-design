import { shallowRef } from "vue";
import { resolveFlareTheme, type FlareThemeMode } from "@flare-im/tokens/theme";

/** The colours a resource pack sets, by native field name (`bgPrimary`), per mode. */
export type FlareResourceColorSet = {
  light: Readonly<Record<string, string>>;
  dark: Readonly<Record<string, string>>;
};

type ColorTree = { [key: string]: string | ColorTree };

const STYLE_ID = "flare-resource-overlay";

// Scoped themes put the attribute on an element of their own, so a light subtree inside a dark page needs its own match.
const LIGHT_SELECTOR = ':root:not([data-flare-theme="dark"]), [data-flare-theme="light"]';
const DARK_SELECTOR = '[data-flare-theme="dark"]';

const applied = shallowRef<FlareResourceColorSet>({ light: {}, dark: {} });

let fields: Map<string, readonly string[]> | undefined;

/** Every colour field, named as the native kits name it, with where it sits in a theme's tree. */
function colorFields(): Map<string, readonly string[]> {
  if (fields) return fields;
  const found = new Map<string, readonly string[]>();
  const walk = (tree: ColorTree, name: string, path: readonly string[]): void => {
    for (const [key, value] of Object.entries(tree)) {
      const field = name ? name + key[0].toUpperCase() + key.slice(1) : key;
      if (typeof value === "string") found.set(field, [...path, key]);
      else walk(value, field, [...path, key]);
    }
  };
  walk(resolveFlareTheme("violet", "light").colors as ColorTree, "", []);
  fields = found;
  return found;
}

/** The colour keys a resource pack may name. */
export function flareResourceColorKeys(): Set<string> {
  return new Set(colorFields().keys());
}

/** The custom property behind a colour field: `messageStatusRead` is `--flare-color-message-status-read`. */
export function flareColorVariable(field: string): string {
  return `--flare-color-${field.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase()}`;
}

function block(selector: string, values: Readonly<Record<string, string>>): string {
  const lines = Object.entries(values).map(([field, value]) => `  ${flareColorVariable(field)}: ${value} !important;`);
  return lines.length ? `${selector} {\n${lines.join("\n")}\n}` : "";
}

/**
 * The stylesheet for a set of colours. `!important` because the kit's own rules reach higher specificity per brand and
 * a custom theme writes its values inline, and a pack is meant to win over both. Keys and values were checked against
 * the rules before they got here, so nothing in this text comes through unchecked.
 */
export function flareResourceColorCss(colors: FlareResourceColorSet): string {
  return [block(LIGHT_SELECTOR, colors.light), block(DARK_SELECTOR, colors.dark)].filter(Boolean).join("\n");
}

function writeStylesheet(css: string): void {
  if (typeof document === "undefined") return;
  const existing = document.getElementById(STYLE_ID);
  if (!css) {
    existing?.remove();
    return;
  }
  const style = existing ?? document.head.appendChild(Object.assign(document.createElement("style"), { id: STYLE_ID }));
  style.textContent = css;
}

/** Puts `colors` in force, replacing what an earlier call set. Empty groups take the stylesheet away. */
export function setFlareResourceColors(colors: FlareResourceColorSet): void {
  applied.value = colors;
  writeStylesheet(flareResourceColorCss(colors));
}

/**
 * `colors` (a theme's tree, which the caller owns) with the pack's values for `mode` written in. For what reads a theme
 * as values rather than through the custom properties; it reads a ref, so a computed around it follows the overlay.
 */
export function withFlareResourceColors<T extends object>(colors: T, mode: FlareThemeMode): T {
  for (const [field, value] of Object.entries(applied.value[mode === "dark" ? "dark" : "light"])) {
    const path = colorFields().get(field);
    if (!path) continue;
    let cursor = colors as ColorTree;
    for (const part of path.slice(0, -1)) cursor = cursor[part] as ColorTree;
    cursor[path[path.length - 1]] = value;
  }
  return colors;
}
