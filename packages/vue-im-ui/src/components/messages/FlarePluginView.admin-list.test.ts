// @vitest-environment happy-dom
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, reactive } from "vue";
import FlarePluginView from "./FlarePluginView.vue";
import FlarePluginAdminList from "./FlarePluginAdminList.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareAdminList from "../data/FlareAdminList.vue";
import type { FlareAdminPagination } from "../data/admin-list";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type {
  FlarePluginAction,
  FlarePluginActionPayload,
  FlarePluginRow,
  FlarePluginRowsBlock,
  FlarePluginStrings,
  FlarePluginViewModel,
} from "../../shared/contracts/plugin-ui";

enableAutoUnmount(afterEach);
afterEach(() => {
  document.body.innerHTML = "";
});
type RowsSlot = {
  block: FlarePluginRowsBlock;
  shownBlock?: FlarePluginRowsBlock;
  strings?: FlarePluginStrings;
  actions?: readonly FlarePluginAction[];
  busy: boolean;
  busyActionId?: string;
  busyRow?: string | null;
  run: (action: FlarePluginAction, row: FlarePluginRow, input: unknown) => void;
  runAction?: (action: FlarePluginAction) => void;
  openRow?: (row: FlarePluginRow) => void;
  loadMore?: (cursor: string) => void;
};
const rowInput = { id: "r1", expectedRevision: "900719925474099301" };
const view: FlarePluginViewModel = {
  available: true,
  title: "Records",
  fields: [],
  inputs: [{ id: "name", kind: "text", label: "Name", required: true }],
  actions: [
    {
      id: "create",
      label: "Create record",
      confirm: "Create the reviewed record?",
      form: ["name"],
    },
  ],
  blocks: [
    {
      kind: "rows",
      source: "records.list",
      columns: [{ label: "Name", format: "text" }],
      actions: [
        {
          id: "edit",
          label: "Edit record",
          confirm: "Edit the reviewed record?",
          form: ["name"],
        },
      ],
      rows: [
        {
          key: "r1",
          cells: [{ text: "First record" }],
          actions: [{ id: "edit", input: rowInput }],
          detailInput: { id: "r1" },
        },
      ],
      nextCursor: "next-page",
    },
  ],
};
function setup(
  options: {
    contentLayout?: "flow" | "list";
    view?: FlarePluginViewModel;
    pagination?: FlareAdminPagination;
  } = {},
) {
  const { pagination, ...viewProps } = options;
  const state = reactive({
    busy: false,
    busyActionId: undefined as string | undefined,
    error: "",
    settleToken: 0,
  });
  const actions: Array<[string, FlarePluginActionPayload]> = [],
    details: unknown[] = [],
    loads: unknown[] = [];
  let context: RowsSlot | undefined;
  const wrapper = mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("en-US");
        return () =>
          h(
            FlarePluginView as never,
            {
              view,
              embedded: true,
              actionsPlacement: "rows",
              errorPresentation: "external",
              ...viewProps,
              ...state,
              formInitialValues: (id: string) =>
                id === "edit" ? { name: "Original" } : undefined,
              onAction: (id: string, payload: FlarePluginActionPayload) =>
                actions.push([id, payload]),
              onOpenDetail: (row: unknown) => details.push(row),
              onLoadMore: (...value: unknown[]) => loads.push(value),
            },
            {
              rows: (slot: RowsSlot) => {
                context = slot;
                return h(
                  FlarePluginAdminList as never,
                  {
                    block: slot.shownBlock ?? slot.block,
                    strings: slot.strings,
                    label: "Records",
                    pagination,
                    disabled: slot.busy,
                    busyActionId: slot.busyActionId,
                    busyRow: slot.busyRow,
                    onRowAction: slot.run,
                    onOpenRow: slot.openRow,
                  },
                  {
                    actions: () =>
                      (slot.actions ?? []).map((action) =>
                        h(FlareButton, {
                          key: action.id,
                          label: action.label,
                          size: "sm",
                          disabled: slot.busy,
                          "data-page-action": action.id,
                          onClick: () => slot.runAction?.(action),
                        }),
                      ),
                  },
                );
              },
            },
          );
      },
    }),
    { attachTo: document.body },
  );
  return { wrapper, state, actions, details, loads, context: () => context! };
}
async function confirm(label: string) {
  await flushPromises();
  const button = [
    ...document.body.querySelectorAll(
      ".flare-danger-confirm button, [role='dialog'] button",
    ),
  ].find((entry) => entry.textContent?.trim() === label) as
    HTMLButtonElement | undefined;
  expect(button, `the real confirmation offers ${label}`).toBeDefined();
  button!.click();
  await flushPromises();
}
async function submitName(name: string) {
  const input = document.body.querySelector(
    ".flare-plugin-form input",
  ) as HTMLInputElement | null;
  expect(input).not.toBeNull();
  input!.value = name;
  input!.dispatchEvent(new Event("input", { bubbles: true }));
  await flushPromises();
  (
    document.body.querySelector(
      ".flare-plugin-form [data-form-submit]",
    ) as HTMLButtonElement
  ).click();
  await flushPromises();
}

