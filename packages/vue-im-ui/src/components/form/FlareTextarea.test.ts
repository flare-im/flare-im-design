// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareTextarea from "./FlareTextarea.vue";

describe("textarea keyboard submission", () => {
  it("keeps plain Enter as a newline and emits one explicit shortcut intent", async () => {
    const wrapper = mount(FlareTextarea, { props: { modelValue: "原评论", rows: 2, maxRows: 5 } });
    await wrapper.get("textarea").trigger("keydown", { key: "Enter" });
    expect(wrapper.emitted("enter")).toBeUndefined();
    await wrapper.get("textarea").trigger("keydown", { key: "Enter", ctrlKey: true });
    expect(wrapper.emitted("enter")).toEqual([[]]);
    expect((wrapper.get("textarea").element as HTMLTextAreaElement).value).toBe("原评论");
    wrapper.unmount();
  });
  it.each([{ isComposing: true }, { keyCode: 229 }, { disabled: true }])("never submits during IME composition or a locked draft: %j", async (state) => {
    const wrapper = mount(FlareTextarea, { props: { modelValue: "未完成的文字", disabled: !!state.disabled } });
    await wrapper.get("textarea").trigger("keydown", { key: "Enter", ctrlKey: true, ...state });
    expect(wrapper.emitted("enter")).toBeUndefined();
    wrapper.unmount();
  });
});
