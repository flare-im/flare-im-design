/**
 * 一层「上下文层」(多选工具条一类:不是模态,但占着一个可以退出的状态)对 Escape 的裁决表。
 *
 * 照 form-behavior.ts 的做法写成纯函数:输入是几个布尔事实,输出三种意图。事实由
 * useContextualLayer.ts 在真 DOM 里读出来,表本身在 happy-dom 里就能逐行验证。
 *
 * 顺序就是优先级,每一条都对应一个真实踩过或会踩的坑:
 *  - IME 合成中 Escape 是取消候选,不是任何层的键(与 form-behavior 同序、最先);
 *  - `defaultPrevented`:内层已经用掉了 —— 动作菜单、composer 的面板/编辑/回复、会话批量条的
 *    `.esc.prevent`、Select/DatePicker 的桌面弹层。消费了 Escape 的层必须 preventDefault,
 *    这是本仓的契约(见 useContextualLayer.ts 头注释);
 *  - 模态在上(kit 的模态栈,或任何**可见**的 `aria-modal` 对话框):模态自己收 Escape;
 *  - 焦点在可编辑控件里:Escape 归输入框(composer 裸 Escape 只 blur、不 preventDefault,
 *    所以第二下才退出 —— 两步,是刻意的「先里后外」);
 *  - 焦点所在的页面/面不包含本层(全局搜索盖在聊天上、详情栏里的一页):那一页在关自己,
 *    本层在它下面,不该跟着退 —— 「一次 Escape 关两层」正是 useModalSurface 头注释里的坑;
 *  - 不是最上面那层、或者被 v-show 藏起来了:不响应;
 *  - busy:吞掉不退出,与 useModalSurface 的 dismissible=false 同一语义,也对应退出键此时禁用。
 */
export type FlareContextualLayerEscapeIntent = "exit" | "swallow" | "ignore";

export interface FlareContextualLayerEscapeInput {
  key: string;
  composing?: boolean;
  defaultPrevented?: boolean;
  modalOpen?: boolean;
  editableTarget?: boolean;
  foreignSurface?: boolean;
  topmost?: boolean;
  visible?: boolean;
  busy?: boolean;
}

export function resolveContextualLayerEscape(input: FlareContextualLayerEscapeInput): FlareContextualLayerEscapeIntent {
  if (input.key !== "Escape") return "ignore";
  if (input.composing) return "ignore";
  if (input.defaultPrevented) return "ignore";
  if (input.modalOpen) return "ignore";
  if (input.editableTarget) return "ignore";
  if (input.foreignSurface) return "ignore";
  if (input.topmost === false || input.visible === false) return "ignore";
  return input.busy ? "swallow" : "exit";
}
