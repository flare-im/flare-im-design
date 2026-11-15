// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, type Component } from "vue";
import { mount } from "@vue/test-utils";
import FlareNotificationDeliverySettings from "./FlareNotificationDeliverySettings.vue";
import FlareSettingsList from "./FlareSettingsList.vue";
import type { FlareSettingsItem, FlareSettingsSection } from "../../shared/contracts";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";

const wrappers: ReturnType<typeof mount>[] = [];

function setup(props: Record<string, unknown>, locale = "en-US", slots?: Record<string, unknown>) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      useFlarePlatformProvider({ capabilities: { bottomSheet: true } });
      return () => h(FlareNotificationDeliverySettings as Component, props, slots);
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host;
}

const rows = () => [...document.body.querySelectorAll(".flare-settings__row")] as HTMLElement[];
const row = (label: string) => rows().find((r) => r.querySelector(".flare-settings__label")?.textContent === label);

afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
  document.body.innerHTML = "";
});

describe("FlareNotificationDeliverySettings", () => {
  it("shows the permission in the row's words and hands the press to the host", () => {
    const onStatusAction = vi.fn();
    setup({ status: "notTurnedOn", onStatusAction });
    const status = row("New message notifications");
    expect(status?.textContent).toContain("Not turned on");
    status?.click();
    expect(onStatusAction).toHaveBeenCalledOnce();
    expect(row("Receive messages in the background")).toBeUndefined();
  });

  it("leaves the status out until it has been read, and draws the footer", () => {
    setup({ status: null, footer: "Changes apply on this device." }, "zh-CN");
    expect(row("新消息通知")?.querySelector(".flare-settings__detail")).toBeNull();
    expect(document.body.querySelector(".flare-settings__footer")?.textContent).toBe("Changes apply on this device.");
  });

  it("opens the background guide with the battery settings and the maker's pages", async () => {
    const onOpenBatterySettings = vi.fn();
    const autoStart = vi.fn();
    setup({ status: "on", background: "restricted", vendorActions: [{ label: "Auto-start", onSelect: autoStart }], onOpenBatterySettings });
    const background = row("Receive messages in the background");
    expect(background?.textContent).toContain("Restricted");
    background?.click();
    await nextTick();
    const sheet = document.body.querySelector('[data-flare-presentation="sheet"]');
    expect(sheet?.textContent).toContain("When a message arrives");
    expect(sheet?.textContent).toContain("Allow this app to start automatically.");
    row("Battery usage")?.click();
    row("Auto-start")?.click();
    expect(onOpenBatterySettings).toHaveBeenCalledOnce();
    expect(autoStart).toHaveBeenCalledOnce();
  });

  it("joins the host's own settings list through the section slot", async () => {
    const onStatusAction = vi.fn();
    const autoStart = vi.fn();
    const hostRows: string[] = [];
    const general: FlareSettingsSection = { items: [{ key: "language", label: "Language" }] };
    setup({
      status: "off",
      background: "optimized",
      vendorActions: [{ onSelect: autoStart }],
      onStatusAction,
    }, "en-US", {
      section: ({ section, select }: { section: FlareSettingsSection; select: (item: FlareSettingsItem) => boolean }) =>
        h(FlareSettingsList as Component, {
          sections: [general, section],
          onSelect: (item: FlareSettingsItem) => select(item) || hostRows.push(item.key),
        }),
    });
    // One list: the host's row and the group's rows are drawn together.
    expect(document.body.querySelectorAll(".flare-settings")).toHaveLength(1);
    row("Language")?.click();
    row("New message notifications")?.click();
    expect(hostRows).toEqual(["language"]);
    expect(onStatusAction).toHaveBeenCalledOnce();

    row("Receive messages in the background")?.click();
    await nextTick();
    // A maker's page the host did not name reads the kit's label.
    row("Auto-start settings")?.click();
    expect(autoStart).toHaveBeenCalledOnce();
  });
});
