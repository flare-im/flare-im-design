// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { NTag } from "naive-ui";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import ConversationDetails from "./ConversationDetails.vue";
import type { FlareConversationDetailsModel } from "../../shared/contracts/conversation";

let host: ReturnType<typeof mount>;
afterEach(() => { host?.unmount(); });

const conversation: FlareConversationDetailsModel = {
  conversationId: "c1", channelId: "g1", displayName: "Design", conversationKind: "group", membersCount: 12,
};

function mountDetails(props: Record<string, unknown>) {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("en-US");
    return () => h(ConversationDetails as Component, { conversation, connectionText: "Connected", messageCount: 3, latestMessageId: "m3", ...props });
  } }));
  return host.findComponent(ConversationDetails);
}

describe("FlareConversationDetails", () => {
  it("takes a structural conversation (no SDK type) and reads group members case-insensitively", () => {
    const pane = mountDetails({ tone: "success" });
    expect(pane.find("h2").text()).toBe("Design");
    expect(pane.find(".details-hero p").text()).toContain("12");
  });

  it("maps FlareTone onto the tag without leaking the naive enum", () => {
    const pane = mountDetails({ tone: "danger" });
    const tag = pane.findComponent(NTag);
    expect(tag.props("type")).toBe("error");
    expect(tag.attributes("data-tone")).toBe("danger");
    host.unmount();
    expect(mountDetails({ tone: "neutral" }).findComponent(NTag).props("type")).toBe("default");
  });

  it("uses neutral as the default semantic tone", () => {
    expect(mountDetails({}).findComponent(NTag).attributes("data-tone")).toBe("neutral");
  });

  it("emits pin / mute toggles with the next boolean", async () => {
    const pane = mountDetails({ tone: "success" });
    const buttons = pane.findAll(".details-actions button");
    await buttons[3].trigger("click");
    expect(pane.emitted("pin")?.[0]).toEqual([true]);
  });
});
