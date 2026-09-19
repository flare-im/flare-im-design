// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareScreenHeader from "./FlareScreenHeader.vue";

describe("FlareScreenHeader", () => {
  it("reads eyebrow, title and meta in that order", () => {
    const wrapper = mount(FlareScreenHeader, {
      props: { title: "通讯录", eyebrow: "团队", meta: "128 人" },
    });
    expect(wrapper.find("h1").text()).toBe("通讯录");
    expect(wrapper.find(".flare-screen-header__eyebrow").text()).toBe("团队");
    expect(wrapper.find(".flare-screen-header__meta").text()).toBe("128 人");
  });

  it("takes a leading control — what the screen is reached through, before its title", () => {
    const wrapper = mount(FlareScreenHeader, {
      props: { title: "通讯录" },
      slots: { leading: '<button class="host-back">返回</button>' },
    });
    const header = wrapper.find(".flare-screen-header");
    expect(header.find(".flare-screen-header__leading .host-back").exists()).toBe(true);
    // Before the title, not after it: a back key that follows the heading is not a back key.
    const children = Array.from(header.element.children).map((node) => node.className);
    expect(children.indexOf("flare-screen-header__leading")).toBeLessThan(children.indexOf("flare-screen-header__heading"));
  });

  it("takes no room when the host gives no leading control", () => {
    const wrapper = mount(FlareScreenHeader, { props: { title: "通讯录" } });
    expect(wrapper.find(".flare-screen-header__leading").exists()).toBe(false);
  });

  it("keeps trailing actions in their own region", () => {
    const wrapper = mount(FlareScreenHeader, {
      props: { title: "通讯录" },
      slots: { leading: '<button class="host-back">返回</button>', actions: '<button class="host-add">添加</button>' },
    });
    expect(wrapper.find(".flare-screen-header__actions .host-add").exists()).toBe(true);
    expect(wrapper.find(".flare-screen-header__leading .host-add").exists()).toBe(false);
  });
});
