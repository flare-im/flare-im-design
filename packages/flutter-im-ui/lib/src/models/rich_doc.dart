/// A rich-text message as it is drawn: the RichDoc v2 document the core stores
/// (`docJson`, flare-proto `RichTextContent.doc_json`) read into blocks and
/// runs. The rule is shared with the other three kits and written down in
/// `spec/rich-doc-vectors.json`; Vue implements it in `utils/richDoc.ts`.
library;

import 'dart:convert';

import 'url_safety.dart';

/// The marks a run can carry, in the order a run lists them.
enum FlareRichMark { bold, italic, underline, strike, spoiler }

/// One run of a paragraph or heading.
class FlareRichRun {
  const FlareRichRun(
    this.text, {
    this.marks = const [],
    this.code = false,
    this.link,
    this.mention,
    this.emoji,
  });

  final String text;

  /// The known marks, once each, in [FlareRichMark] order.
  final List<FlareRichMark> marks;

  /// Inline code.
  final bool code;

  /// The href of the innermost link around the run that [safeExternalUrl]
  /// accepts, as written.
  final String? link;

  /// A mention: the user id it names, possibly empty.
  final String? mention;

  /// An emoji: its pack key, possibly empty.
  final String? emoji;

  bool has(FlareRichMark mark) => marks.contains(mark);

  FlareRichRun _linked(String? href) => href == null
      ? this
      : FlareRichRun(
          text,
          marks: marks,
          code: code,
          link: href,
          mention: mention,
          emoji: emoji,
        );
}

/// A block of a rich-text body.
sealed class FlareRichBlock {
  const FlareRichBlock();
}

class FlareRichParagraph extends FlareRichBlock {
  const FlareRichParagraph(this.runs);
  final List<FlareRichRun> runs;
}

class FlareRichHeading extends FlareRichBlock {
  const FlareRichHeading(this.level, this.runs);

  /// 1…6.
  final int level;
  final List<FlareRichRun> runs;
}

class FlareRichQuote extends FlareRichBlock {
  const FlareRichQuote(this.blocks);
  final List<FlareRichBlock> blocks;
}

class FlareRichCode extends FlareRichBlock {
  const FlareRichCode(this.text, {this.language});
  final String text;
  final String? language;
}

class FlareRichList extends FlareRichBlock {
  const FlareRichList({required this.ordered, required this.items});
  final bool ordered;

  /// Each item's blocks; never empty.
  final List<List<FlareRichBlock>> items;
}

class FlareRichDivider extends FlareRichBlock {
  const FlareRichDivider();
}

/// What a covered spoiler run draws in place of [text]: every code point that
/// is not whitespace becomes U+3000 IDEOGRAPHIC SPACE, so the words are in
/// neither the rendered text nor a copy until the reader reveals them.
String flareRichSpoilerCover(String text) => String.fromCharCodes(
  text.runes.map(
    (rune) => _whitespace.hasMatch(String.fromCharCode(rune)) ? rune : 0x3000,
  ),
);

final _whitespace = RegExp(r'\s');

/// The core's own limits (`rich_doc_v2/validate.rs`).
const int flareRichDocMaxDepth = 64;
const int flareRichDocMaxNodes = 10000;

/// The blocks a rich-text body draws for [input] — the document's JSON text
/// or its decoded map — or null when it is not a drawable RichDoc v2 document,
/// and the body shows the message's plain text instead.
List<FlareRichBlock>? flareParseRichDoc(Object? input) {
  Object? value = input;
  if (input is String) {
    try {
      value = jsonDecode(input);
    } on FormatException {
      return null;
    }
  }
  if (value is! Map) return null;
  final version = value['version'];
  if (value['type'] != 'doc' ||
      version is! num ||
      version != 2 ||
      value['children'] is! List) {
    return null;
  }
  if (!_withinLimits(value)) return null;
  return _blocks(value['children'] as List);
}

List<Object?> _children(Object? node) => node is Map && node['children'] is List
    ? node['children'] as List
    : const [];

String _string(Object? value) => value is String ? value : '';

