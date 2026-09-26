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
        ownerId: "me", adminIds: [], mutedIds: [], canManage: true, isOwner: true, discoverable: false },
    });
  } }), { attachTo: document.body });
  // 改名从 hero 的标题进去:「群名称」那一行已经去掉了(名字在同一屏上不写两遍)。
  await host.find(".flare-group-detail__title-text").trigger("click");
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
        ownerId: "a", adminIds: [], mutedIds: [], canManage: false, isOwner: false, discoverable: false },
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
        ownerId: "a", adminIds: [], mutedIds: [], canManage: true, isOwner: true, discoverable: false },
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
      model: { groupId: "g", name: "Team", memberCount: 2, ownerId: "me", adminIds: ["ivy"], mutedIds: [], canManage: true, isOwner: true, discoverable: false,
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
    ownerId: "a", adminIds: [], mutedIds: [], canManage: false, isOwner: false, discoverable: false, joinPolicy: null };
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
  // 比的是**顺序**，不是完整 class 串：FlareSettingsList 现在还带一个形态类
  // （flare-settings--card / --flush），把整串拿来相等比，加个变体就会红。
  const order = [...host.element.querySelectorAll(".flare-settings, .read-bar, .flare-group-detail__foot, .report")]
    .map((node) => node.className.split(/\s+/)[0]);
  expect(order).toEqual(["flare-settings", "read-bar", "flare-settings", "flare-group-detail__foot", "report"]);
});

