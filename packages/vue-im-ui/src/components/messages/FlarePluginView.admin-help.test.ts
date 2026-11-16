// @vitest-environment happy-dom
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import FlarePluginView from "./FlarePluginView.vue";
import { groupSigninBlocks } from "./FlarePluginView.admin-help.fixture";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type {
  FlarePluginBlock,
  FlarePluginViewModel,
} from "../../shared/contracts/plugin-ui";

enableAutoUnmount(afterEach);
afterEach(() => {
  document.body.innerHTML = "";
});

const rows: FlarePluginBlock = {
  kind: "rows",
  source: "records.list",
  columns: [{ label: "Name", format: "text" }],
  rows: [{ key: "r1", cells: [{ text: "First record" }] }],
};
const info: FlarePluginBlock = { kind: "note", text: "Info explanation", tone: "info" };
const body: FlarePluginBlock = { kind: "text", text: "Plain explanation" };
const warning: FlarePluginBlock = { kind: "note", text: "Careful with this", tone: "warning" };
const fields: FlarePluginBlock = { kind: "fields", fields: [{ label: "State", value: "On" }] };

const viewOf = (blocks: FlarePluginBlock[]): FlarePluginViewModel => ({
  available: true,
  title: "Page",
  fields: [],
  inputs: [],
  actions: [],
  blocks,
});

type RowsSlot = { help?: FlarePluginBlock[]; notices?: FlarePluginBlock[] };

function setup(
  blocks: FlarePluginBlock[],
  props: Record<string, unknown> = {},
  withSlot = true,
) {
  const slot: RowsSlot = {};
  const wrapper = mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () =>
          h(
            FlarePluginView as never,
            { view: viewOf(blocks), embedded: true, ...props },
            withSlot
              ? {
                  rows: (ctx: RowsSlot) => {
                    slot.help = ctx.help;
                    slot.notices = ctx.notices;
                    return h("div", { "data-rows-stub": "true" });
                  },
                }
              : {},
          );
      },
    }),
  );
  return { wrapper, slot };
}

const textLength = (blocks: readonly FlarePluginBlock[]) =>
  blocks.reduce((sum, block) => sum + ("text" in block ? block.text.length : 0), 0);

describe("FlarePluginView admin presentation", () => {
  it("list layout moves leading explanations into help", () => {
    const { wrapper, slot } = setup([info, body, rows], {
      presentation: "admin",
      contentLayout: "list",
    });
    expect(slot.help).toHaveLength(2);
    expect(slot.notices).toHaveLength(0);
    expect(wrapper.find('[data-block="note"]').exists()).toBe(false);
    expect(wrapper.find('[data-block="text"]').exists()).toBe(false);
  });

  it("warning notes go to notices", () => {
    const { slot } = setup([warning, rows], {
      presentation: "admin",
      contentLayout: "list",
    });
    expect(slot.notices).toHaveLength(1);
    expect(slot.help).toHaveLength(0);
  });

  it("message presentation is unchanged", () => {
    const { wrapper, slot } = setup([info, body, rows], { contentLayout: "list" }, false);
    const order = wrapper
      .findAll("[data-block]")
      .map((node) => node.attributes("data-block"))
      .filter((kind) => ["note", "text", "rows"].includes(kind ?? ""));
    expect(order).toEqual(["note", "text", "rows"]);
    expect(slot.help).toBeUndefined();
  });

  it("flow layout gathers info notes into the header help", () => {
    const { wrapper } = setup([info, fields, warning], {
      presentation: "admin",
      contentLayout: "flow",
    });
    const trigger = wrapper.find('.flare-plugin-view__help button[aria-label="About"]');
    expect(trigger.exists()).toBe(true);
    const notes = wrapper.findAll('[data-block="note"]');
    expect(notes).toHaveLength(1);
    expect(notes[0].text()).toContain("Careful with this");
    expect(notes[0].classes()).toContain("is-clamped");
    expect(notes[0].attributes("style")).toContain("--flare-clamp-lines: 2");
  });

  it("admin keeps note tone", () => {
    const { wrapper } = setup([warning, fields], {
      presentation: "admin",
      contentLayout: "flow",
      notePresentation: "plain",
    });
    const note = wrapper.get('[data-block="note"]');
    expect(note.classes()).toContain("is-warning");
    expect(note.classes()).not.toContain("is-plain");
  });

  it("nothing is lost", () => {
    const original = groupSigninBlocks
      .filter((block) => block.kind === "note" || block.kind === "text")
      .map((block) => ("text" in block ? block.text : ""));
    const total = original.reduce((sum, text) => sum + text.length, 0);
    const { slot } = setup(groupSigninBlocks, {
      presentation: "admin",
      contentLayout: "list",
    });
    expect(textLength(slot.help ?? []) + textLength(slot.notices ?? [])).toBe(total);
  });
});
