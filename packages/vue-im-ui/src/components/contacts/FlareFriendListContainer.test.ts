// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareFriendListContainer from "./FlareFriendListContainer.vue";

describe("FlareFriendListContainer", () => {
  it("passes its retry label to the error state", async () => {
    let retries = 0;
    const host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareFriendListContainer as Component, {
          state: { status: "error", error: "好友列表未能加载", retry: { available: true } },
          retryLabel: "重试",
          onRetry: () => { retries += 1; },
        });
      },
    }));
    // 一条都没有、而且是失败：这一屏上没有别的东西，所以失败本身就是这一屏的内容，
    // 画的是完整空态而不是一条细横幅（改前更严重的状态反而只有一条带子）。
    // 断言的行为没变：失败要给出一个真的能点、点了会重试的入口。
    expect(host.find(".flare-empty").exists()).toBe(true);
    expect(host.get(".flare-empty__title").text()).toBe("好友列表未能加载");
    const button = host.get(".flare-empty__act");
    expect(button.text()).toBe("重试");
    await button.trigger("click");
    expect(retries).toBe(1);
    host.unmount();
  });
});
