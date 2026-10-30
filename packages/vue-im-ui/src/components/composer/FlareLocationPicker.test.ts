// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlareLocationCoordinate, FlareLocationPlace } from "../../shared/contracts/location";
import FlareLocationPicker from "./FlareLocationPicker.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";

enableAutoUnmount(afterEach);
afterEach(() => vi.useRealTimers());

const HERE: FlareLocationCoordinate = { latitude: 39.9087, longitude: 116.3975 };
const CAFE: FlareLocationPlace = { id: "p1", title: "Mellow Brew", address: "前门大街 1 号", latitude: 39.9001, longitude: 116.398, distanceM: 240 };
const MUSEUM: FlareLocationPlace = { id: "p2", title: "国家博物馆", address: "东长安街 16 号", latitude: 39.9051, longitude: 116.4013, distanceM: 1240 };

function deferred<T>() {
  let resolve!: (value: T) => void;
  let reject!: (error: unknown) => void;
  const promise = new Promise<T>((res, rej) => { resolve = res; reject = rej; });
  return { promise, resolve, reject };
}

function render(props: Record<string, unknown>) {
  const sends: FlareLocationPlace[] = [];
  let cancels = 0;
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareLocationPicker as never, {
        searchNearby: async (_lat: number | null, _lng: number | null, query: string) => (query ? [] : [CAFE, MUSEUM]),
        reverseGeocode: async () => ({ title: "天安门广场", address: "北京市东城区" }),
        previewUrl: async (lat: number, lng: number, zoom: number) => `https://geo.example/map?c=${lat},${lng}&z=${zoom}`,
        onSend: (place: FlareLocationPlace) => sends.push(place),
        onCancel: () => { cancels += 1; },
        ...props,
      });
    },
  }), { attachTo: document.body });
  const root = () => wrapper.get(".flare-location-picker");
  return { wrapper, root, sends, cancels: () => cancels };
}

const rowIds = (wrapper: ReturnType<typeof render>["wrapper"]) =>
  wrapper.findAll(".flare-location-picker__row").map((row) => row.attributes("data-place-id"));

