// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { NInput, NSelect, NSwitch } from "naive-ui";
import FlareAdminEntitySelect from "./FlareAdminEntitySelect.vue";
import { schemaFieldPath } from "./schema-selections";
import FlareSchemaForm from "./FlareSchemaForm.vue";
import {
  schemaFields,
  schemaFieldValue,
  updateSchemaField,
} from "./schema-fields";

const schema = {
  $defs: {
    Policy: { oneOf: [{ const: "allow" }, { const: "forbid" }] },
    Amount: { type: "string" },
  },
  properties: {
    enabled: { type: "boolean", default: true },
    policy: { $ref: "#/$defs/Policy", default: "allow" },
    allowed: {
      type: "array",
      items: { $ref: "#/$defs/Policy" },
      default: ["allow"],
    },
    amount: { anyOf: [{ $ref: "#/$defs/Amount" }, { type: "null" }] },
    rate: { type: ["integer", "null"], minimum: 1, maximum: 600 },
    secret: { type: "string", writeOnly: true },
  },
};
describe("schema configuration forms", () => {
  it("edits a bounded object array through referenced fields without losing sibling data", async () => {
    const nested = {
      $defs: {
        Plan: {
          type: "object",
          required: ["assetId"],
          properties: {
            assetId: { type: "string" },
            sourceInstanceKey: { type: ["string", "null"] },
          },
        },
      },
      properties: {
        fundingAssets: {
          type: "array",
          minItems: 1,
          maxItems: 2,
          items: { $ref: "#/$defs/Plan" },
        },
      },
    };
    const wrapper = mount(FlareSchemaForm, {
      props: {
        schema: nested,
        modelValue: {
          activeAssetId: "cash",
          fundingAssets: [{ assetId: "cash", sourceInstanceKey: "primary" }],
        },
        addLabel: "Add",
        removeLabel: "Remove",
      },
    });
    const input = wrapper
      .findAllComponents(NInput)
      .find((i) => i.props("value") === "primary")!;
    input.vm.$emit("update:value", "spare");
    expect(wrapper.emitted("update:modelValue")?.[0]).toEqual([
      {
        activeAssetId: "cash",
        fundingAssets: [{ assetId: "cash", sourceInstanceKey: "spare" }],
      },
    ]);
    const remove = wrapper
      .findAll("button")
      .find((b) => b.text() === "Remove 1")!;
    expect(remove.attributes("disabled")).toBeDefined();
    await wrapper
      .findAll("button")
      .find((b) => b.text() === "Add")!
      .trigger("click");
    expect(wrapper.emitted("update:modelValue")?.at(-1)).toEqual([
      {
        activeAssetId: "cash",
        fundingAssets: [{ assetId: "cash", sourceInstanceKey: "primary" }, {}],
      },
    ]);
    await wrapper.setProps({ disabled: true });
    input.vm.$emit("update:value", "forbidden");
    expect(wrapper.emitted("update:modelValue")).toHaveLength(2);
    wrapper.unmount();
  });
  it("resolves enums, multi-select, nullable amounts and nullable integers", () => {
    const fields = schemaFields(schema);
    expect(fields).toHaveLength(6);
    expect(fields.find((f) => f.id === "allowed")).toMatchObject({
      type: "array",
      options: ["allow", "forbid"],
    });
    expect(fields.find((f) => f.id === "amount")).toMatchObject({
      type: "string",
      nullable: true,
    });
    expect(fields.find((f) => f.id === "rate")).toMatchObject({
      type: "integer",
      minimum: 1,
      maximum: 600,
    });
    expect(
      schemaFields({
        ...schema,
        properties: {
          policy: { oneOf: [{ $ref: "#/$defs/Policy" }, { type: "null" }] },
        },
      })[0],
    ).toMatchObject({ options: ["allow", "forbid"], nullable: true });
  });
  it("shows defaults without mutating JSON, preserving explicit false/null and other keys", () => {
    const field = schemaFields(schema).find((f) => f.id === "enabled")!;
    expect(schemaFieldValue({}, field)).toBe(true);
    expect(schemaFieldValue({ enabled: false }, field)).toBe(false);
    expect(schemaFieldValue({ enabled: null }, field)).toBe(null);
    const model = { enabled: false, unknown: { keep: true } };
    expect(updateSchemaField(model, field, undefined)).toEqual({
      unknown: { keep: true },
    });
    expect(model.enabled).toBe(false);
  });
  it("retains exact minor-unit decimal strings and never converts them through floating point", () => {
    const field = schemaFields(schema).find((f) => f.id === "amount")!;
    expect(updateSchemaField({}, field, "1000000000000")).toEqual({
      amount: "1000000000000",
    });
  });
  it("honors grouping, order, localization and password inputs", () => {
    const fields = schemaFields(
      schema,
      {
        rate: { group: "limits", order: 1 },
        amount: { group: "limits", order: 2 },
      },
      { rate: { label: "每分钟上限" } },
    );
    expect(fields.filter((f) => f.group === "limits").map((f) => f.id)).toEqual(
      ["rate", "amount"],
    );
    expect(fields.find((f) => f.id === "rate")?.title).toBe("每分钟上限");
    const wrapper = mount(FlareSchemaForm, {
      props: { schema, modelValue: {} },
    });
    expect(wrapper.findComponent(NSwitch).props("value")).toBe(true);
    expect(
      wrapper.findAllComponents(NSelect).some((s) => s.props("multiple")),
    ).toBe(true);
    expect(
      wrapper
        .findAllComponents(NInput)
        .some((input) => input.props("type") === "password"),
    ).toBe(true);
    expect(wrapper.emitted()).toEqual({});
    wrapper.unmount();
  });
  it("changes one field and protects disabled forms", () => {
    const wrapper = mount(FlareSchemaForm, {
      props: { schema, modelValue: { custom: 5 }, disabled: false },
    });
    wrapper.findComponent(NSwitch).vm.$emit("update:value", false);
    expect(wrapper.emitted("update:modelValue")?.[0]).toEqual([
      { custom: 5, enabled: false },
    ]);
    wrapper.unmount();
    const disabled = mount(FlareSchemaForm, {
      props: { schema, modelValue: {}, disabled: true },
    });
    disabled.findComponent(NSwitch).vm.$emit("update:value", false);
    expect(disabled.emitted("update:modelValue")).toBeUndefined();
    disabled.unmount();
  });
  it("changes column layout without remounting fields or changing exact values and unknown keys", async () => {
    const modelValue = { amount: "1000000000000", custom: { keep: true } };
    const wrapper = mount(FlareSchemaForm, { props: { schema, modelValue } });
    const input = wrapper
      .findAllComponents(NInput)
      .find((item) => item.props("value") === modelValue.amount)!;
    const element = input.get("input").element;
    await wrapper.setProps({ columns: 2 });
    expect(input.get("input").element).toBe(element);
    expect(wrapper.emitted("update:modelValue")).toBeUndefined();
    input.vm.$emit("update:value", "999999999999");
    expect(wrapper.emitted("update:modelValue")?.[0]).toEqual([
      { amount: "999999999999", custom: { keep: true } },
    ]);
    wrapper.unmount();
  });
  it("does not resolve remote references, loop local refs or invent editors for complex shapes", () => {
    expect(
      schemaFields({
        $defs: { Loop: { $ref: "#/$defs/Loop" } },
        properties: {
          a: { $ref: "#/$defs/Loop" },
          b: { $ref: "https://remote/schema" },
          c: { type: "object" },
        },
      }),
    ).toEqual([]);
  });
});

