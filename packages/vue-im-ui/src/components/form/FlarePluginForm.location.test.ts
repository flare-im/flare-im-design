// @vitest-environment happy-dom
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { nextTick } from "vue";
import FlarePluginForm from "./FlarePluginForm.vue";
import {
  flarePluginCheckInput,
  flarePluginDraftValue,
  type FlarePluginInput,
  type FlarePluginLocationAction,
} from "../../shared/contracts/plugin-ui";

enableAutoUnmount(afterEach);
const place: FlarePluginInput = { id: "place", kind: "location", label: "Where", required: true, precision: "coarse" };
const fix = { latitude: 31.23, longitude: 121.47, accuracyM: 1000, precision: "coarse" as const };

describe("location input", () => {
  it("is empty until the host writes a fix, then submits it", async () => {
    const actions: FlarePluginLocationAction[] = [];
    const submitted: Record<string, unknown>[] = [];
    const wrapper = mount(FlarePluginForm, {
      props: { inputs: [place], onLocationAction: (a: FlarePluginLocationAction) => actions.push(a), onSubmit: (v: Record<string, unknown>) => submitted.push(v) },
    });
    expect(wrapper.find("[data-location-empty]").exists()).toBe(true);
    await wrapper.get("[data-location-locate]").trigger("click");
    expect(actions.map((a) => [a.action, a.inputId])).toEqual([["locate", "place"]]);
    await wrapper.setProps({ locationStates: { place: { locating: true } } });
    expect(wrapper.get("[data-location-locate]").attributes("disabled")).toBeDefined();
    await wrapper.setProps({ locationStates: { place: { value: fix } } });
    expect(wrapper.get("[data-location-place]").text()).toBe("31.23°N, 121.47°E");
    await wrapper.get("form").trigger("submit");
    expect(submitted).toEqual([{ place: fix }]);
  });

  it("clears the fix and tells the host", async () => {
    const actions: FlarePluginLocationAction[] = [];
    const wrapper = mount(FlarePluginForm, {
      props: { inputs: [place], locationStates: { place: { value: fix } }, onLocationAction: (a: FlarePluginLocationAction) => actions.push(a) },
    });
    await nextTick();
    await wrapper.get("[data-location-clear]").trigger("click");
    expect(actions.at(-1)?.action).toBe("clear");
    expect(wrapper.find("[data-location-empty]").exists()).toBe(true);
  });

  it("never takes a fix of another precision", async () => {
    const wrapper = mount(FlarePluginForm, { props: { inputs: [{ ...place, precision: "fine" }], locationStates: { place: { value: fix } } } });
    await nextTick();
    expect(wrapper.find("[data-location-empty]").exists()).toBe(true);
    expect(flarePluginDraftValue({ ...place, precision: "fine" }, { place: fix })).toBeNull();
    expect(flarePluginCheckInput(place, null)).toBe("required");
    expect(flarePluginCheckInput(place, { ...fix, latitude: 31.234 })).toBe("invalidType");
  });

  it("offers no locate key when the host does not listen", () => {
    const wrapper = mount(FlarePluginForm, { props: { inputs: [place] } });
    expect(wrapper.get("[data-location-locate]").attributes("disabled")).toBeDefined();
  });

  it("shows the host's failure", () => {
    const wrapper = mount(FlarePluginForm, { props: { inputs: [place], locationStates: { place: { error: "Location is off" } } } });
    expect(wrapper.text()).toContain("Location is off");
  });
});
