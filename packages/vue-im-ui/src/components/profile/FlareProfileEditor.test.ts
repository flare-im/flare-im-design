// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, nextTick, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareProfileEditor from "./FlareProfileEditor.vue";

function mountEditor(listeners: Record<string, unknown> = {}) {
  const host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareProfileEditor as Component, { user: { id: "u1", name: "林夏", signature: "" }, ...listeners });
  } }), { attachTo: document.body });
  return host;
}

describe("FlareProfileEditor", () => {
  it("offers the avatar change as a named button", async () => {
    let picked = 0;
    const host = mountEditor({ onPickAvatar: () => { picked += 1; } });
    const avatar = host.get("button.flare-profile-editor__avatar");
    expect(avatar.attributes("aria-label")).toBe("更换头像");
    expect(avatar.attributes("type")).toBe("button");
    await avatar.trigger("click");
    expect(picked).toBe(1);
    host.unmount();
  });

  it("labels the nickname and bio inputs", async () => {
    const host = mountEditor();
    await nextTick();
    const labels = host.findAll("label");
    expect(labels.map((label) => label.text())).toEqual(["昵称", "个性签名"]);
    for (const label of labels) {
      const target = label.attributes("for");
      expect(target).toBeTruthy();
      expect(host.find(`#${target}`).exists()).toBe(true);
    }
    host.unmount();
  });
});
