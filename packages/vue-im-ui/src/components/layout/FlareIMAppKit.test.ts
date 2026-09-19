// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, ref, type Component } from "vue";
import type { FlareIMAppConfiguration } from "../../shared/contracts/application";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareAdaptiveNavigation from "./FlareAdaptiveNavigation.vue";
import FlareAppLayout from "./FlareAppLayout.vue";
import FlareDesktopAppShell from "./FlareDesktopAppShell.vue";
import FlareIMAppKit from "./FlareIMAppKit.vue";
import FlareScreen from "./FlareScreen.vue";

// The shell contract (FR-095): the shell measures its own box, keeps every destination it has shown, and steps
// its phone navigation aside while the active destination shows a page beyond its root.

const configuration: FlareIMAppConfiguration = {
  features: { enabled: ["conversations", "contacts"] },
  navigation: [{ id: "primary", items: [
    { id: "chats", label: "Chats", icon: "chats" },
    { id: "contacts", label: "Contacts", icon: "people" },
  ] }],
};

/** happy-dom lays nothing out: give every box a width. */
function stubWidth(width: number): void {
  Object.defineProperty(HTMLElement.prototype, "clientWidth", { configurable: true, get() { return width; } });
}
afterEach(() => {
  delete (HTMLElement.prototype as unknown as Record<string, unknown>).clientWidth;
});

/** A destination whose state is only its own: a counter the person bumps, and a mount count. */
const mounts: string[] = [];
const Counter = defineComponent({
  props: { name: { type: String, required: true } },
  setup(props) {
    mounts.push(props.name);
    const count = ref(0);
    return () => h("button", { class: `counter-${props.name}`, onClick: () => { count.value += 1; } }, `${props.name} ${count.value}`);
  },
});

async function mountShell(width: number, props: Record<string, unknown>, destination: (id: string) => unknown) {
  stubWidth(width);
  mounts.length = 0;
  const active = ref(props.activeNavigationId as string);
  const configurationRef = ref(configuration);
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlareIMAppKit as Component, {
        configuration: configurationRef.value,
        activeNavigationId: active.value,
        label: "Reference IM",
        onNavigate: (id: string) => { active.value = id; },
      }, { destination: ({ id }: { id: string }) => destination(id) });
    },
  }), { attachTo: document.body });
  await wrapper.vm.$nextTick();
  return Object.assign(wrapper, { active, configurationRef });
}

