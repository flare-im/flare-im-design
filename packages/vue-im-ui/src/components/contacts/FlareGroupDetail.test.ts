// @vitest-environment happy-dom
import { afterEach, expect, it, vi } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareGroupDetail from "./FlareGroupDetail.vue";
import FlareFormSheet from "../general/FlareFormSheet.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareSettingsList from "../profile/FlareSettingsList.vue";
import FlareGroupMemberGrid from "./FlareGroupMemberGrid.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareRadioGroup from "../form/FlareRadioGroup.vue";
let host: ReturnType<typeof mount>;
afterEach(() => { host?.unmount(); document.body.innerHTML = ""; });
it("keeps failed group edits, blocks empty names, and awaits a successful retry", async () => {
  let resolveSave: () => void = () => {};
  const submitEdit = vi.fn().mockRejectedValueOnce(new Error("Unavailable"))
    .mockImplementationOnce(() => new Promise<void>((resolve) => { resolveSave = resolve; }));
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, {
      submitEdit, model: { groupId: "g", name: "Team", members: [], memberCount: 0,
        ownerId: "me", adminIds: [], mutedIds: [], canManage: true, isOwner: true },
    });
  } }), { attachTo: document.body });
  host.findComponent(FlareSettingsList).vm.$emit("select", { key: "name" });
  await flushPromises();
  const form = host.findComponent(FlareFormSheet);
  const input = host.findComponent(FlareInput);
  input.vm.$emit("update:modelValue", "   ");
  await flushPromises();
  expect(form.props("confirmDisabled")).toBe(true);
  form.vm.$emit("confirm");
  await flushPromises();
  expect(submitEdit).not.toHaveBeenCalled();
  input.vm.$emit("update:modelValue", "New team");
  await flushPromises();
  form.vm.$emit("confirm");
  await flushPromises();
  expect(form.props("open")).toBe(true);
  expect(form.props("error")).toBe("Unavailable");
  expect(input.props("modelValue")).toBe("New team");
  form.vm.$emit("confirm");
  await flushPromises();
  expect(form.props("busy")).toBe(true);
  form.vm.$emit("confirm");
  expect(submitEdit).toHaveBeenCalledTimes(2);
  resolveSave();
  await flushPromises();
  expect(form.props("open")).toBe(false);
});
it("emits openChat with positional (userIds, name) like the native onOpenChat", async () => {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, {
      model: { groupId: "g", name: "Team", members: [{ id: "a", name: "A" }, { id: "b", name: "B" }], memberCount: 2,
        ownerId: "a", adminIds: [], mutedIds: [], canManage: false, isOwner: false },
      onOpenChat: () => {},
    });
  } }), { attachTo: document.body });
  await flushPromises();
  await host.find(".flare-group-detail__foot button").trigger("click");
  const detail = host.findComponent(FlareGroupDetail);
  expect(detail.emitted("openChat")?.[0]).toEqual([["a", "b"], "Team"]);
});
it("picks invitees through checkbox rows and invites exactly the picked ids", async () => {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, {
      model: { groupId: "g", name: "Team", members: [{ id: "a", name: "A" }], memberCount: 1,
        ownerId: "a", adminIds: [], mutedIds: [], canManage: true, isOwner: true },
      invitableContacts: [{ id: "a", name: "A" }, { id: "b", name: "Bea" }, { id: "c", name: "Cai" }],
    });
  } }), { attachTo: document.body });
  await flushPromises();
  host.findComponent(FlareGroupMemberGrid).vm.$emit("addMember");
  await flushPromises();
  // Members already in the group are not offered; every row is one named checkbox.
  const boxes = () => [...document.body.querySelectorAll<HTMLElement>(".flare-contact-list [role=checkbox]")];
  expect(boxes().map((box) => box.getAttribute("aria-label"))).toEqual(["Bea", "Cai"]);
  (document.body.querySelector(".flare-contact-item__name") as HTMLElement).click();
  await flushPromises();
  boxes()[1].click();
  await flushPromises();
  boxes()[1].click();
  await flushPromises();
  expect(boxes().map((box) => box.getAttribute("aria-checked"))).toEqual(["true", "false"]);
  host.findComponent(FlareGroupDetail).findAllComponents(FlareButton).find((b) => b.text() === "邀请成员")!.vm.$emit("click");
  expect(host.findComponent(FlareGroupDetail).emitted("inviteMembers")).toEqual([[["b"]]]);
});

