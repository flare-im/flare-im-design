// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareMomentActionPopover from "./FlareMomentActionPopover.vue";

function render(props: Record<string, unknown> = {}) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareMomentActionPopover, props);
    },
  }));
}

/**
 * The like control says what pressing it will do, not what the state is — so it reads "赞" before
 * and "取消赞" after. Delete only exists for a post the viewer owns. Release criterion §1.
 */
describe("FlareMomentActionPopover", () => {
  it("offers like and comment as a group", () => {
    const wrapper = render();
    expect(wrapper.find('[role="group"]').exists()).toBe(true);
    expect(wrapper.findAll(".flare-moment-actions__btn").map((b) => b.text())).toEqual(["赞", "评论"]);
  });

  it("names the like control by what it will do", () => {
    expect(render({ liked: false }).findAll(".flare-moment-actions__btn")[0].text()).toBe("赞");
    expect(render({ liked: true }).findAll(".flare-moment-actions__btn")[0].text()).toBe("取消赞");
  });

  it("offers delete only to someone who may delete", () => {
    expect(render().findAll(".is-danger")).toHaveLength(0);
    const own = render({ canDelete: true });
    expect(own.findAll(".is-danger")).toHaveLength(1);
    expect(own.find(".is-danger").text()).toBe("删除");
  });

  it("leaves out like or comment when the host does not offer them, with dividers only between drawn actions", () => {
    const commentOnly = render({ canLike: false });
    expect(commentOnly.findAll(".flare-moment-actions__btn").map((b) => b.text())).toEqual(["评论"]);
    expect(commentOnly.findAll(".flare-moment-actions__divider")).toHaveLength(0);
    const reportOnly = render({ canLike: false, canComment: false, canReport: true });
    expect(reportOnly.findAll(".flare-moment-actions__btn").map((b) => b.text())).toEqual(["举报"]);
    expect(reportOnly.findAll(".flare-moment-actions__divider")).toHaveLength(0);
    const all = render({ canDelete: true });
    expect(all.findAll(".flare-moment-actions__divider")).toHaveLength(2);
  });

  it("reports each intent and performs none of them", async () => {
    const wrapper = render({ canDelete: true });
    const buttons = wrapper.findAll(".flare-moment-actions__btn");
    await buttons[0].trigger("click");
    await buttons[1].trigger("click");
    await wrapper.find(".is-danger").trigger("click");
    const emitted = wrapper.findComponent(FlareMomentActionPopover).emitted();
    expect(emitted.like).toHaveLength(1);
    expect(emitted.comment).toHaveLength(1);
    expect(emitted.delete).toHaveLength(1);
  });
});
