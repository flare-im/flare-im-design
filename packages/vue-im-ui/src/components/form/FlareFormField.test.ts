// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareFormField from "./FlareFormField.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareSelect from "./FlareSelect.vue";
import FlareSlider from "./FlareSlider.vue";
import FlareSwitch from "./FlareSwitch.vue";
import FlareTextarea from "./FlareTextarea.vue";

function describedTargets(root: Element, control: Element): (Element | null)[] {
  return (control.getAttribute("aria-describedby") ?? "").split(/\s+/).filter(Boolean).map((id) => root.querySelector(`#${CSS.escape(id)}`));
}

describe("FlareFormField control association", () => {
  it("points the label at the nested Input and describes it with the hint, then the error", async () => {
    const error = ref<string | undefined>(undefined);
    const wrapper = mount(defineComponent({
      setup: () => () => h(FlareFormField, { label: "Account", hint: "Your sign-in name", required: true, error: error.value }, () => h(FlareInput, { placeholder: "Type here" })),
    }), { attachTo: document.body });
    await nextTick();

    const input = wrapper.get("input");
    const label = wrapper.get("label");
    expect(input.attributes("id")).toBeTruthy();
    expect(label.attributes("for")).toBe(input.attributes("id"));
    // The visible label names the input; the placeholder no longer overrides it.
    expect(input.attributes("aria-label")).toBeUndefined();
    expect(input.attributes("aria-required")).toBe("true");
    expect(input.attributes("aria-invalid")).toBeUndefined();
    let targets = describedTargets(wrapper.element, input.element);
    expect(targets).toHaveLength(1);
    expect(targets[0]?.textContent).toBe("Your sign-in name");

    error.value = "Required";
    await nextTick();
    expect(input.attributes("aria-invalid")).toBe("true");
    targets = describedTargets(wrapper.element, input.element);
    expect(targets).toHaveLength(1);
    expect(targets[0]?.textContent).toBe("Required");
    wrapper.unmount();
  });

  it("keeps explicit control props and points the label at the explicit id", async () => {
    const wrapper = mount(defineComponent({
      setup: () => () => h(FlareFormField, { label: "Note", hint: "Optional" }, () => h(FlareTextarea, { id: "note", ariaDescribedby: "outside", ariaLabel: "Custom" })),
    }));
    await nextTick();
    const textarea = wrapper.get("textarea");
    expect(textarea.attributes("id")).toBe("note");
    expect(wrapper.get("label").attributes("for")).toBe("note");
    expect(textarea.attributes("aria-describedby")).toBe("outside");
    expect(textarea.attributes("aria-label")).toBe("Custom");
  });

  it("binds only the first control, so ids never repeat, and hands the field over when it unmounts", async () => {
    const first = ref(true);
    const wrapper = mount(defineComponent({
      setup: () => () => h(FlareFormField, { label: "Code", hint: "6 digits" }, () => [
        first.value ? h(FlareInput, { class: "first" }) : null,
        h(FlareInput, { class: "second" }),
      ]),
    }));
    await nextTick();
    const fieldId = wrapper.get("label").attributes("for");
    expect(wrapper.get(".first input").attributes("id")).toBe(fieldId);
    expect(wrapper.get(".second input").attributes("id")).toBeUndefined();
    expect(wrapper.get(".second input").attributes("aria-describedby")).toBeUndefined();

    first.value = false;
    await nextTick();
    await nextTick();
    expect(wrapper.get(".second input").attributes("id")).toBe(fieldId);
    expect(wrapper.get("label").attributes("for")).toBe(fieldId);
  });

  it("leaves the label without `for` when no kit control is inside", async () => {
    const wrapper = mount(FlareFormField, { props: { label: "Members" }, slots: { default: () => h("div", "list") } });
    await nextTick();
    expect(wrapper.get("label").attributes("for")).toBeUndefined();
    // A host control of its own declares the id it renders.
    await wrapper.setProps({ controlId: "host-control" });
    expect(wrapper.get("label").attributes("for")).toBe("host-control");
  });

  it("names Select as label plus value, and Switch and Slider through the label", async () => {
    const wrapper = mount(defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () => h("div", [
          h(FlareFormField, { label: "Language", class: "select-field" }, () => h(FlareSelect, { options: [{ value: "en", label: "English" }], modelValue: "en", title: "Language" })),
          h(FlareFormField, { label: "Allow strangers", hint: "Off blocks new chats", class: "switch-field" }, () => h(FlareSwitch)),
          h(FlareFormField, { label: "Volume", class: "slider-field" }, () => h(FlareSlider)),
        ]);
      },
    }));
    await nextTick();

    const trigger = wrapper.get(".select-field button.flare-select__trigger");
    const selectLabel = wrapper.get(".select-field label");
    expect(selectLabel.attributes("for")).toBe(trigger.attributes("id"));
    expect(trigger.attributes("aria-label")).toBeUndefined();
    const [labelRef, valueRef] = (trigger.attributes("aria-labelledby") ?? "").split(" ");
    expect(wrapper.element.querySelector(`#${CSS.escape(labelRef)}`)?.textContent?.trim()).toBe("Language");
    expect(wrapper.element.querySelector(`#${CSS.escape(valueRef)}`)?.textContent).toBe("English");

    const toggle = wrapper.get(".switch-field [role=switch]");
    expect(wrapper.get(".switch-field label").attributes("for")).toBe(toggle.attributes("id"));
    expect(describedTargets(wrapper.element, toggle.element)[0]?.textContent).toBe("Off blocks new chats");

    const range = wrapper.get(".slider-field input[type=range]");
    expect(wrapper.get(".slider-field label").attributes("for")).toBe(range.attributes("id"));
    expect(range.attributes("aria-label")).toBeUndefined();
  });

  it("keeps a standalone Input named by its placeholder and a standalone Select by its title", () => {
    const input = mount(FlareInput, { props: { placeholder: "Search" } });
    expect(input.get("input").attributes("aria-label")).toBe("Search");
    expect(input.get("input").attributes("id")).toBeUndefined();
    const select = mount(FlareSelect, { props: { options: [], title: "Filter" } });
    expect(select.get("button").attributes("aria-label")).toBe("Filter");
    expect(select.get("button").attributes("aria-labelledby")).toBeUndefined();
  });
});
