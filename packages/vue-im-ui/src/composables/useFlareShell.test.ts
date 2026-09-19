// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, nextTick, type Component } from "vue";
import FlareSelect from "../components/form/FlareSelect.vue";
import FlareIMAppKit from "../components/layout/FlareIMAppKit.vue";
import FlareUiProvider from "../design-system/provider/FlareUiProvider.vue";
import type { FlareIMAppConfiguration } from "../shared/contracts/application";
import type { FlareLayoutMode } from "../shared/contracts/layout";
import { useFlarePlatformSafe, type FlarePlatformOptions } from "../shared/platform/useFlarePlatform";
import { useMessageMenuInteraction } from "./chat/useMessageMenuInteraction";
import { useFlareAdaptiveSafe } from "./useAdaptiveMode";
import { useViewport } from "./useViewport";

// FR-139: inside an application shell, "is this a phone" has one answer — the shell's own box — and not a second one
// read from the window. Every path a component asks through follows it: the adaptive kind (selects, pickers, the
// composer, conversation rows and sheets), the viewport mode (the message menu) and the platform's `bottomSheet`.

const configuration: FlareIMAppConfiguration = {
  features: { enabled: ["conversations"] },
  navigation: [{ id: "primary", items: [{ id: "chats", label: "Chats", icon: "chats" }] }],
};

/** happy-dom lays nothing out: every box reports this width (0 is a box not laid out yet). */
function stubBox(width: number): void {
  Object.defineProperty(HTMLElement.prototype, "clientWidth", { configurable: true, get() { return width; } });
}
function stubWindow(width: number): void {
  Object.defineProperty(window, "innerWidth", { configurable: true, writable: true, value: width });
}
afterEach(() => {
  delete (HTMLElement.prototype as unknown as Record<string, unknown>).clientWidth;
  stubWindow(1024);
  document.body.innerHTML = "";
});

type Reading = { kind: string; viewport: string; bottomSheet: boolean; menu: string };

/** Records what a component at this spot is told, every time it renders. */
function probe(readings: Record<string, Reading>) {
  return defineComponent({
    props: { name: { type: String, required: true } },
    setup(props) {
      const adaptive = useFlareAdaptiveSafe();
      const viewport = useViewport();
      const platform = useFlarePlatformSafe();
      const { profile } = useMessageMenuInteraction();
      return () => {
        readings[props.name] = {
          kind: adaptive.viewportKind.value,
          viewport: viewport.mode.value,
          bottomSheet: platform.capabilities.value.bottomSheet,
          menu: profile.value.menuPresentation,
        };
        return h("i");
      };
    },
  });
}

async function settle(): Promise<void> {
  for (let i = 0; i < 3; i += 1) await nextTick();
}

async function mountApp(options: {
  box: number;
  window: number;
  layoutMode?: FlareLayoutMode;
  platform?: FlarePlatformOptions;
  provider?: boolean;
}) {
  stubWindow(options.window);
  stubBox(options.box);
  const readings: Record<string, Reading> = {};
  const Probe = probe(readings);
  const shell = () => h(FlareIMAppKit as Component, { configuration, activeNavigationId: "chats" }, {
    destination: () => h(Probe, { name: "inside" }),
  });
  const wrapper = mount(defineComponent({
    setup() {
      if (options.provider === false) return shell;
      return () => h(FlareUiProvider as Component, { locale: "en-US", layoutMode: options.layoutMode ?? "auto", platform: options.platform }, {
        default: () => [h(Probe, { name: "outside" }), shell()],
      });
    },
  }), { attachTo: document.body });
  await settle();
  return { wrapper, readings };
}

const phone: Reading = { kind: "h5", viewport: "mobile", bottomSheet: true, menu: "bottomSheet" };
const desktop: Reading = { kind: "pc", viewport: "desktop", bottomSheet: false, menu: "dropdown" };

describe("the shell's mode is the one answer inside it (FR-139)", () => {
  it("a phone-sized shell in a desktop window: inside it is a phone, beside it the window still answers", async () => {
    const { wrapper, readings } = await mountApp({ box: 390, window: 1400 });
    expect(readings.inside).toEqual(phone);
    expect(readings.outside).toEqual(desktop);
    wrapper.unmount();
  });

  it("a desktop-sized shell in a phone-sized window is a desktop inside", async () => {
    const { wrapper, readings } = await mountApp({ box: 1200, window: 390 });
    expect(readings.inside).toEqual(desktop);
    expect(readings.outside).toEqual(phone);
    wrapper.unmount();
  });

  it("a tablet-sized shell is a tablet to both the adaptive kind and the menu", async () => {
    const { wrapper, readings } = await mountApp({ box: 700, window: 1400 });
    expect(readings.inside).toEqual({ kind: "ipad", viewport: "tablet", bottomSheet: false, menu: "dropdown" });
    wrapper.unmount();
  });

  it("until the shell has measured its box, the window answers", async () => {
    const { wrapper, readings } = await mountApp({ box: 0, window: 390 });
    expect(readings.inside).toEqual(phone);
    wrapper.unmount();
  });

  it("the host's explicit layout mode and bottomSheet setting still win over the shell", async () => {
    const forced = await mountApp({ box: 390, window: 1400, layoutMode: "pc" });
    expect(forced.readings.inside.kind).toBe("pc");
    expect(forced.readings.inside.bottomSheet).toBe(false);
    forced.wrapper.unmount();

    const overridden = await mountApp({ box: 1200, window: 1400, platform: { capabilities: { bottomSheet: true } } });
    expect(overridden.readings.inside.kind).toBe("pc");
    expect(overridden.readings.inside.bottomSheet).toBe(true);
    overridden.wrapper.unmount();
  });

  it("a shell without a provider still gives its box's answer", async () => {
    const { wrapper, readings } = await mountApp({ box: 390, window: 1400, provider: false });
    expect(readings.inside).toEqual(phone);
    wrapper.unmount();
  });

  it("a select in a phone-sized shell opens a bottom sheet, not the window's dropdown", async () => {
    stubWindow(1400);
    stubBox(390);
    const wrapper = mount(defineComponent({
      setup() {
        return () => h(FlareUiProvider as Component, { locale: "en-US" }, {
          default: () => h(FlareIMAppKit as Component, { configuration, activeNavigationId: "chats" }, {
            destination: () => h(FlareSelect as Component, { title: "Theme", options: [{ value: "violet", label: "Violet" }], modelValue: "violet" }),
          }),
        });
      },
    }), { attachTo: document.body });
    await settle();
    await wrapper.get("button.flare-select__trigger").trigger("click");
    await settle();
    expect(wrapper.find(".flare-select__menu").exists()).toBe(false);
    expect(document.body.querySelector(".flare-sheet")?.getAttribute("data-flare-presentation")).toBe("sheet");
    wrapper.unmount();
  });
});
