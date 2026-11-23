// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { useFlarePlatformProvider } from '../../shared/platform/useFlarePlatform';
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

function mountCard(listeners: Record<string, (...args: unknown[]) => void>, props: Record<string, unknown> = {}, phone = false) {
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { bottomSheet: phone } });
      return () => h(FlareMomentCard as Component, { moment, ...props, ...listeners });
    },
  }), { attachTo: document.body });
  return host;
}

const actionButtons = () => [...document.body.querySelectorAll<HTMLButtonElement>('[data-action-menu-item]')];
const actionLabels = () => actionButtons().map((button) => button.textContent?.trim());

describe("FlareMomentCard", () => {
  it('folds long posts without losing text and expands through a named control', async () => {
    const card = mountCard({}, { moment: { ...moment, text: 'Long post\n'.repeat(12) }, appearance: 'feed' });
    expect(card.get('article').classes()).toContain('flare-moment--feed');
    expect(card.get('.flare-moment__text').classes()).toContain('is-clamped');
    await card.get('.flare-moment__expand').trigger('click');
    expect(card.get('.flare-moment__expand').attributes('aria-expanded')).toBe('true');
    expect(card.get('.flare-moment__text').classes()).not.toContain('is-clamped');
  });
  it("uses full-width detailed comments and keeps the complete post expanded in detail", () => {
    const card = mountCard({}, { moment: { ...moment, text: '完整正文\n'.repeat(12) }, appearance: 'detail' });
    expect(card.find('.flare-moment__text.is-clamped').exists()).toBe(false);
    expect(card.get('.flare-moment__comments-heading').text()).toContain('评论');
    expect(card.get('.flare-comment-thread').classes()).toContain('flare-comment-thread--detail');
  });
  it("renders people and comments as text when the host does nothing with them", () => {
    const card = mountCard({ onLike: () => {} });
    expect(card.findAll("button.flare-moment__name, button.flare-moment__liker, button.flare-comment__row, button.flare-moment__avatar")).toHaveLength(0);
    expect(card.text()).toContain("周屿");
    expect(card.text()).toContain("带上我");
  });

  it("updates comment and reply availability without replacing the moment data", async () => {
    const availability = reactive({ canComment: false, canLike: false });
    const events: string[] = [];
    const card = mountCard({ onComment: () => events.push("comment"), onSelectComment: () => events.push("reply") }, availability);
    expect(card.find("button.flare-comment__row").exists()).toBe(false);
    availability.canComment = true; await nextTick();
    await card.get("button.flare-comment__row").trigger("click");
    expect(events).toEqual(["reply"]);
    availability.canComment = false; await nextTick();
    expect(card.find("button.flare-comment__row").exists()).toBe(false);
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

  // A host gates a feature by not binding its listener: like and comment follow the rule selectAuthor follows.
  it("offers like and comment only when the host takes them", async () => {
    const events: string[] = [];
    const both = mountCard({ onLike: () => events.push("like"), onComment: () => events.push("comment") });
    await both.get("button.flare-moment__more").trigger("click");
    expect(actionLabels()).toEqual(["赞", "评论"]);
    actionButtons()[1].click();
    await nextTick();
    expect(events).toEqual(["comment"]);
    // Picking an action closes the popover.
    expect(both.get('button.flare-moment__more').attributes('aria-expanded')).toBe('false');
    both.unmount();

    const likeOnly = mountCard({ onLike: () => {} });
    await likeOnly.get("button.flare-moment__more").trigger("click");
    expect(actionLabels()).toEqual(["赞"]);
    expect(document.body.querySelectorAll('[role="separator"]')).toHaveLength(0);
  });

  it("hides the more key when nothing is left to offer", () => {
    const bare = mountCard({});
    expect(bare.find("button.flare-moment__more").exists()).toBe(false);
    expect(bare.text()).toContain("10 分钟前");
  });

  it('names unlike explicitly rather than suggesting dismissal', async () => {
    const events: string[] = [];
    const card = mountCard({ onLike: () => events.push('like') }, { moment: { ...moment, likedBySelf: true } });
    await card.get('button.flare-moment__more').trigger('click');
    expect(actionLabels()).toEqual(['取消赞']);
    actionButtons()[0].click();
    await nextTick();
    expect(events).toEqual(['like']);
  });

  it("keeps the more key for delete or report alone", async () => {
    const own = mountCard({ onDelete: () => {} }, { canDelete: true });
    await own.get("button.flare-moment__more").trigger("click");
    expect(actionLabels()).toEqual(["删除"]);
    expect(document.body.querySelectorAll('[role="separator"]')).toHaveLength(0);
    expect(own.get("button.flare-moment__more").attributes("aria-expanded")).toBe("true");
  });

  it.each([false, true])('offers accessible actions and restores focus on Escape (phone=%s)', async (phone) => {
    const card = mountCard({ onLike: () => {} }, { canReport: true }, phone);
    const trigger = card.get<HTMLButtonElement>('button.flare-moment__more');
    trigger.element.focus();
    await trigger.trigger('click');
    await nextTick();
    expect(actionLabels()).toEqual(['赞', '举报']);
    const menu = document.body.querySelector('[role="menu"]');
    expect(Boolean(menu?.closest('[data-flare-presentation="sheet"]'))).toBe(phone);
    expect(menu?.getAttribute('aria-orientation')).toBe(phone ? 'vertical' : 'horizontal');
    actionButtons()[0].dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    await nextTick();
    expect(trigger.attributes('aria-expanded')).toBe('false');
    expect(document.activeElement).toBe(trigger.element);
  });
});
