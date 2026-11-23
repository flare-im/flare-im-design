// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import FlareAvatar from "./FlareAvatar.vue";

let wrapper: ReturnType<typeof mount>;
afterEach(() => { wrapper?.unmount(); });

describe("FlareAvatar", () => {
  it("renders the presence dot from `presence` with a text label (not colour alone)", () => {
    wrapper = mount(FlareAvatar, { props: { userId: "u1", presence: "away" } });
    const dot = wrapper.find(".im-avatar__status");
    expect(dot.exists()).toBe(true);
    expect(dot.classes()).toContain("im-avatar__status--away");
    expect(dot.attributes("data-presence")).toBe("away");
    expect(dot.attributes("aria-label")).toBe("离开");
  });

  it("marks a group with a named people mark in place of the presence dot", async () => {
    wrapper = mount(FlareAvatar, { props: { userId: "g1", displayName: "产品设计组", group: true, presence: "online" } });
    const mark = wrapper.find(".im-avatar__group");
    expect(mark.attributes("role")).toBe("img");
    expect(mark.attributes("aria-label")).toBe("群聊");
    expect(mark.find(".flare-icon").exists()).toBe(true);
    expect(wrapper.find(".im-avatar__status").exists()).toBe(false);
    await wrapper.setProps({ group: false });
    expect(wrapper.find(".im-avatar__group").exists()).toBe(false);
    expect(wrapper.find(".im-avatar__status").exists()).toBe(true);
  });

  it("hides the dot when no presence is given", () => {
    wrapper = mount(FlareAvatar, { props: { userId: "u1" } });
    expect(wrapper.find(".im-avatar__status").exists()).toBe(false);
  });

  it("only shows the person without a click listener", () => {
    wrapper = mount(FlareAvatar, { props: { userId: "u1", displayName: "Ann", ariaLabel: "Open Ann" } });
    expect(wrapper.element.tagName).toBe("SPAN");
    expect(wrapper.attributes("aria-label")).toBeUndefined();
    expect(wrapper.classes()).not.toContain("im-avatar--interactive");
  });

  // Flutter's onTap: with a listener the avatar is a named button, so hosts stop wrapping it in one.
  it("is a named button that reports activation when the host takes the click", async () => {
    const clicks: MouseEvent[] = [];
    wrapper = mount(FlareAvatar, { props: { userId: "u1", displayName: "Ann", presence: "online", onClick: (event: MouseEvent) => clicks.push(event) } });
    expect(wrapper.element.tagName).toBe("BUTTON");
    expect(wrapper.attributes("type")).toBe("button");
    expect(wrapper.attributes("aria-label")).toBe("Ann, 在线");
    await wrapper.trigger("click");
    expect(clicks).toHaveLength(1);
    wrapper.unmount();
    wrapper = mount(FlareAvatar, { props: { userId: "u1", displayName: "Ann", ariaLabel: "打开个人中心", onClick: () => {} } });
    expect(wrapper.attributes("aria-label")).toBe("打开个人中心");
  });

  it("accepts the FlareIdentity aliases id / name", () => {
    wrapper = mount(FlareAvatar, { props: { id: "u9", name: "Zed" } });
    expect(wrapper.find(".im-avatar__fallback").text()).toBe("Z");
    wrapper.unmount();
    wrapper = mount(FlareAvatar, { props: { id: "u9", name: "Zed", userId: "u1", displayName: "Ann" } });
    expect(wrapper.find(".im-avatar__fallback").text()).toBe("A");
  });
});
