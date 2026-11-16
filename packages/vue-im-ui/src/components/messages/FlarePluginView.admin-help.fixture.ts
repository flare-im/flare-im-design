import type { FlarePluginBlock } from "../../shared/contracts/plugin-ui";

// The mission center's group sign-in admin page (group_signin in the mission plugin's
// platform-plugin.template.json), resolved the way the console sends it to the kit: the explanation notes
// are copied verbatim, the field and row blocks carry sample resolved data.
export const groupSigninBlocks: FlarePluginBlock[] = [
  {
    kind: "note",
    text: "成员在允许签到的群里发送签到关键字（整条消息去掉首尾空白后与某个关键字完全相同），即完成本群当天的签到；同一个人在同一个群一天只算一次。要先在应用的功能发布里开启「群关键字签到」，任务中心才会收到群消息。奖励由触发事实为群签到的任务发放，例如模板「群每日签到」：奖励动作按群签到设置发放时，金额和钱包用群单独设置的，没有设置的用应用的。只限名单时，只有设为允许的群能签到。改动立即生效；打开总开关之前发的消息不算。",
    tone: "info",
  },
  {
    kind: "note",
    text: "群里不会回复签到结果，成员在任务中心的我的记录和钱包里查看到账。",
    tone: "info",
  },
  {
    kind: "note",
    text: "如果应用同时启用了签到插件（flare.checkin）且关键字相同，同一条消息两边都会计入，请只保留一个。",
    tone: "warning",
  },
  {
    kind: "fields",
    fields: [
      { label: "群签到开启", value: "是" },
      { label: "哪些群能签到", value: "只限名单" },
      { label: "奖励金额（最小单位）", value: "100" },
      { label: "预算别名", value: "daily" },
    ],
  },
  { kind: "note", text: "应用的签到关键字：", tone: "info" },
  {
    kind: "note",
    text: "在群的行上逐项修改它的单独设置：「能否签到」改是否允许（备注名留空不改），「奖励」改金额与预算别名，「关键字」改关键字，留空的项跟随应用，没改的项保持原样。「恢复跟随应用」删除这个群的全部单独设置。点开一个群查看它的设置。",
    tone: "info",
  },
  {
    kind: "rows",
    source: "flare.mission.admin.group_signin.groups.list",
    columns: [
      { label: "群编号", format: "text" },
      { label: "本群能否签到", format: "text" },
    ],
    emptyText: "还没有单独设置的群，所有群都按应用的设置",
    rows: [{ key: "g1", cells: [{ text: "g1" }, { text: "允许" }] }],
  } as FlarePluginBlock,
];
