// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { mount } from "@vue/test-utils";
import FlareContactDetail from "./FlareContactDetail.vue";
import FlareGroupDetail from "./FlareGroupDetail.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

// FR-046: a report action lived outside the kit's detail pages, floated over the kit header on
// Android and bolted beside it on web. The host declares it now and the kit draws it in place.

const wrappers: ReturnType<typeof mount>[] = [];

function setup(component: Component, props: Record<string, unknown>) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(component, props);
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host.findComponent(component);
}

const contact = { id: "u1", name: "Ada Chen", avatarUrl: undefined };
const group = {
  id: "g1", name: "设计组", announcement: "", memberCount: 2, isOwner: false, isAdmin: false,
  members: [{ id: "u1", name: "Ada" }, { id: "u2", name: "Bo" }],
  joinPolicy: "anyone" as const, muteAll: false, myMuted: false, myPinned: false, myNickname: "",
};

afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
  document.body.innerHTML = "";
});

describe("host actions in the detail pages", () => {
  it("a contact detail draws them and reports the id", async () => {
    const view = setup(FlareContactDetail, {
      contact,
      extraActions: [{ id: "report", label: "举报", danger: true }, { id: "share", label: "分享名片" }],
    });

    const keys = view.findAll(".flare-contact-detail__extra button");
    expect(keys.map((key) => key.text())).toEqual(["举报", "分享名片"]);
    expect(keys[0].classes()).toContain("is-danger");
    await keys[0].trigger("click");
    expect(view.emitted("extraAction")).toEqual([["report"]]);
  });

  it("a contact detail without them draws nothing extra", () => {
    expect(setup(FlareContactDetail, { contact }).find(".flare-contact-detail__extra").exists()).toBe(false);
  });

  it("a group detail draws them above leaving the group", async () => {
    const view = setup(FlareGroupDetail, {
      model: group,
      extraActions: [{ id: "report", label: "举报群聊", danger: true }],
    });

    const texts = view.findAll(".flare-group-detail__foot button").map((key) => key.text());
    expect(texts).toContain("举报群聊");
    expect(texts.indexOf("举报群聊")).toBeLessThan(texts.findIndex((text) => text.includes("退出")));
    await view.findAll(".flare-group-detail__foot button")[texts.indexOf("举报群聊")].trigger("click");
    expect(view.emitted("extraAction")).toEqual([["report"]]);
  });
});
