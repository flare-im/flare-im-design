// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareDesktopAppShell from "./FlareDesktopAppShell.vue";

const navigation = [{ id: "main", items: [{ id: "chats", label: "Chats", icon: "comment" }] }];

describe("FlareDesktopAppShell", () => {
  it("emits one command per desktop shortcut and keeps them distinct", async () => {
    const wrapper = mount(FlareDesktopAppShell, {
      props: { navigation, activeNavigationId: "chats" },
      slots: { primary: "List", default: "Chat" },
    });
    const scope = wrapper.get("[tabindex='-1']");
    await scope.trigger("keydown", { key: "k", ctrlKey: true });
    await scope.trigger("keydown", { key: "f", metaKey: true });
    await scope.trigger("keydown", { key: "n", ctrlKey: true });
    await scope.trigger("keydown", { key: "D", ctrlKey: true, shiftKey: true });
    await scope.trigger("keydown", { key: ",", metaKey: true });
    await scope.trigger("keydown", { key: "/", altKey: true });
    await scope.trigger("keydown", { key: "Escape" });
    await scope.trigger("keydown", { key: "k" });

    expect(wrapper.emitted("command")?.map(([command]) => command)).toEqual([
      "openCommandPalette",
      "openSearch",
      "newConversation",
      "toggleDetails",
      "openSettings",
      "moreActions",
      "closeOverlay",
    ]);
  });

  it("forwards navigation from the adaptive rail", async () => {
    const wrapper = mount(FlareDesktopAppShell, {
      props: { navigation, activeNavigationId: "chats" },
      slots: { default: "Chat" },
    });
    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("navigate")).toEqual([["chats"]]);
  });
});
