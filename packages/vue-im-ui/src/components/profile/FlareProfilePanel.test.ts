// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareProfilePanel from "./FlareProfilePanel.vue";
import FlareScreen from "../layout/FlareScreen.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => { host?.unmount(); host = undefined; });

describe("FlareProfilePanel", () => {
  it("keeps identity and QR outside the named sidebar navigation and delegates the current entry", async () => {
    const actions: string[] = [];
    host = mount(defineComponent({ setup() {
      useFlareI18nProvider('zh-CN');
      return () => h(FlareProfilePanel, { user: { id: 'u', name: '林夏', flareId: 'lin' }, layout: 'sidebar',
        sections: [{ title: '账号', items: [{ key: 'privacy', label: '隐私与安全', current: true }] }],
        onQr: () => actions.push('qr'), onAction: item => actions.push(item.key),
      });
    } }));
    const navigation = host.get('[role="navigation"]');
    expect(navigation.attributes('aria-labelledby')).toBe(host.get('.flare-profile__meta').attributes('id'));
    expect(navigation.find('.flare-profile__hdr').exists()).toBe(false);
    expect(navigation.find('.flare-profile__qr').exists()).toBe(false);
    const current = navigation.get('[aria-current="true"]');
    await current.trigger('click');
    await host.get('.flare-profile__qr').trigger('click');
    expect(actions).toEqual(['privacy', 'qr']);
  });

  it("retains menu nodes and selection when restoring the identity on the page layout", async () => {
    const layout = ref<"page" | "sidebar">('sidebar');
    host = mount(defineComponent({ setup() {
      useFlareI18nProvider('en-US');
      return () => h(FlareScreen, { title: 'Me' }, {
        default: () => h(FlareProfilePanel, {
          user: { id: 'u', name: 'Lin' }, layout: layout.value, showIdentity: layout.value === 'page',
          sections: [{ title: 'Account', items: [{ key: 'profile', label: 'Profile', current: true }] }],
        }),
      });
    } }));
    const panel = host.getComponent(FlareProfilePanel);
    const row = panel.get('[aria-current="true"]').element;
    expect(panel.get('[role="navigation"]').attributes('aria-label')).toBe('Me');
    expect(panel.get('[role="navigation"]').attributes('aria-labelledby')).toBeUndefined();
    expect(panel.find('.flare-profile__hdr').exists()).toBe(false);
    layout.value = 'page';
    await nextTick();
    expect(panel.find('[role="navigation"]').exists()).toBe(false);
    expect(panel.get('[aria-current="true"]').element).toBe(row);
    expect(panel.find('.flare-profile__hdr').exists()).toBe(true);
  });

  it("does not leave a heading or blank card for unavailable empty sections", () => {
    host = mount(defineComponent({ setup() {
      useFlareI18nProvider('zh-CN');
      return () => h(FlareProfilePanel, { user: { id: 'u', name: '林夏' }, sections: [
        { title: '未提供的服务', items: [] },
        { title: '常用功能', items: [{ key: 'moments', label: '圈子' }] },
      ] });
    } }));
    expect(host.findAll('h2').map(heading => heading.text())).toEqual(['常用功能']);
    expect(host.findAll('.flare-profile__list')).toHaveLength(1);
  });
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
    expect(host.get(".flare-profile__meta .flare-profile__sig").text()).toBe("产品设计");
    expect(identity.element.contains(qr.element)).toBe(false);
    expect(qr.attributes("aria-label")).toBe("我的二维码");
    await qr.trigger("click");
    await identity.trigger("click");
    expect(events).toEqual(["qr", "edit"]);
  });

  // The Flutter panel draws a title per section; the Vue one dropped them, so a grouped profile center had none.
  it("draws each section's title above its card and names the card by it, and the footer under it", () => {
    host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareProfilePanel as Component, {
          user: { id: "u_lin", name: "林夏" },
          sections: [
            { title: "服务", items: [{ key: "wallet", label: "钱包" }], footer: "余额与账单" },
            { items: [{ key: "settings", label: "设置" }] },
          ],
        });
      },
    }));
    const titles = host.findAll(".flare-profile__section-title");
    expect(titles.map((title) => title.text())).toEqual(["服务"]);
    const cards = host.findAll(".flare-profile__list");
    expect(cards).toHaveLength(2);
    expect(cards[0].attributes("role")).toBe("group");
    expect(cards[0].attributes("aria-labelledby")).toBe(titles[0].attributes("id"));
    expect(cards[1].attributes("role")).toBeUndefined();
    expect(host.get(".flare-profile__section-footer").text()).toBe("余额与账单");
    expect(host.text()).toContain("钱包");
  });
});

it("names the identity destination supplied by the host without conflating the QR intent", async () => {
  const events: string[] = [];
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareProfilePanel as Component, {
        user: { id: "u_lin", name: "林夏" }, identityActionLabel: "个人中心",
        onEdit: () => events.push("profile"), onQr: () => events.push("qr"),
      });
    },
  }));
  expect(host.get(".flare-profile__identity").attributes("aria-label")).toBe("个人中心");
  await host.get(".flare-profile__qr").trigger("click");
  expect(events).toEqual(["qr"]);
  await host.get(".flare-profile__identity").trigger("click");
  expect(events).toEqual(["qr", "profile"]);
});
