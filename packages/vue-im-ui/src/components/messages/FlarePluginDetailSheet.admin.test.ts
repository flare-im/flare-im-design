// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import type { FlarePluginViewModel } from "../../shared/contracts/plugin-ui";
import FlarePluginDetailSheet from "./FlarePluginDetailSheet.vue";

enableAutoUnmount(afterEach);
afterEach(() => { document.body.innerHTML = ""; });

const detail: FlarePluginViewModel = { available: true, title: "Record", fields: [], actions: [] };
const actions = [
  { id: "approve", label: "Approve", style: "primary" },
  { id: "reject", label: "Reject" },
];

function render(props: Record<string, unknown>, bottomSheet: boolean) {
  const calls: Array<[string, unknown]> = [];
  mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      useFlarePlatformProvider({ capabilities: { bottomSheet } });
      return () => h(FlarePluginDetailSheet as never, {
        open: true,
        view: detail,
        actions,
        onAction: (id: string, payload: unknown) => calls.push([id, payload]),
        ...props,
      });
    },
  }), { attachTo: document.body });
  return calls;
}
const surface = () => document.body.querySelector("[data-flare-presentation]")?.getAttribute("data-flare-presentation");

describe("FlarePluginDetailSheet row actions", () => {
  it("detail sheet shows row actions", async () => {
    const calls = render({ presentation: "page" }, false);
    await flushPromises();
    const buttons = document.body.querySelectorAll<HTMLButtonElement>(".flare-plugin-detail__footer .flare-button");
    expect(buttons).toHaveLength(2);
    expect(buttons[0].classList.contains("flare-button--primary")).toBe(true);
    buttons[1].click();
    await flushPromises();
    expect(calls).toEqual([["reject", {}]]);
  });

  // Long record browsing is a full-height drawer on desktop and a full-width page on a phone (the compact drawer).
  it("page presentation opens a drawer on desktop and a full page on a phone", async () => {
    render({ presentation: "page" }, false);
    await flushPromises();
    expect(surface()).toBe("drawer");
    expect(document.body.querySelector("[data-flare-presentation=drawer] .flare-plugin-detail__footer")).not.toBeNull();
    expect(document.body.querySelector(".flare-drawer--compact")).toBeNull();
    document.body.innerHTML = "";
    render({ presentation: "page" }, true);
    await flushPromises();
    expect(surface()).toBe("drawer");
    expect(document.body.querySelector(".flare-drawer--compact")).not.toBeNull();
  });

  it("the default presentation stays the modal path on desktop", async () => {
    render({}, false);
    await flushPromises();
    expect(surface()).toBe("dialog");
  });
});
