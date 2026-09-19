// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { nextTick } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import type { FlareNavigationGroup } from "../../shared/contracts/application";
import FlareAdaptiveNavigation from "./FlareAdaptiveNavigation.vue";

const groups: readonly FlareNavigationGroup[] = [
  {
    id: "primary",
    items: [
      { id: "chats", label: "Chats", icon: "chats", badge: { kind: "count", count: 3, label: "3 unread conversations" } },
      { id: "search", label: "Search", icon: "search", disabled: true },
      { id: "media", label: "Media", icon: "image" },
    ],
  },
  {
    id: "utilities",
    items: [{ id: "settings", label: "Settings", icon: "settings" }],
  },
];

afterEach(() => {
  document.body.innerHTML = "";
});

describe("FlareAdaptiveNavigation", () => {
  it("renders an accessible icon-only rail with trailing utilities", async () => {
    const wrapper = mount(FlareAdaptiveNavigation, {
      attachTo: document.body,
      props: {
        groups,
        activeId: "chats",
        responsiveMode: "desktop",
        presentation: "rail",
        label: "Flare IM navigation",
      },
    });

    expect(wrapper.get("nav").attributes("data-presentation")).toBe("rail");
    expect(wrapper.get("nav").attributes("aria-label")).toBe("Flare IM navigation");
    expect(wrapper.findAll('[role="group"]')[1].classes()).toContain("is-trailing");

    const buttons = wrapper.findAll("button");
    expect(buttons[0].attributes("aria-current")).toBe("page");
    // An entry that is still the kit's own default (same id and same default label) reads from the
    // strings table, so a Chinese-first app does not show an English rail; a host's own wording stays.
    expect(buttons[0].attributes("aria-label")).toBe("消息");
    expect(buttons[0].attributes("title")).toBe("消息");
    expect(buttons[0].get(".flare-adaptive-navigation__label").text()).toBe("消息");
    expect(buttons[2].get(".flare-adaptive-navigation__label").text()).toBe("Media");

    await buttons[0].trigger("click");
    expect(wrapper.emitted("navigate")).toEqual([["chats"]]);
    wrapper.unmount();
  });

  it("moves vertical keyboard focus across groups and skips disabled items", async () => {
    const wrapper = mount(FlareAdaptiveNavigation, {
      attachTo: document.body,
      props: {
        groups,
        activeId: "chats",
        responsiveMode: "desktop",
        presentation: "rail",
      },
    });
    const buttons = wrapper.findAll("button");

    (buttons[0].element as HTMLButtonElement).focus();
    await buttons[0].trigger("keydown", { key: "ArrowDown" });
    await nextTick();
    expect(document.activeElement).toBe(buttons[2].element);

    await buttons[2].trigger("keydown", { key: "End" });
    expect(document.activeElement).toBe(buttons[3].element);
    wrapper.unmount();
  });
});
