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
    const button = host.get(".flare-status-banner button");
    expect(button.text()).toBe("重试");
    await button.trigger("click");
    expect(retries).toBe(1);
    host.unmount();
  });
});
