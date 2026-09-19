// @vitest-environment happy-dom
import { expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { useFlareI18nProvider } from "../../../../shared/i18n/useFlareI18n";
import CardView from "./CardView.vue";

function render(card: Record<string, unknown>) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(CardView, { content: { contentType: "card", card } as never, isSelf: false });
    },
  }));
}

it("names the person on a contact card and never prints the account id", () => {
  const named = render({ title: "周屿", subtitle: "产品设计组", id: "u_4f3a91" });
  expect(named.text()).toContain("周屿");
  expect(named.text()).toContain("产品设计组");
  expect(named.text()).not.toContain("u_4f3a91");
  const anonymous = render({ id: "u_4f3a91" });
  expect(anonymous.text()).not.toContain("u_4f3a91");
  expect(anonymous.text()).toContain("名片");
  named.unmount(); anonymous.unmount();
});
