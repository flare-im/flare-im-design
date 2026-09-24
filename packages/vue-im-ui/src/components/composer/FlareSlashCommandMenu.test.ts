// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareSlashCommandMenu from "./FlareSlashCommandMenu.vue";

const commands = [
  { command: "mute", description: "静音这个会话", hint: "⌘M" },
  { command: "poll", description: "发起投票" },
  { command: "remind", description: "设置提醒" },
];

function render(props: InstanceType<typeof FlareSlashCommandMenu>["$props"]) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareSlashCommandMenu, props);
    },
  }));
}

/**
 * The menu narrows as the person types. It is a listbox, it writes the leading slash itself, and it
 * says so when nothing matches rather than going blank. Release criterion §1 (component tests).
 */
describe("FlareSlashCommandMenu", () => {
  it("is a named listbox of options", () => {
    const wrapper = render({ commands });
    expect(wrapper.find('[role="listbox"]').attributes("aria-label")).toBeTruthy();
    expect(wrapper.findAll('[role="option"]')).toHaveLength(3);
  });

  it("writes the slash itself, so a host passes the command and not the punctuation", () => {
    const wrapper = render({ commands });
    expect(wrapper.findAll(".flare-slash-menu__cmd").map((n) => n.text())).toEqual(["/mute", "/poll", "/remind"]);
  });

  it("filters on the command and on its description", () => {
    expect(render({ commands, query: "mu" }).findAll('[role="option"]')).toHaveLength(1);
    expect(render({ commands, query: "投票" }).findAll(".flare-slash-menu__cmd").map((n) => n.text())).toEqual(["/poll"]);
  });

  it("ignores a leading slash and surrounding space in the query", () => {
    expect(render({ commands, query: " /po " }).findAll('[role="option"]')).toHaveLength(1);
  });

  it("says nothing matched instead of showing an empty box", () => {
    const wrapper = render({ commands, query: "zzz" });
    expect(wrapper.findAll('[role="option"]')).toHaveLength(0);
    expect(wrapper.find(".flare-slash-menu__empty").text()).toBeTruthy();
  });

  it("reports the whole command, so the host does not look it up again", async () => {
    const wrapper = render({ commands });
    await wrapper.findAll('[role="option"]')[1].trigger("click");
    expect(wrapper.findComponent(FlareSlashCommandMenu).emitted("select")?.[0]).toEqual([commands[1]]);
  });
});