it("names the target role and mute state in member intents", async () => {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("en-US");
    return () => h(FlareGroupDetail as Component, {
      model: { groupId: "g", name: "Team", memberCount: 2, ownerId: "me", adminIds: ["ivy"], mutedIds: [], canManage: true, isOwner: true,
        members: [{ id: "me", name: "Me" }, { id: "ivy", name: "Ivy" }] },
    });
  } }), { attachTo: document.body });
  const grid = host.findComponent(FlareGroupMemberGrid);
  const detail = host.findComponent(FlareGroupDetail);
  const pick = async (label: string) => {
    grid.vm.$emit("select", "ivy");
    await flushPromises();
    const button = host.findAllComponents(FlareButton).find((b) => b.text() === label);
    if (!button) throw new Error(`no ${label} button`);
    await button.trigger("click");
  };
  await pick("Remove admin");
  await pick("Mute");
  expect(detail.emitted("promoteMember")).toEqual([["ivy", false]]);
  expect(detail.emitted("muteMember")).toEqual([["ivy", true]]);
});

it("offers the message button only to a host that opens the chat, and places host content in its slots", async () => {
  const model = { groupId: "g", name: "Team", members: [{ id: "a", name: "A" }], memberCount: 1,
    ownerId: "a", adminIds: [], mutedIds: [], canManage: false, isOwner: false, joinPolicy: null };
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, { model }, {
      "after-info": () => h("p", { class: "read-bar" }, "12 read"),
      footer: () => h("button", { type: "button", class: "report" }, "Report group"),
    });
  } }), { attachTo: document.body });
  await flushPromises();
  const footButtons = host.findAll(".flare-group-detail__foot button");
  expect(footButtons.map((button) => button.text())).toEqual(["退出群聊"]);
  // The read bar sits between the group information and the viewer's own settings.
  const lists = host.findAllComponents(FlareSettingsList);
  expect(lists).toHaveLength(2);
  expect((lists[0]!.props("sections") as Array<{ title?: string }>).map((section) => section.title)).toEqual(["群信息"]);
  const order = [...host.element.querySelectorAll(".flare-settings, .read-bar, .flare-group-detail__foot, .report")].map((node) => node.className);
  expect(order).toEqual(["flare-settings", "read-bar", "flare-settings", "flare-group-detail__foot", "report"]);
});

