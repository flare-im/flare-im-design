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

  it("hides the dot when no presence is given", () => {
    wrapper = mount(FlareAvatar, { props: { userId: "u1" } });
    expect(wrapper.find(".im-avatar__status").exists()).toBe(false);
  });

  it("accepts the FlareIdentity aliases id / name", () => {
    wrapper = mount(FlareAvatar, { props: { id: "u9", name: "Zed" } });
    expect(wrapper.find(".im-avatar__fallback").text()).toBe("Z");
    wrapper.unmount();
    wrapper = mount(FlareAvatar, { props: { id: "u9", name: "Zed", userId: "u1", displayName: "Ann" } });
    expect(wrapper.find(".im-avatar__fallback").text()).toBe("A");
  });
});
