// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareProgressBar from "./FlareProgressBar.vue";

describe("FlareProgressBar", () => {
  it("gives a screen reader the number and draws the fill to it", () => {
    const bar = mount(FlareProgressBar, { props: { value: 0.42, label: "Download" } });
    const root = bar.find('[role="progressbar"]');
    expect(root.attributes("aria-label")).toBe("Download");
    expect(root.attributes("aria-valuemin")).toBe("0");
    expect(root.attributes("aria-valuemax")).toBe("100");
    expect(root.attributes("aria-valuenow")).toBe("42");
    expect(root.attributes("aria-valuetext")).toBe("42%");
    expect(bar.find<HTMLElement>(".flare-progress-bar__fill").element.style.width).toBe("42%");
    expect(root.classes()).not.toContain("is-indeterminate");
  });

  it("clamps a value outside 0 to 1", () => {
    const bar = mount(FlareProgressBar, { props: { value: 1.5 } });
    expect(bar.find('[role="progressbar"]').attributes("aria-valuenow")).toBe("100");
  });

  it("has no number while indeterminate, and says the work is under way", () => {
    const bar = mount(FlareProgressBar, { props: { value: 0.5, indeterminate: true } });
    const root = bar.find('[role="progressbar"]');
    expect(root.attributes("aria-valuenow")).toBeUndefined();
    expect(root.attributes("aria-valuetext")).toBeTruthy();
    expect(root.classes()).toContain("is-indeterminate");
  });

  it("reads no value as indeterminate", () => {
    const bar = mount(FlareProgressBar);
    expect(bar.find('[role="progressbar"]').classes()).toContain("is-indeterminate");
  });

  it("wears its tone", () => {
    const bar = mount(FlareProgressBar, { props: { value: 1, tone: "success" } });
    expect(bar.find('[role="progressbar"]').classes()).toContain("flare-progress-bar--success");
  });
});
