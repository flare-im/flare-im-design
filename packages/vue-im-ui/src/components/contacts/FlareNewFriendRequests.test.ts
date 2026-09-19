// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlareFriendRequest } from "../../shared/contracts";
import FlareNewFriendRequests from "./FlareNewFriendRequests.vue";

const incoming: FlareFriendRequest = { id: "r1", name: "Ann", message: "Hi" };
const outgoing: FlareFriendRequest = { id: "r2", name: "Bob", message: "Let's connect", direction: "outgoing" };

type RequestsProps = {
  items: FlareFriendRequest[];
  withdrawLabel?: string;
  onAccept?: () => void;
  onReject?: () => void;
  onWithdraw?: () => void;
};

function mountRequests(props: RequestsProps) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlareNewFriendRequests, props);
    },
  }));
  return host.findComponent(FlareNewFriendRequests);
}

describe("FlareNewFriendRequests direction", () => {
  it("shows a pending status and withdraw on outgoing rows, and accept / decline only on incoming rows", async () => {
    const wrapper = mountRequests({ items: [incoming, outgoing], onAccept: () => {}, onReject: () => {}, onWithdraw: () => {} });
    const [first, second] = wrapper.findAll(".flare-new-friends__row");

    expect(first.findAll("button").map((b) => b.text())).toEqual(["Decline", "Accept"]);
    expect(first.find(".flare-new-friends__status").exists()).toBe(false);

    expect(second.get(".flare-new-friends__status").text()).toBe("Pending");
    expect(second.findAll("button").map((b) => b.text())).toEqual(["Withdraw"]);
    await second.get("button").trigger("click");
    expect(wrapper.emitted("withdraw")).toEqual([[outgoing]]);
    expect(wrapper.emitted("accept")).toBeUndefined();
    expect(wrapper.emitted("reject")).toBeUndefined();
  });

  it("offers no withdraw without a listener and honours withdrawLabel", () => {
    const passive = mountRequests({ items: [outgoing] });
    const row = passive.get(".flare-new-friends__row");
    expect(row.find("button").exists()).toBe(false);
    expect(row.get(".flare-new-friends__status").text()).toBe("Pending");

    const labelled = mountRequests({ items: [outgoing], withdrawLabel: "Cancel request", onWithdraw: () => {} });
    expect(labelled.get("button").text()).toBe("Cancel request");
  });
});
