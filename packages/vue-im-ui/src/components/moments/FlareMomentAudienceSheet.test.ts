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
    const rows = wrapper.findAll(".flare-moment-audience__options")[0].findAll(".flare-moment-audience__row");
    expect(rows).toHaveLength(3);
    expect(rows.filter((r) => r.classes().includes("is-active"))).toHaveLength(1);
    expect(wrapper.findAll(".flare-moment-audience__check")).toHaveLength(1);
  });

  it("reports a visibility change and changes nothing itself", async () => {
    const wrapper = render({ visibility: "friends" });
    await wrapper.findAll(".flare-moment-audience__row")[1].trigger("click");
    expect(wrapper.findComponent(FlareMomentAudienceSheet).emitted("update:visibility")?.[0]).toEqual(["public"]);
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
