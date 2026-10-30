// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, nextTick, type Component } from "vue";
import {
  flareReadReceiptPresentation,
  type FlareReadReceiptColumn,
  type FlareReadReceiptState,
} from "../../shared/contracts/read-receipt";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareReadReceiptSheet from "./FlareReadReceiptSheet.vue";

interface Input {
  state?: FlareReadReceiptState;
  readers: number;
  unread: number;
  readCount?: number;
  unreadCount?: number;
  readHasMore?: boolean;
  unreadHasMore?: boolean;
  loadingMore?: FlareReadReceiptColumn;
  loadMoreFailed?: FlareReadReceiptColumn;
  initialTab?: FlareReadReceiptColumn;
}
interface Expect {
  tabs: { value: FlareReadReceiptColumn; count: number | null }[] | null;
  body: string;
  empty?: FlareReadReceiptColumn;
  rows: number;
  tail: string;
}
interface Vector {
  id: string;
  platforms: string[];
  input: Input;
  expect: Expect;
  taps?: { tap: string; emits: unknown[][]; then?: Omit<Expect, "tabs"> }[];
}
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/read-receipt-vectors.json"), "utf8")) as {
  strings: Record<"zh" | "en", Record<string, string>>;
  cases: Vector[];
};
const cases = table.cases.filter((v) => v.platforms.includes("vue"));

const people = (prefix: string, count: number) =>
  Array.from({ length: count }, (_, i) => ({ id: `${prefix}${i + 1}`, name: `${prefix.toUpperCase()}${i + 1}` }));

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
});

function mountSheet(input: Input, locale: "zh-CN" | "en-US" = "zh-CN", extra: Record<string, unknown> = {}) {
  const events: unknown[][] = [];
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareReadReceiptSheet as Component, {
        readers: people("r", input.readers),
        unread: people("u", input.unread),
        ...(input.state ? { state: input.state } : {}),
        ...(input.readCount === undefined ? {} : { readCount: input.readCount }),
        ...(input.unreadCount === undefined ? {} : { unreadCount: input.unreadCount }),
        readHasMore: input.readHasMore ?? false,
        unreadHasMore: input.unreadHasMore ?? false,
        ...(input.loadingMore ? { loadingMore: input.loadingMore } : {}),
        ...(input.loadMoreFailed ? { loadMoreFailed: input.loadMoreFailed } : {}),
        ...(input.initialTab ? { initialTab: input.initialTab } : {}),
        ...extra,
        onLoadMore: (column: string) => events.push(["loadMore", column]),
        onRetry: () => events.push(["retry"]),
        onSelect: (id: string) => events.push(["select", id]),
      });
    },
  }), { attachTo: document.body });
  return events;
}

const root = () => host!.find(".flare-read-receipt");
const tabLabels = () => host!.findAll('[role="tab"]').map((tab) => tab.text().trim());
const rows = () => host!.findAll(".flare-read-receipt__row");
function body(): string {
  if (host!.find(".flare-empty__spinner").exists()) return "spinner";
  if (host!.find(".flare-empty.is-error").exists()) return "error";
  if (host!.find(".flare-read-receipt__list").exists()) return "list";
  return host!.find(".flare-empty").exists() ? "notice" : "none";
}
function tail(): string {
  if (host!.find(".flare-read-receipt__tail.is-busy").exists()) return "busy";
  const key = host!.find("button.flare-read-receipt__tail");
  return key.exists() ? String(key.attributes("data-tail")) : "none";
}

describe("flareReadReceiptPresentation", () => {
  it.each(cases.map((v) => [v.id, v] as const))("follows the shared vector %s", (_id, v) => {
    const input = { ...v.input, tab: v.input.initialTab ?? "read" };
    const view = flareReadReceiptPresentation(input);
    expect({ tabs: view.tabs, body: view.body, rows: view.rows, tail: view.tail, ...(view.empty ? { empty: view.empty } : {}) })
      .toEqual(v.expect);
    for (const step of v.taps ?? []) {
      if (!step.then) continue;
      const column = step.tap.replace("tab:", "") as FlareReadReceiptColumn;
      const next = flareReadReceiptPresentation({ ...v.input, tab: column });
      expect({ body: next.body, rows: next.rows, tail: next.tail }).toEqual(step.then);
    }
  });
});

