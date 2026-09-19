// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { afterEach, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareAnnouncementReadBar from "./FlareAnnouncementReadBar.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => host?.unmount());

function mountBar(locale: "zh-CN" | "en-US", props: Record<string, unknown>) {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider(locale);
    return () => h(FlareAnnouncementReadBar as Component, props);
  } }));
  return host;
}

it("shows localized copy instead of message keys", () => {
  const zh = mountBar("zh-CN", { readCount: 3, memberCount: 4, selfRead: false });
  expect(zh.text()).toContain("3/4 人已读");
  expect(zh.text()).toContain("已读");
  expect(zh.text()).not.toContain("announcement.");
  zh.unmount();
  const en = mountBar("en-US", { readCount: 3, memberCount: 4, selfRead: false });
  expect(en.text()).toContain("3/4 read");
  expect(en.text()).toContain("Mark as read");
});

it("offers view unread only to a permitted host that handles it", () => {
  const unhandled = mountBar("en-US", { readCount: 1, memberCount: 4, selfRead: true, canViewUnread: true });
  expect(unhandled.text()).not.toContain("View unread");
  unhandled.unmount();
  const handled = mountBar("en-US", { readCount: 1, memberCount: 4, selfRead: true, canViewUnread: true, onViewUnread: () => {} });
  expect(handled.text()).toContain("View unread");
});
