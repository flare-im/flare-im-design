export type FlareThemeName = "violet" | "ocean" | "forest" | "sunset" | "rose" | "graphite";
export type FlareThemeMode = "light" | "dark";

export interface FlareThemeColorMap {
  readonly [key: string]: string | FlareThemeColorMap;
}

export interface FlareThemeModeDefinition {
  readonly colors: FlareThemeColorMap;
}

export interface FlareCustomTheme {
  readonly name: string;
  readonly light: FlareThemeModeDefinition;
  readonly dark: FlareThemeModeDefinition;
}

export const flareThemeNames: readonly FlareThemeName[];
export const flareBuiltInThemes: Readonly<Record<FlareThemeName, {
  readonly label: string;
  readonly light: FlareThemeModeDefinition;
  readonly dark: FlareThemeModeDefinition;
}>>;
export function createFlareCustomTheme(input: FlareCustomTheme): FlareCustomTheme;
export function resolveFlareTheme(
  theme?: FlareThemeName | FlareCustomTheme,
  mode?: FlareThemeMode,
): FlareThemeModeDefinition;
export function flareThemeVars(
  theme?: FlareThemeName | FlareCustomTheme,
  mode?: FlareThemeMode,
): Record<string, string>;
export function applyFlareTheme(
  theme?: FlareThemeName | FlareCustomTheme,
  mode?: FlareThemeMode,
  element?: HTMLElement,
): void;
