// @vitest-environment happy-dom
import { afterEach, expect, it, vi } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareGroupDetail from "./FlareGroupDetail.vue";
import FlareFormSheet from "../general/FlareFormSheet.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareSettingsList from "../profile/FlareSettingsList.vue";
let host: ReturnType<typeof mount>;
afterEach(() => { host?.unmount(); document.body.innerHTML = ""; });
it("keeps failed group edits, blocks empty names, and awaits a successful retry", async () => {
  let resolveSave: () => void = () => {};
  const submitEdit = vi.fn().mockRejectedValueOnce(new Error("Unavailable"))
    .mockImplementationOnce(() => new Promise<void>((resolve) => { resolveSave = resolve; }));
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, {
      submitEdit, model: { groupId: "g", name: "Team", members: [], memberCount: 0,
        ownerId: "me", adminIds: [], mutedIds: [], canManage: true, isOwner: true },
    });
  } }), { attachTo: document.body });
  host.findComponent(FlareSettingsList).vm.$emit("select", { key: "name" });
  await flushPromises();
  const form = host.findComponent(FlareFormSheet);
  const input = host.findComponent(FlareInput);
  input.vm.$emit("update:modelValue", "   ");
  await flushPromises();
  expect(form.props("confirmDisabled")).toBe(true);
  form.vm.$emit("confirm");
  await flushPromises();
  expect(submitEdit).not.toHaveBeenCalled();
  input.vm.$emit("update:modelValue", "New team");
  await flushPromises();
  form.vm.$emit("confirm");
  await flushPromises();
  expect(form.props("open")).toBe(true);
  expect(form.props("error")).toBe("Unavailable");
  expect(input.props("modelValue")).toBe("New team");
  form.vm.$emit("confirm");
  await flushPromises();
  expect(form.props("busy")).toBe(true);
  form.vm.$emit("confirm");
  expect(submitEdit).toHaveBeenCalledTimes(2);
  resolveSave();
  await flushPromises();
  expect(form.props("open")).toBe(false);
});
