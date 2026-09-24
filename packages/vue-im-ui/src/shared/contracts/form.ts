// Form-control shared contracts.

/**
 * `text` 是链接式动作(忘记密码 / 取消 / 举报),用品牌色。
 * `quiet` 是**中性**的安静动作:一行里那个「算了」型出口 —— 它和主按钮配对时不该也是品牌色,
 * 否则一对按钮读成「紫块 + 紫字」,分不出谁主谁次。与 SearchBar / FilterTabs 的 `quiet` 同一个词:
 * 这个控件不画自己的面。
 */
/**
 * 按钮的强度阶梯。`quiet` 是中性的低强度一档:透明底、无描边、次级文字色,内距走尺寸类 ——
 * 它是配在主按钮旁边的那个「出口」。`text` 用品牌色,两颗都用紫色就分不出主次。
 * 成员四端必须一致,由 spec/validate.mjs 的枚举等值关守。
 */
export type FlareButtonVariant = "primary" | "secondary" | "ghost" | "danger" | "text" | "quiet";
/** 同一份成员,给需要遍历全部变体的地方(测试、文档演示)用。 */
export const FLARE_BUTTON_VARIANTS = ["primary", "secondary", "ghost", "danger", "text", "quiet"] as const satisfies readonly FlareButtonVariant[];
export type FlareControlSize = "sm" | "md" | "lg";

/** One option in a select / radio group. */
export interface FlareSelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}
