// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, reactive } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { FlarePluginFormError, FlarePluginInput } from "../../shared/contracts/plugin-ui";
import FlarePluginForm from "./FlarePluginForm.vue";
import FlareSelect from "./FlareSelect.vue";
import FlareAdminEntitySelect from "./FlareAdminEntitySelect.vue";

enableAutoUnmount(afterEach);
afterEach(() => { document.body.innerHTML = ""; });

const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plugin-view-vectors.json"), "utf8")) as {
  form: {
    inputs: FlarePluginInput[];
    initial: { options: { rows: number; canAdd: boolean; canRemove: boolean }; counters: Record<string, string | null> };
    cases: Array<{ name: string; values: Record<string, unknown>; clientErrors: FlarePluginFormError[]; submitted: Record<string, unknown> | null }>;
    hostErrors: Array<{ error: FlarePluginFormError; zh: string }>;
    shownPerInput: Record<string, string>;
  };
};
const { inputs } = vectors.form;
const members = [
  { userId: "u_alice01", name: "Alice" },
  { userId: "u_bob0002", name: "Bob" },
  { userId: "u_carol003", name: "Carol" },
];

function render(props: Record<string, unknown> = {}) {
  const state = reactive<Record<string, unknown>>({ inputs, members, ...props });
  const submits: Array<Record<string, unknown>> = [];
  let cancels = 0;
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlarePluginForm as never, {
        ...state,
        onSubmit: (values: Record<string, unknown>) => submits.push(values),
        onCancel: () => { cancels += 1; },
      });
    },
  }), { attachTo: document.body });
  return { wrapper, state, submits, cancels: () => cancels };
}
const field = (wrapper: ReturnType<typeof render>["wrapper"], id: string) => wrapper.get(`[data-input-id="${id}"]`);
const errorOf = (wrapper: ReturnType<typeof render>["wrapper"], id: string) => {
  const node = wrapper.find(`[data-input-id="${id}"] .flare-form-field__error`);
  return node.exists() ? node.text() : null;
};

