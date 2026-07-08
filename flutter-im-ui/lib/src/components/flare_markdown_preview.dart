import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Read-only Markdown/RichDoc renderer with optional stats. Spec:
/// Media/MarkdownPreview (`FlareMarkdownPreview`).
///
/// A compact, dependency-free renderer covering the subset Flare's composer
/// produces: headings, bold/italic, inline code, fenced code, bullet/ordered
/// lists, links, and paragraphs. Content is normalised by core upstream.
class FlareMarkdownPreview extends StatelessWidget {
  const FlareMarkdownPreview({
    super.key,
    required this.content,
    this.showStats = false,
  });

  final String content;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final blocks = _parseBlocks(content, colors);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...blocks,
        if (showStats) ...[
          const SizedBox(height: FlareSizes.spacingSm),
          Text(
            _stats(content),
            style: TextStyle(
                color: colors.textTertiary, fontSize: FlareSizes.fontSizeXs),
          ),
        ],
      ],
    );
  }

  static String _stats(String content) {
    final chars = content.runes.length;
    final words = content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return '$words 词 · $chars 字';
  }

  List<Widget> _parseBlocks(String src, FlareColors colors) {
    final lines = src.replaceAll('\r\n', '\n').split('\n');
    final out = <Widget>[];
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];

      // fenced code block
      if (line.trimLeft().startsWith('```')) {
        final buf = <String>[];
        i++;
        while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
          buf.add(lines[i]);
          i++;
        }
        i++; // closing fence
        out.add(_codeBlock(buf.join('\n'), colors));
        continue;
      }

      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // heading
      final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(line);
      if (heading != null) {
        final level = heading.group(1)!.length;
        out.add(_heading(heading.group(2)!, level, colors));
        i++;
        continue;
      }

      // bullet list
      if (RegExp(r'^\s*[-*]\s+').hasMatch(line)) {
        while (i < lines.length && RegExp(r'^\s*[-*]\s+').hasMatch(lines[i])) {
          final text = lines[i].replaceFirst(RegExp(r'^\s*[-*]\s+'), '');
          out.add(_listItem('•', text, colors));
          i++;
        }
        continue;
      }

      // ordered list
      if (RegExp(r'^\s*\d+\.\s+').hasMatch(line)) {
        var n = 1;
        while (i < lines.length && RegExp(r'^\s*\d+\.\s+').hasMatch(lines[i])) {
          final text = lines[i].replaceFirst(RegExp(r'^\s*\d+\.\s+'), '');
          out.add(_listItem('$n.', text, colors));
          n++;
          i++;
        }
        continue;
      }

      // paragraph
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: FlareSizes.spacingSm),
        child: Text.rich(_inline(line, _baseStyle(colors))),
      ));
      i++;
    }
    return out;
  }

  TextStyle _baseStyle(FlareColors colors) => TextStyle(
        color: colors.textPrimary,
        fontSize: FlareSizes.fontSizeLg,
        height: FlareSizes.lineHeightNormal,
      );

  Widget _heading(String text, int level, FlareColors colors) {
    final size = level == 1
        ? FlareSizes.fontSize4xl
        : level == 2
            ? FlareSizes.fontSize3xl
            : FlareSizes.fontSize2xl;
    return Padding(
      padding: const EdgeInsets.only(
          top: FlareSizes.spacingSm, bottom: FlareSizes.spacingXs),
      child: Text.rich(_inline(
          text,
          _baseStyle(colors)
              .copyWith(fontSize: size, fontWeight: FontWeight.w700))),
    );
  }

  Widget _listItem(String marker, String text, FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FlareSizes.spacingXs, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(marker, style: _baseStyle(colors)),
          ),
          Expanded(child: Text.rich(_inline(text, _baseStyle(colors)))),
        ],
      ),
    );
  }

  Widget _codeBlock(String code, FlareColors colors) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: FlareSizes.spacingSm),
      padding: const EdgeInsets.all(FlareSizes.spacingMd),
      decoration: BoxDecoration(
        color: colors.bgTertiary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: FlareSizes.fontSizeMd,
          color: colors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }

  /// Inline parser: **bold**, *italic*/_italic_, `code`, [text](url).
  TextSpan _inline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'(\*\*(.+?)\*\*)|(\*(.+?)\*)|(_(.+?)_)|(`(.+?)`)|(\[(.+?)\]\((.+?)\))',
    );
    var last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      if (m.group(1) != null) {
        spans.add(TextSpan(
            text: m.group(2),
            style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(
            text: m.group(4),
            style: const TextStyle(fontStyle: FontStyle.italic)));
      } else if (m.group(5) != null) {
        spans.add(TextSpan(
            text: m.group(6),
            style: const TextStyle(fontStyle: FontStyle.italic)));
      } else if (m.group(7) != null) {
        spans.add(TextSpan(
            text: m.group(8),
            style: const TextStyle(
                fontFamily: 'monospace', letterSpacing: -0.2)));
      } else if (m.group(9) != null) {
        spans.add(TextSpan(
            text: m.group(10),
            style: TextStyle(
                color: base.color,
                decoration: TextDecoration.underline)));
      }
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: base, children: spans);
  }
}
