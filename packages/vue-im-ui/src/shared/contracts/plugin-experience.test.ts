// The pure plugin page rules of docs/plugin-experience.md against spec/plugin-view-vectors.json.
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import {
  FLARE_PLUGIN_RESULT_POLL_FOR_MS,
  FLARE_PLUGIN_RESULT_POLL_MS,
  flarePluginActionPlaces,
  flarePluginActionRole,
  flarePluginBoundInputs,
  flarePluginCardHead,
  flarePluginCounterShown,
  flarePluginDedupeActions,
  flarePluginDisplayAmount,
  flarePluginDrawnInputs,
  flarePluginFormPlacement,
  flarePluginIsBlockAction,
  flarePluginLoadingFace,
  flarePluginPageAppearanceOf,
  flarePluginPageInlineForm,
  flarePluginResultFacts,
  flarePluginSelectControl,
  flarePluginShowsRefreshKey,
  flarePluginSplitReferences,
  flarePluginStatusCard,
  flarePluginStatusDraw,
  flarePluginTopLevelActions,
  type FlarePluginActionPlaces,
} from "./plugin-experience";
import type { FlarePluginAction, FlarePluginField, FlarePluginPageAppearance, FlarePluginResultBlock, FlarePluginViewModel } from "./plugin-ui";

type Case<T = Record<string, unknown>> = T & { name: string; platforms: string[] };
type View = Partial<FlarePluginViewModel>;
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-view-vectors.json"), "utf8")) as Record<string, Case[]>;
const vue = <T extends Case>(cases: T[]) => cases.filter((c) => c.platforms.includes("vue"));
/** A vector view as the kit gets it: available, titled. */
const viewOf = (view: View): FlarePluginViewModel => ({ available: true, title: "", fields: [], actions: [], ...view } as FlarePluginViewModel);
const ids = (actions: ReadonlyArray<FlarePluginAction>) => actions.map((action) => action.id);

afterEach(() => vi.restoreAllMocks());

describe("display amount (R10)", () => {
  it("swaps only a leading hyphen for the minus sign, never one inside a date or an id", () => {
    expect(flarePluginDisplayAmount("-¥5.00")).toBe("\u2212¥5.00");
    expect(flarePluginDisplayAmount(" -12.30 CNY")).toBe(" \u221212.30 CNY");
    for (const value of ["2026-11-19", "2026-11-19 08:30", "rp-001", "¥5.00", "+¥5.00", "-", "-abc"])
      expect(flarePluginDisplayAmount(value)).toBe(value);
  });
});

describe("actionRoles (R2)", () => {
  type Expect = { archetype: string; places: Record<string, unknown>; roles?: Record<string, string>; chevron?: string[] };
  it.each(vue(vectors.actionRoles as Case<{ embedded: boolean; inlineFormActionId?: string; view: View; expect: Expect }>[]).map((c) => [c.name, c] as const))("%s", (_, c) => {
    const view = viewOf(c.view);
    const places = flarePluginActionPlaces(view, { embedded: c.embedded, inlineFormActionId: c.inlineFormActionId });
    expect(places.archetype).toBe(c.expect.archetype);
    const keys = ["quick", "list", "bar", "barSecondary", "more", "header", "commands", "danger", "footer", "menu"] as const;
    for (const key of keys) {
      const expected = c.expect.places[key];
      if (key === "list") {
        expect(places.list.map((group) => ({ group: group.group, ids: ids(group.actions) }))).toEqual(expected ?? []);
      } else {
        expect(ids(places[key] as FlarePluginAction[]), key).toEqual(expected ?? []);
      }
    }
    const all = [...view.actions, ...(view.menuActions ?? [])];
    for (const [id, role] of Object.entries(c.expect.roles ?? {})) expect(flarePluginActionRole(all.find((a) => a.id === id)!), id).toBe(role);
    if (c.expect.chevron) {
      const listed = places.list.flatMap((group) => group.actions);
      expect(ids(listed.filter((action) => flarePluginActionRole(action) === "destination"))).toEqual(c.expect.chevron);
    }
  });
});

