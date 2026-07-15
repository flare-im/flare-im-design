import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// Global search results — kind-grouped rows with query highlighting and
/// per-group "View all". Spec: Search/SearchResults (`FlareSearchResults`).
class FlareSearchResults extends StatelessWidget {
  const FlareSearchResults({
    super.key,
    required this.groups,
    required this.query,
    this.onOpen,
    this.onViewAll,
  });

  final List<FlareSearchResultGroup> groups;
  final String query;
  final void Function(FlareSearchResultItem)? onOpen;
  final void Function(FlareSearchResultKind)? onViewAll;

  /// Split [text] into highlighted / plain spans around case-insensitive
  /// occurrences of [query].
  static List<TextSpan> highlightSpans(
    String text,
    String query, {
    required Color baseColor,
    required Color matchColor,
  }) {
    final baseStyle = TextStyle(color: baseColor);
    if (query.isEmpty) return [TextSpan(text: text, style: baseStyle)];
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: TextStyle(color: matchColor, fontWeight: FontWeight.w600),
      ));
      start = idx + q.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final nonEmpty = groups.where((g) => g.items.isNotEmpty).toList();
    if (nonEmpty.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: FlareSizes.spacingLg),
        child: Center(
          child: Text('No results found',
              style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeMd)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final g in nonEmpty) ..._section(colors, g),
      ],
    );
  }

  List<Widget> _section(FlareColors colors, FlareSearchResultGroup g) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(FlareSizes.spacingLg, FlareSizes.spacingMd,
            FlareSizes.spacingLg, FlareSizes.spacingXs),
        child: Text(g.label,
            style: TextStyle(
                color: colors.textTertiary,
                fontSize: FlareSizes.fontSizeSm,
                fontWeight: FontWeight.w600)),
      ),
      for (final item in g.items) _row(colors, item),
      if (g.total != null && g.total! > g.items.length) _viewAll(colors, g),
    ];
  }

  Widget _row(FlareColors colors, FlareSearchResultItem item) {
    return GestureDetector(
      onTap: () => onOpen?.call(item),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingSm),
        child: Row(
          children: [
            FlareAvatar(
                userId: item.id, displayName: item.title, avatarUrl: item.avatarUrl, size: 38),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                        children: highlightSpans(item.title, query,
                            baseColor: colors.textPrimary, matchColor: colors.primary)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: FlareSizes.fontSizeLg),
                  ),
                  if (item.subtitle != null && item.subtitle!.isNotEmpty)
                    Text.rich(
                      TextSpan(
                          children: highlightSpans(item.subtitle!, query,
                              baseColor: colors.textTertiary, matchColor: colors.primary)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: FlareSizes.fontSizeSm),
                    ),
                ],
              ),
            ),
            if (item.meta != null && item.meta!.isNotEmpty) ...[
              const SizedBox(width: FlareSizes.spacingSm),
              Text(item.meta!,
                  style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _viewAll(FlareColors colors, FlareSearchResultGroup g) {
    return GestureDetector(
      onTap: () => onViewAll?.call(g.kind),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingLg, vertical: FlareSizes.spacingSm),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('View all ${g.total}',
              style: TextStyle(
                  color: colors.primary,
                  fontSize: FlareSizes.fontSizeMd,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
