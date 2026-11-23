// @vitest-environment happy-dom
// The wallet pages moved from the retired account renderer to plain blocks (hero, stats, section, rows, qr).
// spec/wallet-flow-vectors.json holds the new resolved views; spec/wallet-flow-account-vectors.json the same 44
// samples as the account renderer drew them. Per sample, every piece of information the old view carried must
// still be in the new one, and the new one must need nothing beyond the kit vocabulary.
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import type { FlarePluginPageViewModel } from "../../../shared/contracts/plugin-ui";
import { PLUGIN_UI_VOCABULARY } from "../../../shared/contracts/plugin-ui-vocabulary";
import FlarePluginPage from "../FlarePluginPage.vue";

type Json = null | boolean | number | string | Json[] | { [key: string]: Json };
interface Case { id: string; variant: string; locale: string; page: string; view: Record<string, Json> }
const spec = (name: string) => JSON.parse(readFileSync(resolve(__dirname, "../../../../../../spec", name), "utf8")).cases as Case[];
const before = spec("wallet-flow-account-vectors.json");
const after = spec("wallet-flow-vectors.json");
const key = (c: Case) => `${c.id}/${c.variant}/${c.locale}`;

/** Account-renderer props that only placed things; the plain page draws them in its own frame. */
const LAYOUT_ONLY = new Set([
  "layout", // wallet / ledger / flow arrangement
  "groupByDate", // date headings over ledger rows
  "maskRowAmounts", // the eye toggle over row amounts
  "rowBadgePlacement", // badge beside or under the row title
  "rowEntryAction", // the row's own action, still in the rows block
  "servicesTitle", // heading over the action list
  "informationTitle", // heading over the folded fields
  "shortcutsTitle", // heading over the record shortcuts
]);
/** Account-renderer props that carried copy or values: each must be somewhere in the new view. */
const CONTENT = new Set(["sectionTitle", "description", "stepLabel", "summaryTitle", "contextLabel", "rowBadgeLabel", "amount", "methodLabel"]);
/**
 * The empty state's copy. The page's list now says the empty title itself (it replaces the generic "暂无记录"), and
 * the empty description is a note shown only while the list has no rows, as the account renderer did.
 */
const EMPTY_STATE = new Set(["emptyTitle", "emptyDescription"]);
/** Keys whose strings are machine values (ids, targets, paths), not information a person reads. */
const MACHINE = new Set(["id", "kind", "format", "style", "tone", "target", "command", "continuation", "input", "key", "source", "page", "operation", "value_path", "valuePath", "renderer", "placement", "mode", "slot", "form"]);

/**
 * Copy the wallet contract changed after the account samples were taken: the old string, then what the contract
 * says now (spec/wallet-flow-vectors.json was cross-checked against the Rust contract's pages). The new view must
 * carry one of the current strings in its place.
 */