it("reads an unknown join policy as not set and only saves a picked one", async () => {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, {
      model: { groupId: "g", name: "Team", members: [], memberCount: 0, ownerId: "me", adminIds: [], mutedIds: [],
        canManage: true, isOwner: true, discoverable: false, joinPolicy: null },
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
it("emits the requested public-search state from the discoverability switch", async () => {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, {
      model: { groupId: "g", name: "Team", members: [], memberCount: 1, ownerId: "me", adminIds: [], mutedIds: [],
        canManage: true, isOwner: true, discoverable: false },
    });
  } }), { attachTo: document.body });
  const list = host.findComponent(FlareSettingsList);
  const discoverable = (list.props("sections") as Array<{ items: Array<{ key: string; value?: boolean }> }>)
    .flatMap((section) => section.items).find((item) => item.key === "discoverable");
  expect(discoverable).toMatchObject({ value: false });
  list.vm.$emit("toggle", { key: "discoverable" }, true);
  expect(host.findComponent(FlareGroupDetail).emitted("toggleDiscoverable")).toEqual([[true]]);
});
it("previews the first members and opens everyone, searchable, from the grid header", async () => {
  const members = Array.from({ length: 30 }, (_, index) => ({ id: `u${index}`, name: index === 25 ? "林夏" : `成员${index}` }));
  const bigGroup = { groupId: "g", name: "Big team", members, memberCount: 30, ownerId: "u0", adminIds: [], mutedIds: [], canManage: true, isOwner: true, discoverable: false };
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, { model: bigGroup });
  } }), { attachTo: document.body });
  // Nineteen people and the add tile fill the preview grid.
  expect(host.findComponent(FlareGroupMemberGrid).props("members")).toHaveLength(19);
  // 完整名单从成员栅格的头部进去:「群成员 / N 名成员」那一行已经去掉了
  // (人数在同一屏上不写两遍),头部自己带上了陈述入口的 chevron。
  expect(host.findAll(".flare-settings__row").some((row) => row.text().includes("群成员"))).toBe(false);
  const head = host.get(".flare-member-grid__head");
  expect(head.classes()).toContain("is-interactive");
  expect(head.find(".flare-member-grid__chev").exists()).toBe(true);
  await head.trigger("click");
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
        ownerId: "a", adminIds: [], mutedIds: [], canManage: true, isOwner: true, discoverable: false },
      onSearchMembers: searchMembers,
    });
  } }), { attachTo: document.body });
  await host.get(".flare-member-grid__head").trigger("click");
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
    return () => h(FlareGroupDetail as Component, { model: { groupId: "g", name: "Big team", members, memberCount: 30, ownerId: "u0", adminIds: [], mutedIds: [], canManage: false, isOwner: false, discoverable: false } });
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
    ownerId: "a", adminIds: [], mutedIds: [], canManage: false, isOwner: false, discoverable: false, myNickname: "" };
  const chevrons = () => Object.fromEntries(host.findAll(".flare-settings__row")
    .map((row) => [row.get(".flare-settings__label").text(), row.find(".flare-settings__chev").exists()]));
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, { model });
  } }), { attachTo: document.body });
  // 群名称与群成员已不在设置列表里:它们由 hero 的标题和成员栅格的头部承担。
  expect(chevrons()).toMatchObject({ 群公告: false, 我的群昵称: false });
  expect(Object.keys(chevrons())).not.toContain("群名称");
  expect(Object.keys(chevrons())).not.toContain("群成员");
  // 不能管理的人,标题只是标题:没有改名入口。
  expect(host.find(".flare-group-detail__title").classes()).not.toContain("is-interactive");
  host.findComponent(FlareSettingsList).vm.$emit("select", { key: "myNickname" });
  await flushPromises();
  expect(host.findComponent(FlareFormSheet).props("open")).toBe(false);
  host.unmount();

  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareGroupDetail as Component, { model: { ...model, canManage: true }, onUpdateMyNickname: () => {} });
  } }), { attachTo: document.body });
  expect(chevrons()).toMatchObject({ 群公告: true, 我的群昵称: true, 进群方式: true });
  // 能管理的人,标题就是改名入口 —— 那一行删掉了,功能没有跟着删掉。
  const editableTitle = host.find(".flare-group-detail__title");
  expect(editableTitle.classes()).toContain("is-interactive");
  // 群名现在只有这一处,所以这个按钮的可及名称必须**还是群名**:外层挂 aria-label
  // 会顶掉里面的文字,读屏就再也读不到这个群叫什么。用途挂在铅笔上。
  expect(editableTitle.attributes("aria-label")).toBeUndefined();
  const nameButton = editableTitle.get(".flare-group-detail__title-text");
  expect(nameButton.element.tagName).toBe("BUTTON");
  expect(nameButton.text()).toBe("Team");
  // 铅笔是并排的第二颗按钮,不是名字按钮里的一张图。
  const pencil = editableTitle.get(".flare-group-detail__title-edit");
  expect(pencil.element.tagName).toBe("BUTTON");
  expect(pencil.attributes("aria-label")).toBe("修改群名称");
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
        canManage: false, isOwner: false, discoverable: false, myMuted: null, myPinned: null },
    });
  } }), { attachTo: document.body });
  await flushPromises();
  const sections = host.findComponent(FlareSettingsList).props("sections") as Array<{ items: Array<{ key: string; kind?: string; detail?: string }> }>;
  const items = sections.flatMap((section) => section.items);
  expect(items.find((item) => item.key === "notif")).toMatchObject({ kind: "value", detail: "暂时无法读取" });
  expect(items.find((item) => item.key === "pin")).toMatchObject({ kind: "value", detail: "暂时无法读取" });
  expect(host.findAll('[role="switch"]')).toHaveLength(0);
});
it("opens the rename editor, never the member roster, from the pencil next to the name", async () => {
  // 窄屏上的现场:点铅笔弹出来的是「群成员」名单而不是改名框。铅笔现在是自己的按钮,
  // 它的点击到它为止 —— 包着标题的任何入口(这里用宿主的监听代替)都收不到。
  const hostClick = vi.fn();
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h("div", { onClick: hostClick }, [h(FlareGroupDetail as Component, {
      model: { groupId: "g", name: "Team", memberCount: 30, ownerId: "me", adminIds: [], mutedIds: [],
        canManage: true, isOwner: true, discoverable: false,
        members: Array.from({ length: 30 }, (_, index) => ({ id: `u${index}`, name: `成员${index}` })) },
    })]);
  } }), { attachTo: document.body });
  await flushPromises();
  const pencil = host.get(".flare-group-detail__title-edit");
  // 成员栅格的头部确实是成员名单的入口 —— 铅笔不是它的一部分。
  expect(host.get(".flare-member-grid__head").classes()).toContain("is-interactive");
  expect(pencil.element.closest(".flare-member-grid__head")).toBeNull();
  await pencil.trigger("click");
  await flushPromises();
  const form = host.findComponent(FlareFormSheet);
  expect(form.props("open")).toBe(true);
  expect(form.props("title")).toBe("修改群名称");
  expect(host.findComponent(FlareInput).props("modelValue")).toBe("Team");
  expect(document.body.textContent).not.toContain("群成员（30）");
  expect(document.body.querySelector(".flare-group-detail__members")).toBeNull();
  expect(hostClick).not.toHaveBeenCalled();
  // 名字本身仍是桌面上的改名入口。
  form.vm.$emit("close");
  await flushPromises();
  expect(form.props("open")).toBe(false);
  await host.get(".flare-group-detail__title-text").trigger("click");
  await flushPromises();
  expect(form.props("open")).toBe(true);
  expect(document.body.querySelector(".flare-group-detail__members")).toBeNull();
});
