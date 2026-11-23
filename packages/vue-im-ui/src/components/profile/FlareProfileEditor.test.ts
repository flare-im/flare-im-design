// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, nextTick, ref, type Component } from "vue";
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

  it("keeps an in-flight profile save stable: no concurrent avatar, edit or cancel", async () => {
    const host = mountEditor({ busy: true });
    expect(host.get('button.flare-profile-editor__avatar').attributes('disabled')).toBeDefined();
    expect(host.get('input').attributes('disabled')).toBeDefined();
    expect(host.get('textarea').attributes('disabled')).toBeDefined();
    for (const button of host.findAll('.flare-profile-editor__actions button')) {
      expect(button.attributes('disabled')).toBeDefined();
    }
    await host.get('input').trigger('keydown', { key: 'Enter' });
    expect(host.findComponent(FlareProfileEditor).emitted('save')).toBeUndefined();
    host.unmount();
  });

  it('does not write unchanged data through either Save or Enter', async () => {
    const host = mountEditor();
    expect(host.findAll('button').find(button => button.text() === '保存')!.attributes('disabled')).toBeDefined();
    await host.get('input').trigger('keydown', { key: 'Enter' });
    expect(host.findComponent(FlareProfileEditor).emitted('save')).toBeUndefined();
    await host.get('input').setValue('修改后的昵称');
    expect(host.findAll('button').find(button => button.text() === '保存')!.attributes('disabled')).toBeUndefined();
    host.unmount();
  });

  it('lets the caller preserve a draft across navigation and clears it when identity changes', async () => {
    const user = ref({ id: 'u1', name: '林夏', signature: '' });
    const draft = ref<{ name: string; signature: string }>();
    const open = ref(true);
    const host = mount(defineComponent({ setup() {
      useFlareI18nProvider('zh-CN');
      return () => open.value ? h(FlareProfileEditor as Component, { user: user.value, draft: draft.value,
        'onUpdate:draft': (value: typeof draft.value) => { draft.value = value; } }) : null;
    } }));
    await host.get('input').setValue('保留的昵称');
    await host.get('textarea').setValue('保留的签名');
    expect(draft.value).toEqual({ name: '保留的昵称', signature: '保留的签名' });
    open.value = false; await nextTick(); open.value = true; await nextTick();
    expect(host.get('input').element.value).toBe('保留的昵称');
    expect(host.get('textarea').element.value).toBe('保留的签名');
    user.value = { id: 'u2', name: '另一个账号', signature: '' }; await nextTick(); await nextTick();
    expect(host.get('input').element.value).toBe('另一个账号');
    expect(host.get('textarea').element.value).toBe('');
    host.unmount();
  });
});
