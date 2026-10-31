// @vitest-environment happy-dom
import { expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { useFlareI18nProvider } from "../../../../shared/i18n/useFlareI18n";
import SystemView from "./SystemView.vue";

const muted = JSON.stringify({ k: "im.preview.system", a: { ek: "group.muted", ik: "social.group.muted", p: { group_id: "g-1", mute_all: "true" } } });
const renamed = JSON.stringify({ k: "im.preview.system", a: { ek: "group.profile_updated", ik: "social.group.profile_updated", p: { display_name: "周末徒步群", group_id: "g-1" } } });
const withWords = JSON.stringify({ k: "im.preview.system", a: { ek: "group.muted", fb: "群已开启全员禁言", ik: "social.group.muted" } });

function render(locale: "zh-CN" | "en-US", textPreview: string) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(SystemView, {
        content: { contentType: "system", system: { eventKind: "", body: "" } } as never,
        isSelf: false,
        messageExtra: { textPreview },
      });
    },
  }));
}

it("names a timeline event without the server's words in the reader's language", () => {
  const zh = render("zh-CN", muted);
  expect(zh.text()).toBe("已开启全员禁言");
  const en = render("en-US", muted);
  expect(en.text()).toBe("All members were muted");
  const named = render("en-US", renamed);
  expect(named.text()).toBe("Group renamed to 周末徒步群");
  zh.unmount(); en.unmount(); named.unmount();
});

it("shows the server's own words for the event when it sends them", () => {
  const en = render("en-US", withWords);
  expect(en.text()).toBe("群已开启全员禁言");
  en.unmount();
});
