// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, reactive } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import { useFlareAdaptiveProvider } from "../../../composables/useAdaptiveMode";
import type { FlarePluginActionPayload, FlarePluginFormError, FlarePluginPageActionPayload, FlarePluginPageViewModel } from "../../../shared/contracts/plugin-ui";
import FlareAccountView from "./FlareAccountView.vue";
import FlarePluginPage from "../FlarePluginPage.vue";
import FlarePluginView from "../FlarePluginView.vue";
import { flareAccountDayKey, flareAccountEntries } from "./account";
const fixture = JSON.parse(readFileSync(resolve(__dirname, "../../../../../../spec/account-view-vectors.json"), "utf8"));
const walletCases = JSON.parse(readFileSync(resolve(__dirname, "../../../../../../spec/wallet-flow-account-vectors.json"), "utf8")).cases as Array<{id: string; variant: string; locale: string; view: FlarePluginPageViewModel}>;
const scopedCases = JSON.parse(readFileSync(resolve(__dirname, "../../../../../../spec/wallet-scoped-history-vectors.json"), "utf8")).cases as Array<{variant: string; locale: string; sourceData: {walletId: string; walletContext: string}; view: FlarePluginPageViewModel}>;
const cashflowCases = JSON.parse(readFileSync(resolve(__dirname, "../../../../../../spec/wallet-cashflow-vectors.json"), "utf8")).cases as Array<{id: string; variant: string; locale: string; view: FlarePluginPageViewModel}>;
const cashflow = (id: string, variant: string, locale = "zh-CN") => structuredClone(cashflowCases.find(item => item.id === id && item.variant === variant && item.locale === locale)!.view);
const wallet = (id: string, variant = "default") => structuredClone(walletCases.find(item => item.id === id && item.variant === variant && item.locale === "zh-CN")!.view);
const model = (): FlarePluginPageViewModel => structuredClone(fixture.view);
enableAutoUnmount(afterEach);
afterEach(() => { document.body.innerHTML = ""; });
function render(view = model(), page = false) {
  const actions: Array<[string, FlarePluginActionPayload | FlarePluginPageActionPayload]> = [];
  const state = reactive({ error: undefined as string | undefined, settleToken: 0, busyActionId: undefined as string | undefined, formErrors: [] as FlarePluginFormError[] });
  const wrapper = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => page ? h(FlarePluginPage, { page: { pluginId: "example", page: "wallet" }, view, appearance: "account", actionError: state.error, settleToken: state.settleToken, busyActionId: state.busyActionId, formErrors: state.formErrors, onAction: (id, payload) => actions.push([id, payload]) }) : h(FlareAccountView, { view, ...state, onAction: (id, payload) => actions.push([id, payload]) });
  } }), { attachTo: document.body });
  return { wrapper, actions, state };
}
function button(label: string): HTMLButtonElement { return [...document.body.querySelectorAll("button")].find(button => button.textContent?.trim() === label)!; }
describe("account presentation", () => {
  it("forwards member and file intents without inventing host capabilities", async () => {
    const view = wallet("payout_profiles");
    view.presentation!.props.formTitle = "添加收款方式";
    const searches: string[] = [], files: unknown[] = [];
    let retries = 0;
    const wrapper = mount(FlareAccountView, {props: {view, onAction: () => {},
      onMemberSearch: (query: string) => searches.push(query), onMembersRetry: () => { retries++; },
      onFileAction: event => files.push(event)}});
    const inner = wrapper.findAllComponents(FlarePluginView).find(child => child.props("onMemberSearch"));
    expect(inner).toBeDefined();
    inner!.props("onMemberSearch")!("account-or-nickname");
    inner!.props("onMembersRetry")!();
    const event = {inputId: "receipt", action: "preview", generation: 3, scope: "opaque-scope", formValues: {kind: "bank"}};
    inner!.vm.$emit("fileAction", event);
    expect(searches).toEqual(["account-or-nickname"]);
    expect(retries).toBe(1);
    expect(files).toEqual([event]);
    expect(wrapper.emitted("memberSearch")).toEqual([["account-or-nickname"]]);
    expect(wrapper.emitted("membersRetry")).toEqual([[]]);
    expect(wrapper.emitted("fileAction")![0][0]).toBe(event);
    const local = mount(FlareAccountView, {props: {view, onAction: () => {}}});
    for (const child of local.findAllComponents(FlarePluginView)) {
      expect(child.props("onMemberSearch")).toBeUndefined();
      expect(child.props("onMembersRetry")).toBeUndefined();
    }
  });

  it.each(["recharge", "withdrawal", "payout_profiles"])("renders the final Rust-resolved %s form without submitting it", id => {
    const view = cashflow(id, "available");
    const {wrapper, actions} = render(view, true);
    expect(wrapper.get("[data-inline-form-heading]").text()).toContain(view.presentation!.props.formTitle);
    expect(wrapper.findAll("[data-form-submit]")).toHaveLength(1);
    expect(actions).toEqual([]);
  });
  it.each(["recharge", "withdrawal"])("keeps one explicit unavailable reason and a history path for %s", id => {
    const view = cashflow(id, "no_channel", "en-US");
    const {wrapper} = render(view, true);
    expect(wrapper.text().split("No channel is available for new requests. Existing records remain available.")).toHaveLength(2);
    expect(wrapper.find("[data-flow-form-unavailable]").exists()).toBe(false);
    expect(wrapper.find("[data-form-submit]").exists()).toBe(false);
    expect(wrapper.find('[data-action-id="history"]').exists()).toBe(true);
  });
  it.each(["pending", "unknown", "succeeded", "failed"])("preserves the contract's %s result and exact economics", variant => {
    const view = cashflow("cashflow_detail", variant);
    const {wrapper, actions} = render(view, true);
    expect(wrapper.get("[data-flow-result]").classes()).toContain(`flare-status-banner--${view.presentation!.props.resultTone}`);
    for (const amount of ["100.00", "1.00", "99.00"]) expect(wrapper.text()).toContain(amount);
    expect(actions).toEqual([]);
  });
  it("keeps legacy recovery read-only and displays a recorded rejection truthfully", () => {
    const legacy = cashflow("cashflow_recovery", "legacy_unknown");
    const {wrapper: legacyWrapper, actions: legacyActions} = render(legacy, true);
    expect(legacyWrapper.find('[data-action-id="observe"]').exists()).toBe(true);
    expect(legacyWrapper.find('[data-action-id="retry"]').exists()).toBe(false);
    expect(legacyActions).toEqual([]);
    const {wrapper, actions} = render(cashflow("cashflow_recovery", "known_rejection"), true);
    expect(wrapper.text()).toContain("原操作被拒绝");
    expect(wrapper.text()).toContain("FEATURE_DISABLED");
    expect(wrapper.find("[data-form-submit]").exists()).toBe(false);
    expect(actions).toEqual([]);
  });
  it.each(["warning", "danger"] as const)("keeps a declared %s status instead of a duplicate unavailable hint", tone => {
    const view = wallet("payout_profiles");
    view.presentation!.props.formTitle = "添加收款方式";
    view.presentation!.props.formUnavailableDescription = "通用不可提交提示";
    view.actions = []; view.menuActions = [];
    view.blocks = [...view.blocks!, {kind: "status", label: "服务状态", text: "暂无可用渠道", tone}];
    const {wrapper} = render(view);
    expect(wrapper.text()).toContain("暂无可用渠道");
    expect(wrapper.find("[data-flow-form-unavailable]").exists()).toBe(false);
    expect(wrapper.find("[data-flow-result]").exists()).toBe(false);
  });
  it.each(["info", "neutral", "success", "blank-warning", "warning-note"])("keeps the unavailable hint independent of %s", kind => {
    const view = wallet("payout_profiles");
    view.presentation!.props.formTitle = "添加收款方式";
    view.presentation!.props.formUnavailableDescription = "通用不可提交提示";
    view.actions = []; view.menuActions = [];
    if (kind === "warning-note") view.blocks = [...view.blocks!, {kind: "note", text: "普通提示", tone: "warning"}];
    else view.blocks = [...view.blocks!, {kind: "status", text: kind === "blank-warning" ? "  " : "现有状态", tone: kind === "blank-warning" ? "warning" : kind as "info" | "neutral" | "success"}];
    const {wrapper} = render(view);
    expect(wrapper.get("[data-flow-form-unavailable]").text()).toBe("通用不可提交提示");
  });
  it("explains a removed form action without inventing the reason or hiding records", () => {
    const view = wallet("payout_profiles");
    view.presentation!.props.formTitle = "添加收款方式";
    view.presentation!.props.formUnavailableDescription = "当前暂不可提交申请，已有记录仍可查看。";
    view.actions = [];
    view.menuActions = [];
    const {wrapper} = render(view);
    expect(wrapper.get("[data-flow-form-unavailable]").text()).toBe("当前暂不可提交申请，已有记录仍可查看。");
    expect(wrapper.get("[data-flow-form-unavailable]").classes()).toContain("flare-status-banner--neutral");
    expect(wrapper.find("[data-inline-action-form]").exists()).toBe(false);
  });
  it.each(["result", "primary", "blank-title"])("does not add a redundant unavailable banner for %s", reason => {
    const view = wallet("withdrawal_authorization", "prepared");
    view.presentation!.props.formTitle = reason === "blank-title" ? "  " : "验证支付密码";
    view.presentation!.props.formUnavailableDescription = "不可提交";
    if (reason !== "primary") { view.actions = []; view.menuActions = []; }
    if (reason === "result") view.presentation!.props.resultDescription = "功能已关闭";
    const {wrapper} = render(view);
    expect(wrapper.find("[data-flow-form-unavailable]").exists()).toBe(false);
  });
  it("does not render an inline form when the page has no host action handler", () => {
    const view = wallet("payout_profiles");
    view.presentation!.props.formTitle = "添加收款方式";
    const wrapper = mount(defineComponent({setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlarePluginPage, {page: {pluginId: "example", page: "wallet"}, view, appearance: "account"});
    }}), {attachTo: document.body});
    expect(wrapper.find("[data-inline-action-form]").exists()).toBe(false);
    expect(wrapper.find("[data-inline-form-heading]").exists()).toBe(false);
  });
  it("places the declared form heading after existing methods without changing the form runner", async () => {
    const view = wallet("payout_profiles");
    view.presentation!.props.formTitle = "添加收款方式";
    view.presentation!.props.formDescription = "核对资料后保存，审核通过后可用于提现。";
    const block = view.blocks!.find(block => block.kind === "rows")!;
    if (block.kind !== "rows") throw new Error("Missing profile rows");
    block.rows = [{key: "existing-profile", cells: [{text: "银行卡"}, {text: "原户名"}, {text: "****1234"}, {text: "已通过"}], actions: []}];
    const {wrapper, actions, state} = render(view, true);
    const heading = wrapper.get("[data-inline-form-heading]");
    expect(heading.text()).toContain("添加收款方式");
    expect(heading.text()).toContain("核对资料后保存");
    const record = wrapper.get('[data-row-key="existing-profile"]').element;
    expect(Boolean(record.compareDocumentPosition(heading.element) & Node.DOCUMENT_POSITION_FOLLOWING)).toBe(true);
    expect(wrapper.findAll('[data-form-submit]')).toHaveLength(1);
    expect(wrapper.find('[data-form-cancel]').exists()).toBe(false);
    const name = wrapper.get<HTMLInputElement>('[data-input-id="accountName"] input');
    await name.setValue("保留草稿");
    state.busyActionId = "another-action";
    await flushPromises();
    expect(name.element.value).toBe("保留草稿");
    expect(actions).toEqual([]);
  });
  it.each(["success", "warning", "danger", "info", "neutral", "unknown"])("renders only the declared result with safe %s tone", tone => {
    const view = wallet("result");
    view.presentation!.props.resultTitle = "申请状态";
    view.presentation!.props.resultDescription = "请以实际处理状态为准。";
    view.presentation!.props.resultTone = tone;
    const {wrapper, actions} = render(view);
    const result = wrapper.get("[data-flow-result]");
    expect(result.text()).toContain("申请状态");
    expect(result.text()).toContain("请以实际处理状态为准。");
    expect(result.classes()).toContain(`flare-status-banner--${tone === "unknown" ? "neutral" : tone}`);
    expect(result.text()).not.toContain("到账成功");
    expect(actions).toEqual([]);
  });
  it("keeps password verification on its guarded sheet even when a form heading is declared", () => {
    const view = wallet("withdrawal_authorization", "prepared");
    view.presentation!.props.formTitle = "验证支付密码";
    const {wrapper} = render(view);
    expect(wrapper.find("[data-inline-form-heading]").exists()).toBe(false);
    expect(wrapper.find("[data-inline-action-form]").exists()).toBe(false);
    expect(wrapper.get('[data-action-id="authorize"]').text()).toBe("验证支付密码");
  });
  it("keeps the wallet name when the row also has a status badge", () => {
    const view = wallet("home");
    const block = view.blocks!.find(block => block.kind === "rows")!;
    if (block.kind !== "rows") throw new Error("Missing wallet rows");
    block.rows[0].badge = {text: "正常", tone: "success"};
    const {wrapper} = render(view);
    expect(wrapper.get(".flare-account-view__wallet-card-heading strong").text()).toBe(block.rows[0].cells[1].text);
  });
  it("retains local wallet details when the page has no host action listener", async () => {
    const view = wallet("home");
    const wrapper = mount(defineComponent({setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlarePluginPage, {page: {pluginId: "example", page: "wallet"}, view, appearance: "account"});
    }}), {attachTo: document.body});
    expect(wrapper.find(".flare-account-view__wallet-card-link").exists()).toBe(false);
    await wrapper.get("[data-wallet-card]").trigger("click");
    await flushPromises();
    expect(document.body.querySelector('[role="dialog"]')).not.toBeNull();
  });
  it("keeps a hidden wallet balance masked in the local detail and exposes the toggle state", async () => {
    const view = wallet("home");
    view.presentation!.props.rowEntryAction = undefined;
    const {wrapper} = render(view);
    const toggle = wrapper.get('button[aria-label="隐藏余额"]');
    expect(toggle.attributes("aria-pressed")).toBe("false");
    await toggle.trigger("click");
    expect(wrapper.get('button[aria-label="显示余额"]').attributes("aria-pressed")).toBe("true");
    await wrapper.get("[data-wallet-card]").trigger("click");
    await flushPromises();
    expect(document.body.querySelector('[role="dialog"] .flare-account-view__detail-amount')?.textContent).toBe("••••");
  });
  it("draws the wallet's slot primaries as solid quick keys in the overview card and a danger action in its own card (R2.1)", async () => {
    const view = wallet("home");
    view.actions = [{id:"danger",label:"关闭钱包",style:"danger"}, {id:"recharge",label:"充值",style:"primary",target:{kind:"page",page:"recharge"}}, {id:"withdraw",label:"提现",style:"primary",target:{kind:"page",page:"withdrawal"}}];
    view.menuActions = [];
    view.presentation!.actions = {primary:"recharge",secondary:"withdraw",tertiary:"danger"};
    const {wrapper, actions} = render(view);
    const quick = wrapper.findAll('[data-overview-card] [data-place="quick"] [data-action-id]');
    expect(quick.map(node => [node.attributes("data-action-id"), node.attributes("data-action-variant")])).toEqual([["recharge","primary"],["withdraw","primary"]]);
    const danger = wrapper.get('.flare-account-view__navigation [data-place="danger"] [data-action-id="danger"]');
    expect(wrapper.find('[data-overview-card] [data-action-id="danger"]').exists()).toBe(false);
    // §12.3: a danger row always asks first, with no confirm text declared.
    await danger.trigger("click");
    await flushPromises();
    expect(actions).toEqual([]);
    expect(document.body.querySelector('[role="dialog"], [role="alertdialog"]')).not.toBeNull();
  });
  it("puts grouped destinations into titled list cards with their icons (R2.1)", () => {
    const view = wallet("home");
    view.actions = [{id:"recharge",label:"充值",style:"primary",target:{kind:"page",page:"recharge"}}, {id:"history",label:"交易记录",group:"common",icon:"clock",target:{kind:"page",page:"history"}}, {id:"security",label:"支付密码",group:"records",icon:"lock",target:{kind:"page",page:"security"}}];
    view.menuActions = [];
    view.presentation!.actions = {primary:"recharge"};
    const {wrapper} = render(view);
    const lists = wrapper.findAll('.flare-account-view__navigation [data-place="list"]');
    expect(lists.map(node => [node.attributes("data-group"), node.get("h2").text()])).toEqual([["common","常用"],["records","记录与设置"]]);
    expect(lists[0].find('[data-action-id="history"] .flare-settings__ico').exists()).toBe(true);
  });
  it("draws the setup state with no account: no balance, no slot keys, the opening key and its progress key (§5.2)", async () => {
    const view = wallet("home");
    const rows = view.blocks!.find(block => block.kind === "rows")!;
    if (rows.kind !== "rows") throw new Error("Missing wallet rows");
    rows.rows = [];
    const {wrapper, actions} = render(view);
    const setup = wrapper.get("[data-account-setup]");
    expect(setup.get("h2").text()).toBe("开通钱包");
    expect(setup.text()).toContain("开通后可充值、提现、收付款和查看账单");
    expect(wrapper.find("[data-account-balance]").exists()).toBe(false);
    expect(wrapper.find('[data-action-id="recharge"]').exists()).toBe(false);
    expect(wrapper.find('[data-action-id="withdrawal"]').exists()).toBe(false);
    expect(setup.get('[data-action-id="create"]').attributes("data-action-variant")).toBe("primary");
    const progress = setup.get('[data-action-id="openings"]');
    expect(wrapper.findAll('[data-action-id="openings"]')).toHaveLength(1);
    await progress.trigger("click");
    expect(actions).toEqual([["openings", {}]]);
  });
  it("opens a wallet's declared ledger directly with its exact opaque input", async () => {
    const view = wallet("home");
    view.presentation!.props.rowEntryAction = "wallet";
    const block = view.blocks!.find(block => block.kind === "rows")!;
    if (block.kind !== "rows") throw new Error("Missing wallet rows");
    block.actions = [{id: "wallet", label: "查看明细"}];
    block.rows[0].actions = [{id: "wallet", input: {walletId: "opaque-wallet", assetId: "kept-asset"}}];
    const {wrapper, actions, state} = render(view, true);
    expect(wrapper.get("[data-wallet-card]").text()).toContain("查看明细");
    await wrapper.get("[data-wallet-card]").trigger("click");
    expect(actions).toEqual([["wallet", {page: {pluginId: "example", page: "wallet"}, row: {key: block.rows[0].key, input: {walletId: "opaque-wallet", assetId: "kept-asset"}}}]]);
    expect(document.body.querySelector('[role="dialog"]')).toBeNull();
    state.busyActionId = "other";
    await flushPromises();
    expect(wrapper.get("[data-wallet-card]").text()).toContain("查看明细");
    await wrapper.get("[data-wallet-card]").trigger("click");
    expect(actions).toHaveLength(1);
  });
  it.each(["confirmation", "form", "read-only", "missing-action"])("keeps a wallet card on the guarded detail path for %s", async reason => {
    const view = wallet("home");
    view.presentation!.props.rowEntryAction = "wallet";
    const block = view.blocks!.find(block => block.kind === "rows")!;
    if (block.kind !== "rows") throw new Error("Missing wallet rows");
    block.actions = [{id: "wallet", label: "查看明细", ...(reason === "confirmation" ? {confirm: "确认"} : {}), ...(reason === "form" ? {form: ["password"]} : {})}];
    if (reason === "read-only") view.unavailableReason = "unbound_copy";
    if (reason === "missing-action") block.actions = [];
    const {wrapper, actions} = render(view);
    expect(wrapper.get("[data-wallet-card]").find(".flare-account-view__wallet-card-link").exists()).toBe(false);
    await wrapper.get("[data-wallet-card]").trigger("click");
    await flushPromises();
    expect(actions).toEqual([]);
    expect(document.body.querySelector('[role="dialog"]')).not.toBeNull();
  });
  it("renders visible shortcut slots once before account services and retains the original runner", async () => {
    const view = wallet("home");
    view.presentation!.props.shortcutsTitle = "账单与记录";
    view.presentation!.actions = {...view.presentation!.actions, shortcutPrimary: "records", shortcutSecondary: "records", shortcutTertiary: "hidden"};
    view.actions = [...view.actions, {id: "records", label: "全部交易", form: ["query"]}];
    view.inputs = [...(view.inputs ?? []), {id: "query", kind: "text", label: "查询"}];
    const {wrapper, actions} = render(view, true);
    expect(wrapper.findAll('.flare-account-view__shortcuts [data-action-id="records"]')).toHaveLength(1);
    expect(wrapper.find('.flare-account-view__navigation [data-action-id="records"]').exists()).toBe(false);
    expect(wrapper.find('[data-action-id="hidden"]').exists()).toBe(false);
    const shortcuts = wrapper.get(".flare-account-view__shortcuts").element;
    const services = wrapper.get(".flare-account-view__navigation").element;
    expect(Boolean(shortcuts.compareDocumentPosition(services) & Node.DOCUMENT_POSITION_FOLLOWING)).toBe(true);
    await wrapper.get('.flare-account-view__shortcuts [data-action-id="records"]').trigger("click");
    await flushPromises();
    expect(actions).toEqual([]);
    expect(document.body.querySelector(".flare-plugin-form input")).not.toBeNull();
  });
  it("shows the server's ledger scope without inventing a balance", () => {
    const view = wallet("history");
    view.presentation!.props.contextLabel = "旅行钱包 · USD · cash";
    const {wrapper} = render(view);
    expect(wrapper.get(".flare-account-view__context").text()).toBe("旅行钱包 · USD · cash");
    expect(wrapper.find("[data-account-balance]").exists()).toBe(false);
  });
  it.each(scopedCases)("retains the server scope and detail binding in $variant/$locale", async ({view, sourceData}) => {
    const block = view.blocks!.find(block => block.kind === "rows")!;
    if (block.kind !== "rows") throw new Error("Missing history rows");
    const bound = block.rows[0].actions[0];
    const {wrapper, actions} = render({...view, data: sourceData}, true);
    expect(wrapper.get(".flare-account-view__context").text()).toBe(sourceData.walletContext);
    expect(wrapper.find("[data-account-balance]").exists()).toBe(false);
    await wrapper.get("[data-account-entry]").trigger("click");
    expect(actions).toEqual([[bound.id, {page: {pluginId: "example", page: "wallet"}, data: sourceData, row: {key: block.rows[0].key, input: bound.input}}]]);
    expect(bound.input).toMatchObject({walletId: sourceData.walletId});
    const manage = view.actions.find(action => action.id === "manageWallet")!;
    // Page actions retain their declarative binding; the SDK resolves it from
    // the original data carried by the page payload, never from Kit guesses.
    expect(manage).toMatchObject({input: {walletId: "/walletId"}, target: {kind: "page", page: "flare.wallet.page.wallet"}});
    await wrapper.get('[data-action-id="manageWallet"]').trigger("click");
    expect(actions[1]).toEqual(["manageWallet", {page: {pluginId: "example", page: "wallet"}, data: sourceData}]);
  });
  it("keeps server display amounts and bound row identities intact", () => {
    const entries = flareAccountEntries(model());
    expect(entries.map(entry => entry.amount)).toEqual(fixture.expect.amounts);
    expect(entries.map(entry => entry.key)).toEqual(fixture.expect.entryKeys);
    const view = model(); const block = view.blocks!.find(block => block.kind === "rows")!;
    if (block.kind === "rows") block.rows = [...block.rows, block.rows[0]];
    expect(flareAccountEntries(view)).toHaveLength(fixture.expect.amounts.length);
    expect(flareAccountDayKey(Number.NaN)).toBe("unknown");
    expect(flareAccountDayKey()).toBe("unknown");
  });
  it("separates a hidden balance from visible transaction amounts", async () => {
    const { wrapper } = render();
    expect(wrapper.get("[data-account-balance]").text()).toBe("¥1,288.66");
    await wrapper.get('button[aria-label="隐藏余额"]').trigger("click");
    expect(wrapper.get("[data-account-balance]").text()).toBe("••••");
    expect(wrapper.get(".flare-account-view__balance").text()).not.toContain("¥1,288.66");
    expect(wrapper.text()).toContain("+¥88.88");
    expect(wrapper.find("[data-account-information]").exists()).toBe(true);
    expect(document.body.querySelector("[data-account-information-panel]")).toBeNull();
  });
  it("opens record details even without a packet action, and never invents funding controls", async () => {
    const { wrapper, actions } = render();
    await wrapper.get('[data-account-entry="tx-04"]').trigger("click");
    await flushPromises();
    expect(document.body.textContent).toContain("交易详情");
    expect(document.body.textContent).toContain("tx-04");
    expect(actions).toHaveLength(0);
    expect([...document.body.querySelectorAll('[role="dialog"] button')].some(node => node.textContent?.includes("查看红包"))).toBe(false);
    expect(wrapper.text()).not.toContain("提现");
    expect(wrapper.text()).not.toContain("充值");
  });
  it("forwards the original row input and page data when opening its packet", async () => {
    const view = { ...model(), data: { opaque: "kept" } };
    const { wrapper, actions } = render(view, true);
    await wrapper.get('[data-account-entry="tx-01"]').trigger("click");
    await flushPromises();
    button("查看红包").click();
    await flushPromises();
    expect(actions).toEqual([["open", { page: { pluginId: "example", page: "wallet" }, data: { opaque: "kept" }, row: { key: "tx-01", input: { packetId: "packet-01" } } }]]);
  });
  it("shows an honest empty ledger without changing the balance", () => {
    const view = model(); view.blocks = [];
    const { wrapper } = render(view);
    expect(wrapper.text()).toContain("暂无交易记录");
    expect(wrapper.get("[data-account-balance]").text()).toBe("¥1,288.66");
  });
  it("uses the declared account section in wallet details instead of calling a wallet a transaction", async () => {
    const view = model();
    view.presentation = {renderer: "account", props: {sectionTitle: "我的钱包", groupByDate: false}, actions: {}};
    const { wrapper } = render(view);
    await wrapper.get('[data-account-entry="tx-04"]').trigger("click");
    await flushPromises();
    const dialog = document.body.querySelector('[role="dialog"]')!;
    expect(dialog.textContent).toContain("我的钱包");
    expect(dialog.textContent).toContain("记录编号");
    expect(dialog.textContent).not.toContain("交易单号");
  });
  it("does not render account contents for an unavailable page", () => {
    const { wrapper } = render({ ...model(), available: false, unavailableReason: "no_permission" }, true);
    expect(wrapper.find(".flare-account-view").exists()).toBe(false);
    expect(wrapper.text()).not.toContain("¥1,288.66");
    const direct = render({ ...model(), available: false, unavailableReason: "no_permission" }).wrapper;
    expect(direct.find("[data-account-balance]").exists()).toBe(false);
    expect(direct.find("[data-account-entry]").exists()).toBe(false);
  });
  it("groups only visible declared funding actions and leaves metadata inside account information", async () => {
    const view = wallet("home");
    const { wrapper } = render(view);
    // R2.1: the two primaries are the quick keys; the destination (收款方式) joins the list.
    expect(wrapper.findAll('[data-overview-card] [data-place="quick"] [data-action-id]').map(node => node.attributes("data-action-id"))).toEqual(["recharge", "withdrawal"]);
    expect(wrapper.find('.flare-account-view__navigation [data-action-id="payoutProfiles"]').exists()).toBe(true);
    expect(wrapper.findAll('.flare-account-view__navigation [data-action-id="recharge"]')).toHaveLength(0);
    expect(wrapper.findAll("[data-wallet-card]")).toHaveLength(1);
    expect(wrapper.find(".flare-account-view__ledger").exists()).toBe(false);
    // §12.23: a PC card is name, balance and one foot line; the asset · currency stays in the information panel.
    expect(wrapper.get("[data-wallet-card]").text()).not.toContain("CNY · cash");
    await wrapper.get("[data-account-information]").trigger("click");
    await flushPromises();
    expect(document.body.querySelector("[data-account-information-panel]")?.textContent).toContain("CNY · cash");
    view.actions = view.actions.filter(action => action.id !== "recharge");
    const disabled = render(view).wrapper;
    expect(disabled.find('[data-overview-card] [data-action-id="recharge"]').exists()).toBe(false);
    expect(disabled.findAll('[data-action-id="withdrawal"]')).toHaveLength(1);
  });
  it("promotes a visible replacement submit action without inventing a balance or ledger", () => {
    const { wrapper } = render(wallet("withdrawal_authorization", "authorized"));
    expect(wrapper.get('.flare-account-view__flow [data-action-id="create"]').text()).toBe("确认申请提现");
    expect(wrapper.find('[data-action-id="authorize"]').exists()).toBe(false);
    expect(wrapper.find("[data-account-balance]").exists()).toBe(false);
    expect(wrapper.find("[data-account-empty]").exists()).toBe(false);
    expect(wrapper.text()).toContain("提现明细");
  });
  it("shows nonempty cashflow and restricted funds as named records with their original amounts", () => {
    const history = render(wallet("cashflow_history")).wrapper.get('[data-account-entry="cashflow-fixture"]');
    expect(history.get("strong").text()).toBe("提现");
    expect(history.get("b").text()).toBe("100.00");
    expect(history.text()).toContain("待审核");
    const lot = render(wallet("lots")).wrapper.get('[data-account-entry="lot-fixture"]');
    expect(lot.get("strong").text()).toBe("CNY");
    expect(lot.get("b").text()).toBe("200.00");
    expect(lot.text()).toContain("可提现");
    const opening = render(wallet("openings")).wrapper;
    expect(opening.find(".flare-account-view__ledger").exists()).toBe(false);
    expect(opening.text()).toContain("工资钱包");
    expect(opening.text()).toContain("等待审核");
    expect(opening.get('[data-row-key="opening-fixture"] dl').text()).toContain("模板definition-fixture");
    expect(opening.get('[data-row-key="opening-fixture"] dl').text()).toContain("状态pending");
  });
  it("keeps a funding form on the original action runner and preserves the page payload", async () => {
    const view = wallet("withdrawal_authorization", "prepared");
    view.data = { authorizationId: "original-authorization", commandId: "opaque-command" };
    const { wrapper, actions, state } = render(view, true);
    await wrapper.get('[data-action-id="authorize"]').trigger("click");
    await flushPromises();
    expect(actions).toEqual([]);
    const input = document.body.querySelector('.flare-plugin-form input') as HTMLInputElement;
    expect(input).not.toBeNull();
    input.value = "123456";
    input.dispatchEvent(new Event("input"));
    await flushPromises();
    (document.body.querySelector('[data-form-submit]') as HTMLButtonElement).click();
    await flushPromises();
    expect(actions).toEqual([["authorize", { page: { pluginId: "example", page: "wallet" }, data: view.data, formValues: { password: "123456" } }]]);
    state.error = "验证失败，请重试";
    state.settleToken++;
    await flushPromises();
    expect(document.body.querySelector('.flare-plugin-form')?.textContent).toContain(state.error);
    expect(wrapper.findAll('.flare-status-banner')).toHaveLength(1);
  });
  it.each(walletCases.filter(item => item.locale === "zh-CN" && item.view.presentation?.renderer === "account"))("renders the resolved $id/$variant hierarchy without duplicating top-level actions", ({ view }) => {
    const { wrapper } = render(view);
    for (const action of view.actions) expect(wrapper.findAll(`[data-action-id="${action.id}"], [data-inline-action-id="${action.id}"]`)).toHaveLength(1);
    if (view.presentation?.props.layout === "flow") expect(wrapper.find(".flare-account-view__ledger").exists()).toBe(false);
  });
  it("shows each wallet once at the top, keeps the overview separate, and forwards its original identity", async () => {
    const view = wallet("home");
    view.fields = [{ label: "可用余额", value: "900.00" }, ...view.fields.slice(1)];
    const rows = view.blocks!.find(block => block.kind === "rows")!;
    if (rows.kind !== "rows") throw new Error("Missing wallet rows");
    const first = rows.rows[0];
    rows.rows = [first, { ...first, key: "usd-wallet", cells: [{text: "88.50"}, {text: "旅行钱包"}, {text: "USD · cash"}, {text: "active"}], actions: [{id: "wallet", input: {walletId: "usd-wallet"}}] }, first];
    const { wrapper, actions } = render(view, true);
    expect(wrapper.findAll("[data-wallet-card]")).toHaveLength(2);
    expect(wrapper.findAll("[data-account-balance]").map(node => node.text())).toEqual(["1000.00", "88.50"]);
    expect(wrapper.get(".flare-account-view__wallet-header h2").text()).toBe("我的钱包");
    expect(wrapper.get(".flare-account-view__wallet-overview").attributes("aria-label")).toBe("我的钱包");
    // The information is the first row of the destination list (W-06).
    expect(wrapper.find(".flare-account-view__navigation [data-account-information]").exists()).toBe(true);
    await wrapper.get('[data-account-entry="usd-wallet"]').trigger("click");
    await flushPromises();
    expect(actions[0]).toEqual(["wallet", {page: {pluginId: "example", page: "wallet"}, row: {key: "usd-wallet", input: {walletId: "usd-wallet"}}}]);
    expect(document.body.querySelector('[role="dialog"]')).toBeNull();
    await wrapper.get("[data-account-information]").trigger("click");
    await flushPromises();
    expect(document.body.querySelector("[data-account-information-panel]")?.textContent).toContain("900.00");
  });
  it("keeps inline page form values after a rejected submit and resets only after successful settlement", async () => {
    const view = wallet("transfer");
    view.actions = [{id: "preview", label: "核对金额", style: "primary", form: ["decimalAmount"]}];
    view.inputs = [{id: "decimalAmount", label: "金额", kind: "text", required: true}];
    const { wrapper, actions, state } = render(view, true);
    expect(wrapper.find('[data-action-id="preview"]').exists()).toBe(false);
    expect(wrapper.find('[data-form-cancel]').exists()).toBe(false);
    const field = () => wrapper.get<HTMLInputElement>('[data-inline-action-form] input');
    await field().setValue("900719925474099301.01");
    await wrapper.get('[data-form-submit]').trigger("click");
    await wrapper.get('[data-form-submit]').trigger("click");
    expect(actions).toEqual([["preview", {page: {pluginId: "example", page: "wallet"}, formValues: {decimalAmount: "900719925474099301.01"}}]]);
    state.error = "余额不足";
    state.formErrors = [{input: "decimalAmount", issue: "outOfRange"}];
    state.settleToken++;
    await flushPromises();
    expect(field().element.value).toBe("900719925474099301.01");
    expect(wrapper.findAll('[role="alert"]')).toHaveLength(1);
    expect(wrapper.get('[data-form-submit]').attributes("disabled")).toBeUndefined();
    state.error = undefined;
    state.formErrors = [];
    await field().setValue("10.00");
    await wrapper.get('[data-form-submit]').trigger("click");
    state.settleToken++;
    await flushPromises();
    expect(actions).toHaveLength(2);
    expect(field().element.value).toBe("");
  });
  it.each(["password", "confirmation", "missing-input", "read-only", "multiple-primary"])("retains guarded action presentation for %s", (reason) => {
    const view = wallet("transfer");
    view.actions = [{id: "preview", label: "继续", style: "primary", form: ["amount"]}];
    view.inputs = [{id: "amount", label: "金额", kind: reason === "password" ? "password" : "text", required: true}];
    if (reason === "confirmation") view.actions = [{...view.actions[0], confirm: "请核对金额"}];
    if (reason === "missing-input") view.inputs = [];
    if (reason === "read-only") view.unavailableReason = "unbound_copy";
    if (reason === "multiple-primary") view.actions = [...view.actions, {id: "second", label: "其他主操作", style: "primary"}];
    const {wrapper, actions} = render(view);
    expect(wrapper.find("[data-inline-action-form]").exists()).toBe(false);
    expect(actions).toEqual([]);
  });
  it("locks inline inputs during another action without discarding the draft", async () => {
    const view = wallet("transfer");
    view.actions = [{id: "preview", label: "继续", style: "primary", form: ["amount"]}];
    view.inputs = [{id: "amount", label: "金额", kind: "text"}];
    const {wrapper, state, actions} = render(view);
    await wrapper.get("[data-inline-action-form] input").setValue("12.00");
    state.busyActionId = "other";
    await flushPromises();
    expect(wrapper.get("[data-inline-action-form] input").attributes("disabled")).toBeDefined();
    expect(wrapper.get("[data-form-submit]").attributes("disabled")).toBeDefined();
    state.busyActionId = undefined;
    await flushPromises();
    expect(wrapper.get<HTMLInputElement>("[data-inline-action-form] input").element.value).toBe("12.00");
    expect(actions).toEqual([]);
  });
  it("separates a record's status from its title and opens only its declared, unguarded entry action", async () => {
    const view = wallet("cashflow_history");
    view.presentation!.props.rowBadgePlacement = "separate";
    view.presentation!.props.rowBadgeLabel = "申请状态";
    view.presentation!.props.rowEntryAction = "detail";
    view.data = {opaque: "history-source"};
    const block = view.blocks!.find(block => block.kind === "rows")!;
    if (block.kind !== "rows") throw new Error("Missing rows");
    block.actions = [{id: "detail", label: "查看详情"}];
    block.rows[0].badge = {text: "处理中", tone: "warning"};
    block.rows[0].actions = [{id: "detail", input: {recordId: "original-request"}}];
    const {wrapper, actions} = render(view, true);
    const row = wrapper.get('[data-account-entry="cashflow-fixture"]');
    expect(row.get("strong").text()).toBe("提现");
    expect(row.get("[data-account-badge]").text()).toBe("处理中");
    expect(row.get("[data-account-badge]").attributes("data-tone")).toBe("warning");
    await row.trigger("click");
    expect(actions).toEqual([["detail", {page: {pluginId: "example", page: "wallet"}, data: view.data, row: {key: "cashflow-fixture", input: {recordId: "original-request"}}}]]);
    expect(document.body.querySelector('[role="dialog"]')).toBeNull();
    block.actions = [{id: "detail", label: "需确认操作", confirm: "确认后再执行"}];
    const guarded = render(view);
    await guarded.wrapper.get('[data-account-entry="cashflow-fixture"]').trigger("click");
    await flushPromises();
    expect(guarded.actions).toEqual([]);
    expect(document.body.querySelector('[role="dialog"]')?.textContent).toContain("申请状态");
  });
});

