// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import FlareToast from "./FlareToast.vue";

let wrapper: ReturnType<typeof mount>;
afterEach(() => { wrapper?.unmount(); });

describe("FlareToast", () => {
  it("keeps variant and derives the shared tone (error → danger)", () => {
    wrapper = mount(FlareToast, { props: { message: "Failed", variant: "error" } });
    expect(wrapper.classes()).toContain("flare-toast--error");
    expect(wrapper.attributes("data-tone")).toBe("danger");
  });

  it("accepts tone directly and re-derives the form", () => {
    wrapper = mount(FlareToast, { props: { message: "Saved", tone: "success" } });
    expect(wrapper.attributes("data-tone")).toBe("success");
    expect(wrapper.classes()).toContain("flare-toast--success");
  });

  it("emits action / close with stable names", async () => {
    wrapper = mount(FlareToast, { props: { message: "Sent", actionLabel: "Undo" } });
    await wrapper.find(".flare-toast__action").trigger("click");
    expect(wrapper.emitted("action")).toHaveLength(1);
  });
});
