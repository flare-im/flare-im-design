import '../tokens/flare_strings.dart';

/// One markdown message read as one plain line — what a conversation row, a reply strip or a quote shows.
///
/// Marks are stripped, never interpreted: a link keeps its words and loses its target, an image becomes the
/// `preview.image` term with its alt text when it has one, and a fenced block keeps the code inside it. The
/// rule is shared with the Vue, SwiftUI and Compose kits and tested against
/// `spec/markdown-preview-vectors.json`; Vue has applied it to every preview since before this kit existed,
/// which is why the same string used to arrive here with its asterisks (FR-120).
///
/// The word classes are written out as ASCII on purpose. `\w` means different things in different regex
/// engines — under ICU it includes 中文 — and `__周报__已发出` must read the same on every platform.
String flareMarkdownToPlainText(String content, FlareStrings strings) {
  const word = r'A-Za-z0-9_';
  var text = content.replaceAll(RegExp(r'\r\n?'), '\n');
  text = text
      // A fenced block keeps what is inside it; the fence and its language are not words.
      .replaceAllMapped(
        RegExp(r'```(?:[^\n`]*)\n?([\s\S]*?)```'),
        (m) => m.group(1) ?? '',
      )
      .replaceAllMapped(RegExp(r'!\[([^\]\n]*)\]\([^)]+\)'), (m) {
        final label = (m.group(1) ?? '').trim();
        return label.isEmpty
            ? strings.previewImage
            : strings.previewImageNamed(label);
      })
      .replaceAllMapped(RegExp(r'\[([^\]\n]+)\]\([^)]+\)'), (m) => m.group(1)!)
      .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
      .replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '')
      .replaceAll(RegExp(r'^\s{0,3}(?:[-*+]|\d+\.)\s+', multiLine: true), '')
      .replaceAll(RegExp(r'^\s{0,3}---+\s*$', multiLine: true), ' ')
      .replaceAllMapped(
        RegExp(r'<u>([\s\S]+?)</u>', caseSensitive: false),
        (m) => m.group(1)!,
      )
      .replaceAllMapped(RegExp(r'\*\*\*([\s\S]+?)\*\*\*'), (m) => m.group(1)!)
      .replaceAllMapped(RegExp(r'___([\s\S]+?)___'), (m) => m.group(1)!)
      .replaceAllMapped(RegExp(r'\*\*([\s\S]+?)\*\*'), (m) => m.group(1)!)
      .replaceAllMapped(
        RegExp('(^|[^$word])__([^_\\n]+?)__(?=\$|[^$word])'),
        (m) => '${m.group(1)}${m.group(2)}',
      )
      .replaceAllMapped(RegExp(r'~~([\s\S]+?)~~'), (m) => m.group(1)!)
      .replaceAllMapped(RegExp(r'`([^`\n]+?)`'), (m) => m.group(1)!)
      .replaceAllMapped(RegExp(r'\*([^*\n]+?)\*'), (m) => m.group(1)!)
      .replaceAllMapped(
        RegExp('(^|[^$word])_([^_\\n]+?)_(?=\$|[^$word])'),
        (m) => '${m.group(1)}${m.group(2)}',
      )
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
  return text;
}
