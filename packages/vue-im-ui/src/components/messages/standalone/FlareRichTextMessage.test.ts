// @vitest-environment happy-dom
import { mount, type VueWrapper } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareRichTextMessage from "./FlareRichTextMessage.vue";
import RichTextView from "../MessagesView/views/RichTextView.vue";
import FrozenStickerThumb from "../../composer/FrozenStickerThumb/index.vue";
import { formatEmojiPackBracket } from "../../../utils/emojiPackI18n";

const text = (value: string, ...marks: string[]) =>
  marks.length ? { type: "text", text: value, marks: marks.map((type) => ({ type })) } : { type: "text", text: value };

const docJson = JSON.stringify({
  type: "doc",
  version: 2,
  children: [
    { type: "heading", level: 2, children: [text("周会纪要")] },
    {
      type: "paragraph",
      children: [
        text("结论 ", "bold"),
        { type: "link", href: "https://flare.im/docs", children: [text("文档")] },
        text(" "),
        { type: "link", href: "javascript:alert(1)", children: [text("别点")] },
        { type: "hard_break" },
        { type: "inline_code", text: "npm test" },
      ],
    },
    { type: "quote", children: [{ type: "paragraph", children: [text("引用")] }] },
    { type: "ordered_list", children: [{ type: "list_item", children: [{ type: "paragraph", children: [text("第一项")] }] }] },
    { type: "code_block", language: "ts", children: [text("const a = 1;")] },
    { type: "divider" },
    { type: "paragraph", children: [text("谜底是 "), text("42", "spoiler")] },
  ],
});

describe("rich-text body", () => {
  // 核心的 Markdown 归一化把 composer 写进去的 `[key]` 留成字面 text run(不是 emoji run),
  // 于是同一个表情在纯文本气泡里是图、进了富文本就成了 `[angry_face]`。text run 里的已知
  // 令牌按纯文本的规则内联成图;未知的、代码里的原样保留。
  it("draws known [key] emoji-pack tokens inside a text run inline, as a plain text body does", () => {
    const wrapper = mount(FlareRichTextMessage, {
      props: {
        docJson: JSON.stringify({
          type: "doc",
          version: 2,
          children: [
            { type: "paragraph", children: [text("[angry_face][alien] 的高峰时段 [not_a_key]", "bold")] },
            { type: "paragraph", children: [{ type: "inline_code", text: "[angry_face]" }] },
          ],
        }),
      },
    });
    const bold = wrapper.find(".fm-rich__run.is-bold");
    expect(bold.findAllComponents(FrozenStickerThumb).map((thumb: VueWrapper) => (thumb.props() as { alt?: string }).alt))
      .toEqual([formatEmojiPackBracket("angry_face"), formatEmojiPackBracket("alien")]);
    expect(bold.text()).toBe("的高峰时段 [not_a_key]");
    expect(wrapper.find(".fm-rich__code").text()).toBe("[angry_face]");
    expect(wrapper.find(".fm-rich__code").find(".fm-rich__emoji").exists()).toBe(false);
  });

  it("draws the document's blocks, marks and code", () => {
    const wrapper = mount(FlareRichTextMessage, { props: { docJson } });
    expect(wrapper.find(".fm-rich__heading.is-level-2").text()).toBe("周会纪要");
    expect(wrapper.find(".fm-rich__run.is-bold").text()).toBe("结论");
    expect(wrapper.find("blockquote").text()).toBe("引用");
    expect(wrapper.find("ol li").text()).toBe("第一项");
    expect(wrapper.find("pre").attributes("data-language")).toBe("ts");
    expect(wrapper.find("pre code").text()).toBe("const a = 1;");
    expect(wrapper.find("code.fm-rich__code").text()).toBe("npm test");
    expect(wrapper.find("hr").exists()).toBe(true);
  });

  it("links only what safeExternalUrl accepts, and keeps a refused link's words", async () => {
    const wrapper = mount(FlareRichTextMessage, { props: { docJson, onLinkClick: () => {} } });
    const anchors = wrapper.findAll("a");
    expect(anchors.map((a) => a.attributes("href"))).toEqual(["https://flare.im/docs"]);
    expect(anchors[0].attributes("rel")).toBe("noopener noreferrer");
    expect(wrapper.text()).toContain("别点");
    await anchors[0].trigger("click");
    expect(wrapper.emitted("linkClick")?.[0]).toEqual(["https://flare.im/docs"]);
  });

  it("covers a spoiler until the reader reveals it", async () => {
    const wrapper = mount(FlareRichTextMessage, { props: { docJson } });
    const spoiler = wrapper.find("[data-flare-spoiler]");
    expect(spoiler.attributes("role")).toBe("button");
    // The words are not in the page while covered: not drawn, not copied, not read.
    expect(wrapper.text()).not.toContain("42");
    expect(spoiler.element.textContent).toBe("\u3000\u3000");
    expect(spoiler.attributes("aria-label")).toBeTruthy();
    await spoiler.trigger("keydown", { key: "Enter" });
    expect(wrapper.find("[data-flare-spoiler]").exists()).toBe(false);
    expect(wrapper.text()).toContain("谜底是 42");
  });

  it("shows the plain text when the document is not drawable, and the rich-text term with neither", () => {
    const broken = mount(FlareRichTextMessage, { props: { docJson: "{\"type\":\"doc\"", plainText: "周报已发出" } });
    expect(broken.find(".fm-rich__plain").text()).toBe("周报已发出");
    const empty = mount(FlareRichTextMessage, { props: { docJson: null } });
    expect(empty.find(".fm-rich__plain").text()).not.toBe("");
  });

  it("draws the message title above the document", () => {
    const wrapper = mount(FlareRichTextMessage, { props: { docJson, title: "项目周报" } });
    expect(wrapper.find(".fm-rich__title").text()).toBe("项目周报");
    expect(wrapper.find(".fm-rich").element.firstElementChild?.classList.contains("fm-rich__title")).toBe(true);
  });

  it("dispatches runtime rich text through the public body, from the document and never from its Markdown source", () => {
    const wrapper = mount(RichTextView, {
      props: {
        content: {
          contentType: "rich_text",
          rich_text: { docJson, plainText: "周会纪要", sourcePayload: { markdown: "# 不是这个" } },
        },
        isSelf: true,
      },
    });
    const body = wrapper.findComponent(FlareRichTextMessage);
    expect(body.props()).toMatchObject({ docJson, plainText: "周会纪要", self: true, selectable: true });
    expect(wrapper.text()).not.toContain("不是这个");
  });
});
