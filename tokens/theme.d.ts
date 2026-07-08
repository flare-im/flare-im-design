// Types for flare-im-design-tokens/theme
export interface FlareThemeInput {
  primary: string;
  success?: string;
  warning?: string;
  error?: string;
  info?: string;
}
export type FlareThemeOverrides = Record<string, string>;

export function deriveFlareTheme(opts: FlareThemeInput): FlareThemeOverrides;
export function flareThemeVars(overrides: FlareThemeOverrides): Record<string, string>;
export function applyFlareTheme(overrides: FlareThemeOverrides, el?: HTMLElement): void;
export const flarePresets: Record<
  "violet" | "ocean" | "forest" | "sunset" | "rose" | "graphite",
  FlareThemeOverrides
>;
export const flareColorMath: {
  shade(hex: string, delta: number): string;
  mix(hex: string, weight: number, target?: string): string;
};
