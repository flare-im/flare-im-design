import { translateFlare } from "../i18n/messages";

/**
 * 把 SDK 抛出的错误变成能给用户看的一句话。
 *
 * 核心抛出的是 i18n **key**（`FlareError::localized`），期待客户端翻译；
 * 而 kit 的语言表里没有 `sdk.message.*` 这一族，`resolveFlareMessage` 查不到时
 * 会把原 key 返回。再加上 wasm 桥把整个错误对象序列化进了 `Error.message`，
 * 用户最终看到的是这种东西：
 *
 *   {"code":"sdk.error","message":"错误 [INVALID_PARAMETER] sdk.message.card.avatar.invalid_url",…}
 *
 * 这里做三件事：拆掉 JSON 信封、取出 key、按「字段 + 原因」拼出可读文案。
 * 任何一步失败都退回到一句人话——绝不把原始 JSON 或裸 key 交给用户。
 */

const KEY_PATTERN = /\b(sdk(?:\.[a-z0-9_]+)+)\b/i;

/** 从 wasm 桥的 JSON 信封里取出真正的错误信息；不是信封就原样返回。 */
function unwrapEnvelope(raw: string): string {
  const text = raw.trim();
  if (!text.startsWith("{")) return text;
  try {
    const parsed = JSON.parse(text) as Record<string, unknown>;
    const inner = parsed.message;
    return typeof inner === "string" && inner.trim() ? unwrapEnvelope(inner) : text;
  } catch {
    return text;
  }
}

/** `sdk.message.card.avatar.invalid_url` -> { field: "card.avatar", reason: "invalid_url" } */
function splitKey(key: string): { field: string; reason: string } | null {
  const parts = key.split(".");
  if (parts.length < 4) return null;
  const reason = parts[parts.length - 1];
  const field = parts.slice(2, -1).join(".");
  return field ? { field, reason } : null;
}

function translated(key: string): string | null {
  const hit = translateFlare(key);
  // 查不到时 resolveFlareMessage 会把 key 原样返回
  return hit && hit !== key ? hit : null;
}

export function describeSdkError(error: unknown, fallback?: string): string {
  const generic = fallback ?? translateFlare("error.operationFailed");
  const raw = error instanceof Error ? error.message : String(error ?? "");
  if (!raw.trim()) return generic;

  const text = unwrapEnvelope(raw);
  const key = KEY_PATTERN.exec(text)?.[1];
  if (!key) return text || generic;

  const whole = translated(key);
  if (whole) return whole;

  const split = splitKey(key);
  if (split) {
    // 字段没有文案时用「该字段」兜底，不能把 `link_card.thumbnail_url` 这种
    // 内部路径拼进给用户的句子里——那和直接甩 key 没有本质区别。
    const fieldName = translated(`sdkError.field.${split.field}`)
      ?? translated("sdkError.field.unknown")
      ?? "";
    const reason = translated(`sdkError.reason.${split.reason}`);
    if (reason) return reason.replace("{field}", fieldName);
  }

  return generic;
}
