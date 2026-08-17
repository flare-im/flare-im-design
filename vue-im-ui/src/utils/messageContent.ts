// 内容类型判别符。**故意不从 `@flare-im/sdk` 导入。**
//
// 这个文件在纯组件层（被 MessageBubble 用，也就是几乎每个消费方都会加载它）。
// 原先它写的是 `import { MessageContentType } from "@flare-im/sdk"` —— 一个
// **值**导入，进产物、运行时真解析。而 package.json 把 `@flare-im/sdk` 声明成
// `peerDependenciesMeta.optional`，两者直接矛盾：
//
//   - 本地开发看不出问题：示例 app 的 vite alias 把 `@flare-im/sdk` 指到同级仓源码；
//   - 装 npm 发布包的消费方（如 flare-social 各端，它们用 social wasm 核、
//     压根不装 IM 的 TS SDK）构建即失败：
//     `"MessageContentType" is not exported by "__vite-optional-peer-dep:@flare-im/sdk"`。
//
// 所以把取值本地化，让组件库对 SDK 真正只有**类型**依赖（类型会被编译擦除）。
// `src/app/**` 是 kit 里附带的 IM 示例应用层，那里依赖 SDK 是合理的，不受此约束。
//
// ## 顺序是契约的一部分
//
// 下面这份列表是 SDK `MessageContentType` 枚举的**有序**镜像。顺序不能动 ——
// 数值型 contentType 是按声明下标解析的（见 messageContentTypeForUi），
// 插一个到中间会让所有后续类型静默错位。
//
// 枚举本身是从 Rust 核生成的线上契约，会演进。漂移由
// `messageContent.contract.test.ts` 门禁守着：它在本仓（SDK 是 devDependency，
// 能解析到真枚举）逐位比对这份列表。发布物不带该依赖，门禁却拿真值校验 ——
// 这是「组件库零运行时依赖」与「契约不漂移」两个目标唯一能同时成立的方式。
const MESSAGE_CONTENT_TYPES = [
  "text",
  "image",
  "video",
  "audio",
  "file",
  "location",
  "card",
  "sticker",
  "emoji",
  "quote",
  "link_card",
  "forward",
  "thread",
  "mini_program",
  "rich_text",
  "image_group",
  "system",
  "notification",
  "vote",
  "task",
  "schedule",
  "announcement",
  "custom",
  "placeholder",
] as const;

/** 门禁测试用：逐位比对 SDK 枚举。业务代码不要依赖它。 */
export const __messageContentTypesForContractTest = MESSAGE_CONTENT_TYPES;

const CUSTOM = "custom";

const contentTypeValues = new Set<string>(MESSAGE_CONTENT_TYPES);

export function messageContentTypeForUi(value: unknown): string {
  // "system" / "notification" 也在上面的列表里（枚举本来就有），
  // 所以这里不需要额外的 UI 白名单 —— 它们照常命中 contentTypeValues，
  // isSystemLike 能正常触发，不会退化成 Custom 气泡。
  if (typeof value === "string" && contentTypeValues.has(value)) return value;
  if (typeof value === "number") {
    return MESSAGE_CONTENT_TYPES[value] ?? CUSTOM;
  }
  return CUSTOM;
}

export function buildUiTaggedMessageContent(input: {
  contentType: unknown;
  data?: Record<string, unknown>;
}): Record<string, unknown> {
  const contentType = messageContentTypeForUi(input.contentType);
  const data = input.data ?? {};
  return {
    contentType,
    ...data,
    [contentType]: data,
  };
}

export function normalizeEmojiPackKey(value: string): string {
  const trimmed = value.trim();
  if (!trimmed) return "";
  const bracket = /^\[([a-z][a-z0-9_]*)\]$/.exec(trimmed);
  if (bracket) return bracket[1];
  return /^[a-z][a-z0-9_]*$/.test(trimmed) ? trimmed : "";
}

export function formatEmojiPackToken(value: string): string {
  const key = normalizeEmojiPackKey(value);
  return key ? `[${key}]` : "";
}

export function resolveLoneEmojiPackKey(value: string): string {
  const trimmed = value.trim();
  return /^\[[a-z][a-z0-9_]*\]$/.test(trimmed) ? normalizeEmojiPackKey(trimmed) : "";
}
