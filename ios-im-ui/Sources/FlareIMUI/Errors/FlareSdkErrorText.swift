import Foundation

/// 把 SDK 抛出的错误变成能给用户看的一句话。
///
/// 核心用 `FlareError::localized` 抛出的是 i18n **key**（例如
/// `sdk.message.card.avatar.invalid_url`），期待客户端翻译。客户端若直接把
/// `error.message` 显示出来，用户看到的就是这串 key；Web 端还会更糟——
/// wasm 桥把整个错误对象序列化进了 message，用户看到的是一整段 JSON。
///
/// 这里做三件事：拆掉可能存在的 JSON 信封、取出 key、按「字段 + 原因」
/// 拼出可读文案。任何一步失败都退回到一句人话，绝不把 key 交给用户。
///
/// 文案用英文原文当 key，由 app 的 String Catalog 负责翻译——与本仓 iOS 侧
/// 既有的 English-key 约定一致。
public enum FlareSdkErrorText {

    /// `sdk.message.card.avatar.invalid_url` -> ("card.avatar", "invalid_url")
    static func splitKey(_ key: String) -> (field: String, reason: String)? {
        let parts = key.split(separator: ".").map(String.init)
        guard parts.count >= 4 else { return nil }
        let reason = parts[parts.count - 1]
        let field = parts[2..<(parts.count - 1)].joined(separator: ".")
        return field.isEmpty ? nil : (field, reason)
    }

    /// 从 JSON 信封里取出真正的错误信息；不是信封就原样返回。
    static func unwrapEnvelope(_ raw: String) -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasPrefix("{"), let data = text.data(using: .utf8) else { return text }
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let inner = object["message"] as? String,
            !inner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return text }
        return unwrapEnvelope(inner)
    }

    static func firstSdkKey(in text: String) -> String? {
        // sdk 开头、点分、只含小写字母数字下划线的那一段
        for token in text.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" }) {
            let candidate = String(token).trimmingCharacters(in: CharacterSet(charactersIn: "[]（）()，,。；;:"))
            guard candidate.hasPrefix("sdk."), candidate.contains(".") else { continue }
            let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_.")
            if candidate.unicodeScalars.allSatisfy({ allowed.contains($0) }) { return candidate }
        }
        return nil
    }

    static func fieldName(_ field: String) -> String? {
        switch field {
        case "card.avatar": return "the contact card avatar"
        case "card.id": return "the contact card ID"
        case "link_card.url": return "the link URL"
        case "link_card.thumbnail_url": return "the link thumbnail"
        case "app_card.thumbnail_url": return "the thumbnail"
        case "app_card.url": return "the card link"
        case "mini_program.thumbnail_url": return "the mini program thumbnail"
        case "image.url": return "the image URL"
        case "video.url": return "the video URL"
        case "file.url": return "the file URL"
        default: return nil
        }
    }

    static func sentence(field: String, reason: String) -> String? {
        // 字段没有文案时用 "this field" 兜底，不能把 link_card.thumbnail_url
        // 这类内部路径拼进给用户的句子里——那和直接甩 key 没有本质区别。
        let name = fieldName(field) ?? "this field"
        switch reason {
        case "invalid_url": return "\(name) is not a valid link. Use an http(s) address."
        case "required", "empty": return "\(name) is required."
        case "too_long": return "\(name) is too long."
        case "invalid": return "\(name) has an invalid format."
        default: return nil
        }
    }

    /// 主入口。`fallback` 是彻底无法识别时的兜底文案。
    public static func describe(_ raw: String, fallback: String = "The operation failed.") -> String {
        guard !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return fallback }
        let text = unwrapEnvelope(raw)
        guard let key = firstSdkKey(in: text) else { return text.isEmpty ? fallback : text }
        guard let parts = splitKey(key), let sentence = sentence(field: parts.field, reason: parts.reason) else {
            return fallback
        }
        return sentence
    }

    public static func describe(_ error: Error, fallback: String = "The operation failed.") -> String {
        describe(error.localizedDescription, fallback: fallback)
    }
}
