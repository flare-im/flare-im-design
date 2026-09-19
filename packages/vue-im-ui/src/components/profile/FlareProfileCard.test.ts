// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareProfileCard from "./FlareProfileCard.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => { host?.unmount(); host = undefined; });

function mountCard(listeners: Record<string, () => void>) {
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareProfileCard as Component, { user: { id: "u_lin", name: "林夏" }, ...listeners });
    },
  }));
  return host;
}

describe("FlareProfileCard", () => {
  it("offers message, voice and video only when the host handles them", () => {
    expect(mountCard({}).find(".flare-profile-card__actions").exists()).toBe(false);
    host?.unmount();
    const card = mountCard({ onMessage: () => {} });
    expect(card.findAll(".flare-profile-card__actions button").map((button) => button.text())).toEqual(["发消息"]);
    // The account id is internal: without a public Flare ID the card shows none.
    expect(card.text()).not.toContain("u_lin");
  });
});
