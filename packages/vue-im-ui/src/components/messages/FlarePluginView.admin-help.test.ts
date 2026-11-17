// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import FlarePluginView from "./FlarePluginView.vue";
import FlarePluginAdminList from "./FlarePluginAdminList.vue";
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
  rows: [{ key: "r1", cells: [{ text: "First record" }], actions: [] }],
  actions: [],
};
const info: FlarePluginBlock = { kind: "note", text: "Info explanation long enough to belong in help", tone: "info" };
const body: FlarePluginBlock = { kind: "text", text: "Plain explanation" };
const warning: FlarePluginBlock = { kind: "note", text: "Careful with this", tone: "warning" };
const longWarning: FlarePluginBlock = { kind: "note", text: "Line one\nLine two\nLine three", tone: "warning" };
const label: FlarePluginBlock = { kind: "note", text: "Keywords:", tone: "info" };
const heading: FlarePluginBlock = { kind: "text", text: "Section heading", style: "title" };
const fields: FlarePluginBlock = { kind: "fields", fields: [{ label: "State", value: "On" }] };

const viewOf = (blocks: FlarePluginBlock[]): FlarePluginViewModel => ({
  available: true,
  title: "Page",
  fields: [],
  inputs: [],
  actions: [],
  blocks,
});

type RowsSlot = { help?: FlarePluginBlock[]; notices?: FlarePluginBlock[]; [key: string]: unknown };

function setup(
  blocks: FlarePluginBlock[],
  props: Record<string, unknown> = {},
  withSlot = true,
  renderRows?: (ctx: RowsSlot) => ReturnType<typeof h>,
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
                    return renderRows ? renderRows(ctx) : h("div", { "data-rows-stub": "true" });
                  },
                }
              : {},
          );
      },
    }),
    { attachTo: document.body },
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
    const { wrapper } = setup([info, label, heading, fields, warning], {
      presentation: "admin",
      contentLayout: "flow",
    });
    const trigger = wrapper.find('.flare-plugin-view__help button[aria-label="About"]');
    expect(trigger.exists()).toBe(true);
    // The long info note moved into the help; the label-like note, the heading and the warning stay inline.
    const notes = wrapper.findAll('[data-block="note"]');
    expect(notes.map((note) => note.text())).toEqual(["Keywords:", "Careful with this"]);
    // The heading now belongs to the fields section, with real heading semantics.
    expect(wrapper.get('.flare-admin-section__title').text()).toBe("Section heading");
    const warn = notes[1];
    expect(warn.classes()).toContain("is-clamped");
    expect(warn.attributes("style")).toContain("--flare-clamp-lines: 2");
  });

  it("flow layout keeps body text after content inline", () => {
    const { wrapper } = setup([body, fields, { ...body, text: "Text after content" }], {
      presentation: "admin",
      contentLayout: "flow",
    });
    const texts = wrapper.findAll('[data-block="text"]').map((node) => node.text());
    expect(texts).toEqual(["Text after content"]);
    expect(wrapper.find(".flare-plugin-view__help").exists()).toBe(true);
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

  it("no rows slot keeps explanations inline", () => {
    const { wrapper } = setup(
      [info, body, rows],
      { presentation: "admin", contentLayout: "list" },
      false,
    );
    expect(wrapper.get('[data-block="note"]').text()).toContain("Info explanation");
    expect(wrapper.get('[data-block="text"]').text()).toBe("Plain explanation");
  });

  it("flow layout nothing is lost", async () => {
    const original = groupSigninBlocks
      .filter((block) => block.kind === "note" || block.kind === "text")
      .reduce((sum, block) => sum + ("text" in block ? block.text.length : 0), 0);
    const { wrapper } = setup(
      groupSigninBlocks,
      { presentation: "admin", contentLayout: "flow" },
      false,
    );
    await wrapper.get(".flare-plugin-view__help button").trigger("click");
    await flushPromises();
    const painted = Array.from(
      document.body.querySelectorAll(".flare-plugin-note, .flare-plugin-text__body"),
    ).reduce((sum, node) => sum + (node.textContent ?? "").length, 0);
    expect(painted).toBe(original);
  });

  it("admin list renders help and notices", async () => {
    const { wrapper } = setup(
      [info, body, warning, rows],
      { presentation: "admin", contentLayout: "list" },
      true,
      (ctx) =>
        h(
          FlarePluginAdminList as never,
          {
            block: ctx.shownBlock ?? ctx.block,
            strings: ctx.strings,
            label: "Records",
            help: ctx.help,
            notices: ctx.notices,
          },
        ),
    );
    const notice = wrapper.get(".flare-admin-list__notice");
    expect(notice.text()).toContain("Careful with this");
    await wrapper.get(".flare-admin-help button").trigger("click");
    await flushPromises();
    const popover = document.body.textContent ?? "";
    expect(popover).toContain("Info explanation long enough to belong in help");
    expect(popover).toContain("Plain explanation");
  });

  it("clamped note expands", async () => {
    const { wrapper } = setup([longWarning, fields], {
      presentation: "admin",
      contentLayout: "flow",
    });
    const note = wrapper.get('[data-block="note"]');
    expect(note.classes()).toContain("is-clamped");
    const toggle = wrapper.get("[data-note-toggle]");
    expect(toggle.text()).toBe("Expand");
    await toggle.trigger("click");
    expect(wrapper.get('[data-block="note"]').classes()).not.toContain("is-clamped");
    expect(wrapper.get("[data-note-toggle]").text()).toBe("Collapse");
  });
});
