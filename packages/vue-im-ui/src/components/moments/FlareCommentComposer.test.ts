// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareCommentComposer from "./FlareCommentComposer.vue";
let host: ReturnType<typeof mount>;
afterEach(() => { host?.unmount(); document.body.innerHTML = ""; });
const reply = { id: "c1", author: { id: "u1", name: "陈默" }, text: "原评论" };
function setup() {
 const state = reactive({ modelValue: "", busy: false, error: "", replyTo: undefined as typeof reply | undefined });
 const events: string[] = [];
 host = mount(defineComponent({ setup() { useFlareI18nProvider("zh-CN"); return () => h(FlareCommentComposer, { ...state, 'onUpdate:modelValue': value => { state.modelValue = value; }, onSubmit: () => events.push("submit"), onCancelReply: () => events.push("cancel") }); } }), { attachTo: document.body });
 return { state, events };
}
describe("inline comment composer", () => {
 it("emits one send intent without clearing or transforming the host draft", async () => {
  const { state, events } = setup(); await host.get("textarea").setValue("  评论😀\n第二行  ");
  await host.get("form").trigger("submit"); expect(events).toEqual(["submit"]); expect(state.modelValue).toBe("  评论😀\n第二行  ");
 });
 it("keeps a failed draft visible and retries the same intent", async () => {
  const { state, events } = setup(); state.modelValue = "等待重试"; state.error = "发送失败"; await nextTick();
  expect(host.get('[role="alert"]').text()).toBe("发送失败"); await host.findAll("button").find(button => button.text().trim() === "重试")!.trigger("click");
  expect(events).toEqual(["submit"]); expect(state.modelValue).toBe("等待重试"); expect(host.text()).toContain("重试");
 });
 it("locks sending and changing reply context while busy", async () => {
  const { state, events } = setup(); Object.assign(state, { modelValue: "草稿", replyTo: reply, busy: true }); await nextTick();
  expect(host.get("textarea").attributes("disabled")).toBeDefined(); expect(host.get('.flare-reply button').attributes('disabled')).toBeDefined();
  await host.get("form").trigger("submit"); await host.get('.flare-reply button').trigger('click'); expect(events).toEqual([]);
 });
 it("focuses a newly selected reply without replacing the current draft", async () => {
  const { state, events } = setup(); state.modelValue = "已有草稿"; state.replyTo = reply; await nextTick(); await nextTick();
  expect(document.activeElement).toBe(host.get("textarea").element); expect(state.modelValue).toBe("已有草稿");
  await host.get('.flare-reply button').trigger('click'); expect(events).toEqual(["cancel"]); expect(state.modelValue).toBe("已有草稿");
 });
 it("locks blank and busy submissions and locks cancellation without losing the draft", async () => {
  const { state, events } = setup(); state.modelValue = "  "; await nextTick(); await host.get('form').trigger('submit'); expect(events).toEqual([]);
  state.modelValue = '草稿'; state.replyTo = reply; state.busy = true; await nextTick();
  await host.get('form').trigger('submit'); await host.get('.flare-reply button').trigger('click'); expect(events).toEqual([]); expect(host.get('.flare-reply button').attributes('disabled')).toBeDefined();
  state.busy = false; await nextTick(); await host.get('.flare-reply button').trigger('click'); expect(events).toEqual(['cancel']); expect(state.modelValue).toBe('草稿');
 });
 it("focuses the existing field when a reply is selected", async () => {
  const { state } = setup(); state.modelValue = '已有文字'; const field = host.get('textarea').element;
  state.replyTo = reply; await nextTick(); await nextTick(); expect(document.activeElement).toBe(field); expect(state.modelValue).toBe('已有文字');
 });

});