const CONTRACT_COPY = new Map<string, string[]>([
  ["proofReference", ["proofFile"]],
  // The recharge form uploads the proof now; the history's proof link filter is gone.
  ["付款凭证链接或上传引用", ["上传付款凭证", "付款凭证文件"]],
  ["Payment proof link or upload reference", []],
  ["付款凭证", ["付款凭证文件"]],
  ["Payment proof", ["Payment evidence file"]],
  ["收款账户", ["已添加的收款方式"]],
  ["Payout account", []],
  ["请按渠道说明转账，填写真实付款单号和付款凭证链接或上传引用。审核确认收到款项后入账。", ["请按渠道说明转账，填写真实付款单号并上传付款凭证。审核确认收到款项后入账。"]],
  ["Transfer using the channel instructions and provide the real payment reference and proof link or upload reference. Funds are credited after receipt verification.", []],
  ["充值与提现记录", ["充值记录", "提现记录"]],
  ["Recharge and withdrawal history", ["Recharge history", "Withdrawal history"]],
  ["保存收款资料", ["保存收款方式"]],
  ["Save payout details", ["Save payout method"]],
  ["收款资料", ["收款方式"]],
  ["Payout details", ["Payout methods"]],
  ["确认并支付", ["验证并发送红包"]],
  ["Confirm and pay", ["Verify and send red packet"]],
  ["确认支付", ["支付验证"]],
  ["Confirm payment", ["Payment verification"]],
  ["支付密码连续输错五次将暂时锁定。", []],
  ["Five incorrect attempts temporarily lock payment verification.", []],
  ["设置或修改六位支付密码。忘记密码的身份核验重置暂未开放。", ["设置或修改六位支付密码。密码重置后，原支付授权将失效，请本人重新设置。"]],
  ["Set or change your six-digit payment password. Identity verification for forgotten passwords is not available yet.", []],
  // The checkout pays through the host's payment confirmation: no confirm prompt or password input on the page.
  ["确认前请核对收款钱包、资产、扣款、费用和有效期。", []],
  ["Review the recipient wallet, asset, debit, fees and expiry before confirming.", []],
  ["六位支付密码", []],
  ["Six-digit payment password", []],
]);
/** Every string a person reads in a resolved view (labels, values, copy), presentation excluded. */
function information(node: Json, parent = "", out = new Set<string>()): Set<string> {
  if (typeof node === "string") {
    if (!MACHINE.has(parent) && node.trim()) out.add(node);
  } else if (Array.isArray(node)) {
    for (const item of node) information(item, parent, out);
  } else if (node && typeof node === "object") {
    for (const [k, v] of Object.entries(node)) {
      if (k === "presentation" || MACHINE.has(k)) continue;
      information(v, k, out);
    }
  }
  return out;
}
/** Every string anywhere in the view: what the new samples are searched for. */
function corpus(node: Json, out = new Set<string>()): Set<string> {
  if (typeof node === "string") out.add(node);
  else if (Array.isArray(node)) node.forEach(item => corpus(item, out));
  else if (node && typeof node === "object") Object.values(node).forEach(item => corpus(item, out));
  return out;
}
function actionIds(view: Record<string, Json>): Set<string> {
  const ids = new Set<string>();
  const walk = (node: Json, inActions = false) => {
    if (Array.isArray(node)) node.forEach(item => walk(item, inActions));
    else if (node && typeof node === "object") {
      if (inActions && typeof node.id === "string") ids.add(node.id);
      for (const [k, v] of Object.entries(node)) walk(v, k === "actions" || k === "menuActions" || k === "action");
    }
  };
  walk(view);
  return ids;
}
function blocks(view: Record<string, Json>): Array<Record<string, Json>> {
  const top = (view.blocks ?? []) as Array<Record<string, Json>>;
  return top.flatMap(block => [block, ...((block.blocks ?? []) as Array<Record<string, Json>>)]);
}

enableAutoUnmount(afterEach);