describe("dynamic schema selections", () => {
  const schema = {
    properties: {
      plans: {
        type: "array",
        items: {
          type: "object",
          required: ["asset"],
          properties: {
            asset: { type: "string" },
            instance: { type: "string" },
          },
        },
      },
    },
  };
  it("uses absolute nested paths, preserves siblings, and bubbles search/paging/retry", () => {
    const wrapper = mount(FlareSchemaForm, {
      props: {
        schema,
        modelValue: { other: 7, plans: [{ asset: "cash" }] },
        selections: {
          "/plans/0/asset": {
            options: [{ value: "cash", label: "现金 · CNY" }],
            hasMore: true,
          },
          "/plans/0/instance": {
            options: [{ value: "primary", label: "主钱包" }],
            emptyOptionLabel: "用户默认钱包",
          },
        },
      },
    });
    const [asset, instance] = wrapper.findAllComponents(FlareAdminEntitySelect);
    expect(wrapper.findAllComponents(NInput)).toHaveLength(0);
    asset!.vm.$emit("search", "现金");
    asset!.vm.$emit("more");
    asset!.vm.$emit("retry");
    expect(wrapper.emitted("selection-search")?.[0]).toEqual([
      "/plans/0/asset",
      "现金",
    ]);
    expect(wrapper.emitted("selection-more")?.[0]).toEqual(["/plans/0/asset"]);
    expect(wrapper.emitted("selection-retry")?.[0]).toEqual(["/plans/0/asset"]);
    instance!.vm.$emit("update:value", "primary");
    expect(wrapper.emitted("update:modelValue")?.[0]).toEqual([
      { other: 7, plans: [{ asset: "cash", instance: "primary" }] },
    ]);
    instance!.vm.$emit("update:value", "");
    expect(wrapper.emitted("update:modelValue")?.[1]).toEqual([
      { other: 7, plans: [{ asset: "cash" }] },
    ]);
    asset!.vm.$emit("update:value", "arbitrary-id");
    asset!.vm.$emit("update:value", "");
    expect(wrapper.emitted("update:modelValue")).toHaveLength(2);
    wrapper.unmount();
    expect(schemaFieldPath("/a~0", "a/b")).toBe("/a~0/a~1b");
  });
  it("shows unavailable stored selections and rejects writes during loading/error/disabled", async () => {
    const wrapper = mount(FlareSchemaForm, {
      props: {
        schema: { properties: { asset: { type: "string" } } },
        modelValue: { asset: "old" },
        selectionLabels: {
          placeholder: "选择",
          empty: "暂无",
          more: "更多",
          retry: "重试",
          unavailable: "原选择失效",
        },
        selections: {
          "/asset": {
            options: [{ value: "cash", label: "现金" }],
            loading: true,
          },
        },
      },
    });
    const input = wrapper.findComponent(FlareAdminEntitySelect);
    expect(input.props("options")[0]).toMatchObject({
      value: "old",
      label: "选择",
      disabled: true,
    });
    input.vm.$emit("update:value", "cash");
    expect(wrapper.emitted("update:modelValue")).toBeUndefined();
    await wrapper.setProps({
      selections: {
        "/asset": {
          options: [{ value: "cash", label: "现金" }],
          error: "offline",
        },
      },
    });
    input.vm.$emit("update:value", "cash");
    expect(wrapper.emitted("update:modelValue")).toBeUndefined();
    await wrapper.setProps({
      selections: {
        "/asset": {
          options: [{ value: "cash", label: "现金" }],
          invalid: "失效，请重选",
        },
      },
    });
    input.vm.$emit("update:value", "cash");
    expect(wrapper.emitted("update:modelValue")?.[0]).toEqual([
      { asset: "cash" },
    ]);
    await wrapper.setProps({ disabled: true });
    input.vm.$emit("update:value", "cash");
    expect(wrapper.emitted("update:modelValue")).toHaveLength(1);
    wrapper.unmount();
  });
});