describe("PluginView admin rows / one command pipeline", () => {
  it("offers formatted rows and page actions once through the shared operational list", () => {
    const h = setup();
    expect(h.context().shownBlock).toBeDefined();
    expect(h.context().strings?.required).toBeTruthy();
    expect(h.context().actions).toEqual(view.actions);
    expect(h.context().runAction).toBeTypeOf("function");
    expect(h.context().openRow).toBeTypeOf("function");
    expect(h.context().loadMore).toBeTypeOf("function");
    expect(h.wrapper.findAllComponents(FlarePluginAdminList)).toHaveLength(1);
    expect(h.wrapper.findAll('[data-page-action="create"]')).toHaveLength(1);
    expect(h.wrapper.find('[data-action-id="create"]').exists()).toBe(false);
  });

  it("sends row and toolbar forms through confirmation and preserves failed external form values", async () => {
    const h = setup();
    await h.wrapper.get('[data-row-action="edit"]').trigger("click");
    expect(h.actions).toEqual([]);
    await confirm("Edit record");
    await submitName("Edited exact value");
    expect(h.actions).toEqual([
      [
        "edit",
        {
          row: { key: "r1", input: rowInput },
          formValues: { name: "Edited exact value" },
        },
      ],
    ]);
    h.state.error = "External command refused";
    h.state.settleToken++;
    await flushPromises();
    expect(
      (
        document.body.querySelector(
          ".flare-plugin-form input",
        ) as HTMLInputElement
      ).value,
    ).toBe("Edited exact value");
    expect(document.body.textContent).not.toContain("External command refused");
    expect(
      document.body.querySelector(".n-alert, .flare-status-banner"),
    ).toBeNull();
    h.state.error = "";
    h.state.settleToken++;
    await flushPromises();
    expect(document.body.querySelector(".flare-plugin-form")).toBeNull();
    await h.wrapper.get('[data-page-action="create"]').trigger("click");
    await confirm("Create record");
    await submitName("New record");
    expect(h.actions[1]).toEqual([
      "create",
      { formValues: { name: "New record" } },
    ]);
    expect(h.actions).toHaveLength(2);
  });

  it("guards captured row, page, detail and paging callbacks while the view is busy", async () => {
    const h = setup();
    const captured = h.context();
    h.state.busy = true;
    await flushPromises();
    captured.runAction?.(view.actions[0]);
    const block = view.blocks![0] as FlarePluginRowsBlock;
    captured.run(block.actions[0], block.rows[0], rowInput);
    captured.openRow?.(block.rows[0]);
    captured.loadMore?.("next-page");
    await flushPromises();
    expect(h.actions).toEqual([]);
    expect(h.details).toEqual([]);
    expect(h.loads).toEqual([]);
    expect(
      document.body.querySelector(".flare-danger-confirm, .flare-plugin-form"),
    ).toBeNull();
  });

  it("opts only rows into the growing list region while flow and note-only views keep their natural layout", () => {
    const pagination = { page: 1, pageSize: 10, hasNext: false };
    const flow = setup({ pagination });
    const flowView = flow.wrapper.getComponent(FlarePluginView);
    expect(flowView.classes()).not.toContain("is-list-layout");
    expect(flowView.find(".flare-plugin-view__rows").exists()).toBe(true);
    const note = {
      kind: "note" as const,
      text: "Compact guidance stays above the table",
      tone: "neutral" as const,
    };
    const filled = setup({
      contentLayout: "list",
      pagination,
      view: { ...view, blocks: [note, ...view.blocks!] },
    });
    const filledView = filled.wrapper.getComponent(FlarePluginView);
    expect(filledView.classes()).toContain("is-list-layout");
    const rows = filledView.get(".flare-plugin-view__rows");
    expect(rows.find(".flare-plugin-rows--admin-list").exists()).toBe(true);
    expect(filledView.text()).toContain(note.text);
    expect(rows.text()).not.toContain(note.text);
    const list = rows.getComponent(FlareAdminList);
    expect(rows.findAllComponents(FlareAdminList)).toHaveLength(1);
    expect(list.get(".flare-admin-list__table").element.parentElement).toBe(
      list.get(".flare-admin-list__footer").element.parentElement,
    );
    const noteOnly = setup({
      contentLayout: "list",
      view: {
        available: true,
        title: "Guidance",
        fields: [],
        actions: [],
        blocks: [note],
      },
    });
    const noteView = noteOnly.wrapper.getComponent(FlarePluginView);
    expect(noteView.classes()).not.toContain("is-list-layout");
    expect(noteView.find(".flare-plugin-view__rows").exists()).toBe(false);
    expect(noteView.findComponent(FlareAdminList).exists()).toBe(false);
    expect(noteView.text()).toContain(note.text);

    // Source contracts complement mounted DOM structure; happy-dom does not prove browser heights.
    const viewSource = readFileSync(
      resolve(__dirname, "FlarePluginView.vue"),
      "utf8",
    );
    const rowsSource = readFileSync(
      resolve(__dirname, "plugin/PluginRowsBlock.vue"),
      "utf8",
    );
    const declarations = (source: string, selector: RegExp) =>
      [...source.matchAll(/([^{}]+)\{([^{}]*)\}/g)]
        .filter((rule) => selector.test(rule[1]))
        .map((rule) => rule[2])
        .join(";");
    expect(viewSource).toMatch(
      /\.flare-plugin-view__rows\s*\{[^}]*display:\s*contents/,
    );
    const growingRows = declarations(
      viewSource,
      /\.is-list-layout[^{}]*\.flare-plugin-view__rows/,
    );
    expect(growingRows).toMatch(/flex:\s*1\b/);
    expect(growingRows).toMatch(/min-height:\s*0\b/);
    const adminRows = declarations(
      rowsSource,
      /\.flare-plugin-rows--admin-list/,
    );
    expect(adminRows).toMatch(/flex-direction:\s*column/);
    expect(adminRows).toMatch(/flex:\s*1\b/);
    expect(adminRows).toMatch(/min-height:\s*0\b/);
    expect(viewSource).not.toMatch(
      /\.is-list-layout\s*>\s*\*\s*\{[^}]*flex:\s*1\b/,
    );
  });
});
