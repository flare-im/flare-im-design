import { describe, expect, it } from "vitest";
import {
  flareCapabilityEnabled,
  flareFeatureEnabled,
  FLARE_DEFAULT_CONTACT_NAVIGATION,
  FLARE_DEFAULT_IM_NAVIGATION,
  resolveApplicationResponsiveMode,
  resolveMessageActionExtensions,
  resolveNavigationItems,
  resolveNavigationPresentation,
  paneModeMinWidth,
  resolveNavigationWidth,
  resolvePaneMode,
  resolveWorkspacePresentation,
} from "./application";
import layoutVectors from "../../../../../spec/application-layout-vectors.json";

describe("application composition contracts", () => {
  it("uses one responsive model for all shells", () => {
    expect([375, 820, 1180, 1600].map((width) => resolveApplicationResponsiveMode(width))).toEqual([
      "mobile", "tablet", "desktop", "wideDesktop",
    ]);
    expect(resolveApplicationResponsiveMode(1000, 2)).toBe("mobile");
    expect(resolveNavigationPresentation("wideDesktop")).toBe("expandedSidebar");
  });

  it("projects workspace regions without product routing", () => {
    expect(resolveWorkspacePresentation("mobile", true)).toEqual({
      paneMode: "singlePane", navigation: "bottom", detail: "route",
    });
    expect(resolveWorkspacePresentation("tablet", true).detail).toBe("overlay");
    // Below rail 72 + list 320 + chat 360 a tablet shows one pane, and a detail becomes a page.
    expect(resolveWorkspacePresentation("tablet", false, { width: 751 }).paneMode).toBe("singlePane");
    expect(resolveWorkspacePresentation("tablet", true, { width: 700 })).toEqual({ paneMode: "singlePane", navigation: "rail", detail: "route" });
    expect(resolveWorkspacePresentation("tablet", true, { width: 752 }).paneMode).toBe("dualPane");
    // Only the chat grows with the text: 72 + 320 + 360 x 1.3 = 860.
    expect(resolveWorkspacePresentation("tablet", false, { width: 859, textScale: 1.3 }).paneMode).toBe("singlePane");
    expect(resolveWorkspacePresentation("tablet", false, { width: 860, textScale: 1.3 }).paneMode).toBe("dualPane");
    expect(resolveWorkspacePresentation("desktop", true).paneMode).toBe("triplePane");
  });

  it("follows the one pane rule in the shared table", () => {
    expect(layoutVectors.panes.length).toBeGreaterThanOrEqual(20);
    for (const vector of layoutVectors.panes) {
      const metrics = {
        textScale: vector.scale,
        navigationWidth: vector.navigationWidth,
        primaryWidth: "primaryWidth" in vector ? vector.primaryWidth : undefined,
        detailWidth: "detailWidth" in vector ? vector.detailWidth : undefined,
      };
      expect(resolvePaneMode(vector.width, vector.hasDetail, metrics), `${vector.id}: ${vector.why}`).toBe(vector.expected);
    }
    expect(paneModeMinWidth("dualPane", { navigationWidth: resolveNavigationWidth("tablet") })).toBe(752);
    expect(paneModeMinWidth("triplePane")).toBe(980);
  });

  it("follows the shared application layout vectors", () => {
    for (const vector of layoutVectors.cases) {
      const mode = resolveApplicationResponsiveMode(vector.width, vector.scale);
      expect(mode, vector.id).toBe(vector.expected.mode);
      const presentation = resolveWorkspacePresentation(mode, vector.hasDetail, {
        width: vector.width, textScale: vector.scale, navigationWidth: vector.navigation ? undefined : 0,
      });
      expect({ paneMode: presentation.paneMode, detail: presentation.detail }, vector.id).toEqual({
        paneMode: vector.expected.paneMode, detail: vector.expected.detail,
      });
    }
    expect(resolveWorkspacePresentation("desktop", true).detail).toBe("inline");
  });

  it("keeps features, capabilities, and custom actions host-owned", () => {
    expect(flareFeatureEnabled({ enabled: ["contacts"] }, "contacts")).toBe(true);
    expect(flareCapabilityEnabled({ enabled: ["group.rename"] }, "group.rename")).toBe(true);
    expect(resolveMessageActionExtensions([
      { id: "inspect", label: "Inspect", order: 2 },
      { id: "translate", label: "Translate", capability: "message.translate", order: 1 },
      { id: "pay", label: "Pay", available: () => false },
    ], {}, { enabled: ["message.translate"] }).map((action) => action.id)).toEqual(["translate", "inspect"]);
  });

  it("provides removable, reorderable IM and contact navigation defaults", () => {
    expect(FLARE_DEFAULT_IM_NAVIGATION.map((item) => item.id)).toEqual(["chats", "contacts", "profile"]);
    expect(FLARE_DEFAULT_IM_NAVIGATION[0]?.icon).toBe("chats");
    expect(FLARE_DEFAULT_CONTACT_NAVIGATION.map((item) => item.id)).toEqual(["friends", "groups", "newFriends", "favorites"]);
    expect(resolveNavigationItems(FLARE_DEFAULT_IM_NAVIGATION, [
      { id: "profile", label: "Me", order: 3 },
      { id: "work", label: "Work", order: 2 },
      { id: "contacts", label: "Contacts", visible: false },
      { id: "chats", label: "Chats", order: 0 },
    ]).map((item) => item.id)).toEqual(["chats", "work", "profile"]);
  });
});
