// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlareSearchResultGroup } from "../../shared/contracts";
import FlareSearchResults from "./FlareSearchResults.vue";

function mountResults(groups: FlareSearchResultGroup[]) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlareSearchResults as Component, { groups, query: "ship" });
    },
  }));
  return host.findComponent(FlareSearchResults);
}

describe("FlareSearchResults", () => {
  it("keeps every hit in one conversation as its own row and emits its target", async () => {
    const results = mountResults([
      { kind: "contact", label: "Contacts", items: [{ id: "ivy", kind: "contact", title: "Ivy" }] },
      {
        kind: "message",
        label: "Messages",
        items: [
          { id: "ivy", kind: "message", title: "Ivy", subtitle: "ship it", target: { conversationId: "c-1", messageId: "ivy" } },
          { id: "m-2", kind: "message", title: "Ivy", subtitle: "shipping today", target: { conversationId: "c-1", messageId: "m-2" } },
        ],
      },
    ]);
    const rows = results.findAll(".flare-search-row");
    expect(rows).toHaveLength(3);
    await rows[2].trigger("click");
    expect(results.emitted("open")?.[0]?.[0]).toMatchObject({ kind: "message", target: { conversationId: "c-1", messageId: "m-2" } });
  });
});
