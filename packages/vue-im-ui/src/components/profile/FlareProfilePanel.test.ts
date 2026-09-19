// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareProfilePanel from "./FlareProfilePanel.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => { host?.unmount(); host = undefined; });

describe("FlareProfilePanel", () => {
  it("shows the identity as content and no QR button when the host handles neither", () => {
    host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareProfilePanel as Component, { user: { id: "u_lin", name: "林夏" } });
      },
    }));
    expect(host.get(".flare-profile__identity").element.tagName).toBe("DIV");
    expect(host.find(".flare-profile__qr").exists()).toBe(false);
    expect(host.find(".flare-profile__chev").exists()).toBe(false);
    host.unmount();
    host = undefined;
  });

  it("opens the editor and the QR code from two separate, named buttons", async () => {
    const events: string[] = [];
    host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareProfilePanel as Component, {
          user: { id: "u_lin", name: "林夏", signature: "产品设计" },
          onEdit: () => events.push("edit"),
          onQr: () => events.push("qr"),
        });
      },
    }));
    const identity = host.get(".flare-profile__identity");
    const qr = host.get(".flare-profile__qr");
    expect(identity.element.tagName).toBe("BUTTON");
    expect(identity.attributes("aria-label")).toBe("林夏，编辑资料");
    expect(identity.element.contains(qr.element)).toBe(false);
    expect(qr.attributes("aria-label")).toBe("我的二维码");
    await qr.trigger("click");
    await identity.trigger("click");
    expect(events).toEqual(["qr", "edit"]);
  });
});
