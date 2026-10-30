import type { FlareIconName } from "@flare-im/vue-ui";
import type { FlarePluginViewModel } from "@flare-im/vue-ui/contracts";

export interface CardExample { id: string; icon: FlareIconName; sender: string; time: string; self?: boolean; view: FlarePluginViewModel }
// Explicitly fictional preview content; no SDK, network or message commands.
export function cardExamples(): CardExample[] {
  const tomorrow = Date.now() + 24 * 60 * 60 * 1000;
  return [
    { id: "solitaire", icon: "multi-select", sender: "你", time: "10:42", self: true, view: {
      available: true, title: "接龙", fields: [], detail: true,
      blocks: [
        { kind: "text", style: "title", text: "周五下午茶，一起点点心" },
        { kind: "text", style: "secondary", text: "请按「姓名 + 数量」填写，明天中午截止。" },
        { kind: "entries", numbered: true, total: 2, more: false, items: [
          { index: 1, name: "小周", text: "蛋挞 × 2" }, { index: 2, name: "小陈", text: "可颂 × 1" },
        ] },
      ],
      actions: [{ id: "join", label: "参与接龙", style: "primary", form: ["entry"] },
        { id: "end", label: "结束接龙", style: "danger", confirm: "结束后，群成员将无法继续参与。确定结束这条示例接龙吗？" }],
      inputs: [{ id: "entry", kind: "text", label: "接龙内容", placeholder: "姓名 + 数量", required: true, maxLength: 60 }],
    } },
    { id: "task", icon: "check", sender: "林一", time: "10:44", view: {
      available: true, title: "任务", fields: [], detail: true,
      blocks: [
        { kind: "text", style: "title", text: "确认新版本的上线检查清单" },
        { kind: "text", style: "secondary", text: "核对发布内容、灰度范围和回滚方案。" },
        { kind: "progress", label: "完成进度", value: 2, total: 3, percent: 67 },
        { kind: "fields", fields: [{ label: "负责人", value: "你、小周、小陈" }, { label: "截止", value: "明天 18:00" }] },
      ],
      actions: [{ id: "complete", label: "标记完成", style: "primary" }],
      menuActions: [{ id: "end", label: "取消任务", style: "danger", confirm: "确定取消这条示例任务吗？" }],
    } },
    { id: "poll", icon: "poll", sender: "小周", time: "10:46", view: {
      available: true, title: "投票", fields: [], detail: true,
      blocks: [
        { kind: "text", style: "title", text: "周五的分享会，选一个主题" },
        { kind: "text", style: "secondary", text: "单选 · 选择后可修改" },
        { kind: "choices", multiple: false, voted: false, closed: false, showResults: false, inputName: "choice",
          options: [{ index: 0, label: "设计细节与体验打磨", selected: false }, { index: 1, label: "把自动化测试用起来", selected: false }],
          action: { id: "vote", label: "投票", style: "primary" } },
      ], actions: [], menuActions: [{ id: "end", label: "结束投票", style: "danger", confirm: "确定结束这条示例投票吗？" }],
    } },
    { id: "schedule", icon: "calendar", sender: "林一", time: "10:48", view: {
      available: true, title: "日程", fields: [], detail: true,
      blocks: [
        { kind: "text", style: "title", text: "下一阶段产品与设计评审" },
        { kind: "time", label: "时间", atMs: tomorrow, endMs: tomorrow + 3600000, countdown: false },
        { kind: "fields", fields: [{ label: "地点", value: "三楼 · 会议室 A" }, { label: "参与人", value: "产品、设计与研发" }] },
      ], actions: [{ id: "accept", label: "接受邀请", style: "primary" }, { id: "decline", label: "暂不参加" }],
    } },
    { id: "announcement", icon: "announcement", sender: "你", time: "10:50", self: true, view: {
      available: true, title: "群公告", fields: [], detail: true,
      blocks: [
        { kind: "text", style: "title", text: "本周协作安排" },
        { kind: "text", style: "body", maxLines: 3, text: `周五 15:00 进行阶段评审，请提前更新各自负责的内容。
需要协助的事项可以直接在群里提出。
评审后统一整理结论与下一步安排。
会议材料会同步到共享文档。` },
        { kind: "progress", label: "已确认", value: 5, total: 8, percent: 62.5 },
      ], actions: [{ id: "confirm", label: "确认已读", style: "primary" }],
    } },
    { id: "closed", icon: "multi-select", sender: "小陈", time: "昨天", view: {
      available: true, title: "接龙", fields: [], detail: true,
      blocks: [{ kind: "text", style: "title", text: "上周的活动报名" }, { kind: "status", text: "已结束", tone: "neutral" }, { kind: "text", style: "secondary", text: "共 6 人参与，可在详情中查看完整名单。" }], actions: [],
    } },
    { id: "unavailable", icon: "calendar", sender: "小陈", time: "昨天", view: {
      available: false, title: "日程", unavailableReason: "catalog_unreachable", fields: [], actions: [],
    } },
  ];
}
