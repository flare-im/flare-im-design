// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareCommentThread from "./FlareCommentThread.vue";
const long = { id: "long", author: { id: "a", name: "作者" }, replyToName: "回复对象", text: "完整评论😀\n".repeat(9) };
const short = { id: "short", author: { id: "b", name: "另一个作者" }, text: "短评论" };
let host: ReturnType<typeof mount>;
afterEach(() => { host?.unmount(); document.body.innerHTML = ""; vi.restoreAllMocks(); });
function setup(appearance: "inline" | "detail" = "inline") {
 const selected: unknown[] = [], state = reactive({ comments: [long, short], focusCommentId: undefined as string | undefined });
 host = mount(defineComponent({ setup() { useFlareI18nProvider("zh-CN"); return () => h(FlareCommentThread, { ...state, appearance, onSelect: c => selected.push(c) }); } }), { attachTo: document.body });
 return { state, selected };
}
describe("moment comment disclosure", () => {
 it("locates by id, expands and focuses the comment without replying or scrolling the inbox", async () => {
  const { selected, state } = setup("detail");
  const thread = host.getComponent(FlareCommentThread);
  const frame = document.createElement("div"), outer = document.createElement("div");
  frame.style.overflowY = "auto"; outer.style.overflowY = "auto";
  document.body.append(outer); outer.append(frame); frame.append(thread.element);
  Object.defineProperty(frame, "clientHeight", { value: 120 });
  frame.getBoundingClientRect = () => ({ top: 0, height: 120 } as DOMRect);
  const row = thread.get('[data-comment-id="long"]').element as HTMLElement;
  row.getBoundingClientRect = () => ({ top: 300, height: 500 } as DOMRect);
  frame.scrollTop = 25; outer.scrollTop = 88;
  state.focusCommentId = "long"; await nextTick(); await nextTick();
  expect(frame.scrollTop).toBe(317); expect(outer.scrollTop).toBe(88);
  expect(document.activeElement).toBe(row); expect(row.getAttribute("aria-current")).toBe("true");
  expect(thread.get("button.flare-comment__expand").attributes("aria-expanded")).toBe("true");
  expect(selected).toEqual([]);
  state.focusCommentId = "missing"; await nextTick();
  expect(thread.find('[aria-current="true"]').exists()).toBe(false);
  expect(frame.scrollTop).toBe(317);
 });
 it.each(["inline", "detail"] as const)("expands one long comment independently without replying (%s)", async appearance => {
  const { selected } = setup(appearance); await nextTick();
  const toggle = host.get("button.flare-comment__expand");
  expect(toggle.attributes("aria-expanded")).toBe("false");
  const content = document.getElementById(toggle.attributes("aria-controls")!)!;
  expect(content.textContent).toContain(long.text);
  expect(host.findAll("button.flare-comment__expand")).toHaveLength(1);
  expect(host.find("button button").exists()).toBe(false);
  await toggle.trigger("click"); expect(toggle.attributes("aria-expanded")).toBe("true"); expect(selected).toEqual([]);
  await host.get("button.flare-comment__row").trigger("click"); expect(selected).toEqual([long]);
  await toggle.trigger("click"); expect(toggle.attributes("aria-expanded")).toBe("false");
 });
 it("keeps disclosure attached to the comment id when refreshed or reordered", async () => {
  const { state } = setup(); await nextTick(); await host.get("button.flare-comment__expand").trigger("click");
  state.comments = [short, { ...long }]; await nextTick();
  expect(host.get("button.flare-comment__expand").attributes("aria-expanded")).toBe("true");
 });
 it("refolds edited text on the same id and allows an explicit unlimited list", async () => {
  const { state } = setup(); await nextTick(); await host.get("button.flare-comment__expand").trigger("click");
  state.comments = [{ ...long, text: "改过的完整评论\n".repeat(8) }]; await nextTick(); await nextTick();
  expect(host.get("button.flare-comment__expand").attributes("aria-expanded")).toBe("false");
  host.unmount(); host = mount(defineComponent({ setup() { useFlareI18nProvider("zh-CN"); return () => h(FlareCommentThread, { comments: [long], maxLines: 0 }); } })); await nextTick();
  expect(host.find("button.flare-comment__expand").exists()).toBe(false); expect(host.text()).toContain(long.text.trim());
 });
 it("separates reply relationship from body in detail without manufacturing reply controls", async () => {
  host = mount(defineComponent({ setup() { useFlareI18nProvider("zh-CN"); return () => h(FlareCommentThread, { comments: [long], appearance: "detail" }); } })); await nextTick();
  expect(host.get(".flare-comment__relation").text()).toContain("回复对象");
  expect(host.get(".flare-comment__text").text()).toBe(long.text.trim());
  expect(host.find("button.flare-comment__row").exists()).toBe(false);
  expect(host.find("button.flare-comment__expand").exists()).toBe(true);
 });
});