describe("FlarePluginForm (spec/plugin-view-vectors.json → form)", () => {
  it("keeps draft values when labels and choice captions change with the locale", async () => {
    const title = { id: "title", kind: "text", label: "Title", placeholder: "Title" };
    const visibility = { id: "visibility", kind: "select", label: "Visibility", choices: [{ value: "all", label: "Everyone" }] };
    const { wrapper, state, submits } = render({ inputs: [title, visibility], values: { visibility: "all" } });
    await field(wrapper, "title").get("input").setValue("Planning");
    state.inputs = [{ ...title, label: "件名", placeholder: "予定の件名" }, { ...visibility, choices: [{ value: "all", label: "全員" }] }];
    await flushPromises();
    expect(field(wrapper, "title").get("input").attributes("placeholder")).toBe("予定の件名");
    expect(field(wrapper, "visibility").text()).toContain("全員");
    await wrapper.get("form").trigger("submit");
    expect(submits).toEqual([{ title: "Planning", visibility: "all" }]);
  });

  it("updates sibling validation immediately and blocks submission until corrected", async () => {
    const { wrapper, submits } = render({
      inputs: [{ id: "amount", kind: "text", label: "总额" }, { id: "limit", kind: "text", label: "单笔上限" }],
      values: { amount: "9", limit: "8" },
      validateField: (id: string, values: Record<string, string>) =>
        id === "limit" && BigInt(values.limit) > BigInt(values.amount) ? "单笔上限不能超过预算金额。" : undefined,
    });
    await field(wrapper, "amount").get("input").setValue("7");
    expect(errorOf(wrapper, "limit")).toBe("单笔上限不能超过预算金额。");
    await wrapper.get("form").trigger("submit");
    expect(submits).toEqual([]);
    await field(wrapper, "limit").get("input").setValue("7");
    expect(errorOf(wrapper, "limit")).toBeNull();
    await wrapper.get("form").trigger("submit");
    expect(submits).toEqual([{ amount: "7", limit: "7" }]);
  });
  it("shows the exact service amount bounds for correction and names the currency", async () => {
    const { wrapper, submits } = render({ inputs: [{ id: "amount", kind: "money", label: "金额", required: true,
      money: { currency: "CNY", scale: 2, min: "0.01", max: "9007199254740993.99" } }] });
    const input = field(wrapper, "amount").get("input");
    expect(input.attributes("aria-label")).toBe("金额 (CNY)");
    expect(field(wrapper, "amount").text()).toContain("金额范围：0.01–9007199254740993.99 CNY");
    await input.setValue("0");
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(errorOf(wrapper, "amount")).toBe("金额范围：0.01–9007199254740993.99 CNY");
    expect(submits).toHaveLength(0);
    await input.setValue("0.01");
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([{ amount: { amount: "0.01", currency: "CNY" } }]);
  });
  it("authoritative member revisions clear member selection without resetting other fields", async () => {
    const searches:string[]=[];
    const {wrapper,state,submits}=render({
      inputs:[{id:"amount",kind:"text",label:"金额"},{id:"recipients",kind:"members",label:"成员",required:true,min:1,max:1}],
      values:{amount:"1.30",recipients:["u_bob0002"]},membersRevision:0,
      onMemberSearch:(query:string)=>searches.push(query),
    });
    expect(field(wrapper,"recipients").get('[data-members-chosen]').text()).toBe('Bob');
    await field(wrapper,"recipients").get('[data-members-choose]').trigger('click');await flushPromises();
    expect(searches).toEqual(['']);expect(document.body.querySelector('.flare-contact-picker')).not.toBeNull();
    state.membersRevision=1;await flushPromises();
    expect(field(wrapper,"recipients").find('[data-members-chosen]').exists()).toBe(false);
    expect((field(wrapper,"amount").get('input').element as HTMLInputElement).value).toBe('1.30');
    expect(document.body.querySelector('.flare-contact-picker')).toBeNull();
    await wrapper.get('[data-form-submit]').trigger('click');expect(submits).toEqual([]);
  });
  it("masks payment passwords, ignores prefills and clears secrets before submitting", async () => {
    const {wrapper,submits}=render({inputs:[{id:"password",kind:"password",label:"支付密码",required:true,maxLength:6,default:"111111"}],values:{password:"222222"}});
    const input=field(wrapper,"password").get("input");
    expect(input.attributes("type")).toBe("password");
    expect((input.element as HTMLInputElement).value).toBe("");
    await input.setValue("839271");
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([{password:"839271"}]);
    expect((input.element as HTMLInputElement).value).toBe("");
  });

  it("draws a 6-digit password as six PIN cells over one numeric input; an error clears it and shakes", async () => {
    const {wrapper,state}=render({inputs:[{id:"password",kind:"password",label:"支付密码",required:true,maxLength:6}]});
    const pin=field(wrapper,"password").get("[data-pin]");
    expect(pin.findAll(".flare-pin__cell")).toHaveLength(6);
    const input=pin.get("input");
    expect(input.attributes("inputmode")).toBe("numeric");
    expect(input.attributes("type")).toBe("password");
    await input.setValue("12a3");
    expect((input.element as HTMLInputElement).value).toBe("123");
    expect(pin.findAll(".flare-pin__dot")).toHaveLength(3);
    state.errors=[{input:"password",issue:"unknown"}];
    await flushPromises();
    expect((input.element as HTMLInputElement).value).toBe("");
    expect(pin.classes()).toContain("is-shaking");
  });

  it("submits on the sixth PIN digit when no required field follows, else moves to the next field", async () => {
    const last=render({inputs:[{id:"password",kind:"password",label:"支付密码",required:true,maxLength:6}]});
    await field(last.wrapper,"password").get("input").setValue("123456");
    expect(last.submits).toEqual([{password:"123456"}]);
    const before=render({inputs:[{id:"password",kind:"password",label:"支付密码",required:true,maxLength:6},{id:"note",kind:"text",label:"备注",required:true}]});
    await field(before.wrapper,"password").get("input").setValue("123456");
    await flushPromises();
    expect(before.submits).toEqual([]);
    expect(document.activeElement).toBe(field(before.wrapper,"note").get("input").element);
  });

  it("record editing blocks unchanged submissions and preserves exact money text", async () => {
    const {wrapper,submits}=render({inputs:[{id:"amount",kind:"text",label:"额度"}],values:{amount:"900719925474099301"},requireChange:true});
    expect(wrapper.get("[data-form-submit]").attributes("disabled")).toBeDefined();
    await field(wrapper,"amount").get("input").setValue("900719925474099302");
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([{amount:"900719925474099302"}]);
  });
  it("directory inputs keep typed drafts through loading and reject missing or withdrawn references", async () => {
    const { wrapper, state, submits } = render({
      inputs: [{id:"assets",kind:"options",label:"资金",min:1,max:32,required:true},{id:"amount",kind:"text",label:"金额"}],
      values: {assets:["cash"],amount:"900719925474099301"},
      selections: {assets:{options:[],loading:true,remote:false}},
    });
    expect(field(wrapper,"assets").findAll("[data-option-row]")).toHaveLength(0);
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toHaveLength(0);
    state.selections={assets:{options:[{value:"cash",label:"余额 · CNY"}],loading:false,remote:false}};
    await flushPromises();
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([{assets:["cash"],amount:"900719925474099301"}]);
    expect(wrapper.findComponent(FlareAdminEntitySelect).props("remote")).toBe(false);
    state.selections={assets:{options:[{value:"cash",label:"已停用",disabled:true}],loading:false}};
    await flushPromises();
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toHaveLength(1);
  });
  it("a new required directory array starts empty instead of carrying an unremovable text placeholder", async () => {
    const {wrapper,submits}=render({inputs:[{id:"assets",kind:"options",label:"资金",min:1,max:32,required:true,default:[]}],selections:{assets:{options:[{value:"cash",label:"余额"}],remote:false}}});
    const select=wrapper.findComponent(FlareAdminEntitySelect);
    expect(select.props("values")).toEqual([]);
    select.vm.$emit("update:values",["cash"]);
    await flushPromises();
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([{assets:["cash"]}]);
  });
  it("compact filters preserve validation, typed values and the host-owned reset", async () => {
    const { wrapper, submits, cancels } = render({
      presentation: "filters", cancelLabel: "重置", submitLabel: "筛选",
      inputs: [
        { id: "status", kind: "select", label: "状态", choices: [{ value: "active", label: "进行中" }, { value: "ended", label: "已结束" }] },
        { id: "query", kind: "text", label: "查询", maxLength: 3 },
      ],
    });
    expect(wrapper.findAll("input[type=radio]")).toHaveLength(0);
    const select = wrapper.findComponent(FlareSelect);
    expect(select.props("options")[0]).toEqual({ value: "", label: "全部" });
    select.vm.$emit("update:modelValue", "active");
    await field(wrapper, "query").get("input").setValue("four");
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([]);
    expect(errorOf(wrapper, "query")).toBe("超出长度");
    await field(wrapper, "query").get("input").setValue("abc");
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([{ status: "active", query: "abc" }]);
    expect(wrapper.get("[data-form-cancel]").text()).toBe("重置");
    await wrapper.get("[data-form-cancel]").trigger("click");
    expect(cancels()).toBe(1);
  });

  it("compact filters keep native controls and submit/reset disabled during a request", async () => {
    const { wrapper, submits, cancels } = render({
      presentation: "filters", busy: true,
      inputs: [{ id: "status", kind: "select", label: "状态", choices: [{ value: "active", label: "进行中" }] }],
    });
    expect(wrapper.findComponent(FlareSelect).props("disabled")).toBe(true);
    await wrapper.get("[data-form-submit]").trigger("click");
    await wrapper.get("[data-form-cancel]").trigger("click");
    expect(submits).toEqual([]);
    expect(cancels()).toBe(0);
  });

  it("draws every input kind, with counters and the option rows' limits", async () => {
    const { wrapper } = render();
    for (const input of inputs) expect(wrapper.find(`[data-input-id="${input.id}"]`).exists()).toBe(true);
    // R6 (spec formCounter): an empty field has no counter (form.initial.counters are null); typed, it reads "{n}/{max}".
    for (const [id, counter] of Object.entries(vectors.form.initial.counters)) {
      expect(counter).toBeNull();
      expect(field(wrapper, id).find(".flare-form-field__counter").exists()).toBe(false);
    }
    await field(wrapper, "title").get("input").setValue("abc");
    expect(field(wrapper, "title").get(".flare-form-field__counter").text()).toBe(`3/${inputs.find((input) => input.id === "title")!.maxLength}`);
    const options = field(wrapper, "options");
    expect(options.findAll("[data-option-row]")).toHaveLength(vectors.form.initial.options.rows);
    expect(options.get("[data-option-add]").attributes("disabled") === undefined).toBe(vectors.form.initial.options.canAdd);
    expect(options.findAll("[data-option-remove]").every((b) => b.attributes("disabled") !== undefined)).toBe(!vectors.form.initial.options.canRemove);
    expect(field(wrapper, "visibility").findAll("input[type=radio], [role=radio]").length).toBeGreaterThan(0);
  });

  it("shows nothing before an edit or a submit attempt, then every client issue", async () => {
    const { wrapper, submits } = render();
    for (const input of inputs) expect(errorOf(wrapper, input.id)).toBeNull();
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([]);
    const empty = vectors.form.cases.find((c) => c.name === "empty")!;
    for (const input of inputs) {
      const issue = empty.clientErrors.find((e) => e.input === input.id);
      expect(errorOf(wrapper, input.id), input.id).toBe(issue ? "必填" : null);
    }
  });

  it("checks an input as soon as it is edited", async () => {
    const { wrapper } = render();
    await field(wrapper, "title").get("input").setValue("一二三四五六七八九十十一");
    expect(errorOf(wrapper, "title")).toBe("超出长度");
    expect(errorOf(wrapper, "deadline")).toBeNull();
    await field(wrapper, "title").get("input").setValue("团建");
    expect(errorOf(wrapper, "title")).toBeNull();
  });

  it.each(vectors.form.cases.filter((c) => c.submitted).map((c) => [c.name, c] as const))("submits the cleaned values: %s", async (_, v) => {
    const { wrapper, submits } = render({ values: v.values });
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([v.submitted]);
  });

  it("shows the host's errors under their inputs until the input is edited", async () => {
    const { wrapper, state } = render({ values: vectors.form.cases.find((c) => c.name === "valid")!.values });
    state.errors = vectors.form.hostErrors.map((e) => e.error);
    await flushPromises();
    for (const [id, shown] of Object.entries(vectors.form.shownPerInput)) expect(errorOf(wrapper, id), id).toBe(shown);
    await field(wrapper, "title").get("input").setValue("新的标题");
    expect(errorOf(wrapper, "title")).toBeNull();
    expect(errorOf(wrapper, "limit")).toBe("超出范围");
  });

  it("adds and removes option rows inside their limits", async () => {
    const { wrapper, submits } = render();
    const options = () => field(wrapper, "options");
    for (let i = 0; i < 5; i += 1) await options().get("[data-option-add]").trigger("click");
    expect(options().findAll("[data-option-row]")).toHaveLength(5);
    expect(options().get("[data-option-add]").attributes("disabled")).toBeDefined();
    await options().findAll("[data-option-remove]")[0].trigger("click");
    expect(options().findAll("[data-option-row]")).toHaveLength(4);
    const rows = options().findAll("[data-option-row] input");
    await rows[0].setValue(" 爬山 ");
    await rows[2].setValue("桌游");
    await field(wrapper, "title").get("input").setValue("团建");
    void submits;
    expect(errorOf(wrapper, "options")).toBeNull();
  });

  it("picks members through the kit contact picker, one at a time when max is 1", async () => {
    const { wrapper } = render();
    await field(wrapper, "owner").get("[data-members-choose]").trigger("click");
    await flushPromises();
    const picker = document.body.querySelector(".flare-contact-picker") as HTMLElement;
    expect(picker).not.toBeNull();
    const row = [...picker.querySelectorAll("button, [role=option], li")].find((n) => n.textContent?.includes("Carol")) as HTMLElement;
    row.click();
    await flushPromises();
    expect(field(wrapper, "owner").get("[data-members-chosen]").text()).toBe("Carol");
  });
  it("keeps existing members while adding a user from remote search", async () => {
    const searches: string[] = [];
    const { wrapper, state, submits } = render({
      inputs: [{ id: "participants", kind: "members", label: "参与人", max: 10 }],
      values: { participants: [members[0]!.userId] },
      members: [members[0]],
      onMemberSearch: (query: string) => searches.push(query),
    });
    await field(wrapper, "participants").get("[data-members-choose]").trigger("click");
    await flushPromises();
    const picker = document.body.querySelector<HTMLElement>(".flare-contact-picker")!;
    const search = picker.querySelector<HTMLInputElement>("input")!;
    search.value = "Bob";
    search.dispatchEvent(new Event("input", { bubbles: true }));
    await flushPromises();
    expect(searches).toEqual(["", "Bob"]);
    state.members = [members[1]];
    await flushPromises();
    picker.querySelector<HTMLButtonElement>(".flare-contact-picker__row")!.click();
    await flushPromises();
    [...picker.querySelectorAll("button")].find((button) => button.textContent?.includes("确定"))!.click();
    await flushPromises();
    await wrapper.get("[data-form-submit]").trigger("click");
    expect(submits).toEqual([{ participants: [members[0]!.userId, members[1]!.userId] }]);
  });

  it("locks while busy and reports cancel", async () => {
    const busy = render({ busy: true, error: "提交失败" });
    expect(busy.wrapper.get("[data-form-submit]").attributes("disabled")).toBeDefined();
    expect(busy.wrapper.get("[role=alert]").text()).toBe("提交失败");
    const idle = render({ submitLabel: "参与接龙" });
    expect(idle.wrapper.get("[data-form-submit]").text()).toBe("参与接龙");
    await idle.wrapper.get("[data-form-cancel]").trigger("click");
    expect(idle.cancels()).toBe(1);
  });
});
