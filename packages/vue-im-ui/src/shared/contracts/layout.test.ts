import { describe, expect, it } from "vitest";
import {
  FLARE_BREAKPOINT_DESKTOP_MIN,
  FLARE_BREAKPOINT_H5_MAX,
  FLARE_BREAKPOINT_IPAD_MAX,
  FLARE_BREAKPOINT_TABLET_MIN,
  FLARE_BREAKPOINT_WIDE_DESKTOP_MIN,
} from "./layout";
import { flareWorkbenchBreakpoints } from "./desktop-workbench";
import { resolveApplicationResponsiveMode } from "./application";
import tokens from "../../../../../tokens/tokens.json";
import { BREAKPOINT_DESKTOP_PX, BREAKPOINT_TABLET_PX } from "../../composables/useViewport";

// N2 — the two viewport families used to carry their own numbers, so 900–1023
// was desktop to the stylesheet and iPad to the components at the same time.
describe("breakpoints", () => {
  it("has one source: the adaptive kinds and the viewport modes split at the same widths", () => {
    expect(BREAKPOINT_TABLET_PX).toBe(FLARE_BREAKPOINT_TABLET_MIN);
    expect(BREAKPOINT_DESKTOP_PX).toBe(FLARE_BREAKPOINT_DESKTOP_MIN);
  });

  it("leaves no width between the bands", () => {
    expect(FLARE_BREAKPOINT_H5_MAX + 1).toBe(FLARE_BREAKPOINT_TABLET_MIN);
    expect(FLARE_BREAKPOINT_IPAD_MAX + 1).toBe(FLARE_BREAKPOINT_DESKTOP_MIN);
  });

  // tokens.json is the design source; these constants are the TypeScript copy of
  // four of its breakpoints, so the copy is asserted against the source rather
  // than against a second set of literals.
  const px = (value: string) => Number.parseInt(value, 10);
  it("matches the design tokens", () => {
    expect(FLARE_BREAKPOINT_TABLET_MIN).toBe(px(tokens.breakpoints.sm));
    expect(FLARE_BREAKPOINT_DESKTOP_MIN).toBe(px(tokens.breakpoints.md));
    expect(FLARE_BREAKPOINT_WIDE_DESKTOP_MIN).toBe(px(tokens.breakpoints.appShellExpanded));
    expect(px(tokens.breakpoints.appShellCompact)).toBe(FLARE_BREAKPOINT_DESKTOP_MIN);
  });

  it("the workbench shell reads the same numbers instead of restating them", () => {
    expect(flareWorkbenchBreakpoints.appShellCompact).toBe(FLARE_BREAKPOINT_DESKTOP_MIN);
    expect(flareWorkbenchBreakpoints.appShellExpanded).toBe(FLARE_BREAKPOINT_WIDE_DESKTOP_MIN);
    // How many panes fit is a content rule (spec/application-layout-vectors.json), not a breakpoint: the
    // workbench carries no conversation widths of its own for it to drift from.
    expect(Object.keys(flareWorkbenchBreakpoints)).toEqual(["appShellCompact", "appShellExpanded"]);
    expect(Object.keys(tokens.breakpoints).filter((name) => name.startsWith("conversation"))).toEqual([]);
  });

  // The application mode ladder used to carry its own 600/900/1500.
  it("the application responsive ladder flips exactly at the shared widths", () => {
    expect(resolveApplicationResponsiveMode(FLARE_BREAKPOINT_TABLET_MIN - 1)).toBe("mobile");
    expect(resolveApplicationResponsiveMode(FLARE_BREAKPOINT_TABLET_MIN)).toBe("tablet");
    expect(resolveApplicationResponsiveMode(FLARE_BREAKPOINT_DESKTOP_MIN - 1)).toBe("tablet");
    expect(resolveApplicationResponsiveMode(FLARE_BREAKPOINT_DESKTOP_MIN)).toBe("desktop");
    expect(resolveApplicationResponsiveMode(FLARE_BREAKPOINT_WIDE_DESKTOP_MIN - 1)).toBe("desktop");
    expect(resolveApplicationResponsiveMode(FLARE_BREAKPOINT_WIDE_DESKTOP_MIN)).toBe("wideDesktop");
  });
});