describe("wallet layout (§5.1 of docs/plugin-experience.md)", () => {
  function twoWallets(): FlarePluginPageViewModel {
    const view = wallet("home");
    const rows = view.blocks!.find(block => block.kind === "rows")!;
    if (rows.kind !== "rows") throw new Error("Missing wallet rows");
    const first = rows.rows[0];
    rows.rows = [first, { ...first, key: "usd-wallet", cells: [{ text: "88.50" }, { text: "旅行钱包" }, { text: "USD · cash" }, { text: "正常", tone: "success" }], actions: [{ id: "wallet", input: { walletId: "usd-wallet" } }] }];
    return view;
  }
  function mountWith(view: FlarePluginPageViewModel, extra: Record<string, unknown> = {}, mode: "h5" | "pc" = "pc") {
    const actions: Array<[string, FlarePluginActionPayload]> = [];
    const wrapper = mount(defineComponent({ setup() {
      useFlareI18nProvider("zh-CN");
      useFlareAdaptiveProvider(mode);
      return () => h(FlareAccountView, { view, ...extra, onAction: (id: string, payload: FlarePluginActionPayload) => actions.push([id, payload]) });
    } }), { attachTo: document.body });
    return { wrapper, actions };
  }

  it("on a phone keeps the default wallet in the overview card and lists the others", async () => {
    const { wrapper, actions } = mountWith(twoWallets(), {}, "h5");
    expect(wrapper.findAll("[data-wallet-card]")).toHaveLength(1);
    const others = wrapper.get("[data-other-wallets]");
    expect(others.get("h3").text()).toBe("其他钱包");
    const row = others.get('[data-account-entry="usd-wallet"]');
    expect(row.text()).toContain("旅行钱包");
    expect(row.text()).toContain("USD · cash");
    expect(row.text()).toContain("88.50");
    await row.trigger("click");
    expect(actions[0]).toEqual(["wallet", { row: { key: "usd-wallet", input: { walletId: "usd-wallet" } } }]);
    // PC keeps the two-column card grid and no extra list.
    const pc = mountWith(twoWallets()).wrapper;
    expect(pc.findAll("[data-wallet-card]")).toHaveLength(2);
    expect(pc.find("[data-other-wallets]").exists()).toBe(false);
  });

  it("on a phone closes the overview card with the quick keys and then 查看明细 (§5.1)", async () => {
    const view = twoWallets();
    view.presentation!.props.rowEntryAction = "wallet";
    const rows = view.blocks!.find(block => block.kind === "rows")!;
    if (rows.kind !== "rows") throw new Error("Missing wallet rows");
    rows.actions = [{ id: "wallet", label: "查看明细" }];
    const { wrapper, actions } = mountWith(view, {}, "h5");
    const card = wrapper.get("[data-wallet-card]");
    expect(card.text()).not.toContain("查看明细");
    const quick = wrapper.get('[data-overview-card] [data-place="quick"]').element;
    const entry = wrapper.get("[data-overview-card] [data-wallet-entry]");
    expect(entry.text()).toBe("查看明细");
    expect(quick.compareDocumentPosition(entry.element) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
    await entry.trigger("click");
    expect(actions.map(([id]) => id)).toEqual(["wallet"]);
    // PC keeps the line inside each wallet card, above the quick keys under the grid.
    const pc = mountWith(view).wrapper;
    expect(pc.find("[data-wallet-entry]").exists()).toBe(false);
    expect(pc.findAll("[data-wallet-card]")[0].text()).toContain("查看明细");
  });

  it("keeps the balance toggle beside the overview title and leaves desktop quick actions separate", async () => {
    const view = twoWallets();
    view.presentation!.props.rowEntryAction = "wallet";
    const rows = view.blocks!.find(block => block.kind === "rows")!;
    if (rows.kind !== "rows") throw new Error("Missing wallet rows");
    rows.actions = [{ id: "wallet", label: "查看明细" }];
    const pc = mountWith(view).wrapper;
    const overview = pc.get(".flare-account-view__wallet-header");
    expect(overview.get("h2").text()).toBe("我的钱包");
    const card = pc.findAll("[data-wallet-card]")[1];
    expect(card.find(".flare-account-view__wallet-card-label").exists()).toBe(false);
    expect(card.text()).not.toContain("USD · cash");
    const foot = card.get("[data-wallet-card-foot]");
    expect(foot.get("[data-wallet-status]").text()).toBe("正常");
    expect(foot.text()).toBe("正常·查看明细");
    const row = pc.get("[data-wallet-quick-row]");
    const keys = row.findAll('[data-place="quick"] [data-action-id]').map(node => node.attributes("data-action-id"));
    expect(keys).toEqual(["recharge", "withdrawal"]);
    const eye = overview.get("[aria-pressed]");
    expect(eye.attributes("aria-pressed")).toBe("false");
    expect(pc.findAll('[aria-pressed]')).toHaveLength(1);
    await eye.trigger("click");
    expect(pc.findAll("[data-account-balance]").map(node => node.text())).toEqual(["••••", "••••"]);
    // A phone keeps its title row with the eye, the balance label and the details.
    const phone = mountWith(view, {}, "h5").wrapper;
    expect(phone.get(".flare-account-view__wallet-header h2").text()).toBe("我的钱包");
    expect(phone.find("[data-wallet-quick-row]").exists()).toBe(false);
    expect(phone.get("[data-wallet-card]").find(".flare-account-view__wallet-card-label").exists()).toBe(true);
  });

  it("draws a toned wallet status as the kit Tag and an untoned one as text", () => {
    const { wrapper } = mountWith(twoWallets());
    const tags = wrapper.findAll("[data-wallet-status]");
    expect(tags).toHaveLength(1);
    expect(tags[0].text()).toBe("正常");
    expect(wrapper.findAll("[data-wallet-card]")[0].find("[data-wallet-status]").exists()).toBe(false);
  });

  it("puts a warning banner (pending operations) above the overview with its own key", async () => {
    const view = twoWallets();
    view.blocks = [{ kind: "banner", tone: "warning", text: "有资金操作等待确认，请先查看原单，勿重新付款", action: { id: "recovery", label: "查看", target: { kind: "page", page: "flare.wallet.page.recovery" } } }, ...(view.blocks ?? [])];
    const { wrapper, actions } = mountWith(view);
    const notices = wrapper.get(".flare-account-view__wallet-notices").element;
    const overview = wrapper.get(".flare-account-view__wallet-overview").element;
    expect(Boolean(notices.compareDocumentPosition(overview) & Node.DOCUMENT_POSITION_FOLLOWING)).toBe(true);
    expect(notices.textContent).toContain("有资金操作等待确认");
    const key = [...notices.querySelectorAll("button")].find(button => button.textContent?.includes("查看"))!;
    key.click();
    await flushPromises();
    expect(actions.map(([id]) => id)).toContain("recovery");
  });

  it("disables every action while offline and leaves the information readable", async () => {
    const { wrapper } = mountWith(twoWallets(), { offline: true });
    for (const key of wrapper.findAll("[data-action-id]")) expect(key.attributes("disabled"), key.attributes("data-action-id")).toBeDefined();
    expect(wrapper.get('[data-account-entry="usd-wallet"]').attributes("disabled")).toBeDefined();
    expect(wrapper.get("[data-account-information]").attributes("disabled")).toBeUndefined();
  });
});

describe("ledger rows (§5.8 and R10 of docs/plugin-experience.md)", () => {
  it("draws the amount with the minus sign and no Tag for a completed (success) status", () => {
    const view = wallet("cashflow_history");
    view.presentation!.props.rowBadgePlacement = "separate";
    const block = view.blocks!.find(block => block.kind === "rows")!;
    if (block.kind !== "rows") throw new Error("Missing rows");
    block.rows[0].badge = {text: "已完成", tone: "success"};
    block.rows[0].cells = block.rows[0].cells.map((cell, index) => index === 0 ? {...cell, text: "-100.00"} : cell);
    const row = render(view).wrapper.get('[data-account-entry="cashflow-fixture"]');
    expect(row.find("[data-account-badge]").exists()).toBe(false);
    expect(row.get("b").text()).toBe("−100.00");
  });
  it("leads with the sign's icon and puts the amount, then its status Tag, at the end (§5.8 record line)", () => {
    const view = wallet("cashflow_history");
    view.presentation!.props.rowBadgePlacement = "separate";
    const block = view.blocks!.find(block => block.kind === "rows")!;
    if (block.kind !== "rows") throw new Error("Missing rows");
    block.rows[0].badge = {text: "处理中", tone: "warning"};
    block.rows[0].cells = block.rows[0].cells.map((cell, index) => index === 0 ? {...cell, text: "+100.00"} : cell);
    const row = render(view).wrapper.get('[data-account-entry="cashflow-fixture"]');
    expect(row.get(".flare-account-view__entry-icon").classes()).toContain("is-in");
    expect(row.get(".flare-account-view__entry-value b").classes()).toContain("is-positive");
    expect(row.get(".flare-account-view__entry-value [data-account-badge]").text()).toBe("处理中");
    expect(row.find(".flare-account-view__entry-main [data-account-badge]").exists()).toBe(false);
  });
});
