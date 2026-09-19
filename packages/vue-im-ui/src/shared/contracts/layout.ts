export type FlareViewportKind = "pc" | "ipad" | "h5";
export type FlareLayoutMode = "auto" | "pc" | "ipad" | "h5";
export type FlareDensityMode = "comfortable" | "compact";

/**
 * The kit's one set of width thresholds (tokens `breakpoints.sm` / `breakpoints.md`).
 *
 * Two families used to carry their own numbers: `useViewport` split at 600/900
 * to match `responsive.css` and the app shell, while `useFlareAdaptive` split at
 * 599/1023. Between 900 and 1023 a screen therefore got desktop CSS with iPad
 * component behaviour — sheets where the layout had already gone to three
 * columns. One source, one boundary, both families derived from it.
 */
export const FLARE_BREAKPOINT_TABLET_MIN = 600;
export const FLARE_BREAKPOINT_DESKTOP_MIN = 900;
export const FLARE_BREAKPOINT_H5_MAX = FLARE_BREAKPOINT_TABLET_MIN - 1;
export const FLARE_BREAKPOINT_IPAD_MAX = FLARE_BREAKPOINT_DESKTOP_MIN - 1;
/** `breakpoints.appShellExpanded` — where the shell earns a permanently expanded sidebar. */
export const FLARE_BREAKPOINT_WIDE_DESKTOP_MIN = 1500;
