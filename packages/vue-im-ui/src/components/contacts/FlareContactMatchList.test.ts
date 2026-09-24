// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareContactMatchList from "./FlareContactMatchList.vue";

const matches = [
  { userId: "u1", displayName: "陈默", matchedBy: "手机号 138****8000", alreadyFriend: false },
  { userId: "u2", displayName: "林夏", matchedBy: "Flare ID lin-xia", alreadyFriend: true },
];

function render(props: InstanceType<typeof FlareContactMatchList>["$props"]) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareContactMatchList, props);
    },
  }));
}

/**
 * Search results for people: each row says how it matched, and the trailing control differs by
 * whether they are already a friend — add, or message. Release criterion §1.
 */
describe("FlareContactMatchList", () => {
  it("lists a row per match, with the name and how it matched", () => {
    const wrapper = render({ matches });
    const rows = wrapper.findAll(".flare-contact-match-list__row");
    expect(rows).toHaveLength(2);
    expect(rows[0].find(".flare-contact-match-list__name").text()).toBe("陈默");
    expect(rows[0].find(".flare-contact-match-list__matched").text()).toBe("手机号 138****8000");
  });

  it("offers add to a stranger and message to a friend", () => {
    const wrapper = render({ matches });
    const buttons = wrapper.findAll(".flare-contact-match-list__row button");
    expect(buttons[0].text()).not.toBe(buttons[1].text());
  });

  it("reports the whole contact for each intent, and a row tap separately", async () => {
    const wrapper = render({ matches });
    const rows = wrapper.findAll(".flare-contact-match-list__row");
    await rows[0].find("button").trigger("click");
    await rows[1].find("button").trigger("click");
    await rows[0].trigger("click");
    const emitted = wrapper.findComponent(FlareContactMatchList).emitted();
    expect(emitted.addFriend?.[0]).toEqual([matches[0]]);
    expect(emitted.openConversation?.[0]).toEqual([matches[1]]);
    expect(emitted.selectContact?.[0]).toEqual([matches[0]]);
  });

  it("a trailing control does not also open the row", async () => {
    const wrapper = render({ matches });
    await wrapper.findAll(".flare-contact-match-list__row")[0].find("button").trigger("click");
    expect(wrapper.findComponent(FlareContactMatchList).emitted().selectContact).toBeUndefined();
  });

  it("says the search found nobody, rather than showing an empty box", () => {
    const wrapper = render({ matches: [] });
    expect(wrapper.find(".flare-contact-match-list__empty").exists()).toBe(true);
    expect(wrapper.findAll(".flare-contact-match-list__row")).toHaveLength(0);
  });

  it("shows placeholders while the search is running, and no empty state", () => {
    const wrapper = render({ matches: [], loading: true });
    expect(wrapper.find(".flare-contact-match-list__empty").exists()).toBe(false);
    expect(wrapper.findAll(".flare-contact-match-list__row").length).toBeGreaterThan(0);
  });
});
