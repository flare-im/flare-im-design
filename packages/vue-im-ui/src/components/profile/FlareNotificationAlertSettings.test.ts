// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { mount } from "@vue/test-utils";
import FlareNotificationAlertSettings from "./FlareNotificationAlertSettings.vue";
import FlareSettingsList from "./FlareSettingsList.vue";
import type { FlareSettingsItem, FlareSettingsSection } from "../../shared/contracts";
import { defaultNotificationAlertPreferences, type FlareNotificationAlertPreferences } from "../../shared/contracts/notification-alert";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";

const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/notification-alert-vectors.json"), "utf8")) as {
  rows: { quietHoursEnabled: boolean; sections: string[][] }[];
  end: { start: number; end: number; zh: string; en: string }[];
  summary: { mask: number; zh: string; en: string }[];
};

const wrappers: ReturnType<typeof mount>[] = [];

function setup(props: Record<string, unknown>, locale = "en-US", slots?: Record<string, unknown>) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      useFlarePlatformProvider({ capabilities: { bottomSheet: true } });
      return () => h(FlareNotificationAlertSettings as Component, props, slots);
    },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host;
}

function value(quietHours: Partial<FlareNotificationAlertPreferences["quietHours"]> = {}, rest: Partial<FlareNotificationAlertPreferences> = {}): FlareNotificationAlertPreferences {
  return { ...defaultNotificationAlertPreferences, ...rest, quietHours: { ...defaultNotificationAlertPreferences.quietHours, ...quietHours } };
}
const rows = () => [...document.body.querySelectorAll(".flare-settings__row")] as HTMLElement[];
const row = (label: string) => rows().find((r) => r.querySelector(".flare-settings__label")?.textContent === label);
const detail = (label: string) => row(label)?.querySelector(".flare-settings__detail")?.textContent;
const sheet = () => document.body.querySelector('[data-flare-presentation="sheet"]') as HTMLElement | null;

afterEach(() => {
  wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
  document.body.innerHTML = "";
});

