// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h } from "vue";
import { describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import { resolveMessageId } from "../../shared/contracts/messageRow";
import PinnedMessageBar from "./PinnedMessageBar.vue";

describe("PinnedMessageBar", () => {
  it("focuses a pinned message by the id MessageList.scrollToMessage resolves", async () => {
    const item = { serverId: "server-7", clientMsgId: "client-7", senderDisplayName: "Ivy", content: { contentType: "text", data: { text: "Release notes" } } };
    const host = mount(FlareUiProvider, {
      props: { themeMode: "light", locale: "en-US" },
      slots: { default: () => h(PinnedMessageBar, { items: [item] }) },
    });
    const bar = host.findComponent(PinnedMessageBar);
    await bar.find("button").trigger("click");
    expect(bar.emitted("focus")?.[0]).toEqual([resolveMessageId(item)]);
    expect(bar.emitted("focus")?.[0]).toEqual(["client-7"]);
    host.unmount();
  });
});
