// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareContactDetail from "./FlareContactDetail.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => { host?.unmount(); host = undefined; });

const contact = { id: "u_lin", name: "林夏", remark: "", presence: "online" as const };

function mountDetail(props: Record<string, unknown>) {
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareContactDetail as Component, { contact, ...props });
    },
  }));
  return host;
}

describe("FlareContactDetail", () => {
  it("offers only the intents the host handles, so a stranger gets no friend-only actions", () => {
    const view = mountDetail({ onMessage: () => {} });
    expect(view.findAll(".flare-contact-detail__actions button").map((button) => button.text())).toEqual(["发消息"]);
    expect(view.find(".flare-contact-detail__foot").exists()).toBe(false);
    // No public handle: the account id is internal and never shown.
    expect(view.find(".flare-contact-detail__card").exists()).toBe(false);
    expect(view.text()).not.toContain("u_lin");
    expect(view.find('[role="switch"]').exists()).toBe(false);
  });

  it("gives a friend editable remark and description rows, the star switch and the danger zone", async () => {
    const events: string[] = [];
    const view = mountDetail({
      contact: { ...contact, remark: "设计评审", flareId: "linxia" }, description: "响应快",
      onMessage: () => events.push("message"), onCall: () => events.push("call"),
      onEdit: () => events.push("edit"), onEditDescription: () => events.push("editDescription"),
      onToggleStar: () => events.push("star"), onBlock: () => events.push("block"), onRemove: () => events.push("remove"),
      disabledActions: ["call"],
    });
    const actions = view.findAll(".flare-contact-detail__actions button");
    expect(actions.map((button) => button.text())).toEqual(["发消息", "语音通话"]);
    expect(actions[1].attributes("disabled")).toBeDefined();
    const rows = view.findAll(".flare-settings__row");
    expect(rows.map((row) => row.get(".flare-settings__label").text())).toEqual(["Flare ID", "备注", "描述", "星标好友"]);
    expect(rows[0].find(".flare-settings__chev").exists()).toBe(false);
    expect(rows[1].find(".flare-settings__chev").exists()).toBe(true);
    await rows[1].trigger("click");
    await rows[3].trigger("click");
    const foot = view.findAll(".flare-contact-detail__foot button");
    expect(foot.map((button) => button.text())).toEqual(["加入黑名单", "删除好友"]);
    await foot[1].trigger("click");
    expect(events).toEqual(["edit", "star", "remove"]);
  });
});
