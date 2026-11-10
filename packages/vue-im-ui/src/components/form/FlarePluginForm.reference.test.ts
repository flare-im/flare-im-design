// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, reactive } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type {
  FlarePluginInput,
  FlarePluginReferenceRequest,
} from "../../shared/contracts/plugin-ui";
import FlareAdminEntitySelect from "./FlareAdminEntitySelect.vue";
import FlarePluginForm from "./FlarePluginForm.vue";
import type { SchemaSelection } from "./schema-selections";

enableAutoUnmount(afterEach);

const reference = { operation: "op", valuePath: "/value", labelPath: "/label" };
const pick = (extra: Partial<FlarePluginInput> = {}): FlarePluginInput => ({
  id: "pick",
  kind: "select",
  label: "Pick",
  reference,
  ...extra,
});

function render(inputs: FlarePluginInput[], values?: Record<string, unknown>) {
  const state = reactive<{
    selections: Record<string, SchemaSelection>;
    inputs: FlarePluginInput[];
  }>({
    selections: {},
    inputs,
  });
  const requests: FlarePluginReferenceRequest[] = [];
  const submits: unknown[] = [];
  const wrapper = mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () =>
          h(FlarePluginForm as never, {
            inputs: state.inputs,
            values,
            selections: state.selections,
            onReferenceLoad: (request: FlarePluginReferenceRequest) =>
              requests.push(request),
            onSubmit: (value: unknown) => submits.push(value),
          });
      },
    }),
  );
  return { wrapper, state, requests, submits };
}

describe("reference inputs", () => {
  it("asks the host once and stays closed until it answers", async () => {
    const { wrapper, state, requests } = render([pick()], { pick: "cny" });
    expect(requests).toEqual([
      { id: "pick", reference, parents: {}, selected: "cny" },
    ]);
    expect(
      wrapper.findComponent(FlareAdminEntitySelect).props("disabled"),
    ).toBe(true);
    state.selections = { pick: { options: [{ value: "cny", label: "Yuan" }] } };
    await flushPromises();
    expect(
      wrapper.findComponent(FlareAdminEntitySelect).props("disabled"),
    ).toBeFalsy();
    expect(requests).toHaveLength(1);
  });

  it("asks again when a parent changes, and not before it holds a value", async () => {
    const parent: FlarePluginInput = {
      id: "asset",
      kind: "text",
      label: "Asset",
    };
    const child = pick({
      reference: { ...reference, parents: { assetId: "asset" } },
    });
    const { wrapper, requests, state } = render([parent, child]);
    state.selections = { pick: { options: [{ value: "a", label: "A" }] } };
    await flushPromises();
    expect(requests).toEqual([]);
    expect(
      wrapper.findComponent(FlareAdminEntitySelect).props("disabled"),
    ).toBe(true);
    await wrapper.find("[data-input-id=asset] input").setValue("cny");
    await flushPromises();
    expect(requests[0]?.parents).toEqual({ assetId: "cny" });
    await wrapper.find("[data-input-id=asset] input").setValue("usd");
    await flushPromises();
    expect(requests).toHaveLength(2);
  });

  it("synchronizes a new choice for the next search without changing its parent scope", async () => {
    const { wrapper, state, requests } = render([pick()], { pick: "cny" });
    state.selections = {
      pick: {
        options: [
          { value: "cny", label: "Yuan" },
          { value: "usd", label: "Dollar" },
        ],
      },
    };
    await flushPromises();
    wrapper
      .findComponent(FlareAdminEntitySelect)
      .vm.$emit("update:value", "usd");
    await flushPromises();
    expect(requests.map((request) => request.selected)).toEqual(["cny", "usd"]);
    expect(requests[1]?.parents).toEqual({});
    state.inputs = [
      pick({ reference: { ...reference, operation: "other-op" } }),
    ];
    await flushPromises();
    expect(requests.at(-1)?.reference.operation).toBe("other-op");
  });

  it("picks declared options from their choices without asking the host", () => {
    const { wrapper, requests } = render([
      {
        id: "purposes",
        kind: "options",
        label: "Purposes",
        max: 4,
        choices: [{ value: "transfer", label: "Transfer" }],
      },
    ]);
    const select = wrapper.findComponent(FlareAdminEntitySelect);
    expect(select.props("multiple")).toBe(true);
    expect(select.props("options")).toEqual([
      { value: "transfer", label: "Transfer" },
    ]);
    expect(requests).toEqual([]);
  });

  it("lets an optional control the viewer cannot read stay empty", async () => {
    const { wrapper, submits } = render([pick()]);
    (
      wrapper.findComponent(FlarePluginForm).vm as unknown as { submit(): void }
    ).submit();
    await flushPromises();
    expect(submits).toHaveLength(1);
  });

  it("holds a required one back", async () => {
    const { wrapper, submits } = render([pick({ required: true })]);
    (
      wrapper.findComponent(FlarePluginForm).vm as unknown as { submit(): void }
    ).submit();
    await flushPromises();
    expect(submits).toEqual([]);
  });
});