describe("FlareReadReceiptSheet", () => {
  it.each(cases.map((v) => [v.id, v] as const))("draws and emits as the shared vector %s says", async (_id, v) => {
    const events = mountSheet(v.input);
    await nextTick();
    const expected = v.expect;
    if (expected.tabs === null) expect(tabLabels()).toEqual([]);
    else {
      expect(tabLabels()).toEqual(expected.tabs.map((tab) => {
        const word = tab.value === "read" ? "已读" : "未读";
        return tab.count === null ? word : `${word} ${tab.count}`;
      }));
    }
    const drawn = body();
    if (expected.body === "list") expect(drawn).toBe("list");
    else if (expected.body === "spinner" || expected.body === "error") expect(drawn).toBe(expected.body);
    else expect(drawn).toBe("notice");
    if (expected.body === "unavailable") expect(root().text()).toContain(table.strings.zh.readReceiptUnavailable);
    if (expected.body === "error") expect(root().text()).toContain(table.strings.zh.readReceiptLoadFailed);
    if (expected.empty) expect(root().text()).toContain(expected.empty === "read" ? "还没有人已读" : "全部成员已读");
    expect(rows().length).toBe(expected.rows);
    expect(tail()).toBe(expected.tail);
    for (const step of v.taps ?? []) {
      events.length = 0;
      if (step.tap === "tail") {
        const key = host!.find("button.flare-read-receipt__tail");
        if (key.exists()) await key.trigger("click");
        else await host!.find(".flare-read-receipt__tail").trigger("click");
      } else if (step.tap === "retry") {
        await host!.get(".flare-empty__act").trigger("click");
      } else {
        const label = step.tap === "tab:unread" ? "未读" : "已读";
        await host!.findAll('[role="tab"]').find((tab) => tab.text().startsWith(label))!.trigger("click");
      }
      await nextTick();
      expect(events).toEqual(step.emits);
      if (step.then) {
        expect(rows().length).toBe(step.then.rows);
        expect(tail()).toBe(step.then.tail);
      }
    }
  });

  it("writes the English copy and tab numbers", async () => {
    mountSheet({ readers: 1, unread: 0, readCount: 1, unreadCount: 0, readHasMore: true }, "en-US");
    await nextTick();
    expect(tabLabels()).toEqual(["Read 1", "Unread 0"]);
    expect(host!.get("button.flare-read-receipt__tail").text()).toBe(table.strings.en.readReceiptLoadMore);
  });

  it("names the people it lists and reports a pick", async () => {
    const events = mountSheet({ readers: 2, unread: 0 });
    await nextTick();
    expect(rows().map((row) => row.get(".flare-read-receipt__name").text())).toEqual(["R1", "R2"]);
    await rows()[1].trigger("click");
    expect(events).toEqual([["select", "r2"]]);
  });

  it("is its own card outside a sheet, at most the popover width", async () => {
    mountSheet({ readers: 1, unread: 0 });
    await nextTick();
    expect(root().classes()).not.toContain("is-in-sheet");
  });

  it("drops its shell in a kit sheet and declares its own header, so a filled sheet does not repeat the title", async () => {
    host = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        useFlarePlatformProvider({ capabilities: { bottomSheet: true } });
        return () => h(FlareBottomSheet as Component, { open: true, title: "已读名单", fill: true }, {
          default: () => h(FlareReadReceiptSheet as Component, { readers: people("r", 2), unread: [] }),
        });
      },
    }), { attachTo: document.body });
    await nextTick();
    const sheet = document.body.querySelector<HTMLElement>('[role="dialog"]')!;
    expect(sheet.getAttribute("aria-label")).toBe("已读名单");
    expect(sheet.querySelector(".flare-sheet__title")).toBeNull();
    expect(sheet.querySelector(".flare-read-receipt")!.classList).toContain("is-in-sheet");
    expect(sheet.querySelector(".flare-read-receipt__title")!.textContent).toContain("消息回执");
  });
});
