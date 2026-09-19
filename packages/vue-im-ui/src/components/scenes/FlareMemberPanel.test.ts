// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareMemberPanel from "./FlareMemberPanel.vue";

const members = [
  { id: "u1", title: "陈默", detail: "管理员", badge: "群主", actions: [{ id: "remove", label: "移出群聊", destructive: true }] },
  { id: "u2", title: "林夏", detail: "成员", actions: [{ id: "remove", label: "移出群聊" }] },
];

function render(props: Record<string, unknown>) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareMemberPanel, props);
    },
  }));
}

/**
 * The member list is a scene panel: it names itself, it reports a host action with the member it was
 * on, and it shows one state at a time — rows, or a way back from a failure, never both.
 * Release criterion §1 (component tests).
 */
describe("FlareMemberPanel", () => {
  it("names itself from the kit, and takes a host's title instead", () => {
    expect(render({ items: members }).find("section").attributes("aria-label")).toBeTruthy();
    expect(render({ items: members, title: "群成员（18）" }).find("h3").text()).toBe("群成员（18）");
  });

  it("lists a row per member with its detail and badge", () => {
    const wrapper = render({ items: members });
    const rows = wrapper.findAll(".scene-list__row");
    expect(rows).toHaveLength(2);
    expect(rows[0].find(".scene-list__name").text()).toBe("陈默");
    expect(rows[0].find(".scene-list__detail").text()).toBe("管理员");
    expect(rows[0].find(".scene-list__badge").text()).toBe("群主");
  });

  it("reports which action was taken on which member", async () => {
    const wrapper = render({ items: members });
    await wrapper.findAll(".scene-list__row")[1].find("button").trigger("click");
    expect(wrapper.findComponent(FlareMemberPanel).emitted("action")?.[0]).toEqual([{ id: "u2", action: "remove" }]);
  });

  it("shows a failure with a way back, and no rows behind it", async () => {
    const wrapper = render({ items: [], error: "名单没能取回来" });
    expect(wrapper.findAll(".scene-list__row")).toHaveLength(0);
    const retry = wrapper.findAll("button").find((b) => b.text().length > 0);
    await retry?.trigger("click");
    expect(wrapper.findComponent(FlareMemberPanel).emitted("reload")).toHaveLength(1);
  });

  it("says the list is empty in the reader's language when the host gives no words", () => {
    const wrapper = render({ items: [] });
    expect(wrapper.text()).toContain("暂无成员");
  });

  it("shows placeholders while it is loading, not an empty list", () => {
    const wrapper = render({ items: [], loading: true });
    expect(wrapper.findAll(".scene-list__row")).toHaveLength(0);
    expect(wrapper.find(".scene-list__items").exists()).toBe(false);
  });
});