describe("FlareNotificationAlertSettings", () => {
  it.each(table.rows)("lists the rows of the table with quiet hours $quietHoursEnabled", ({ quietHoursEnabled, sections }) => {
    const seen: string[][] = [];
    setup({ value: value({ enabled: quietHoursEnabled }) }, "en-US", {
      sections: ({ sections: groups }: { sections: FlareSettingsSection[] }) => {
        seen.splice(0, seen.length, ...groups.map((group) => group.items.map((item) => item.key)));
        return h("div");
      },
    });
    expect(seen).toEqual(sections);
  });

  it("reads each row's value with a footer under each section", () => {
    setup({ value: value({ enabled: true, startMinute: 1320, endMinute: 480, weekdays: 31 }, { preview: "senderOnly", multiDevice: "badgeOnly" }) });
    expect(detail("Starts")).toBe("22:00");
    expect(detail("Ends")).toBe("08:00 next day");
    expect(detail("Repeat")).toBe("Weekdays");
    expect(detail("Preview")).toBe("Name only");
    expect(detail("While active elsewhere")).toBe("Badge only");
    expect(document.body.querySelectorAll(".flare-settings__footer")).toHaveLength(3);
  });

  it.each(table.end)("reads the end from $start to $end in both languages", ({ start, end, zh, en }) => {
    setup({ value: value({ enabled: true, startMinute: start, endMinute: end }) });
    expect(detail("Ends")).toBe(en);
    wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
    setup({ value: value({ enabled: true, startMinute: start, endMinute: end }) }, "zh-CN");
    expect(detail("结束时间")).toBe(zh);
  });

  it.each(table.summary)("summarises the days of $mask in both languages", ({ mask, zh, en }) => {
    setup({ value: value({ enabled: true, weekdays: mask }) });
    expect(detail("Repeat")).toBe(en);
    wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
    setup({ value: value({ enabled: true, weekdays: mask }) }, "zh-CN");
    expect(detail("重复")).toBe(zh);
  });

  it("writes the whole value when a switch changes", () => {
    const onChange = vi.fn();
    setup({ value: value(), onChange });
    row("Quiet hours")?.click();
    expect(onChange).toHaveBeenCalledWith(value({ enabled: true }));
  });

  it("picks a start time in the sheet", async () => {
    const onChange = vi.fn();
    setup({ value: value({ enabled: true }), onChange });
    row("Starts")?.click();
    await nextTick();
    const hours = sheet()?.querySelectorAll('[role="listbox"]')[0].querySelectorAll(".flare-tp__cell");
    (hours?.[21] as HTMLElement).click();
    await nextTick();
    (sheet()?.querySelector(".flare-tp__btn.is-primary") as HTMLElement).click();
    expect(onChange).toHaveBeenCalledWith(value({ enabled: true, startMinute: 21 * 60 }));
  });

  it("turns a day off in the repeat sheet and never empties the week", async () => {
    const onChange = vi.fn();
    setup({ value: value({ enabled: true, weekdays: 0 }), onChange });
    row("Repeat")?.click();
    await nextTick();
    row("Sunday")?.click();
    expect(onChange).toHaveBeenLastCalledWith(value({ enabled: true, weekdays: 63 }));
    wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
    onChange.mockClear();
    setup({ value: value({ enabled: true, weekdays: 1 }), onChange });
    row("Repeat")?.click();
    await nextTick();
    const monday = row("Monday") as HTMLButtonElement | undefined;
    expect(monday?.disabled).toBe(true);
  });

  it("applies a preview pick and closes the sheet", async () => {
    const onChange = vi.fn();
    setup({ value: value(), onChange });
    row("Preview")?.click();
    await nextTick();
    const choice = [...(sheet()?.querySelectorAll('[role="radio"]') ?? [])].find((radio) => radio.textContent?.includes("Hidden")) as HTMLElement;
    choice.click();
    await nextTick();
    expect(onChange).toHaveBeenCalledWith(value({}, { preview: "hidden" }));
    expect(sheet()).toBeNull();
  });

  it("takes no input while disabled", async () => {
    const onChange = vi.fn();
    setup({ value: value({ enabled: true }), disabled: true, onChange });
    row("Quiet hours")?.click();
    row("Starts")?.click();
    await nextTick();
    expect(onChange).not.toHaveBeenCalled();
    expect(sheet()).toBeNull();
  });

  it("keeps an open sheet working when the rows turn disabled", async () => {
    const onChange = vi.fn();
    const props = reactive({ value: value({ enabled: true, weekdays: 0 }), disabled: false, onChange });
    setup(props);
    row("Repeat")?.click();
    await nextTick();
    props.disabled = true;
    await nextTick();
    expect(sheet()).not.toBeNull();
    row("Sunday")?.click();
    expect(onChange).toHaveBeenLastCalledWith(value({ enabled: true, weekdays: 63 }));
    wrappers.splice(0).forEach((wrapper) => wrapper.unmount());
    onChange.mockClear();

    const choiceProps = reactive({ value: value(), disabled: false, onChange });
    setup(choiceProps);
    row("Preview")?.click();
    await nextTick();
    choiceProps.disabled = true;
    await nextTick();
    const choice = [...(sheet()?.querySelectorAll('[role="radio"]') ?? [])].find((radio) => radio.textContent?.includes("Hidden")) as HTMLElement;
    choice.click();
    await nextTick();
    expect(onChange).toHaveBeenCalledWith(value({}, { preview: "hidden" }));
    expect(sheet()).toBeNull();
  });

  it("joins the host's own settings list through the sections slot", async () => {
    const onChange = vi.fn();
    const own: string[] = [];
    const general: FlareSettingsSection = { items: [{ key: "language", label: "Language" }] };
    setup({ value: value(), onChange }, "en-US", {
      sections: ({ sections, select, toggle }: {
        sections: FlareSettingsSection[];
        select: (item: FlareSettingsItem) => boolean;
        toggle: (item: FlareSettingsItem, on: boolean) => boolean;
      }) => h(FlareSettingsList as Component, {
        sections: [general, ...sections],
        onSelect: (item: FlareSettingsItem) => { if (!select(item)) own.push(item.key); },
        onToggle: (item: FlareSettingsItem, on: boolean) => { if (!toggle(item, on)) own.push(item.key); },
      }),
    });
    row("Language")?.click();
    row("Quiet hours")?.click();
    row("While active elsewhere")?.click();
    await nextTick();
    expect(own).toEqual(["language"]);
    expect(onChange).toHaveBeenCalledWith(value({ enabled: true }));
    expect(sheet()?.textContent).toContain("Immediately");
  });
});
