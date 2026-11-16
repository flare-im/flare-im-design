// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlarePluginViewModel } from "../../shared/contracts/plugin-ui";
import FlarePluginDetailSheet from "./FlarePluginDetailSheet.vue";

enableAutoUnmount(afterEach);
afterEach(() => { document.body.innerHTML = ""; });

const detail: FlarePluginViewModel = { available: true, title: "Record", fields: [], actions: [] };

describe("FlarePluginDetailSheet row actions", () => {
  it("detail sheet shows row actions", async () => {
    const calls: Array<[string, unknown]> = [];
    mount(defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () => h(FlarePluginDetailSheet as never, {
          open: true,
          presentation: "page",
          view: detail,
          actions: [
            { id: "approve", label: "Approve", style: "primary" },
            { id: "reject", label: "Reject" },
          ],
          onAction: (id: string, payload: unknown) => calls.push([id, payload]),
        });
      },
    }), { attachTo: document.body });
    await flushPromises();
    const buttons = document.body.querySelectorAll<HTMLButtonElement>(".flare-plugin-detail__footer .flare-button");
    expect(buttons).toHaveLength(2);
    expect(buttons[0].classList.contains("flare-button--primary")).toBe(true);
    buttons[1].click();
    await flushPromises();
    expect(calls).toEqual([["reject", {}]]);
  });
});
