// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { NSelect } from "naive-ui";
import type { FlarePluginReferenceRequest } from "../../shared/contracts/plugin-ui";
import FlareAdminEntitySelect from "./FlareAdminEntitySelect.vue";
import FlareSchemaForm from "./FlareSchemaForm.vue";
import { schemaFields } from "./schema-fields";

const reference = {
  plugin: "flare.wallet",
  operation: "op",
  valuePath: "/value",
  labelPath: "/label",
};
const schema = {
  properties: {
    plans: {
      type: "array",
      title: "Plans",
      items: {
        type: "object",
        properties: {
          assetId: { type: "string", title: "Asset" },
          definitionId: { type: "string", title: "Wallet" },
        },
      },
    },
  },
};
const uiHints = {
  plans: {
    group: "funding",
    fields: {
      assetId: { reference },
      definitionId: {
        reference: { ...reference, parents: { assetId: "assetId" } },
      },
    },
  },
};

describe("configuration references", () => {
  it("reads title, description, choice titles, group and order from the declaration", () => {
    const fields = schemaFields(
      {
        properties: {
          second: { type: "string", title: "Second" },
          first: {
            title: "First",
            description: "Help",
            oneOf: [{ const: "a", title: "Option A" }, { const: "b" }],
          },
        },
      },
      { first: { group: "g", order: 0 }, second: { group: "g", order: 1 } },
    );
    expect(fields.map((field) => field.title)).toEqual(["First", "Second"]);
    expect(fields[0]).toMatchObject({
      description: "Help",
      group: "g",
      optionLabels: { a: "Option A" },
    });
  });

  it("prefers the manifest's translations and falls back to the schema", () => {
    const schema = {
      properties: {
        policy: {
          title: "Schema title",
          description: "Schema help",
          enum: ["allow", "forbid"],
        },
        limit: { type: "integer", title: "Limit" },
      },
    };
    const hints = {
      policy: {
        label: { "zh-CN": "改票规则", "en-US": "Vote change policy" },
        description: { "zh-CN": "说明" },
        options: { allow: { "zh-CN": "允许", "en-US": "Allow" } },
      },
    };
    const policy = (presentation = {}, locale = "zh-CN") =>
      schemaFields(schema, hints, presentation, locale).find(
        (field) => field.id === "policy",
      );
    expect(policy()).toMatchObject({
      title: "改票规则",
      description: "说明",
      optionLabels: { allow: "允许" },
    });
    expect(policy({}, "en")).toMatchObject({
      title: "Vote change policy",
      description: "Schema help",
      optionLabels: { allow: "Allow" },
    });
    expect(policy({}, "fr")?.title).toBe("Schema title");
    expect(policy({ policy: { label: "Host" } })?.title).toBe("Host");
  });

  it("reads a group heading declared by locale", () => {
    const wrapper = mount(FlareSchemaForm, {
      props: {
        schema: { properties: { a: { type: "string" } } },
        modelValue: {},
        uiHints: { a: { group: "limits" } },
        groupLabels: {
          limits: { "zh-CN": "业务限制", "en-US": "Business limits" },
        },
        locale: "en-US",
      },
    });
    expect(wrapper.find(".flare-schema-form-heading").text()).toBe(
      "Business limits",
    );
  });

  it("draws a choice's own title", () => {
    const wrapper = mount(FlareSchemaForm, {
      props: {
        schema: {
          properties: {
            policy: { oneOf: [{ const: "allow", title: "Allow" }] },
          },
        },
        modelValue: {},
      },
    });
    expect(wrapper.findComponent(NSelect).props("options")).toEqual([
      { label: "Allow", value: "allow" },
    ]);
  });

  it("asks for a nested field by its pointer, parents read beside it", () => {
    const wrapper = mount(FlareSchemaForm, {
      props: { schema, uiHints, modelValue: { plans: [{ assetId: "cny" }] } },
    });
    const requests = wrapper
      .findAllComponents(FlareSchemaForm)
      .flatMap((form) =>
        (form.emitted("reference-load") ?? []).map(
          ([request]) => request as FlarePluginReferenceRequest,
        ),
      );
    expect(
      requests.map((request) => [request.id, request.parents]),
    ).toContainEqual(["/plans/0/assetId", {}]);
    expect(
      requests.map((request) => [request.id, request.parents]),
    ).toContainEqual(["/plans/0/definitionId", { assetId: "cny" }]);
  });

  it("keeps a field closed until the host answers", () => {
    const wrapper = mount(FlareSchemaForm, {
      props: { schema, uiHints, modelValue: { plans: [{}] } },
    });
    const selects = wrapper.findAllComponents(FlareAdminEntitySelect);
    expect(selects).toHaveLength(2);
    expect(selects.every((select) => select.props("disabled") === true)).toBe(
      true,
    );
  });

  it("opens with the host's answer", () => {
    const wrapper = mount(FlareSchemaForm, {
      props: {
        schema,
        uiHints,
        modelValue: { plans: [{}] },
        selections: {
          "/plans/0/assetId": { options: [{ value: "cny", label: "Yuan" }] },
        },
      },
    });
    expect(
      wrapper.findAllComponents(FlareAdminEntitySelect)[0]?.props("disabled"),
    ).toBeFalsy();
  });

  it("synchronizes a changed selection so subsequent directory reads hydrate the current value", async () => {
    const wrapper = mount(FlareSchemaForm, {
      props: {
        schema: { properties: { assetId: { type: "string" } } },
        uiHints: { assetId: { reference } },
        modelValue: { assetId: "cny" },
        selections: {
          "/assetId": {
            options: [
              { value: "cny", label: "Yuan" },
              { value: "usd", label: "Dollar" },
            ],
          },
        },
      },
    });
    await wrapper.setProps({ modelValue: { assetId: "usd" } });
    const requests = (wrapper.emitted("reference-load") ?? []).map(
      ([request]) => request as FlarePluginReferenceRequest,
    );
    expect(requests.map((request) => request.selected)).toEqual(["cny", "usd"]);
    expect(requests[1]?.parents).toEqual({});
    await wrapper.setProps({
      selections: {
        "/assetId": { options: [{ value: "usd", label: "Dollar" }] },
      },
    });
    expect(wrapper.emitted("reference-load")).toHaveLength(2);
    await wrapper.setProps({
      uiHints: {
        assetId: { reference: { ...reference, operation: "other-op" } },
      },
    });
    const latest = wrapper
      .emitted("reference-load")
      ?.at(-1)?.[0] as FlarePluginReferenceRequest;
    expect(latest.reference.operation).toBe("other-op");
  });
});
