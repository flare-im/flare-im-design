/// 聊天界面可以跳转的 URL。
///
/// 消息内容是别人写的,里面的链接就是攻击者挑的字符串。`javascript:` 和 `data:`
/// 在 href 上会在页面来源里执行,`file:` / `blob:` 会读本地状态。所以默认只有一条:
/// 不是明摆着的网址就当纯文本。
///
/// kit 几乎从不自己跳转——组件把 URL 报给宿主,由宿主打开。这是两边共用的判定,
/// 免得 kit 的链接卡片和宿主的打开逻辑各有一套。
library;

/// 消息链接唯一允许的两个 scheme。
const List<String> flareSafeUrlSchemes = ['http', 'https'];

/// 可跳转时返回规范化后的 URL,否则返回 null。
///
/// 完全不带 scheme 的字符串按 https 读——用户打 `example.com` 就是这个意思——
/// 但只在真的一个 scheme 都没有时才补,`javascript:alert(1)` 绝不会被救成
/// `https://javascript:alert(1)`。
String? safeExternalUrl(String? raw) {
  if (raw == null) return null;
  // 只剥 URL 解析器本来就会忽略的制表符与换行:`java\tscript:` 会规范成
  // `javascript:`,先剥掉才判得准。**不能连空格一起剥**——那会把一句话
  // (`just some text`)捏成一个合法主机名。
  final trimmed = raw.trim().replaceAll(RegExp(r'[\t\n\r]'), '');
  if (trimmed.isEmpty) return null;
  // 真正的 URL 里没有裸空格。拒掉它,一是不让一句话被当成网址,二是让四端靠
  // 同一条规则对齐,而不是靠谁的解析器更严:Dart 的 Uri 会把 `just some text`
  // 百分号编码成一个合法主机,JS 的 URL 会直接抛。
  if (RegExp(r'\s').hasMatch(trimmed)) return null;
  final candidate = _hasScheme(trimmed) ? trimmed : 'https://$trimmed';
  final parsed = Uri.tryParse(candidate);
  if (parsed == null) return null;
  if (!flareSafeUrlSchemes.contains(parsed.scheme.toLowerCase())) return null;
  if (parsed.host.isEmpty) return null;
  return parsed.toString();
}

/// 这个字符串是不是本界面可以打开的网址。
bool isSafeExternalUrl(String? raw) => safeExternalUrl(raw) != null;

/// 开头是 `scheme:`(RFC 3986:字母、数字、`+`、`-`、`.`)。
///
/// 主机加端口在这套语法里长得一样(`example.com:8443` 也是合法 scheme),所以冒号
/// 后面跟数字就当端口。认错的最坏结果是一个主机名古怪的 https URL,无害;把真
/// scheme 认成主机才是不能发生的,这里的偏向就是躲开那一侧。
bool _hasScheme(String value) {
  final match = RegExp(r'^[a-z][a-z0-9+.\-]*:', caseSensitive: false).firstMatch(value);
  if (match == null) return false;
  return !RegExp(r'^\d').hasMatch(value.substring(match.end));
}
