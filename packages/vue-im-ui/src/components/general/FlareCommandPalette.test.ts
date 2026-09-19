// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { nextTick } from "vue";
import { describe, expect, it } from "vitest";
import FlareCommandPalette from "./FlareCommandPalette.vue";

const groups = [{
  id: "message",
  label: "Message",
  commands: [
    { id: "reply", label: "Reply", shortcut: "R" },
    { id: "copy", label: "Copy", shortcut: "Ctrl+C" },
    { id: "delete", label: "Delete", disabled: true },
  ],
}];

describe("FlareCommandPalette", () => {
  it("filters controlled results and emits query intent", async () => {
    const wrapper = mount(FlareCommandPalette, {
      props: { open: true, query: "", groups, label: "Commands", placeholder: "Find", emptyText: "None" },
      global: { stubs: { Teleport: true } },
    });
    await wrapper.get("input").setValue("copy");
    expect(wrapper.emitted("queryChange")?.at(-1)).toEqual(["copy"]);
    await wrapper.setProps({ query: "copy" });
    expect(wrapper.findAll("button")).toHaveLength(1);
    expect(wrapper.text()).toContain("Copy");
  });

  it("navigates enabled commands and closes from the keyboard", async () => {
    const wrapper = mount(FlareCommandPalette, {
      props: { open: true, query: "", groups, label: "Commands", placeholder: "Find", emptyText: "None", selectedId: "reply" },
      global: { stubs: { Teleport: true } },
    });
    const dialog = wrapper.get("[role=dialog]");
    await dialog.trigger("keydown", { key: "ArrowDown" });
    expect(wrapper.emitted("selectedIdChange")?.at(-1)).toEqual(["copy"]);
    await wrapper.setProps({ selectedId: "copy" });
    await dialog.trigger("keydown", { key: "Enter" });
    expect(wrapper.emitted("invoke")?.at(-1)?.[0]).toMatchObject({ id: "copy" });
    await dialog.trigger("keydown", { key: "Escape" });
    expect(wrapper.emitted("close")).toHaveLength(1);
  });

  it("restores focus to the trigger after closing", async () => {
    const trigger = document.createElement("button");
    document.body.appendChild(trigger);
    trigger.focus();
    const wrapper = mount(FlareCommandPalette, {
      props: { open: false, query: "", groups, label: "Commands", placeholder: "Find", emptyText: "None" },
      attachTo: document.body,
      global: { stubs: { Teleport: true } },
    });
    await wrapper.setProps({ open: true });
    await nextTick();
    expect(document.activeElement).toBe(wrapper.get("input").element);
    await wrapper.setProps({ open: false });
    expect(document.activeElement).toBe(trigger);
    wrapper.unmount();
    trigger.remove();
  });
});
