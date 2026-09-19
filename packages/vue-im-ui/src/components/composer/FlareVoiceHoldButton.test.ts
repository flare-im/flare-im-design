// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareVoiceHoldButton from "./FlareVoiceHoldButton.vue";

function render(props: Record<string, unknown> = {}) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareVoiceHoldButton, props);
    },
  }));
}

/**
 * Hold to record, lift to send, leave to cancel. The three have to stay distinct: a pointer that
 * leaves the key must not send what it recorded. Release criterion §1 (component tests).
 */
describe("FlareVoiceHoldButton", () => {
  it("names itself from the kit's strings, and takes a host's words instead", () => {
    expect(render().text()).toBe("按住说话");
    expect(render({ label: "Hold to talk" }).text()).toBe("Hold to talk");
  });

  it("says it is recording while held, and goes back when released", async () => {
    const wrapper = render();
    const button = wrapper.find("button");
    await button.trigger("pointerdown");
    expect(wrapper.text()).toBe("松开发送");
    expect(button.classes()).toContain("pressing");

    await button.trigger("pointerup");
    expect(wrapper.text()).toBe("按住说话");
    expect(button.classes()).not.toContain("pressing");
  });

  it("reports start then end for a hold that finishes on the key", async () => {
    const wrapper = render();
    const button = wrapper.find("button");
    await button.trigger("pointerdown");
    await button.trigger("pointerup");
    expect(wrapper.findComponent(FlareVoiceHoldButton).emitted("start")).toHaveLength(1);
    expect(wrapper.findComponent(FlareVoiceHoldButton).emitted("end")).toHaveLength(1);
    expect(wrapper.findComponent(FlareVoiceHoldButton).emitted("cancel")).toBeUndefined();
  });

  it("cancels instead of sending when the pointer leaves the key", async () => {
    const wrapper = render();
    const button = wrapper.find("button");
    await button.trigger("pointerdown");
    await button.trigger("pointerleave");
    const emitted = wrapper.findComponent(FlareVoiceHoldButton).emitted();
    expect(emitted.cancel).toHaveLength(1);
    expect(emitted.end).toBeUndefined();
  });

  it("ignores a release or a leave that follows no hold", async () => {
    const wrapper = render();
    const button = wrapper.find("button");
    await button.trigger("pointerup");
    await button.trigger("pointerleave");
    const emitted = wrapper.findComponent(FlareVoiceHoldButton).emitted();
    expect(emitted.end).toBeUndefined();
    expect(emitted.cancel).toBeUndefined();
  });
});
