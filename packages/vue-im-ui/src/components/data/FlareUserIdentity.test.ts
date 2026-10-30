// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareUserIdentity from "./FlareUserIdentity.vue";
describe("user identity summary", () => {
  it("shows the full nickname, account and avatar without truncation or an internal ID", () => {
    const user = {
      name: "运营审核用户的完整昵称",
      account: "full-account-20261029",
      avatarUrl: "/avatar.png",
    };
    const host = mount(FlareUserIdentity, { props: { user } });
    expect(host.text()).toContain(user.name);
    expect(host.text()).toContain(user.account);
    expect(host.get("img").attributes("src")).toBe(user.avatarUrl);
    host.unmount();
  });
  it("represents unavailable and loading states with labels, never a synthesized ID", async () => {
    const host = mount(FlareUserIdentity, {
      props: { user: { state: "unavailable" } },
    });
    expect(host.text()).toContain("用户资料不可用");
    await host.setProps({ user: { state: "loading" } });
    expect(host.attributes("aria-busy")).toBe("true");
    expect(host.text()).toContain("正在加载用户资料");
    host.unmount();
  });
});
