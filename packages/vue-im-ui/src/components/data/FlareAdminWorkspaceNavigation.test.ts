// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { nextTick } from "vue";
import { FlareAdminWorkspaceNavigation as Navigation, type FlareAdminWorkspaceNavigationGroup } from "../../admin";

const groups: readonly FlareAdminWorkspaceNavigationGroup[] = [
  { key: "poll", label: "Poll", icon: "poll", items: [
    { key: "poll/records", label: "Poll records" },
    { key: "poll/review", label: "Poll review", disabled: true },
  ] },
  { key: "task", label: "Task", items: [
    { key: "task/records", label: "Task records" },
    { key: "task/review", label: "Task review" },
  ] },
  { key: "locked", label: "Locked", disabled: true, items: [
    { key: "locked/records", label: "Locked records" },
  ] },
];
const hosts: ReturnType<typeof mount>[] = [];
function setup(value: string | null = "poll/records", disabled = false) {
  const host = mount(Navigation, { props: { label: "Plugin workspace", groups, value, disabled }, attachTo: document.body });
  hosts.push(host);
  return host;
}
afterEach(() => {
  hosts.splice(0).forEach((host) => host.unmount());
  document.body.innerHTML = "";
});

describe("FlareAdminWorkspaceNavigation", () => {
  it("opens the selected leaf's group and follows external selection changes", async () => {
    const host = setup();
    expect(host.get("nav").attributes("aria-label")).toBe("Plugin workspace");
    expect(host.get('[data-workspace-key="poll"]').attributes("aria-expanded")).toBe("true");
    expect(host.get('[data-workspace-key="task"]').attributes("aria-expanded")).toBe("false");
    expect(host.get('[data-workspace-key="poll/records"]').attributes("aria-current")).toBe("page");
    await host.setProps({ value: "task/review" });
    expect(host.get('[data-workspace-key="task"]').attributes("aria-expanded")).toBe("true");
    expect(host.get('[data-workspace-key="poll"]').attributes("aria-expanded")).toBe("false");
    expect(host.get('[data-workspace-key="task/review"]').attributes("aria-current")).toBe("page");
    expect(host.emitted("change")).toBeUndefined();
  });

  it("uses an accordion and emits leaf selection without changing the controlled value", async () => {
    const host = setup();
    await host.get('[data-workspace-key="task"] .n-menu-item-content').trigger("click");
    expect(host.get('[data-workspace-key="task"]').attributes("aria-expanded")).toBe("true");
    expect(host.get('[data-workspace-key="poll"]').attributes("aria-expanded")).toBe("false");
    expect(host.emitted("change")).toBeUndefined();
    await host.get('[data-workspace-key="task/records"] .n-menu-item-content').trigger("click");
    expect(host.emitted("change")).toEqual([["task/records"]]);
    expect(host.emitted("update:value")).toEqual([["task/records"]]);
    expect(host.get('[data-workspace-key="task/records"]').attributes("aria-current")).toBeUndefined();
  });

  it("supports keyboard expansion and selection while skipping disabled items", async () => {
    const host = setup();
    const poll = host.get('[data-workspace-key="poll"]');
    (poll.element as HTMLElement).focus();
    await poll.trigger("keydown", { key: "ArrowDown" });
    expect(document.activeElement).toBe(host.get('[data-workspace-key="poll/records"]').element);
    await host.get('[data-workspace-key="poll/records"]').trigger("keydown", { key: "ArrowDown" });
    expect(document.activeElement).toBe(host.get('[data-workspace-key="task"]').element);
    await host.get('[data-workspace-key="task"]').trigger("keydown", { key: "ArrowRight" });
    await nextTick();
    await host.get('[data-workspace-key="task"]').trigger("keydown", { key: "ArrowDown" });
    expect(document.activeElement).toBe(host.get('[data-workspace-key="task/records"]').element);
    await host.get('[data-workspace-key="task/records"]').trigger("keydown", { key: "Enter" });
    expect(host.emitted("change")).toEqual([["task/records"]]);
    await host.get('[data-workspace-key="task/records"]').trigger("keydown", { key: "ArrowLeft" });
    expect(document.activeElement).toBe(host.get('[data-workspace-key="task"]').element);
    await host.get('[data-workspace-key="task"]').trigger("keydown", { key: " " });
    expect(host.get('[data-workspace-key="task"]').attributes("aria-expanded")).toBe("false");
  });

  it("prevents disabled leaves, groups and the whole navigation from activating", async () => {
    const host = setup();
    const leaf = host.get('[data-workspace-key="poll/review"]');
    expect(leaf.attributes("aria-disabled")).toBe("true");
    expect(leaf.attributes("tabindex")).toBe("-1");
    await leaf.get(".n-menu-item-content").trigger("click");
    await leaf.trigger("keydown", { key: "Enter" });
    await host.get('[data-workspace-key="locked"] .n-menu-item-content').trigger("click");
    expect(host.get('[data-workspace-key="locked"]').attributes("aria-expanded")).toBe("false");
    await host.setProps({ disabled: true });
    await host.get('[data-workspace-key="poll/records"] .n-menu-item-content').trigger("click");
    await host.get('[data-workspace-key="task"]').trigger("keydown", { key: "Enter" });
    expect(host.get('[data-workspace-key="task"]').attributes("aria-expanded")).toBe("false");
    expect(host.emitted("change")).toBeUndefined();
    expect(host.emitted("update:value")).toBeUndefined();
  });
});
