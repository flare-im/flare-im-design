// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlareFriendRequest } from "../../shared/contracts";
import FlareNewFriendRequests from "./FlareNewFriendRequests.vue";

const incoming: FlareFriendRequest = { id: "r1", name: "Ann", message: "Hi" };
const outgoing: FlareFriendRequest = { id: "r2", name: "Bob", message: "Let's connect", direction: "outgoing" };

type RequestsProps = {
  items: FlareFriendRequest[];
  withdrawLabel?: string;
  pendingActions?: Readonly<Record<string, "accept" | "reject">>;
  errors?: Readonly<Record<string, string>>;
  onRetry?: () => void;
  onAccept?: () => void;
  onReject?: () => void;
  onWithdraw?: () => void;
  onView?: () => void;
};

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => hosts.splice(0).forEach(host => host.unmount()));
function mountRequests(props: RequestsProps) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlareNewFriendRequests, props);
    },
  }));
  hosts.push(host);
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

describe("FlareNewFriendRequests source line", () => {
  it("draws the source on its own secondary line under the message", () => {
    const fromCard: FlareFriendRequest = { id: "r3", name: "Cleo", message: "我是 Cleo", source: "通过名片添加，由 Ann 推荐" };
    const wrapper = mountRequests({ items: [fromCard, incoming], onAccept: () => {}, onReject: () => {} });
    const [first, second] = wrapper.findAll(".flare-new-friends__row");
    const body = first.get(".flare-new-friends__body");
    const lines = body.findAll(":scope > span").map((line) => line.classes()[0]);
    expect(lines).toEqual(["flare-new-friends__name", "flare-new-friends__msg", "flare-new-friends__source"]);
    expect(first.get(".flare-new-friends__msg").text()).toBe("我是 Cleo");
    expect(first.get("[data-request-source]").text()).toBe("通过名片添加，由 Ann 推荐");
    // A request without a source keeps the two lines it always had.
    expect(second.find("[data-request-source]").exists()).toBe(false);
  });
});

describe("FlareNewFriendRequests profile access", () => {
  it("offers a native keyboard-operable profile button only when the host handles view", async () => {
    const wrapper = mountRequests({ items: [incoming], onView: () => {}, onAccept: () => {} });
    const profile = wrapper.get("button.flare-new-friends__body");
    expect(profile.attributes("type")).toBe("button");
    expect(profile.text()).toContain("Ann");
    await profile.trigger("click");
    expect(wrapper.emitted("view")).toEqual([[incoming]]);
    expect(wrapper.emitted("accept")).toBeUndefined();
    const readonly = mountRequests({ items: [incoming] });
    expect(readonly.find("button.flare-new-friends__body").exists()).toBe(false);
  });
});

it("keeps pending and retry states scoped to the request id without changing the target", async () => {
  const other = { ...incoming, id: "r3", name: "Ivy" };
  const wrapper = mountRequests({ items: [incoming, other], pendingActions: { r1: "accept" }, errors: { r3: "Could not decline" }, onRetry: () => {} });
  const rows = wrapper.findAll(".flare-new-friends__row");
  expect(rows[0].attributes("aria-busy")).toBe("true");
  expect(rows[0].findAll("button").every(button => button.attributes("disabled") !== undefined)).toBe(true);
  expect(rows[1].findAll("button").every(button => button.attributes("disabled") === undefined)).toBe(true);
  await wrapper.get(".flare-new-friends__error button").trigger("click");
  expect(wrapper.emitted("retry")).toEqual([[other]]);
  expect(wrapper.emitted("accept")).toBeUndefined();
});