describe("FlareIMAppKit", () => {
  it("resolves the mode from its own box and draws the navigation for it", async () => {
    const wide = await mountShell(1600, { activeNavigationId: "chats" }, (id) => h("p", id));
    expect(wide.get(".flare-im-app-kit").attributes("data-responsive-mode")).toBe("wideDesktop");
    expect(wide.getComponent(FlareAdaptiveNavigation).props("presentation")).toBe("rail");
    expect(wide.getComponent(FlareAdaptiveNavigation).props("label")).toBe("Reference IM");
    wide.unmount();

    const phone = await mountShell(390, { activeNavigationId: "chats" }, (id) => h("p", id));
    expect(phone.get(".flare-im-app-kit").attributes("data-responsive-mode")).toBe("mobile");
    expect(phone.getComponent(FlareAdaptiveNavigation).props("presentation")).toBe("bottom");
    phone.unmount();
  });

  it("keeps a destination it has shown, with its state, while another is active", async () => {
    const shell = await mountShell(1200, { activeNavigationId: "chats" }, (id) => h(Counter, { name: id }));
    await shell.get(".counter-chats").trigger("click");
    await shell.get(".counter-chats").trigger("click");
    expect(shell.get(".counter-chats").text()).toBe("chats 2");

    shell.active.value = "contacts";
    await shell.vm.$nextTick();
    const chats = shell.get('[data-destination="chats"]');
    expect(chats.classes()).not.toContain("is-active");
    expect(chats.attributes("inert")).toBeDefined();
    expect(shell.get('[data-destination="contacts"]').classes()).toContain("is-active");

    shell.active.value = "chats";
    await shell.vm.$nextTick();
    expect(shell.get(".counter-chats").text()).toBe("chats 2");
    expect(mounts).toEqual(["chats", "contacts"]);
    shell.unmount();
  });

  it("drops a destination whose navigation item is gone", async () => {
    const shell = await mountShell(1200, { activeNavigationId: "chats" }, (id) => h(Counter, { name: id }));
    shell.active.value = "contacts";
    await shell.vm.$nextTick();
    shell.configurationRef.value = { ...configuration, navigation: [{ id: "primary", items: [configuration.navigation[0].items[1]] }] };
    await shell.vm.$nextTick();
    expect(shell.find('[data-destination="chats"]').exists()).toBe(false);
    expect(shell.find('[data-destination="contacts"]').exists()).toBe(true);
    shell.unmount();
  });

  it("hides the phone navigation while the active destination shows a page with a way back", async () => {
    const page = ref(false);
    const shell = await mountShell(390, { activeNavigationId: "contacts" }, (id) => id === "contacts"
      ? (page.value ? h(FlareScreen as Component, { title: "Ivy Chen", back: true }) : h(FlareScreen as Component, { title: "Contacts" }))
      : h("p", id));
    expect(shell.findComponent(FlareAdaptiveNavigation).exists()).toBe(true);

    page.value = true;
    await shell.vm.$nextTick();
    await shell.vm.$nextTick();
    expect(shell.findComponent(FlareAdaptiveNavigation).exists()).toBe(false);
    expect(shell.get(".flare-im-app-kit").attributes("data-navigation-hidden")).toBeDefined();

    page.value = false;
    await shell.vm.$nextTick();
    await shell.vm.$nextTick();
    expect(shell.findComponent(FlareAdaptiveNavigation).exists()).toBe(true);
    shell.unmount();
  });

  it("makes a destination without a pane frame the page's main landmark", async () => {
    const shell = await mountShell(390, { activeNavigationId: "contacts" }, () => h(FlareScreen as Component, { title: "Contacts" }));
    expect(shell.get('[data-destination="contacts"]').attributes("role")).toBe("main");
    expect(shell.findAll("main")).toHaveLength(0);
    shell.unmount();
  });

  it("keeps the rail beside a page with a way back on wider layouts", async () => {
    const shell = await mountShell(1200, { activeNavigationId: "contacts" }, () => h(FlareScreen as Component, { title: "Ivy Chen", back: true }));
    expect(shell.getComponent(FlareAdaptiveNavigation).props("presentation")).toBe("rail");
    shell.unmount();
  });

  it("hands its mode down: a pane frame inside a phone shell shows one pane, and a chat in the list's place is a page", async () => {
    const pane = ref<"primary" | "content">("primary");
    const shell = await mountShell(390, { activeNavigationId: "chats" }, (id) => id === "chats"
      ? h(FlareAppLayout as Component, { activePane: pane.value, paneMode: "dualPane" }, { primary: () => "Conversation list", content: () => "Message timeline" })
      : h("p", id));
    const layout = shell.get(".flare-app-layout");
    expect(layout.attributes("data-responsive-mode")).toBe("mobile");
    expect(layout.attributes("data-pane-mode")).toBe("singlePane");
    expect(shell.text()).toContain("Conversation list");
    expect(shell.findComponent(FlareAdaptiveNavigation).exists()).toBe(true);

    pane.value = "content";
    await shell.vm.$nextTick();
    await shell.vm.$nextTick();
    expect(shell.text()).toContain("Message timeline");
    expect(shell.findComponent(FlareAdaptiveNavigation).exists()).toBe(false);
    // One main landmark: the frame's content pane took it, so the destination around it is not a second one.
    expect(shell.findAll("main")).toHaveLength(1);
    expect(shell.findAll('[role="main"]')).toHaveLength(0);
    shell.unmount();
  });

  it("gives a frame the mode of the shell it is in, not the mode of its own box", async () => {
    // 500 on its own is a phone; inside a desktop shell the frame lays out as a desktop.
    stubWidth(500);
    const wrapper = mount(defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () => h(FlareDesktopAppShell as Component, { navigation: configuration.navigation, activeNavigationId: "chats" }, {
          primary: () => "Conversation list",
          default: () => "Message timeline",
        });
      },
    }), { attachTo: document.body });
    await wrapper.vm.$nextTick();
    expect(wrapper.get(".flare-app-layout").attributes("data-responsive-mode")).toBe("desktop");
    wrapper.unmount();
  });
});
