// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import FlareAuthShell from "./FlareAuthShell.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => { host?.unmount(); host = undefined; });

describe("FlareAuthShell", () => {
  it("keeps one task heading and exposes the product story", () => {
    host = mount(FlareAuthShell, {
      props: {
        product: "Flare",
        tagline: "安全 · 可靠 · 随时同步",
        headline: "连接重要的人",
        description: "消息自然衔接。",
        title: "登录",
        subtitle: "欢迎回来",
      },
      slots: { default: "表单" },
    });
    expect(host.findAll("h1")).toHaveLength(1);
    expect(host.get("h1").text()).toBe("登录");
    expect(host.text()).toContain("连接重要的人");
    expect(host.text()).toContain("表单");
  });

  it("emits back from a labelled touch target", async () => {
    host = mount(FlareAuthShell, {
      props: { product: "Flare", title: "创建账号", subtitle: "开始使用", backLabel: "返回登录" },
    });
    const back = host.get(".flare-auth-shell__back");
    expect(back.attributes("aria-label")).toBe("返回登录");
    await back.trigger("click");
    expect(host.emitted("back")).toHaveLength(1);
  });
});