describe("statusValues (R3)", () => {
  type Expect = { draw: "tag" | "text"; text?: string; tone?: string; unknown?: boolean; warn?: boolean };
  it.each(vue(vectors.statusValues as Case<{ where: string; item: Record<string, unknown>; expect: Expect }>[]).map((c) => [c.name, c] as const))("%s", (_, c) => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => undefined);
    const drawn = flarePluginStatusDraw(c.item as never, `vector:${c.name}`);
    expect(drawn.draw).toBe(c.expect.draw);
    if (c.expect.unknown) {
      expect(drawn.unknown).toBe(true);
      expect(drawn.text).toBe("");
    } else expect(drawn.text).toBe(c.expect.text);
    if (c.expect.tone) expect(drawn.tone).toBe(c.expect.tone);
    expect(warn).toHaveBeenCalledTimes(c.expect.warn ? 1 : 0);
  });
});

describe("references (R3)", () => {
  it.each(vue(vectors.references as Case<{ fields: FlarePluginField[]; expect: { main: string[]; references: string[] } }>[]).map((c) => [c.name, c] as const))("%s", (_, c) => {
    const split = flarePluginSplitReferences(c.fields);
    expect(split.main.map((f) => f.label)).toEqual(c.expect.main);
    expect(split.references.map((f) => f.label)).toEqual(c.expect.references);
  });
});

describe("blockBoundInputs (R6.1)", () => {
  type Expect = { formFields: string[]; topLevel: string[]; blockActions: string[]; inlineFormActionId: string | null };
  it.each(vue(vectors.blockBoundInputs as Case<{ view: View; expect: Expect }>[]).map((c) => [c.name, c] as const))("%s", (_, c) => {
    const view = viewOf(c.view);
    const bound = flarePluginBoundInputs(view);
    const top = flarePluginTopLevelActions(view, true);
    expect([...new Set(top.flatMap((action) => flarePluginDrawnInputs(action, bound)))]).toEqual(c.expect.formFields);
    expect(ids(top)).toEqual(c.expect.topLevel);
    expect(ids(view.actions.filter((action) => flarePluginIsBlockAction(action, bound)))).toEqual(c.expect.blockActions);
    expect(flarePluginPageInlineForm(view) ?? null).toBe(c.expect.inlineFormActionId);
  });
});

describe("cardHeader (R5)", () => {
  type Card = { detail: boolean; footerActions: number; menuActions: number; expect: { order: string[]; detailInFooter?: boolean } };
  it.each(vue(vectors.cardHeader as Case<Card>[]).map((c) => [c.name, c] as const))("%s", (_, c) => {
    const head = flarePluginCardHead(c);
    expect(head.order).toEqual(c.expect.order);
    expect(head.detailInFooter).toBe(Boolean(c.expect.detailInFooter));
  });
});

describe("refreshKey (R1)", () => {
  it.each(vue(vectors.refreshKey as Case<{ view: View; inlineFormActionId?: string; expect: boolean }>[]).map((c) => [c.name, c] as const))("%s", (_, c) => {
    expect(flarePluginShowsRefreshKey(viewOf(c.view), c.inlineFormActionId)).toBe(c.expect);
  });
});

describe("accountDerivation (R12)", () => {
  it.each(vue(vectors.accountDerivation as Case<{ appearance: FlarePluginPageAppearance | null; view: View; expect: string }>[]).map((c) => [c.name, c] as const))("%s", (_, c) => {
    expect(flarePluginPageAppearanceOf(viewOf(c.view), c.appearance ?? undefined)).toBe(c.expect);
  });
});

describe("forms (R6)", () => {
  it.each(vue(vectors.formPlacement as Case<{ inputs: string[]; inline: boolean; expect: string }>[]).map((c) => [c.name, c] as const))("formPlacement: %s", (_, c) => {
    expect(flarePluginFormPlacement(c.inputs, c.inline)).toBe(c.expect);
  });
  it.each(vue(vectors.formCounter as Case<{ maxLength: number | null; length: number; expect: boolean }>[]).map((c) => [c.name, c] as const))("formCounter: %s", (_, c) => {
    expect(flarePluginCounterShown(c.maxLength, c.length)).toBe(c.expect);
  });
  it.each(vue(vectors.selectOptions as Case<{ choices: number; expect: { control: string; disabled: boolean; submitDisabled: boolean } }>[]).map((c) => [c.name, c] as const))("selectOptions: %s", (_, c) => {
    const rule = flarePluginSelectControl(c.choices);
    expect(rule.control).toBe(c.expect.control);
    expect(rule.disabled).toBe(c.expect.disabled);
    expect(rule.disabled).toBe(c.expect.submitDisabled);
  });
});

