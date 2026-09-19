// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { mount } from "@vue/test-utils";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareComposerReplyStrip from "./FlareComposerReplyStrip.vue";

function setup(props: Record<string, unknown>) {
  const host = mount(defineComponent({ setup() { useFlareI18nProvider("en-US"); return () => h(FlareComposerReplyStrip as Component, props); } }));
  return host.findComponent(FlareComposerReplyStrip);
}

describe("FlareComposerReplyStrip", () => {
  it("labels the cancel control from the strings table and emits cancel", async () => {
    const strip = setup({ senderName: "Ivy", summary: "See the draft" });
    expect(strip.text()).toContain("Reply Ivy");
    const cancel = strip.get("button");
    expect(cancel.attributes("aria-label")).toBe("Cancel reply");
    await cancel.trigger("click");
    expect(strip.emitted("cancel")).toHaveLength(1);
  });

  it("takes host labels and tones for edit and warning contexts", () => {
    const edit = setup({ senderName: "", summary: "old text", label: "Editing", cancelLabel: "Cancel edit", tone: "edit" });
    expect(edit.classes()).toContain("flare-reply--edit");
    expect(edit.get("button").attributes("aria-label")).toBe("Cancel edit");
    const warn = setup({ senderName: "Ivy", summary: "expired", tone: "warn" });
    expect(warn.classes()).toContain("flare-reply--warn");
  });
});
