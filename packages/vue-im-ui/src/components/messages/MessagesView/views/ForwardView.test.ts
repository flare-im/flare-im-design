// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, nextTick } from "vue";
import { useFlareI18nProvider } from "../../../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../../../shared/platform/useFlarePlatform";
import type { ContentElem } from "../../../../utils/contentElem";
import FlareDrawer from "../../../general/FlareDrawer.vue";
import ForwardView from "./ForwardView.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => {
  host?.unmount();
  host = undefined;
  document.body.innerHTML = "";
  document.body.style.overflow = "";
});

const text = (value: string) => ({ contentType: "text", text: { text: value, mentions: [] } });

/** A merged record: two text lines and a nested forward whose single item renders inline through ContentView. */
const merged = {
  contentType: "forward",
  forward: {
    mode: 2,
    title: "Ada and Lin",
    items: [
      { sourceMessageId: "m1", sourceSenderName: "Ada", plainText: "Ship it" },
      { sourceMessageId: "m2", sourceSenderName: "Lin", plainText: "On it" },
      {
        sourceMessageId: "m3",
        sourceSenderName: "Ada",
        content: { contentType: "forward", forward: { mode: 1, items: [{ sourceMessageId: "n1", sourceSenderName: "Kai", content: text("nested hello") }] } },
      },
    ],
  },
} as unknown as ContentElem;

function mountForward() {
  const handlers: Array<() => boolean> = [];
  const adapter = {
    onNativeBack(handler: () => boolean) {
      handlers.push(handler);
      return () => handlers.splice(handlers.indexOf(handler), 1);
    },
  };
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      useFlarePlatformProvider({ adapter, capabilities: { nativeBack: true } });
      return () => h(ForwardView, { content: merged, isSelf: false });
    },
  }), { attachTo: document.body });
  return { handlers };
}

const drawer = () => document.body.querySelector('[role="dialog"][data-flare-presentation="drawer"]') as HTMLElement | null;

describe("ForwardView merged record", () => {
  it("opens the full list in the kit drawer, named after the record, at the token width", async () => {
    mountForward();
    expect(drawer()).toBeNull();
    await host!.get("button.im-fwd-card").trigger("click");
    await nextTick();
    expect(drawer()).not.toBeNull();
    expect(drawer()!.getAttribute("aria-label")).toBe("Ada and Lin · 3");
    // No per-instance width: the drawer reads the sheetWidth token (the old naive drawer was a fixed 502px).
    expect(drawer()!.style.getPropertyValue("--flare-drawer-width")).toBe("");
    expect(host!.findComponent(FlareDrawer).props("width")).toBeUndefined();
    const senders = [...drawer()!.querySelectorAll(".im-fwd-item__sender")].map((el) => el.textContent);
    expect(senders).toEqual(["Ada", "Lin", "Ada"]);
    // The nested record renders recursively through ContentView inside the drawer.
    expect(drawer()!.querySelector(".im-fwd-item__embed .im-fwd-single")).not.toBeNull();
    expect(drawer()!.textContent).toContain("nested hello");
  });

  it("closes on Escape", async () => {
    mountForward();
    await host!.get("button.im-fwd-card").trigger("click");
    await nextTick();
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    await nextTick();
    expect(drawer()).toBeNull();
  });

  it("claims the platform back exactly once, and that back closes the drawer", async () => {
    const { handlers } = mountForward();
    await nextTick();
    expect(handlers).toHaveLength(0);
    await host!.get("button.im-fwd-card").trigger("click");
    await nextTick();
    expect(handlers).toHaveLength(1);
    handlers[0]();
    await nextTick();
    expect(drawer()).toBeNull();
    expect(handlers).toHaveLength(0);
  });
});
