// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareMomentCard from "./FlareMomentCard.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => { host?.unmount(); host = undefined; });

const moment = {
  id: "m1",
  author: { id: "u_lin", name: "林夏" },
  text: "周末去爬山",
  time: "10 分钟前",
  likes: [{ id: "u_zhou", name: "周屿" }, { id: "u_su", name: "苏晚晴" }],
  comments: [{ id: "c1", author: { id: "u_he", name: "何川" }, text: "带上我" }],
};

function mountCard(listeners: Record<string, (...args: unknown[]) => void>) {
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareMomentCard as Component, { moment, ...listeners });
    },
  }), { attachTo: document.body });
  return host;
}

describe("FlareMomentCard", () => {
  it("renders people and comments as text when the host does nothing with them", () => {
    const card = mountCard({ onLike: () => {} });
    expect(card.findAll("button.flare-moment__name, button.flare-moment__liker, button.flare-comment__row, button.flare-moment__avatar")).toHaveLength(0);
    expect(card.text()).toContain("周屿");
    expect(card.text()).toContain("带上我");
  });

  it("makes the author, likers and comments keyboard controls with names when handled", async () => {
    const events: unknown[][] = [];
    const card = mountCard({
      onSelectAuthor: (id) => events.push(["author", id]),
      onSelectLiker: (id) => events.push(["liker", id]),
      onSelectComment: (comment) => events.push(["comment", (comment as { id: string }).id]),
    });
    await card.get("button.flare-moment__name").trigger("click");
    const likers = card.findAll("button.flare-moment__liker");
    expect(likers.map((liker) => liker.text())).toEqual(["周屿", "苏晚晴"]);
    await likers[1].trigger("click");
    const row = card.get("button.flare-comment__row");
    expect(row.attributes("aria-label")).toBe("回复 何川：带上我");
    await row.trigger("click");
    await row.get(".flare-comment__name--author").trigger("click");
    expect(events).toEqual([["author", "u_lin"], ["liker", "u_su"], ["comment", "c1"], ["author", "u_he"]]);
    expect(card.get("button.flare-moment__avatar").attributes("tabindex")).toBe("-1");
  });
});