describe("actionDedupe (R9)", () => {
  it.each(vue(vectors.actionDedupe as Case<{ actions: FlarePluginAction[]; expect: { drawn: string[]; warn: boolean } }>[]).map((c) => [c.name, c] as const))("%s", (_, c) => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => undefined);
    expect(ids(flarePluginDedupeActions(c.actions).drawn)).toEqual(c.expect.drawn);
    expect(warn.mock.calls.length > 0).toBe(c.expect.warn);
  });
});

describe("result (R7)", () => {
  type Expect = { icon: string; tone: string; title?: string; amount?: string; description?: string; unknown?: boolean; poll: boolean; pollMs?: number; pollForMs?: number; announce?: string; warn?: boolean };
  it.each(vue(vectors.result as Case<{ block: FlarePluginResultBlock; expect: Expect }>[]).map((c) => [c.name, c] as const))("%s", (_, c) => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => undefined);
    const facts = flarePluginResultFacts(c.block, "未知状态");
    expect(facts.icon).toBe(c.expect.icon);
    expect(facts.tone).toBe(c.expect.tone);
    expect(facts.unknown).toBe(Boolean(c.expect.unknown));
    expect(facts.title).toBe(c.expect.unknown ? "未知状态" : c.expect.title);
    expect(facts.amount).toBe(c.expect.amount);
    expect(facts.description).toBe(c.expect.description);
    expect(facts.poll).toBe(c.expect.poll);
    if (c.expect.pollMs) expect(FLARE_PLUGIN_RESULT_POLL_MS).toBe(c.expect.pollMs);
    if (c.expect.pollForMs) expect(FLARE_PLUGIN_RESULT_POLL_FOR_MS).toBe(c.expect.pollForMs);
    if (c.expect.announce) expect(facts.announce).toBe(c.expect.announce);
    expect(warn.mock.calls.length > 0).toBe(Boolean(c.expect.warn));
  });
});

describe("pageStates first load (R8)", () => {
  const loading = vue(vectors.pageStates as Case<{ loading: boolean; elapsedMs?: number; view: unknown; expect: { state: string; skeleton?: string; rows?: number } }>[])
    .filter((c) => c.loading && c.view === null);
  it.each(loading.map((c) => [c.name, c] as const))("%s", (_, c) => {
    expect(flarePluginLoadingFace(c.elapsedMs ?? 0)).toEqual(c.expect);
  });
});

describe("statusCard (6.1)", () => {
  it.each(vue(vectors.statusCard as Case<{ view: View; expect: boolean }>[]).map((c) => [c.name, c] as const))("%s", (_, c) => {
    expect(flarePluginStatusCard(viewOf(c.view))).toBe(c.expect);
  });
});

it("places carry no action twice and lose none (every archetype)", () => {
  for (const c of vue(vectors.actionRoles as Case<{ embedded: boolean; inlineFormActionId?: string; view: View }>[])) {
    const view = viewOf(c.view);
    const places: FlarePluginActionPlaces = flarePluginActionPlaces(view, { embedded: c.embedded, inlineFormActionId: c.inlineFormActionId });
    const drawn = [...places.quick, ...places.list.flatMap((g) => g.actions), ...places.bar, ...places.barSecondary, ...places.more,
      ...places.header, ...places.commands, ...places.danger, ...places.footer, ...places.menu];
    expect(new Set(ids(drawn)).size, c.name).toBe(drawn.length);
    expect(ids(drawn).sort(), c.name).toEqual([...ids(view.actions), ...ids(view.menuActions ?? [])].sort());
  }
});
