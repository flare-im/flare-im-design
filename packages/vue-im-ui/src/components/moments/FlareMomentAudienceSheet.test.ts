// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareMomentAudienceSheet from "./FlareMomentAudienceSheet.vue";

const contacts = [
  { userId: "u1", displayName: "陈默" },
  { userId: "u2", displayName: "林夏" },
];

function render(props: Record<string, unknown>) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareMomentAudienceSheet, {
        visibility: "friends", audienceMode: "everyone", audienceUserIds: [], contacts, ...props,
      });
    },
  }));
}

/**
 * Who sees a post. Two rules carry the meaning: a private post has no audience list at all (nobody
 * can see it, so adding names would only look like it did something), and picking the current mode
 * again turns it off and clears the list rather than leaving names behind for next time.
 * Release criterion §1 (component tests).
 */
describe("FlareMomentAudienceSheet", () => {
  it("offers the three visibilities and marks the current one", () => {
    const wrapper = render({ visibility: "public" });
    const tabs = wrapper.findAll('[role="tab"]');
    expect(tabs).toHaveLength(3);
    expect(tabs.map(tab => tab.attributes("aria-selected"))).toEqual(["false", "true", "false"]);
    expect(wrapper.get(".flare-moment-audience__hint").text()).toBe("所有人可见");
  });

  it("reports a visibility change and changes nothing itself", async () => {
    const wrapper = render({ visibility: "friends" });
    await wrapper.findAll('[role="tab"]')[1].trigger("click");
    expect(wrapper.findComponent(FlareMomentAudienceSheet).emitted("update:visibility")?.[0]).toEqual(["public"]);
  });

  it("exposes visibility, audience modes and people as native keyboard controls with selection state", () => {
    const wrapper = render({ audienceMode: "include", audienceUserIds: ["u1"] });
    const choice = wrapper.get('button[role="tab"][aria-selected="true"]');
    expect(choice.attributes("type")).toBe("button");
    expect(wrapper.get("button.is-include").attributes("aria-pressed")).toBe("true");
    const people = wrapper.findAll("button.flare-moment-audience__contact");
    expect(people.map(person => person.attributes("aria-pressed"))).toEqual(["true", "false"]);
  });

  it("searches the local list without losing selected people or changing the audience intent", async () => {
    const wrapper = render({ audienceMode: "include", audienceUserIds: ["u1"] });
    const search = wrapper.get('input');
    await search.setValue("林夏");
    expect(wrapper.findAll(".flare-moment-audience__contact-name").map(row => row.text())).toEqual(["林夏"]);
    await wrapper.get(".flare-moment-audience__contact").trigger("click");
    expect(wrapper.findComponent(FlareMomentAudienceSheet).emitted("update:audience")?.[0]).toEqual([{ mode: "include", userIds: ["u1", "u2"] }]);
    await search.setValue("not-a-contact");
    expect(wrapper.text()).toContain("没有找到相关结果");
    await search.setValue("");
    expect(wrapper.findAll(".flare-moment-audience__contact")).toHaveLength(2);
  });

  it("keeps Done in the header, and explains an empty contact list", async () => {
    const wrapper = render({ audienceMode: "exclude", contacts: [] });
    expect(wrapper.text()).toContain("暂无联系人");
    await wrapper.get(".flare-moment-audience__head button").trigger("click");
    expect(wrapper.findComponent(FlareMomentAudienceSheet).emitted("close")).toEqual([[]]);
  });

  it("hides the audience list for a private post, where a list would mean nothing", () => {
    const wrapper = render({ visibility: "private" });
    expect(wrapper.find(".is-include").exists()).toBe(false);
    expect(wrapper.find(".is-exclude").exists()).toBe(false);
  });

  it("offers include and exclude for a post that has an audience", () => {
    const wrapper = render({ visibility: "friends" });
    expect(wrapper.find(".is-include").exists()).toBe(true);
    expect(wrapper.find(".is-exclude").exists()).toBe(true);
  });

  it("picking the current mode again turns it off and clears the names", async () => {
    const wrapper = render({ audienceMode: "include", audienceUserIds: ["u1"] });
    await wrapper.find(".is-include").trigger("click");
    expect(wrapper.findComponent(FlareMomentAudienceSheet).emitted("update:audience")?.[0]).toEqual([
      { mode: "everyone", userIds: [] },
    ]);
  });

  it("switching modes keeps the names the host already had", async () => {
    const wrapper = render({ audienceMode: "include", audienceUserIds: ["u1"] });
    await wrapper.find(".is-exclude").trigger("click");
    expect(wrapper.findComponent(FlareMomentAudienceSheet).emitted("update:audience")?.[0]).toEqual([
      { mode: "exclude", userIds: ["u1"] },
    ]);
  });

  it("shows the picker only once a mode is chosen, and counts who is in it", () => {
    expect(render({ audienceMode: "everyone" }).find(".flare-moment-audience__picker").exists()).toBe(false);
    const chosen = render({ audienceMode: "include", audienceUserIds: ["u1"] });
    expect(chosen.find(".flare-moment-audience__picker").exists()).toBe(true);
    expect(chosen.find(".flare-moment-audience__count").text()).toContain("1");
  });
});
