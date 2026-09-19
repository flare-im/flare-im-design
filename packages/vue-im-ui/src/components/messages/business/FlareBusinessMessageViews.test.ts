// @vitest-environment happy-dom
import { afterEach, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import FlareAnnouncementMessageView from "./FlareAnnouncementMessageView.vue";
import FlareMiniProgramMessageView from "./FlareMiniProgramMessageView.vue";
import FlareScheduleMessageView from "./FlareScheduleMessageView.vue";
import FlareTaskMessageView from "./FlareTaskMessageView.vue";
import FlareVoteMessageView from "./FlareVoteMessageView.vue";

let wrapper: ReturnType<typeof mount> | undefined;
afterEach(() => { wrapper?.unmount(); wrapper = undefined; });

function render(view: Component, content: Record<string, unknown>) {
  wrapper = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(view, { content, isSelf: false });
  } }));
  return wrapper;
}

// No host handles an "open details" intent, so a card must not draw a button that does nothing.
it.each([
  ["announcement", FlareAnnouncementMessageView, { contentType: "announcement", title: "发版通知", content: "周五发布" }],
  ["schedule", FlareScheduleMessageView, { contentType: "schedule", title: "评审会", startTime: 1760000000000 }],
  ["task", FlareTaskMessageView, { contentType: "task", title: "整理发版说明", status: "open" }],
  ["vote", FlareVoteMessageView, { contentType: "vote", title: "午饭吃什么", options: [{ id: "a", text: "面" }, { id: "b", text: "饭" }] }],
])("the %s card offers no details button without a handler", (_kind, view, content) => {
  const card = render(view as Component, content);
  expect(card.text()).not.toContain("查看详情");
  expect(card.findAll("button").filter((button) => button.text().includes("查看详情"))).toHaveLength(0);
});

it("the mini program card names the program without its app id or page path", () => {
  const card = render(FlareMiniProgramMessageView as Component, {
    contentType: "mini_program", title: "报销助手", appId: "wx_internal_42", path: "pages/claim/index",
  });
  expect(card.text()).toContain("报销助手");
  expect(card.text()).not.toContain("wx_internal_42");
  expect(card.text()).not.toContain("pages/claim/index");
  expect(card.find("button").exists()).toBe(false);
});