it("reads an unknown join policy as not set and only saves a picked one", async () => {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, {
      model: { groupId: "g", name: "Team", members: [], memberCount: 0, ownerId: "me", adminIds: [], mutedIds: [],
        canManage: true, isOwner: true, joinPolicy: null },
    });
  } }), { attachTo: document.body });
  await flushPromises();
  const list = host.findComponent(FlareSettingsList);
  const manage = (list.props("sections") as Array<{ items: Array<{ key: string; detail?: string }> }>)
    .flatMap((section) => section.items).find((item) => item.key === "joinPolicy");
  expect(manage?.detail).toBe("未设置");
  list.vm.$emit("select", { key: "joinPolicy" });
  await flushPromises();
  const save = host.findAllComponents(FlareButton).find((button) => button.text() === "保存");
  expect(save?.props("disabled")).toBe(true);
  const radio = host.findComponent(FlareRadioGroup);
  expect(radio.props("modelValue")).toBe("");
  radio.vm.$emit("update:modelValue", "approval");
  await flushPromises();
  const detail = host.findComponent(FlareGroupDetail);
  save?.vm.$emit("click");
  await flushPromises();
  expect(detail.emitted("setJoinPolicy")).toEqual([["approval"]]);
});
it("previews the first members and opens everyone, searchable, from the members row", async () => {
  const members = Array.from({ length: 30 }, (_, index) => ({ id: `u${index}`, name: index === 25 ? "林夏" : `成员${index}` }));
  const bigGroup = { groupId: "g", name: "Big team", members, memberCount: 30, ownerId: "u0", adminIds: [], mutedIds: [], canManage: true, isOwner: true };
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, { model: bigGroup });
  } }), { attachTo: document.body });
  // Nineteen people and the add tile fill the preview grid.
  expect(host.findComponent(FlareGroupMemberGrid).props("members")).toHaveLength(19);
  const rows = host.findAll(".flare-settings__row");
  const membersRow = rows.find((row) => row.text().includes("群成员"));
  expect(membersRow?.find(".flare-settings__chev").exists()).toBe(true);
  await membersRow!.trigger("click");
  await flushPromises();
  expect(document.body.textContent).toContain("群成员（30）");
  const search = document.body.querySelector<HTMLInputElement>(".flare-group-detail__sheet input[type=search]");
  expect(search).not.toBeNull();
  search!.value = "林";
  search!.dispatchEvent(new Event("input"));
  await flushPromises();
  const names = [...document.body.querySelectorAll(".flare-group-detail__members .flare-contact-item__name")].map((node) => node.textContent);
  expect(names).toEqual(["林夏"]);
});
it("emits host-backed member searches without filtering the loaded rows locally", async () => {
  const searchMembers = vi.fn();
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, {
      model: { groupId: "g", name: "Team", members: [{ id: "a", name: "Alice" }], memberCount: 20,
        ownerId: "a", adminIds: [], mutedIds: [], canManage: true, isOwner: true },
      onSearchMembers: searchMembers,
    });
  } }), { attachTo: document.body });
  const membersRow = host.findAll(".flare-settings__row").find((row) => row.text().includes("群成员"));
  await membersRow!.trigger("click");
  await flushPromises();
  const search = document.body.querySelector<HTMLInputElement>(".flare-group-detail__sheet input[type=search]");
  search!.value = "林";
  search!.dispatchEvent(new Event("input"));
  await flushPromises();
  expect(searchMembers).toHaveBeenCalledWith("林");
  const names = [...document.body.querySelectorAll(".flare-group-detail__members .flare-contact-item__name")].map((node) => node.textContent);
  expect(names).toEqual(["Alice"]);
});
it("counts the whole group in the preview grid header and keeps long names inside their cells", async () => {
  const members = Array.from({ length: 30 }, (_, index) => ({ id: `u${index}`, name: index === 1 ? "产品体验与用户研究中心华东区负责人" : `成员${index}` }));
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, { model: { groupId: "g", name: "Big team", members, memberCount: 30, ownerId: "u0", adminIds: [], mutedIds: [], canManage: false, isOwner: false } });
  } }), { attachTo: document.body });
  const grid = host.findComponent(FlareGroupMemberGrid);
  expect(grid.get(".flare-member-grid__count").text()).toBe("30 名成员");
  expect(grid.get(".flare-member-grid__grid").attributes("style")).toContain("minmax(0, 1fr)");
  expect(grid.findAll(".flare-member-grid__cell")[1].attributes("title")).toBe("产品体验与用户研究中心华东区负责人");
});
it("shows a loading state until the model arrives, and the unavailable state only without one", async () => {
  host = mount(defineComponent({ props: { loading: Boolean }, setup(props) {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, { model: null, loading: props.loading });
  } }), { props: { loading: true }, attachTo: document.body });
  expect(host.text()).toContain("加载中");
  await host.setProps({ loading: false });
  expect(host.text()).not.toContain("加载中");
  expect(host.find(".flare-group-detail__empty").exists()).toBe(true);
});
it("gives the rows the viewer can change a chevron and leaves the rest as values", async () => {
  const model = { groupId: "g", name: "Team", announcement: "", members: [], memberCount: 3,
    ownerId: "a", adminIds: [], mutedIds: [], canManage: false, isOwner: false, myNickname: "" };
  const chevrons = () => Object.fromEntries(host.findAll(".flare-settings__row")
    .map((row) => [row.get(".flare-settings__label").text(), row.find(".flare-settings__chev").exists()]));
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, { model });
  } }), { attachTo: document.body });
  expect(chevrons()).toMatchObject({ 群名称: false, 群公告: false, 群成员: true, 我的群昵称: false });
  host.findComponent(FlareSettingsList).vm.$emit("select", { key: "myNickname" });
  await flushPromises();
  expect(host.findComponent(FlareFormSheet).props("open")).toBe(false);
  host.unmount();

  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, { model: { ...model, canManage: true }, onUpdateMyNickname: () => {} });
  } }), { attachTo: document.body });
  expect(chevrons()).toMatchObject({ 群名称: true, 群公告: true, 我的群昵称: true, 进群方式: true });
  host.unmount();

  // A host that persists through submitEdit instead of the event can edit its nickname too.
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, { model, submitEdit: async () => {} });
  } }), { attachTo: document.body });
  expect(chevrons()).toMatchObject({ 我的群昵称: true });
});
it("claims no state for my notification and pin settings when they could not be read", async () => {
  const onToggleMyMuted = vi.fn();
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, {
      onToggleMyMuted,
      model: { groupId: "g", name: "Team", members: [], memberCount: 3, ownerId: "o", adminIds: [], mutedIds: [],
        canManage: false, isOwner: false, myMuted: null, myPinned: null },
    });
  } }), { attachTo: document.body });
  await flushPromises();
  const sections = host.findComponent(FlareSettingsList).props("sections") as Array<{ items: Array<{ key: string; kind?: string; detail?: string }> }>;
  const items = sections.flatMap((section) => section.items);
  expect(items.find((item) => item.key === "notif")).toMatchObject({ kind: "value", detail: "暂时无法读取" });
  expect(items.find((item) => item.key === "pin")).toMatchObject({ kind: "value", detail: "暂时无法读取" });
  expect(host.findAll('[role="switch"]')).toHaveLength(0);
});
