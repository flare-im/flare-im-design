// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareGroupList from "./FlareGroupList.vue";

const groups = [
  { id: "g1", name: "设计评审组", memberCount: 18 },
  { id: "g2", name: "Flare IM", memberCount: 4 },
];

describe("FlareGroupList", () => {
  it("marks the displayed group separately from hover and retains the picked id", async () => {
    const wrapper = mount(FlareGroupList, { props: { items: groups, activeId: "g2" } });
    expect(wrapper.findAll("[aria-current=true]").map(row => row.text())).toEqual([expect.stringContaining("Flare IM")]);
    await wrapper.setProps({ activeId: "g1" });
    expect(wrapper.get(".is-current").text()).toContain("设计评审组");
    await wrapper.get(".is-current").trigger("click");
    expect(wrapper.emitted("select")?.[0]).toEqual([groups[0]]);
    wrapper.unmount();
  });
  it("lists every group with its member count", () => {
    const wrapper = mount(FlareGroupList, { props: { items: groups } });
    expect(wrapper.findAll(".flare-group-list__row")).toHaveLength(2);
    expect(wrapper.text()).toContain("18 名成员");
  });

  it("emits the group a person picked", async () => {
    const wrapper = mount(FlareGroupList, { props: { items: groups } });
    await wrapper.findAll(".flare-group-list__row")[1].trigger("click");
    expect(wrapper.emitted("select")?.[0]?.[0]).toMatchObject({ id: "g2" });
  });

  it("says the list is empty in the reader's language, not in English by default", () => {
    // The fallback used to be the literal string "No groups yet", which a Chinese reader got too.
    const wrapper = mount(FlareGroupList, { props: { items: [] } });
    expect(wrapper.find(".flare-empty").text()).toContain("还没有群聊");
  });

  it("takes the host's own empty state, which can say what to do about it", () => {
    const wrapper = mount(FlareGroupList, {
      props: { items: [] },
      slots: { empty: '<button class="host-empty">建一个群</button>' },
    });
    expect(wrapper.find(".host-empty").exists()).toBe(true);
    expect(wrapper.find(".flare-empty").exists()).toBe(false);
  });

  it("shows no empty state once there is a group", () => {
    const wrapper = mount(FlareGroupList, {
      props: { items: groups },
      slots: { empty: '<button class="host-empty">建一个群</button>' },
    });
    expect(wrapper.find(".host-empty").exists()).toBe(false);
    expect(wrapper.find(".flare-empty").exists()).toBe(false);
  });
});