it("passes localized group labels through nested objects and object arrays", () => {
  const part = {
    type: "object",
    properties: { asset: { type: "string" }, wallet: { type: "string" } },
  };
  const wrapper = mount(FlareSchemaForm, {
    props: {
      schema: {
        properties: { details: part, plans: { type: "array", items: part } },
      },
      modelValue: {
        details: { asset: "cash" },
        plans: [{ wallet: "primary" }],
      },
      uiHints: { asset: { group: "funds" }, wallet: { group: "payer" } },
      groupLabels: { funds: "资金与额度", payer: "付款钱包" },
    },
  });
  expect(wrapper.findAll("h3").map((h) => h.text())).toEqual([
    "资金与额度",
    "付款钱包",
    "资金与额度",
    "付款钱包",
  ]);
  wrapper.unmount();
});
it("required references cannot be cleared and default wallet selection has no duplicate reset action", () => {
  const wrapper = mount(FlareSchemaForm, {
    props: {
      schema: {
        required: ["asset"],
        properties: { asset: { type: "string" }, wallet: { type: "string" } },
      },
      modelValue: { asset: "cash", wallet: "primary" },
      resetLabel: "Reset",
      selections: {
        "/asset": { options: [{ value: "cash", label: "Cash" }] },
        "/wallet": {
          options: [{ value: "primary", label: "Primary" }],
          emptyOptionLabel: "Default wallet",
        },
      },
    },
  });
  const selectors = wrapper.findAllComponents(FlareAdminEntitySelect);
  expect(selectors[0]!.props("clearable")).toBe(false);
  expect(selectors[1]!.props("clearable")).toBe(true);
  expect(wrapper.findAll("button").some((b) => b.text() === "Reset")).toBe(
    false,
  );
  wrapper.unmount();
});
