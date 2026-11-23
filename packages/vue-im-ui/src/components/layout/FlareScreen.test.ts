// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareScreen from "./FlareScreen.vue";
import FlareProfileEditor from "../profile/FlareProfileEditor.vue";
import FlareVersionPanel from "../profile/FlareVersionPanel.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => { host?.unmount(); host = undefined; });

function mountScreen(props: Record<string, unknown>) {
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareScreen as Component, props, { default: () => h("p", "内容") });
    },
  }));
  return host;
}

describe("FlareScreen", () => {
  it("changes detail presentation without discarding a draft or changing save intent", async () => {
    const layout = ref<'page' | 'detail'>('detail');
    const saved: unknown[] = [];
    host = mount(defineComponent({ setup() {
      useFlareI18nProvider('zh-CN');
      return () => h(FlareScreen, { title: '编辑资料', layout: layout.value }, () => h(FlareProfileEditor, {
        user: { id: 'u', name: 'Lin' }, onSave: (value: { name: string; signature: string }) => saved.push(value),
      }));
    } }));
    const input = host.get('input');
    await input.setValue('Draft kept');
    expect(host.get('.flare-profile-editor').classes()).toContain('is-detail');
    expect(host.get('.flare-profile-editor__actions button').classes()).not.toContain('is-block');
    layout.value = 'page'; await nextTick();
    expect(host.get('input').element).toBe(input.element);
    expect((input.element as HTMLInputElement).value).toBe('Draft kept');
    expect(host.get('.flare-profile-editor__actions button').classes()).toContain('is-block');
    await host.get('.flare-profile-editor__actions button:last-child').trigger('click');
    expect(saved).toEqual([{ name: 'Draft kept', signature: '' }]);
  });

  it("omits repeated detail headings and resets presentation inside a nested page", () => {
    host = mount(defineComponent({ setup() {
      useFlareI18nProvider('zh-CN');
      return () => h(FlareScreen, { title: '版本信息', layout: 'detail' }, () => [
        h(FlareVersionPanel, { version: '1.0' }),
        h(FlareScreen, { title: '关于' }, () => h(FlareVersionPanel, { version: '2.0' })),
      ]);
    } }));
    const panels = host.findAllComponents(FlareVersionPanel);
    expect(panels[0].find('.flare-settings__title').exists()).toBe(false);
    expect(panels[1].find('.flare-settings__title').exists()).toBe(true);
    expect(panels[1].get('.flare-settings').classes()).not.toContain('is-detail');
    expect(panels[0].text()).toContain('1.0');
    expect(panels[1].text()).toContain('2.0');
  });

  it("names its back button in the interface language", async () => {
    let backs = 0;
    const screen = mountScreen({ title: "设置", back: true, onBack: () => { backs += 1; } });
    const back = screen.get(".flare-screen__back");
    expect(back.attributes("aria-label")).toBe("返回");
    await back.trigger("click");
    expect(backs).toBe(1);
  });

  // 一级页(通讯录/圈子/我)不传 back 就不能有返回键。曾因 <script setup> 里的 back() 函数在模板里
  // 遮住同名 prop,`v-if="back"` 永远为真,四个 tab 根页全长出返回箭头。
  it("draws no back button unless asked", () => {
    const screen = mountScreen({ title: "通讯录" });
    expect(screen.find(".flare-screen__back").exists()).toBe(false);
    expect(screen.get(".flare-screen__title").text()).toBe("通讯录");
  });

  it("puts a readable page in the reading column only when asked", () => {
    expect(mountScreen({ title: "我" }).classes()).not.toContain("flare-screen--readable");
    host?.unmount();
    expect(mountScreen({ title: "我", readable: true }).get(".flare-screen").classes()).toContain("flare-screen--readable");
  });
});