describe("wallet flow vectors with plain blocks", () => {
  it("rewrites every one of the 44 samples, one for one", () => {
    expect(before).toHaveLength(44);
    expect(after.map(key)).toEqual(before.map(key));
  });

  it.each(before.map(c => [key(c), c] as const))("%s keeps every piece of information", (_name, old) => {
    const next = after.find(c => key(c) === key(old))!;
    const have = corpus(next.view);
    const props = ((old.view.presentation as Record<string, Json> | undefined)?.props ?? {}) as Record<string, Json>;
    const rows = (view: Record<string, Json>) => ((view.blocks ?? []) as Array<Record<string, Json>>).filter(b => b.kind === "rows");
    // A list's generic empty text gives way to the page's own empty title.
    const superseded = new Set(typeof props.emptyTitle === "string"
      ? rows(old.view).map(b => b.emptyText).filter((t): t is string => typeof t === "string" && t !== props.emptyTitle)
      : []);
    if (superseded.size) expect(rows(next.view).some(b => b.emptyText === props.emptyTitle)).toBe(true);
    // Changed copy: the current string, or (with no fixed replacement) a different string where the old one was.
    const replaced = (text: string) => {
      const current = CONTRACT_COPY.get(text);
      return current !== undefined && (current.length === 0 || current.some(next => have.has(next)));
    };
    const missing = [...information(old.view)].filter(text => !have.has(text) && !superseded.has(text) && !replaced(text));
    expect(missing, "strings of the old view missing from the new one").toEqual([]);
    const listEmpty = !rows(next.view).some(b => ((b.rows ?? []) as Json[]).length > 0);
    for (const [prop, value] of Object.entries(props)) {
      expect(LAYOUT_ONLY.has(prop) || CONTENT.has(prop) || EMPTY_STATE.has(prop), `unclassified account prop ${prop}`).toBe(true);
      if (typeof value !== "string" || !value.trim()) continue;
      if (CONTENT.has(prop)) expect(have.has(value) || replaced(value), `${prop}: ${value}`).toBe(true);
      // Shown only in the empty state; a populated sample need not carry it.
      if (prop === "emptyDescription" && listEmpty) expect(have.has(value), `${prop}: ${value}`).toBe(true);
      if (prop === "emptyTitle" && listEmpty && rows(next.view).length) expect(have.has(value), `${prop}: ${value}`).toBe(true);
    }
    // The account slots named actions; each must still be offered.
    const slots = ((old.view.presentation as Record<string, Json> | undefined)?.actions ?? {}) as Record<string, string>;
    const ids = actionIds(next.view);
    for (const [slot, id] of Object.entries(slots)) expect(ids.has(id), `${slot} -> ${id}`).toBe(true);
    // The balance fields moved into the head keep their label beside their value.
    for (const field of (old.view.fields ?? []) as Array<{ label: string; value?: string }>) {
      if (!field.value) continue;
      const inFields = ((next.view.fields ?? []) as Array<{ label: string; value?: string }>).some(f => f.label === field.label && f.value === field.value);
      const inHead = blocks(next.view).some(b =>
        (b.kind === "hero" && b.label === field.label && b.value === field.value)
        || (b.kind === "stats" && (b.items as Array<Record<string, Json>>).some(i => i.label === field.label && i.value === field.value)));
      expect(inFields || inHead, `${field.label}: ${field.value}`).toBe(true);
    }
  });

  it.each(after.map(c => [key(c), c] as const))("%s needs only the kit vocabulary", (_name, sample) => {
    const view = sample.view;
    const presentation = view.presentation as Record<string, Json> | undefined;
    if (presentation) {
      expect(["confirm", "checkout"]).toContain(sample.id);
      expect(PLUGIN_UI_VOCABULARY.renderers).toContain(presentation.renderer as string);
    }
    for (const block of blocks(view)) expect(PLUGIN_UI_VOCABULARY.blocks, String(block.kind)).toContain(block.kind as string);
    for (const section of (view.blocks as Array<Record<string, Json>>).filter(b => b.kind === "section")) {
      expect((section.blocks as Array<Record<string, Json>>).every(child => !["section", "rows", "protected-media"].includes(child.kind as string))).toBe(true);
    }
    expect(blocks(view).filter(b => b.kind === "hero").length).toBeLessThanOrEqual(1);
    for (const input of (view.inputs ?? []) as Array<Record<string, Json>>) expect(PLUGIN_UI_VOCABULARY.inputs).toContain(input.kind as string);
  });

  it.each(after.filter(c => c.locale === "zh-CN").map(c => [key(c), c] as const))("%s draws its head without the account appearance", (_name, sample) => {
    const view = structuredClone(sample.view) as unknown as FlarePluginPageViewModel;
    const wrapper = mount(defineComponent({ setup() {
      useFlareI18nProvider("zh-CN");
      // R12: absent appearance is derived from the structure; document turns the derivation off.
      return () => h(FlarePluginPage, { page: { pluginId: "flare.wallet", page: sample.page }, view, appearance: "document" });
    } }), { attachTo: document.body });
    const text = wrapper.text();
    const head = (sample.view.blocks as Array<Record<string, Json>>)[0];
    expect(head.kind).toBe("section");
    expect(text).toContain(head.label as string);
    for (const child of head.blocks as Array<Record<string, Json>>) {
      if (typeof child.text === "string") expect(text).toContain(child.text);
      if (child.kind === "hero") expect(text).toContain(child.value as string);
    }
    wrapper.unmount();
    document.body.innerHTML = "";
  });
});