/// Whether the tree stays inside the core's depth and node limits.
bool _withinLimits(Map root) {
  var nodes = 1;
  final stack = <(Object?, int)>[
    for (final child in _children(root)) (child, 1),
  ];
  while (stack.isNotEmpty) {
    final (node, depth) = stack.removeLast();
    if (depth > flareRichDocMaxDepth) return false;
    nodes += 1;
    if (nodes > flareRichDocMaxNodes) return false;
    for (final child in _children(node)) {
      stack.add((child, depth + 1));
    }
  }
  return true;
}

List<FlareRichRun> _runs(
  List<Object?> inlines,
  String? link, [
  List<FlareRichRun>? into,
]) {
  final out = into ?? <FlareRichRun>[];
  void push(FlareRichRun run) => out.add(run._linked(link));
  for (final node in inlines) {
    if (node is! Map) continue;
    switch (node['type']) {
      case 'text':
        final text = _string(node['text']);
        if (text.isEmpty) break;
        final named = <Object?>{
          for (final mark
              in node['marks'] is List ? node['marks'] as List : const [])
            if (mark is Map) mark['type'],
        };
        push(
          FlareRichRun(
            text,
            marks: [
              for (final mark in FlareRichMark.values)
                if (named.contains(mark.name)) mark,
            ],
          ),
        );
      case 'inline_code':
        final text = _string(node['text']);
        if (text.isNotEmpty) push(FlareRichRun(text, code: true));
      case 'hard_break':
        push(const FlareRichRun('\n'));
      case 'mention':
        final userId = _string(node['user_id']);
        final text = _string(node['text']);
        if (userId.isNotEmpty || text.isNotEmpty) {
          push(
            FlareRichRun(text.isNotEmpty ? text : '@$userId', mention: userId),
          );
        }
      case 'emoji':
        final key = _string(node['key']);
        final text = _string(node['text']);
        if (key.isNotEmpty || text.isNotEmpty) {
          push(FlareRichRun(text.isNotEmpty ? text : ':$key:', emoji: key));
        }
      case 'link':
        final href = _string(node['href']);
        final accepted = href.isNotEmpty && safeExternalUrl(href) != null;
        _runs(_children(node), accepted ? href : link, out);
      case 'custom_inline':
        break;
      default:
        final text = _string(node['text']);
        if (text.isNotEmpty) push(FlareRichRun(text));
    }
  }
  return out;
}

List<FlareRichBlock> _blocks(
  List<Object?> values, [
  List<FlareRichBlock>? into,
]) {
  final out = into ?? <FlareRichBlock>[];
  for (final node in values) {
    if (node is! Map) continue;
    switch (node['type']) {
      case 'paragraph':
        final runs = _runs(_children(node), null);
        if (runs.isNotEmpty) out.add(FlareRichParagraph(runs));
      case 'heading':
        final runs = _runs(_children(node), null);
        if (runs.isEmpty) break;
        final level = node['level'];
        final raw = level is num && level.isFinite ? level.truncate() : 1;
        out.add(FlareRichHeading(raw.clamp(1, 6), runs));
      case 'quote':
        final blocks = _blocks(_children(node));
        if (blocks.isNotEmpty) out.add(FlareRichQuote(blocks));
      case 'code_block':
        final text = _children(node).map((child) {
          if (child is! Map) return '';
          if (child['type'] == 'text') return _string(child['text']);
          return child['type'] == 'hard_break' ? '\n' : '';
        }).join();
        if (text.isEmpty) break;
        final language = _string(node['language']);
        out.add(
          FlareRichCode(text, language: language.isEmpty ? null : language),
        );
      case 'bullet_list':
      case 'ordered_list':
        final items = [
          for (final child in _children(node))
            if (child is Map && child['type'] == 'list_item')
              _blocks(_children(child)),
        ].where((item) => item.isNotEmpty).toList();
        if (items.isNotEmpty) {
          out.add(
            FlareRichList(
              ordered: node['type'] == 'ordered_list',
              items: items,
            ),
          );
        }
      case 'divider':
        out.add(const FlareRichDivider());
      case 'custom_block':
        _blocks(_children(node), out);
      default:
        break;
    }
  }
  return out;
}
