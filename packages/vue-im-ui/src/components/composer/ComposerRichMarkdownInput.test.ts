// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import ComposerRichMarkdownInput from "./ComposerRichMarkdownInput.vue";

describe("ComposerRichMarkdownInput emoji tokens", () => {
  const wrappers: ReturnType<typeof mount>[] = [];
  afterEach(() => wrappers.splice(0).forEach((wrapper) => wrapper.unmount()));

  it("draws a known token as an image while serializing the raw protocol value", async () => {
    const wrapper = mount(ComposerRichMarkdownInput, {
      props: { modelValue: "hello [alien]" },
      attachTo: document.body,
    });
    wrappers.push(wrapper);
    await flushPromises();

    const token = wrapper.get<HTMLElement>(".composer-md-token--emoji");
    expect(token.attributes("data-token")).toBe("[alien]");
    expect(token.attributes("contenteditable")).toBe("false");
    const image = token.get<HTMLImageElement>("img");
    expect(image.attributes("alt")).toBe("alien");
    expect(image.attributes("data-flare-static-preview")).toBe("true");
    expect(image.attributes("data-source-url")).toContain("/flare-im-ui-assets/emoji/alien.webp");
    expect(image.element.src).not.toMatch(/\.webp$/);

    const editor = wrapper.get<HTMLElement>(".composer-rich-markdown-input__editable");
    editor.element.appendChild(document.createTextNode("!"));
    await editor.trigger("input");
    expect(wrapper.emitted("update:modelValue")?.at(-1)).toEqual(["hello [alien]!"]);
  });

  it("keeps an unknown pack token as editable text", async () => {
    const wrapper = mount(ComposerRichMarkdownInput, {
      props: { modelValue: "[not_a_pack_key]" },
    });
    wrappers.push(wrapper);
    await flushPromises();

    expect(wrapper.find(".composer-md-token--emoji").exists()).toBe(false);
    expect(wrapper.get(".composer-rich-markdown-input__editable").text()).toBe("[not_a_pack_key]");
  });
});
