// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlarePollComposer from "./FlarePollComposer.vue";

let host: ReturnType<typeof mount>;
afterEach(() => { host?.unmount(); });

function mountComposer(props: Record<string, unknown> = {}) {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("en-US");
    return () => h(FlarePollComposer as Component, props);
  } }));
  return host.findComponent(FlarePollComposer);
}

describe("FlarePollComposer", () => {
  it("draws its own title and close key as a standalone card", () => {
    const composer = mountComposer();
    expect(composer.find(".flare-poll-composer__head").exists()).toBe(true);
    expect(composer.classes()).not.toContain("flare-poll-composer--embedded");
  });

  it("embedded leaves the title and close to the host sheet, so it is not framed twice", () => {
    const composer = mountComposer({ embedded: true });
    expect(composer.find(".flare-poll-composer__head").exists()).toBe(false);
    expect(composer.classes()).toContain("flare-poll-composer--embedded");
  });

  it("the multiple-choice box shows its state, not a permanent tick", async () => {
    const composer = mountComposer({ embedded: true });
    expect(composer.find(".flare-poll-composer__box").exists()).toBe(true);
    expect(composer.find(".flare-poll-composer__check").exists()).toBe(false);
    await composer.find('.flare-poll-composer__multi input[type="checkbox"]').setValue(true);
    expect(composer.find(".flare-poll-composer__box").exists()).toBe(false);
    expect(composer.find(".flare-poll-composer__check").exists()).toBe(true);
  });

  it("submits the trimmed question, the filled options and the multiple flag", async () => {
    const composer = mountComposer({ embedded: true });
    await composer.find(".flare-poll-composer__question").setValue("  Lunch?  ");
    const options = composer.findAll(".flare-poll-composer__opt-input");
    await options[0].setValue("Noodles");
    await options[1].setValue(" Rice ");
    await composer.find('.flare-poll-composer__multi input[type="checkbox"]').setValue(true);
    await composer.find(".flare-poll-composer__submit").trigger("click");
    expect(composer.emitted("submit")).toEqual([[{ question: "Lunch?", options: ["Noodles", "Rice"], multiple: true }]]);
  });
});