describe("FlareLocationPicker", () => {
  it("credits OpenStreetMap on the map preview, and not AMap's", async () => {
    const osm = render({ requestCurrentLocation: async () => HERE });
    await flushPromises();
    expect(osm.wrapper.get("img").attributes("src")).toContain("https://geo.example/map");
    expect(osm.wrapper.get("[data-map-attribution]").text()).toBe("© OpenStreetMap contributors");
    const amap = render({ requestCurrentLocation: async () => HERE, provider: "amap" });
    await flushPromises();
    expect(amap.wrapper.find("img").exists()).toBe(true);
    expect(amap.wrapper.find("[data-map-attribution]").exists()).toBe(false);
  });

  it("paints at once: skeleton rows while locating, then the current location first and the places around", async () => {
    const fix = deferred<FlareLocationCoordinate>();
    const picker = render({ requestCurrentLocation: () => fix.promise });
    expect(picker.root().attributes("data-state")).toBe("locating");
    expect(picker.wrapper.text()).toContain("正在定位…");
    expect(picker.wrapper.find(".flare-skeleton").exists()).toBe(true);
    fix.resolve(HERE);
    await flushPromises();
    expect(picker.root().attributes("data-state")).toBe("located");
    expect(rowIds(picker.wrapper)).toEqual(["current", "p1", "p2"]);
    const current = picker.wrapper.get('[data-place-id="current"]');
    expect(current.text()).toContain("天安门广场");
    expect(current.attributes("aria-checked")).toBe("true");
    expect(picker.wrapper.get('[data-place-id="p1"]').text()).toContain("240m");
    expect(picker.wrapper.get('[data-place-id="p2"]').text()).toContain("1.2km");
    expect(picker.wrapper.get(".flare-location-map__image").attributes("src")).toBe("https://geo.example/map?c=39.9087,116.3975&z=16");
  });

  it("shows the remembered place before the device answers", async () => {
    const picker = render({
      requestCurrentLocation: () => new Promise<FlareLocationCoordinate>(() => {}),
      initialLocation: { id: "last", title: "上次的位置", address: "朝阳区", latitude: 39.99, longitude: 116.48 },
    });
    expect(picker.wrapper.get('[data-place-id="current"]').text()).toContain("上次的位置");
    await flushPromises();
    expect(picker.wrapper.get(".flare-location-map__image").attributes("src")).toContain("c=39.99,116.48");
  });

  it("selecting a place moves the map, and send returns that place", async () => {
    const picker = render({ requestCurrentLocation: async () => HERE });
    await flushPromises();
    await picker.wrapper.get('[data-place-id="p2"]').trigger("click");
    await flushPromises();
    expect(picker.wrapper.get('[data-place-id="p2"]').attributes("aria-checked")).toBe("true");
    expect(picker.wrapper.get(".flare-location-map__image").attributes("src")).toContain("c=39.9051,116.4013");
    await picker.wrapper.get(".flare-location-picker__foot button").trigger("click");
    expect(picker.sends).toEqual([MUSEUM]);
  });

  it("sends the current location with its reverse-geocoded name", async () => {
    const picker = render({ requestCurrentLocation: async () => HERE });
    await flushPromises();
    await picker.wrapper.get(".flare-location-picker__foot button").trigger("click");
    expect(picker.sends).toEqual([{ id: "current", ...HERE, title: "天安门广场", address: "北京市东城区" }]);
  });

  it("turns to manual search when the device refuses, and sends nothing until a place is chosen", async () => {
    const searches: Array<[number | null, number | null, string]> = [];
    const picker = render({
      requestCurrentLocation: async () => { throw new Error("denied"); },
      searchNearby: async (lat: number | null, lng: number | null, query: string) => {
        searches.push([lat, lng, query]);
        return query === "咖啡" ? [CAFE] : [];
      },
    });
    await flushPromises();
    expect(picker.root().attributes("data-state")).toBe("denied");
    expect(picker.wrapper.text()).toContain("无法获取定位，可以搜索地点");
    expect(picker.wrapper.get(".flare-location-picker__foot button").attributes("disabled")).toBeDefined();
    await picker.wrapper.get(".flare-location-picker__search input").setValue("咖啡");
    await picker.wrapper.get(".flare-location-picker__search input").trigger("keydown", { key: "Enter" });
    await flushPromises();
    expect(searches.at(-1)).toEqual([null, null, "咖啡"]);
    expect(rowIds(picker.wrapper)).toEqual(["p1"]);
    await picker.wrapper.get('[data-place-id="p1"]').trigger("click");
    await picker.wrapper.get(".flare-location-picker__foot button").trigger("click");
    expect(picker.sends).toEqual([CAFE]);
  });

  it("shows a lookup failure distinctly and retries the same query after recovery", async () => {
    let unavailable = true;
    const searchNearby = vi.fn(async (_lat: number | null, _lng: number | null, query: string) => {
      if (unavailable) throw new Error("503 GEO_PROVIDER_UNAVAILABLE");
      return query ? [CAFE] : [];
    });
    const picker = render({ requestCurrentLocation: async () => { throw new Error("denied"); }, searchNearby });
    await flushPromises();
    await picker.wrapper.get(".flare-location-picker__search input").setValue("coffee");
    await picker.wrapper.get(".flare-location-picker__search input").trigger("keydown", { key: "Enter" });
    await flushPromises();
    expect(picker.root().attributes("data-state")).toBe("mapUnavailable");
    expect(picker.wrapper.text()).toContain("地图暂不可用");
    expect(picker.wrapper.text()).not.toContain("附近没有找到地点");
    unavailable = false;
    await picker.wrapper.get("[data-lookup-unavailable] button").trigger("click");
    await flushPromises();
    expect(searchNearby.mock.calls.at(-1)?.[2]).toBe("coffee");
    expect(picker.wrapper.find("[data-lookup-unavailable]").exists()).toBe(false);
    await picker.wrapper.get('[data-place-id="p1"]').trigger("click");
    await picker.wrapper.get(".flare-location-picker__foot button").trigger("click");
    expect(picker.sends).toEqual([CAFE]);
  });

  it("retains a usable coordinate when nearby lookup fails and retry recovers", async () => {
    let unavailable = true;
    const picker = render({
      requestCurrentLocation: async () => HERE,
      searchNearby: async () => { if (unavailable) throw new Error("503"); return [CAFE]; },
    });
    await flushPromises();
    expect(picker.wrapper.get("[data-lookup-unavailable]").text()).toContain("地图暂不可用");
    expect(rowIds(picker.wrapper)).toEqual(["current"]);
    expect(picker.wrapper.get(".flare-location-picker__foot button").attributes("disabled")).toBeUndefined();
    unavailable = false;
    await picker.wrapper.get("[data-lookup-unavailable] button").trigger("click");
    await flushPromises();
    expect(rowIds(picker.wrapper)).toEqual(["current", "p1"]);
    expect(picker.wrapper.find("[data-lookup-unavailable]").exists()).toBe(false);
  });

  it("retries a failed static preview without requiring a new position", async () => {
    let unavailable = true;
    const previewUrl = vi.fn(async () => unavailable ? null : "https://geo.example/recovered.png");
    const picker = render({ requestCurrentLocation: async () => HERE, previewUrl });
    await flushPromises();
    unavailable = false;
    await picker.wrapper.get("[data-map-unavailable] button").trigger("click");
    await flushPromises();
    expect(picker.wrapper.get("img").attributes("src")).toBe("https://geo.example/recovered.png");
    expect(picker.wrapper.find("[data-map-unavailable]").exists()).toBe(false);
    expect(picker.wrapper.get('[data-place-id="current"]').attributes("aria-checked")).toBe("true");
  });

  it("says when a search finds nothing", async () => {
    const picker = render({ requestCurrentLocation: async () => HERE });
    await flushPromises();
    await picker.wrapper.get(".flare-location-picker__search input").setValue("不存在的地方");
    await picker.wrapper.get(".flare-location-picker__search input").trigger("keydown", { key: "Enter" });
    await flushPromises();
    expect(picker.root().attributes("data-state")).toBe("noResults");
    expect(picker.wrapper.text()).toContain("附近没有找到地点");
  });

  it("shows the coordinate when the map is unavailable, and still sends", async () => {
    const picker = render({ requestCurrentLocation: async () => HERE, previewUrl: async () => null });
    await flushPromises();
    expect(picker.root().attributes("data-state")).toBe("mapUnavailable");
    const note = picker.wrapper.get("[data-map-unavailable]");
    expect(note.text()).toContain("地图暂不可用");
    expect(note.text()).toContain("39.90870, 116.39750");
    expect(picker.wrapper.find("[data-placeholder]").exists()).toBe(true);
    await picker.wrapper.get(".flare-location-picker__foot button").trigger("click");
    expect(picker.sends).toHaveLength(1);
  });

  it("falls back to the remembered place when locating times out, and takes a late fix", async () => {
    vi.useFakeTimers();
    const fix = deferred<FlareLocationCoordinate>();
    const picker = render({
      requestCurrentLocation: () => fix.promise,
      locateTimeoutMs: 5000,
      initialLocation: { id: "last", title: "上次的位置", address: "朝阳区", latitude: 39.99, longitude: 116.48 },
    });
    await vi.advanceTimersByTimeAsync(5000);
    expect(picker.root().attributes("data-state")).toBe("located");
    expect(picker.wrapper.get('[data-place-id="current"]').text()).toContain("上次的位置");
    fix.resolve(HERE);
    await vi.runAllTimersAsync();
    expect(picker.wrapper.get('[data-place-id="current"]').text()).toContain("天安门广场");
  });

  it("does not count the permission prompt into the locate timeout", async () => {
    vi.useFakeTimers();
    const permission = deferred<boolean>();
    const fix = deferred<FlareLocationCoordinate>();
    const request = vi.fn(() => fix.promise);
    const picker = render({ ensurePermission: () => permission.promise, requestCurrentLocation: request, locateTimeoutMs: 5000 });
    // The person reads the system prompt for longer than the timeout: still locating, nothing asked yet.
    await vi.advanceTimersByTimeAsync(8000);
    expect(picker.root().attributes("data-state")).toBe("locating");
    expect(request).not.toHaveBeenCalled();
    permission.resolve(true);
    await vi.advanceTimersByTimeAsync(4000);
    expect(request).toHaveBeenCalledTimes(1);
    expect(picker.root().attributes("data-state")).toBe("locating");
    // The clock started when permission came: 5 s after that the picker gives up waiting.
    await vi.advanceTimersByTimeAsync(1000);
    expect(picker.root().attributes("data-state")).toBe("denied");
    fix.resolve(HERE);
    await vi.runAllTimersAsync();
    expect(picker.wrapper.get('[data-place-id="current"]').text()).toContain("天安门广场");
  });

  it("goes straight to denied when the host's permission step says no, without asking for the position", async () => {
    const request = vi.fn(async () => HERE);
    const picker = render({ ensurePermission: async () => false, requestCurrentLocation: request });
    await flushPromises();
    expect(picker.root().attributes("data-state")).toBe("denied");
    expect(request).not.toHaveBeenCalled();
    const failing = render({ ensurePermission: async () => { throw new Error("no"); }, requestCurrentLocation: request });
    await flushPromises();
    expect(failing.root().attributes("data-state")).toBe("denied");
    expect(request).not.toHaveBeenCalled();
  });

  it("locks Send while the host is sending", async () => {
    const picker = render({ requestCurrentLocation: async () => HERE, sending: true });
    await flushPromises();
    const send = picker.wrapper.get("[data-location-send]");
    expect(send.attributes("disabled")).toBeDefined();
    expect(send.attributes("aria-busy")).toBe("true");
    await send.trigger("click");
    expect(picker.sends).toHaveLength(0);
  });

  it("asks previewUrl for device pixels: the map area times the screen scale, at most twice", async () => {
    const sizes: Array<[number, number]> = [];
    const ratio = window.devicePixelRatio;
    Object.defineProperty(window, "devicePixelRatio", { configurable: true, value: 3 });
    try {
      render({
        requestCurrentLocation: async () => HERE,
        previewUrl: async (_lat: number, _lng: number, _zoom: number, width: number, height: number) => { sizes.push([width, height]); return null; },
      });
      await flushPromises();
      // happy-dom lays nothing out: the 360 × 168 fallback box, scaled by 2 (3 is capped).
      expect(sizes.at(-1)).toEqual([720, 336]);
    } finally {
      Object.defineProperty(window, "devicePixelRatio", { configurable: true, value: ratio });
    }
  });

  it("declares its own header to a fill sheet, which then draws no second title", async () => {
    const wrapper = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        useFlarePlatformProvider({ capabilities: { bottomSheet: true } });
        return () => h(FlareBottomSheet as never, { open: true, title: "位置", fill: true }, {
          default: () => h(FlareLocationPicker as never, { requestCurrentLocation: async () => HERE, searchNearby: async () => [] }),
        });
      },
    }), { attachTo: document.body });
    await flushPromises();
    const sheet = document.body.querySelector(".flare-sheet") as HTMLElement;
    expect(sheet.querySelector(".flare-sheet__title")).toBeNull();
    expect(sheet.getAttribute("aria-label")).toBe("位置");
    expect(sheet.querySelector(".flare-sheet__fill > .flare-location-picker")).not.toBeNull();
    wrapper.unmount();
  });

  it("locates again from the map key, and cancels", async () => {
    const request = vi.fn(async () => HERE);
    const picker = render({ requestCurrentLocation: request });
    await flushPromises();
    await picker.wrapper.get('[aria-label="定位到当前位置"]').trigger("click");
    await flushPromises();
    expect(request).toHaveBeenCalledTimes(2);
    await picker.wrapper.get(".flare-location-picker__cancel").trigger("click");
    expect(picker.cancels()).toBe(1);
  });
});
