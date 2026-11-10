// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type {
  FlarePluginProtectedMediaRead,
  FlarePluginProtectedMediaState,
  FlarePluginViewModel,
} from "../../shared/contracts/plugin-ui";
import FlarePluginView from "./FlarePluginView.vue";

enableAutoUnmount(afterEach);
afterEach(() => { document.body.innerHTML = ""; });

function view(extra: Partial<FlarePluginViewModel>): FlarePluginViewModel {
  return { available: true, title: "Page", fields: [], actions: [], ...extra };
}
function render(props: Record<string, unknown>) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlarePluginView as never, { embedded: true, ...props });
    },
  }), { attachTo: document.body });
}

describe("field formats", () => {
  it("shows money, a person and a bare reference the console way", async () => {
    const wrapper = render({
      view: view({
        fields: [
          { label: "Amount", value: "1205", format: { kind: "money", minor: "1205", assetId: "cny" } },
          { label: "Owner", value: "user-1", format: { kind: "person", userId: "user-1" } },
          { label: "Asset", value: "cny", format: { kind: "reference", id: "cny", labelled: false } },
        ],
      }),
      assetScale: () => 2,
      resolveUser: () => ({ name: "Alice" }),
    });
    await flushPromises();
    const text = wrapper.text();
    expect(text).toContain("12.05");
    expect(text).toContain("Alice");
    expect(text).not.toContain("user-1");
    expect(text).not.toContain("cny");
  });

  it("draws the plain text of a format it does not know", () => {
    const wrapper = render({
      view: view({
        blocks: [{ kind: "fields", fields: [{ label: "Level", value: "plain", format: { kind: "gauge" } as never }] }],
      }),
    });
    expect(wrapper.find("[data-block=fields]").text()).toContain("plain");
  });

  it("formats the cells of a rows block", () => {
    const wrapper = render({
      rowsLayout: "list",
      view: view({
        blocks: [{
          kind: "rows", source: "op", actions: [],
          columns: [{ label: "Amount", format: "text" }],
          rows: [{ key: "1", actions: [], cells: [{ text: "150", format: { kind: "money", minor: "150", assetId: "cny" } }] }],
        }],
      }),
      assetScale: () => 2,
    });
    expect(wrapper.find("[data-row-primary]").text()).toBe("1.50");
  });
});

describe("rows cards", () => {
  const block = {
    kind: "rows" as const, source: "op", presentation: "cards" as const,
    columns: [{ label: "Name", format: "text" as const }, { label: "State", format: "text" as const }, { label: "By", format: "text" as const }],
    actions: [{ id: "pause", label: "Pause" }],
    rows: [{ key: "r1", cells: [{ text: "Withdrawal" }, { text: "Open" }, { text: "Tenant" }], actions: [{ id: "pause", input: { id: "r1" } }] }],
  };

  it("draws one card per row with its actions", async () => {
    const actions: unknown[] = [];
    const wrapper = render({ view: view({ blocks: [block] }), onAction: (id: string) => actions.push(id) });
    const card = wrapper.find("[data-row-key=r1]");
    expect(card.text()).toContain("Withdrawal");
    expect(card.text()).toContain("Open");
    expect(card.text()).toContain("Tenant");
    await card.find("[data-row-action=pause]").trigger("click");
    expect(actions).toEqual(["pause"]);
  });

  it("keeps the list on a plugin page", () => {
    const wrapper = render({ rowsLayout: "list", view: view({ blocks: [block] }) });
    expect(wrapper.find("[data-row-primary]").text()).toBe("Withdrawal");
    expect(wrapper.find(".flare-admin-policy-card").exists()).toBe(false);
  });
});

describe("protected media", () => {
  const block = {
    kind: "protected-media" as const,
    label: "Materials",
    items: [{ id: "m1", label: "Front", mediaType: "image/jpeg", input: { applicationId: "a1" } }],
    action: { id: "read", label: "View material" },
    inputName: "materialId",
    reasonInput: "reason",
    urlPath: "/readUrl",
  };
  const ask = async (wrapper: ReturnType<typeof render>) => {
    await wrapper.find("[data-media-read]").trigger("click");
    await flushPromises();
    const box = document.body.querySelector("textarea") as HTMLTextAreaElement;
    box.value = " audit case 12 ";
    box.dispatchEvent(new Event("input"));
    await flushPromises();
    (document.body.querySelector("[data-form-submit]") as HTMLButtonElement).click();
    await flushPromises();
  };

  it("asks for a reason and leaves the read to the host", async () => {
    const reads: FlarePluginProtectedMediaRead[] = [];
    const wrapper = render({ view: view({ blocks: [block] }), onProtectedMediaRead: (read: FlarePluginProtectedMediaRead) => reads.push(read) });
    expect(wrapper.find("img").exists()).toBe(false);
    await ask(wrapper);
    expect(reads).toHaveLength(1);
    expect(reads[0]).toMatchObject({
      reason: "audit case 12",
      urlPath: "/readUrl",
      formValues: { materialId: "m1", reason: "audit case 12" },
      item: { input: { applicationId: "a1" } },
    });
  });

  it("sends nothing without a reason", async () => {
    const reads: unknown[] = [];
    const wrapper = render({ view: view({ blocks: [block] }), onProtectedMediaRead: (read: unknown) => reads.push(read) });
    await wrapper.find("[data-media-read]").trigger("click");
    await flushPromises();
    (document.body.querySelector("[data-form-submit]") as HTMLButtonElement).click();
    await flushPromises();
    expect(reads).toEqual([]);
  });

  it("shows what the host fetched, and only an address it may draw", () => {
    const states = (url: string): Record<string, FlarePluginProtectedMediaState> => ({ m1: { url } });
    const shown = render({ view: view({ blocks: [block] }), protectedMedia: states("blob:https://console/1") });
    expect(shown.find("[data-media-image]").attributes("src")).toBe("blob:https://console/1");
    const refused = render({ view: view({ blocks: [block] }), protectedMedia: states("javascript:alert(1)") });
    expect(refused.find("[data-media-image]").exists()).toBe(false);
    expect(refused.find("[data-media-read]").exists()).toBe(true);
  });

  it("shows the host's error", () => {
    const wrapper = render({ view: view({ blocks: [block] }), protectedMedia: { m1: { error: "Refused" } } });
    expect(wrapper.find("[data-media-error]").text()).toBe("Refused");
  });
});
