// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { nextTick } from "vue";
import FlarePluginForm from "./FlarePluginForm.vue";
import PluginFormInput from "./PluginFormInput.vue";
import FlareFileUpload from "../media/FlareFileUpload.vue";
import FlarePluginView from "../messages/FlarePluginView.vue";
import FlarePluginPage from "../messages/FlarePluginPage.vue";
import FlareAccountView from "../messages/account/FlareAccountView.vue";
import { flareMessages } from "../../shared/i18n/messages";
import {
  flarePluginCheckForm, flarePluginDraft, flarePluginFileValue, flarePluginFormValues,
  type FlarePluginFileAction, type FlarePluginFileState, type FlarePluginInput,
} from "../../shared/contracts/plugin-ui";

enableAutoUnmount(afterEach);
const fixture = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-file-input-vectors.json"), "utf8"));
const inputs = fixture.inputs as FlarePluginInput[];
const values = { kind: "alipay", name: "测试", account: "qa" };
function setup(optional = false, fileFirst = false) {
  const actions: FlarePluginFileAction[] = [];
  const fields = (fileFirst ? [inputs[0], inputs[4], ...inputs.slice(1, 4), inputs[5]] : inputs).map(i => i.id === "qr" && optional ? { ...i, required: false } : i);
  const wrapper = mount(FlarePluginForm, { props: { inputs: fields, values, onFileAction: (v: FlarePluginFileAction) => actions.push(v) } });
  const state = (phase: FlarePluginFileState["phase"], ticket = actions.at(-1)!, extra = {}) => ({ scope: ticket.scope, generation: ticket.generation, phase, ...extra });
  const choose = async () => { wrapper.getComponent(FlareFileUpload).vm.$emit("choose"); await nextTick(); return actions.at(-1)!; };
  const host = async (value: FlarePluginFileState) => { await wrapper.setProps({ fileStates: { qr: value } }); };
  return { wrapper, actions, choose, host, state };
}
const submit = async (wrapper: ReturnType<typeof setup>["wrapper"]) => wrapper.get("form").trigger("submit");
describe("protected plugin file form", () => {
  it("shares strict visible values and opaque receipt vectors", () => {
    expect(flareMessages["zh-CN"].pluginFileRejected).toContain("格式");
    expect(flareMessages["en-US"].pluginFileFailed).toContain("Retry");
    for (const v of fixture.cases) expect(flarePluginFormValues(inputs, v.values)).toEqual(v.expectedValues);
    for (const v of fixture.validFileValues) expect(flarePluginFileValue(v)).toBe(true);
    for (const v of fixture.invalidFileValues) expect(flarePluginFileValue(v)).toBe(false);
    expect(flarePluginCheckForm(inputs, fixture.cases[1].values)).toEqual([]);
    expect(flarePluginDraft(inputs, undefined).name).toBe("初始姓名");
    expect(flarePluginDraft(inputs, undefined).bankName).toBeUndefined();
  });
  it("does not infer private preview permission from a prefilled receipt", () => {
    const wrapper = mount(FlarePluginForm, { props: { inputs, values: { ...values, qr: { fileId: "existing" } }, onFileAction: () => {} } });
    expect(wrapper.getComponent(FlareFileUpload).props("previewLabel")).toBeUndefined();
  });
  it("uses a host picker and emits current policy/form values", async () => {
    const { wrapper, choose } = setup();
    expect(wrapper.find('input[type="file"]').exists()).toBe(false);
    const action = await choose();
    expect(action).toMatchObject({ action: "choose", inputId: "qr", generation: 1, formValues: values });
    expect(action.input.file).toEqual(inputs.find(i => i.id === "qr")!.file);
    expect(action.scope).toBeTruthy();
    await submit(wrapper); expect(wrapper.emitted("submit")).toBeUndefined();
  });
  it("blocks optional pending/failed uploads and submits only the accepted receipt", async () => {
    const { wrapper, choose, host, state } = setup(true);
    await choose();
    for (const phase of ["selected", "uploading", "failed"] as const) {
      await host(state(phase)); await submit(wrapper); expect(wrapper.emitted("submit")).toBeUndefined();
      await wrapper.setProps({ fileStates: {} });
      await submit(wrapper); expect(wrapper.emitted("submit")).toBeUndefined();
    }
    await host(state("uploaded", undefined, { value: { fileId: "material_1" }, preview: true }));
    await submit(wrapper);
    expect(wrapper.emitted("submit")?.[0]).toEqual([{ ...values, qr: { fileId: "material_1" } }]);
  });
  it("keeps a completed receipt across a host refresh without retaining preview capability", async () => {
    const { wrapper, choose, host, state } = setup();
    await choose();
    await host(state("uploaded", undefined, { value: { fileId: "material_1" }, fileName: "receipt.png", preview: true }));
    expect(wrapper.getComponent(FlareFileUpload).props("previewLabel")).toBeTruthy();
    await wrapper.setProps({ fileStates: {} });
    expect(wrapper.getComponent(FlareFileUpload).props()).toMatchObject({ state: "uploaded", fileName: "receipt.png" });
    expect(wrapper.getComponent(FlareFileUpload).props("previewLabel")).toBeUndefined();
    await submit(wrapper);
    expect(wrapper.emitted("submit")?.[0]).toEqual([{ ...values, qr: { fileId: "material_1" } }]);
    wrapper.getComponent(FlareFileUpload).vm.$emit("remove"); await nextTick();
    await wrapper.setProps({ fileStates: {} });
    expect(wrapper.getComponent(FlareFileUpload).props("state")).toBe("empty");
    await submit(wrapper); expect(wrapper.emitted("submit")).toHaveLength(1);
  });
  it("does not retain an invalid uploaded receipt after host state disappears", async () => {
    const { wrapper, choose, host, state } = setup(true);
    await choose();
    await host(state("uploaded", undefined, { value: { fileId: "not/a/resource" } }));
    await wrapper.setProps({ fileStates: {} });
    expect(wrapper.getComponent(FlareFileUpload).props("state")).toBe("failed");
    await submit(wrapper); expect(wrapper.emitted("submit")).toBeUndefined();
  });
  it("ignores old generation and scope results", async () => {
    const { wrapper, choose, host, state, actions } = setup();
    const old = await choose();
    wrapper.getComponent(FlareFileUpload).vm.$emit("remove"); await nextTick();
    await host(state("uploaded", old, { value: { fileId: "late" } })); await submit(wrapper);
    expect(wrapper.emitted("submit")).toBeUndefined();
    const current = await choose();
    await host({ ...state("uploaded", current, { value: { fileId: "wrong-scope" } }), scope: old.scope + "-old" });
    await submit(wrapper); expect(wrapper.emitted("submit")).toBeUndefined();
    expect(actions.at(-1)!.generation).toBe(3);
  });
  it("clears still-visible dependent fields and tickets on alipay to wechat", async () => {
    const { wrapper, choose, host, state, actions } = setup(false, true);
    await choose(); await host(state("uploaded", undefined, { value: { fileId: "alipay_qr" } }));
    await wrapper.setProps({ fileStates: {} });
    const kind = wrapper.findAllComponents(PluginFormInput).find(c => c.props("input").id === "kind")!;
    kind.props("state").set("kind", "wechat"); await nextTick();
    expect(actions.at(-1)).toMatchObject({ action: "invalidate", generation: 2, formValues: { kind: "wechat" } });
    expect(kind.props("state").draft.name).toBeNull();
    expect(kind.props("state").draft.account).toBeNull();
    await submit(wrapper); expect(wrapper.emitted("submit")).toBeUndefined();
    expect(wrapper.getComponent(FlareFileUpload).props("state")).toBe("empty");
    kind.props("state").set("kind", "address"); await nextTick();
    expect(wrapper.findComponent(FlareFileUpload).exists()).toBe(false);
  });
  it("previews without mutation and cancels by invalidating the ticket", async () => {
    const { wrapper, choose, host, state, actions } = setup();
    await choose(); await host(state("uploaded", undefined, { value: { fileId: "material_1" }, preview: true }));
    wrapper.getComponent(FlareFileUpload).vm.$emit("preview"); await nextTick();
    expect(actions.at(-1)).toMatchObject({ action: "preview", generation: 1, formValues: { ...values, qr: { fileId: "material_1" } } });
    wrapper.getComponent(FlareFileUpload).vm.$emit("replace"); await nextTick();
    wrapper.getComponent(FlareFileUpload).vm.$emit("cancel"); await nextTick();
    expect(actions.at(-1)).toMatchObject({ action: "cancel", generation: 3 });
  });
  it("changes scope on form reset and invalidates on disposal", async () => {
    const { wrapper, choose, host, state, actions } = setup();
    const old = await choose();
    await host(state("uploaded", old, { value: { fileId: "before-reset" } }));
    await wrapper.setProps({ fileStates: {} });
    await wrapper.setProps({ values: { ...values, account: "new" } });
    expect(actions.at(-1)!.action).toBe("invalidate");
    const fresh = await choose(); expect(fresh.scope).not.toBe(old.scope);
    await host(state("uploaded", old, { value: { fileId: "late" } })); await submit(wrapper);
    expect(wrapper.emitted("submit")).toBeUndefined();
    wrapper.unmount(); expect(actions.at(-1)!.action).toBe("invalidate");
  });
  it("does not imply upload capability when an outer view has no host callback", () => {
    const wrapper = mount(FlarePluginView, { props: { embedded: true, inlineFormActionId: "save", onAction: () => {}, view: { available: true, title: "", fields: [], inputs, actions: [{ id: "save", label: "保存", form: inputs.map(i => i.id) }] } } });
    expect(wrapper.getComponent(FlareFileUpload).props("disabled")).toBe(true);
  });
  it("forwards state and intents through the wallet page account route", () => {
    const states = { qr: { scope: "test", generation: 1, phase: "uploading" as const } };
    const wrapper = mount(FlarePluginPage, { props: { page: { pluginId: "flare.wallet", page: "home" }, appearance: "account", onFileAction: () => {}, view: { available: true, title: "钱包", fields: [], actions: [] }, fileStates: states } });
    const account = wrapper.getComponent(FlareAccountView);
    expect(account.props("fileStates")).toEqual(states);
    const event = { action: "choose", inputId: "qr", scope: "test", generation: 1, input: inputs[4], formValues: values };
    account.vm.$emit("fileAction", event);
    expect(wrapper.emitted("fileAction")?.[0]).toEqual([event]);
  });
});
