// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider, type FlareLocale } from "../../shared/i18n/useFlareI18n";
import FlareStatusBanner from "./FlareStatusBanner.vue";

function mountBanner(props: Record<string, unknown>, locale: FlareLocale = "zh-CN") {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareStatusBanner as Component, props);
    },
  }));
  return host.findComponent(FlareStatusBanner);
}

describe("FlareStatusBanner", () => {
  it("is a polite status strip of one line by default, with nothing to close", () => {
    const banner = mountBanner({ text: "正在同步", tone: "info" });
    expect(banner.attributes("role")).toBe("status");
    expect(banner.attributes("aria-live")).toBe("polite");
    expect(banner.get(".flare-status-banner__text").text()).toBe("正在同步");
    expect(banner.find(".flare-status-banner__title").exists()).toBe(false);
    expect(banner.find(".flare-status-banner__body").exists()).toBe(false);
    expect(banner.find(".flare-status-banner__dismiss").exists()).toBe(false);
  });

  it("carries a notice: a bold subject over the text, and a close key that reports dismiss", async () => {
    const banner = mountBanner({ text: "今晚 23:00 起维护 30 分钟。", title: "计划维护", tone: "warning", dismissible: true });
    expect(banner.classes()).toContain("flare-status-banner--warning");
    expect(banner.get(".flare-status-banner__title").text()).toBe("计划维护");
    expect(banner.get(".flare-status-banner__body .flare-status-banner__text").text()).toBe("今晚 23:00 起维护 30 分钟。");
    const close = banner.get(".flare-status-banner__dismiss");
    expect(close.attributes("aria-label")).toBe("关闭");
    expect(close.attributes("type")).toBe("button");
    await close.trigger("click");
    expect(banner.emitted("dismiss")).toHaveLength(1);
    expect(banner.emitted("action")).toBeUndefined();
    expect(mountBanner({ text: "x", dismissible: true }, "en-US").get(".flare-status-banner__dismiss").attributes("aria-label")).toBe("Close");
  });

  it("keeps its action key beside the close key, each reporting its own event", async () => {
    const banner = mountBanner({ text: "连接已断开", tone: "danger", actionText: "重试", dismissible: true });
    await banner.get(".flare-status-banner__action").trigger("click");
    expect(banner.emitted("action")).toHaveLength(1);
    expect(banner.emitted("dismiss")).toBeUndefined();
  });
});
