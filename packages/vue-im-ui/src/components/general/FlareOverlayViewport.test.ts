// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive } from "vue";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import { provideFlareOverlayContainer } from "../../shared/useOverlayContainer";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareFormSheet from "./FlareFormSheet.vue";
let host: ReturnType<typeof mount>;
afterEach(() => { host?.unmount(); document.body.innerHTML = ""; vi.unstubAllGlobals(); vi.restoreAllMocks(); });
function setup(phone: boolean, scoped = false) {
 const viewport = Object.assign(new EventTarget(), { height: 844, width: 390, offsetTop: 0, offsetLeft: 0, scale: 1 });
 vi.stubGlobal("visualViewport", viewport); vi.stubGlobal("innerHeight", 844); vi.stubGlobal("innerWidth", 390);
 const remove = vi.spyOn(viewport, "removeEventListener"), state = reactive({ open: true });
 if (scoped) { const target = document.createElement("div"); target.id = "preview"; document.body.append(target); }
 host = mount(defineComponent({ setup() { useFlareI18nProvider("zh-CN"); useFlarePlatformProvider({ capabilities: { bottomSheet: phone } }); if (scoped) provideFlareOverlayContainer("#preview"); return () => h(FlareFormSheet, { ...state, title: "回复评论", description: "回复 陈默", error: "发送失败", density: "compact" }, () => h("textarea", { value: "原文😀" })); } }), { attachTo: document.body });
 return { viewport, state, remove };
}
describe("keyboard-visible overlay viewport", () => {
 it.each([true, false])("follows visual resize and pan without remounting the draft (sheet=%s)", async phone => {
  const { viewport, state, remove } = setup(phone); await nextTick(); const field = document.querySelector("textarea")!; field.focus();
  viewport.height = 330; viewport.offsetTop = 24; viewport.dispatchEvent(new Event("resize")); await nextTick();
  const scrim = document.querySelector<HTMLElement>(".flare-overlay-scrim")!;
  expect(scrim.style.height).toBe("330px"); expect(scrim.style.top).toBe("24px");
  expect(document.querySelector("textarea")).toBe(field); expect(field.value).toBe("原文😀"); expect(document.activeElement).toBe(field);
  viewport.offsetTop = 32; viewport.dispatchEvent(new Event("scroll")); await nextTick(); expect(scrim.style.top).toBe("32px");
  viewport.height = 844; viewport.offsetTop = 0; viewport.dispatchEvent(new Event("resize")); await nextTick(); expect(scrim.style.height).toBe("");
  state.open = false; await nextTick(); expect(remove).toHaveBeenCalledWith("resize", expect.any(Function)); expect(remove).toHaveBeenCalledWith("scroll", expect.any(Function));
 });
 it("does not resize scoped documentation frames against the outer browser viewport", async () => {
  const { viewport } = setup(true, true); await nextTick(); viewport.height = 300; viewport.dispatchEvent(new Event("resize")); await nextTick(); expect(document.querySelector<HTMLElement>(".flare-overlay-scrim")!.style.height).toBe("");
 });
 it("leaves pinch zoom to the browser and removes listeners on unmount", async () => {
  const { viewport, remove } = setup(true); await nextTick(); viewport.height = 300; viewport.scale = 2; viewport.dispatchEvent(new Event("resize")); await nextTick(); expect(document.querySelector<HTMLElement>(".flare-overlay-scrim")!.style.height).toBe("");
  host.unmount(); expect(remove).toHaveBeenCalledWith("resize", expect.any(Function));
 });
});
