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

  it("routes a plain rail action straight back, and anchors a menu on one that carries items", async () => {
    const wrapper = mount(FlareAdaptiveNavigation, {
      attachTo: document.body,
      props: {
        groups,
        activeId: "chats",
        responsiveMode: "desktop",
        presentation: "rail",
        identity: { userId: "u1", displayName: "QA Bob" },
        actions: [
          {
            id: "newChat",
            label: "新建",
            icon: "add",
            menu: [{ id: "new:start", label: "发起聊天" }, { id: "new:addFriend", label: "加好友" }],
          },
          { id: "search", label: "搜索", icon: "search" },
        ],
      },
    });

    const actions = wrapper.findAll(".flare-adaptive-navigation__action");
    expect(actions).toHaveLength(2);

    // 没菜单的那个:点一下就把 id 交回宿主。
    await actions[1].trigger("click");
    expect(wrapper.emitted("navigate")).toEqual([["search"]]);

    // 带菜单的那个:点开的是菜单,不是一次 navigate —— 宿主收到的是菜单里选中的那一条。
    await actions[0].trigger("click");
    await nextTick();
    const entry = [...document.body.querySelectorAll("button, [role=menuitem]")]
      .find((node) => node.textContent?.includes("加好友"));
    expect(entry).toBeTruthy();
    (entry as HTMLElement).click();
    await nextTick();
    expect(wrapper.emitted("navigate")).toEqual([["search"], ["new:addFriend"]]);
    wrapper.unmount();
  });

  it("draws the identity bigger than a rail icon and keeps the actions off the rail's two-line height", () => {
    const wrapper = mount(FlareAdaptiveNavigation, {
      attachTo: document.body,
      props: {
        groups,
        activeId: "chats",
        responsiveMode: "desktop",
        presentation: "rail",
        identity: { userId: "u1", displayName: "QA Bob" },
        actions: [{ id: "search", label: "搜索", icon: "search" }],
      },
    });
    // 头像是这一段里最大的东西:它是「谁在用」,不是又一个动作图标(导航项的图标是 24)。
    const avatar = wrapper.get(".flare-adaptive-navigation__identity").get(".im-avatar");
    expect(avatar.attributes("style")).toContain("44px");
    // 动作不带文字 —— rail 上那 60px 是给「图标 + 一行标签」两行留的,动作不需要,
    // 所以 CSS 给它收到触达区那么高。这里锁的是「没有标签」这个前提。
    expect(wrapper.get(".flare-adaptive-navigation__action").find(".flare-adaptive-navigation__label").exists()).toBe(false);
    expect(wrapper.get('[aria-current="page"]').find(".flare-adaptive-navigation__label").exists()).toBe(true);
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
