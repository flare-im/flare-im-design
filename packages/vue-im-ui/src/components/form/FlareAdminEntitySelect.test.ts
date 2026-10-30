// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { NSelect } from "naive-ui";
import Select from "./FlareAdminEntitySelect.vue";
import FlareModal from "../general/FlareModal.vue";
import { h, nextTick } from "vue";
const props = {
  label: "User",
  placeholder: "Search accounts",
  emptyText: "No users",
  moreText: "More",
  retryText: "Retry",
  options: [
    { value: "u1", label: "Alice · alice@example.invalid" },
    { value: "u2", label: "Bob", disabled: true },
  ],
};
describe("FlareAdminEntitySelect", () => {
  it("Escape dismisses an open directory menu without closing its parent edit modal", async () => {
    let closes=0;
    const host=mount({render:()=>h(FlareModal,{open:true,onClose:()=>closes++},{default:()=>h(Select,props)})},{attachTo:document.body});
    const child=host.getComponent(Select);
    child.getComponent(NSelect).vm.$emit("update:show",true);
    await nextTick();
    const event=new KeyboardEvent("keydown",{key:"Escape",bubbles:true,cancelable:true});
    child.get("input").element.dispatchEvent(event);
    await nextTick();
    expect(event.defaultPrevented).toBe(true);
    expect(closes).toBe(0);
    expect(child.getComponent(NSelect).props("show")).toBe(false);
    host.unmount();
  });
  it("renders identities as two-line candidates but concise selected names, escaping their data", () => {
    const option = {
      value: "u1",
      label: "<Alice> · alice@example.invalid",
      title: "<Alice>",
      description: "alice@example.invalid",
    };
    const host = mount(Select, { props: { ...props, options: [option] } });
    const renderLabel = host.getComponent(NSelect).props("renderLabel")!;
    const candidate = mount({
      render: () => renderLabel(option as never, false),
    });
    expect(candidate.text()).toContain("<Alice>");
    expect(candidate.text()).toContain("alice@example.invalid");
    expect(candidate.find("alice").exists()).toBe(false);
    const selected = mount({
      render: () => renderLabel(option as never, true),
    });
    expect(selected.text()).toBe("<Alice>");
    expect(selected.attributes("title")).toBe(option.label);
    selected.unmount();
    candidate.unmount();
    host.unmount();
  });
  it("exposes optional bounded selected-member management without losing unavailable selections", async () => {
    const host = mount(Select, {
      attachTo: document.body,
      props: {
        ...props,
        multiple: true,
        values: ["u1", "u2"],
        selectionSummary: true,
        selectedText: "Selected 2 / 200",
        manageText: "Manage selected",
        collapseText: "Collapse",
        clearText: "Clear",
        removeText: "Remove",
      },
    });
    expect(host.find('[role="list"]').exists()).toBe(false);
    const control = host.getComponent(NSelect);
    control.vm.$emit("update:show", true);
    await host.vm.$nextTick();
    expect(control.props("show")).toBe(true);
    await host
      .findAll("button")
      .find((button) => button.text() === "Manage selected")!
      .trigger("click");
    expect(host.get('[role="list"]').attributes("aria-label")).toBe(
      "Selected 2 / 200",
    );
    expect(control.props("show")).toBe(false);
    expect(host.findAll('[role="listitem"]')).toHaveLength(2);
    await host
      .get('button[aria-label="Remove Alice · alice@example.invalid"]')
      .trigger("click");
    expect(host.emitted("update:values")).toEqual([[["u2"]]]);
    expect(document.activeElement).toBe(host.get('[role="group"]').element);
    await host.setProps({ disabled: true });
    expect(host.find('[role="list"]').exists()).toBe(false);
    host.unmount();
  });
  it("prevents additions at zero capacity and still permits removals after lowering a limit", async () => {
    const host = mount(Select, {
      props: {
        ...props,
        options: [
          { value: "u1", label: "Alice" },
          { value: "u2", label: "Bob" },
          { value: "u3", label: "Carol" },
        ],
        multiple: true,
        values: ["u1", "u2"],
        max: 0,
      },
    });
    const control = host.getComponent(NSelect);
    expect(
      control.props("options")?.find((o) => o.value === "u3")?.disabled,
    ).toBe(true);
    control.vm.$emit("update:value", ["u1", "u2", "u3"]);
    control.vm.$emit("update:value", ["u2"]);
    control.vm.$emit("update:value", ["u3"]);
    expect(host.emitted("update:values")).toEqual([[["u2"]]]);
    host.unmount();
  });
  it("uses small, remote searchable Naive UI selection without free-form tags", () => {
    const host = mount(Select, { props });
    const control = host.getComponent(NSelect);
    expect(control.props()).toMatchObject({
      remote: true,
      filterable: true,
      tag: false,
      size: "small",
      clearable: true,
    });
    expect(host.find("input").attributes("aria-label")).toBe("User");
    host.unmount();
  });
  it("emits only an offered selectable ID or explicit clear, never typed text", async () => {
    const host = mount(Select, { props });
    const control = host.getComponent(NSelect);
    control.vm.$emit("update:value", "typed-id");
    control.vm.$emit("update:value", "u2");
    expect(host.emitted("update:value")).toBeUndefined();
    control.vm.$emit("search", "alice");
    expect(host.emitted("search")).toEqual([["alice"]]);
    control.vm.$emit("update:value", "u1");
    control.vm.$emit("update:value", null);
    expect(host.emitted("update:value")).toEqual([["u1"], [""]]);
    await host.setProps({ disabled: true });
    control.vm.$emit("update:value", "u1");
    expect(host.emitted("update:value")).toHaveLength(2);
    host.unmount();
  });
  it("keeps multi-selection bounded and deduplicated and exposes failures accessibly", () => {
    const host = mount(Select, {
      props: { ...props, multiple: true, max: 2, error: "Lookup failed" },
    });
    const control = host.getComponent(NSelect);
    control.vm.$emit("update:value", ["u1", "u1"]);
    control.vm.$emit("update:value", ["u1", "u1", "u1"]);
    control.vm.$emit("update:value", ["u2"]);
    expect(host.emitted("update:values")).toEqual([[["u1"]]]);
    expect(host.get('[role="status"]').text()).toBe("Lookup failed");
    host.unmount();
  });
  it("allows removing tags without introducing another unavailable persisted user", () => {
    const host = mount(Select, {
      props: { ...props, multiple: true, values: ["u1", "u2"] },
    });
    const control = host.getComponent(NSelect);
    control.vm.$emit("update:value", ["u2"]);
    control.vm.$emit("update:value", ["u2", "unknown"]);
    expect(host.emitted("update:values")).toEqual([[["u2"]]]);
    host.unmount();
  });
});

it("can suppress the clear action without changing the selected value", async () => {
  const wrapper = mount(Select, {
    props: {
      value: "one",
      options: [{ value: "one", label: "One" }],
      label: "Required choice",
      placeholder: "Choose",
      emptyText: "Empty",
      moreText: "More",
      retryText: "Retry",
      clearable: false,
    },
  });
  const input = wrapper.findComponent(NSelect);
  expect(input.props("clearable")).toBe(false);
  input.vm.$emit("update:value", null);
  expect(wrapper.emitted("update:value")).toBeUndefined();
  await wrapper.setProps({ clearable: true });
  input.vm.$emit("update:value", null);
  expect(wrapper.emitted("update:value")?.[0]).toEqual([""]);
  wrapper.unmount();
});
