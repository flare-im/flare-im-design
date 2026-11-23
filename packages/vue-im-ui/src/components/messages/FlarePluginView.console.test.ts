// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, reactive } from "vue";
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

  it("renders host-loaded previews inline with no media buttons or prompt", () => {
    const wrapper = render({
      view: view({ blocks: [{ ...block, inlinePreview: true }] }),
      protectedMedia: { m1: { url: "blob:https://console/1" } },
    });
    expect(wrapper.find("[data-media-image]").attributes("src")).toBe("blob:https://console/1");
    expect(wrapper.find("[data-media-read]").exists()).toBe(false);
    expect(document.body.querySelector("textarea")).toBeNull();
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

describe("protected media on the owner's page", () => {
  const own = {
    kind: "protected-media" as const,
    label: "My documents",
    items: [{ id: "m1", label: "Front", mediaType: "image/jpeg", input: { applicationId: "a1" } }],
    action: { id: "viewDocument", label: "View" },
    inputName: "materialId",
    urlPath: "/url",
  };

  it("reads with one tap when the block declares no reason input", async () => {
    const reads: FlarePluginProtectedMediaRead[] = [];
    const wrapper = render({ view: view({ blocks: [own] }), onProtectedMediaRead: (read: FlarePluginProtectedMediaRead) => reads.push(read) });
    await wrapper.find("[data-media-read]").trigger("click");
    await flushPromises();
    expect(document.body.querySelector("textarea")).toBeNull();
    expect(reads).toHaveLength(1);
    expect(reads[0].formValues).toEqual({ materialId: "m1" });
  });

  it("draws the server's https grant address with no way to save it", () => {
    const url = "https://im.example.com/private/realname/owner-materials/a1/m1?grant=abc.def";
    const wrapper = render({ view: view({ blocks: [own] }), protectedMedia: { m1: { url } } });
    const image = wrapper.find("[data-media-image]");
    expect(image.attributes("src")).toBe(url);
    expect(image.attributes("draggable")).toBe("false");
    expect(image.attributes("referrerpolicy")).toBe("no-referrer");
    const menu = new MouseEvent("contextmenu", { bubbles: true, cancelable: true });
    image.element.dispatchEvent(menu);
    expect(menu.defaultPrevented).toBe(true);
    expect(wrapper.text()).toContain("Only you can see this");
  });
});

describe("protected media thumbnails on the owner's page (6.1)", () => {
  const own = {
    kind: "protected-media" as const,
    label: "My documents",
    items: [
      { id: "m1", label: "Front", mediaType: "image/jpeg", input: {} },
      { id: "m2", label: "Back", mediaType: "image/jpeg", input: {} },
      { id: "m3", label: "Holding", mediaType: "image/jpeg", input: {} },
    ],
    action: { id: "viewDocument", label: "View" },
    inputName: "materialId",
    urlPath: "/url",
  };

  it("draws three named blurred thumbnails and opens the read picture full screen", async () => {
    const state = reactive<{ protectedMedia: Record<string, { url?: string; loading?: boolean }> }>({ protectedMedia: {} });
    const reads: FlarePluginProtectedMediaRead[] = [];
    const wrapper = mount(defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () => h(FlarePluginView as never, { embedded: true, view: view({ blocks: [own] }), protectedMedia: state.protectedMedia, onProtectedMediaRead: (read: FlarePluginProtectedMediaRead) => reads.push(read) });
      },
    }), { attachTo: document.body });
    const thumbs = wrapper.findAll("[data-media-thumbnails] [data-media-read]");
    expect(thumbs.map((thumb) => thumb.attributes("aria-label"))).toEqual(["Front, tap to view", "Back, tap to view", "Holding, tap to view"]);
    await thumbs[0].trigger("click");
    expect(reads.map((read) => read.formValues)).toEqual([{ materialId: "m1" }]);
    expect(document.body.querySelector(".image-preview-modal__img")).toBeNull();
    state.protectedMedia = { m1: { url: "blob:https://app/m1" } };
    await flushPromises();
    expect(wrapper.get("[data-media-id='m1'] [data-media-image]").attributes("src")).toBe("blob:https://app/m1");
    expect(document.body.querySelector(".image-preview-modal__img")?.getAttribute("src")).toBe("blob:https://app/m1");
  });
});

describe("admin flow layout", () => {
  it("admin flow renders sections and a primary save", async () => {
    const wrapper = render({
      presentation: "admin",
      contentLayout: "flow",
      view: view({
        blocks: [
          { kind: "text", text: "Basics", style: "title" },
          { kind: "fields", fields: [{ label: "Name", value: "Alpha" }] },
          { kind: "text", text: "Limits", style: "title" },
          { kind: "fields", fields: [{ label: "Max", value: "10" }] },
        ],
        actions: [
          { id: "save", label: "Save", style: "primary" },
          { id: "reset", label: "Reset" },
        ],
      }),
    });
    await flushPromises();
    expect(wrapper.findAll(".flare-admin-section")).toHaveLength(2);
    expect(wrapper.find(".flare-plugin-view").classes()).toContain("is-admin-flow");
    const save = wrapper.find("[data-action-id=save]");
    const reset = wrapper.find("[data-action-id=reset]");
    expect(save.classes()).toContain("flare-button--primary");
    expect(reset.classes()).toContain("flare-button--secondary");
    expect(wrapper.find(".flare-plugin-view__footer .is-text").exists()).toBe(false);
  });

  it("keeps the message presentation as it was", async () => {
    const wrapper = render({
      view: view({
        blocks: [
          { kind: "text", text: "Basics", style: "title" },
          { kind: "fields", fields: [{ label: "Name", value: "Alpha" }] },
        ],
        actions: [{ id: "save", label: "Save", style: "primary" }, { id: "reset", label: "Reset" }],
      }),
    });
    await flushPromises();
    expect(wrapper.findAll(".flare-admin-section")).toHaveLength(0);
    expect(wrapper.find(".flare-plugin-view").classes()).not.toContain("is-admin-flow");
    // A message card draws real keys (R2.4/R2.6): never a bare text link.
    expect(wrapper.find("[data-action-id=reset]").classes()).not.toContain("is-text");
    expect(wrapper.find("[data-action-id=reset]").classes()).toContain("flare-button--secondary");
  });
});
