// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { h } from "vue";
import { NFormItem, NInput } from "naive-ui";
import FlareAdminFormGrid from "./FlareAdminFormGrid.vue";
import FlareAdminForm from "./FlareAdminForm.vue";
import FlareAdminSection from "../data/FlareAdminSection.vue";

describe("FlareAdminFormGrid", () => {
  it("lays out real form items in the requested columns without owning their values", () => {
    const wrapper = mount(FlareAdminFormGrid, {
      props: { columns: 3, minColumnWidth: "200px" },
      slots: {
        default: () => [
          h(NFormItem, { label: "WS path" }, () => h(NInput, { value: "/ws" })),
          h(NFormItem, { label: "Notes", "data-flare-span": "full" }, () =>
            h(NInput, { value: "Kept" }),
          ),
        ],
      },
    });
    const root = wrapper.get(".flare-admin-form-grid");
    expect(root.attributes("style")).toContain("--flare-admin-form-grid-columns: 3");
    expect(root.attributes("style")).toContain("--flare-admin-form-grid-min: 200px");
    expect(wrapper.findAll(".n-form-item")).toHaveLength(2);
    expect(wrapper.get('[data-flare-span="full"]').text()).toContain("Notes");
    expect(wrapper.findAll("input").map((input) => input.element.value)).toEqual(["/ws", "Kept"]);
    wrapper.unmount();
  });
  it("defaults to two columns and composes inside titled form sections", () => {
    const wrapper = mount(FlareAdminForm, {
      props: { labelPlacement: "top" },
      slots: {
        default: () => [
          h(FlareAdminSection, { title: "Basic" }, () =>
            h(FlareAdminFormGrid, null, () => [
              h(NFormItem, { label: "Weight" }, () => h(NInput)),
              h(NFormItem, { label: "Priority" }, () => h(NInput)),
            ]),
          ),
          h(FlareAdminSection, { title: "Endpoints" }, () => h(NInput)),
        ],
      },
    });
    expect(wrapper.findAll("h3").map((heading) => heading.text())).toEqual(["Basic", "Endpoints"]);
    expect(wrapper.get(".flare-admin-form-grid").attributes("style")).toContain(
      "--flare-admin-form-grid-columns: 2",
    );
    wrapper.unmount();
  });
});
