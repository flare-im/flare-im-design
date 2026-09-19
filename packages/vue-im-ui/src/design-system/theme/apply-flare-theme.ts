import {
  applyFlareTheme as applyTokenTheme,
  type FlareCustomTheme,
  type FlareThemeName,
} from "@flare-im/tokens/theme";

export type FlareBrandTheme = FlareThemeName | FlareCustomTheme;

export function applyFlareColorScheme(
  brand: FlareBrandTheme = "violet",
  isDark = false,
  variant: "default" | "compact" | "callDark" | "highContrast" = "default",
  element?: HTMLElement,
): void {
  if (typeof document === "undefined" && !element) return;
  const target = element ?? document.documentElement;
  const dark = variant === "callDark" || isDark;
  applyTokenTheme(brand, dark ? "dark" : "light", target);
  target.dataset.theme = dark ? "dark" : "light";
  target.dataset.themeVariant = variant;
}

export function isSystemDarkPreferred(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return false;
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
}

export function watchPreferredColorScheme(onChange: (dark: boolean) => void): () => void {
  if (typeof window === "undefined" || !window.matchMedia) return () => {};
  const media = window.matchMedia("(prefers-color-scheme: dark)");
  const handler = () => onChange(media.matches);
  media.addEventListener("change", handler);
  return () => media.removeEventListener("change", handler);
}
