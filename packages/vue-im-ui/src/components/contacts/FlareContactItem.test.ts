// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { mount } from "@vue/test-utils";
import FlareContactItem from "./FlareContactItem.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { RelationState } from "../../shared/contracts/relation";

// FR-098: a row could not say what the viewer's relationship with this person is, so the add-friend
// panel rewrote the signature line to say "已申请". The row says it now, as its own quiet tag.

const wrappers: ReturnType<typeof mount>[] = [];

function setup(relation?: RelationState) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareContactItem as Component, { item: { id: "u1", name: "Ada Chen", relation } });
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host.findComponent(FlareContactItem);
}

afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
  document.body.innerHTML = "";
});

describe("a contact row and the viewer's relationship", () => {
  it("says the relationships worth saying, and nothing for the rest", () => {
    expect(setup("pendingOut").get(".flare-contact-item__relation").text()).toBe("已申请");
    expect(setup("pendingIn").get(".flare-contact-item__relation").text()).toBe("待验证");
    expect(setup("friends").get(".flare-contact-item__relation").text()).toBe("好友");
    expect(setup("blocked").get(".flare-contact-item__relation").text()).toBe("已拉黑");
    expect(setup("none").find(".flare-contact-item__relation").exists()).toBe(false);
    expect(setup().find(".flare-contact-item__relation").exists()).toBe(false);
  });

  it("keeps the signature line for what it is", () => {
    const host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareContactItem as Component, {
          item: { id: "u1", name: "Ada Chen", signature: "在路上", relation: "pendingOut" },
        });
      },
    }), { attachTo: document.body });
    wrappers.push(host);
    const row = host.findComponent(FlareContactItem);
    expect(row.get(".flare-contact-item__sig").text()).toBe("在路上");
    expect(row.get(".flare-contact-item__relation").text()).toBe("已申请");
  });
});
