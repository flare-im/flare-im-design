import { FLARE_BREAKPOINT_DESKTOP_MIN, FLARE_BREAKPOINT_WIDE_DESKTOP_MIN } from "./layout";

export const flareWorkbenchBreakpoints = {
  appShellCompact: FLARE_BREAKPOINT_DESKTOP_MIN,
  appShellExpanded: FLARE_BREAKPOINT_WIDE_DESKTOP_MIN,
} as const;
