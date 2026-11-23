import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_icon.dart';

/// Recent searches — what a search page shows before anything is typed: the
/// terms the reader used last, one tap from searching again, and one way to
/// forget them all. The host owns the list (it is per signed-in user and lives
/// in the host's storage; [flareRememberSearch] is the rule for keeping it);
/// this draws it and reports [onPick] and [onClear]. With no items it draws
/// nothing, so the page's idle line shows instead.
///
/// The terms are rows, not capsules: on a search page they sit right under the
/// type row, which already is a row of capsules, and a second row that looks
/// the same but means something else (history, not a filter) cannot be told
/// apart from it. Each row is a touch target tall and is its own hit area.
/// Spec: Search/RecentSearches (the Vue kit's `FlareRecentSearches`).
class FlareRecentSearches extends StatelessWidget {
  const FlareRecentSearches({
    super.key,
    required this.items,
    this.onPick,
    this.onClear,
    this.title,
    this.clearText,
    this.gutter = FlareSizes.spacingMd,
  });

  final List<String> items;
  final ValueChanged<String>? onPick;

  /// Forget every term. The clear key is drawn only when it is handled.
  final VoidCallback? onClear;

  /// Section heading; the kit's "最近搜索" when null.
  final String? title;

  /// The clear key's words; the kit's "清除" when null.
  final String? clearText;

  /// The page gutter the heading and the rows line up with.
  final double gutter;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final heading = title ?? strings.recentSearchesTitle;
    return Semantics(
      container: true,
      label: heading,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FlareSizes.touchTarget,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: gutter, end: gutter),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      // The same rung as a result group's label: a caption
                      // over a list, not a page title.
                      child: Text(
                        heading,
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: FlareSizes.fontSizeSm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (onClear != null)
                    Semantics(
                      label: strings.recentSearchesClearLabel,
                      button: true,
                      excludeSemantics: true,
                      child: FlareButton(
                        key: const ValueKey('flare-recent-searches-clear'),
                        variant: FlareButtonVariant.quiet,
                        size: FlareControlSize.sm,
                        label: clearText ?? strings.recentSearchesClear,
                        onPressed: onClear,
                      ),
                    ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < items.length; i++)
            _TermRow(
              key: ValueKey('flare-recent-search-$i'),
              term: items[i],
              gutter: gutter,
              onTap: onPick == null ? null : () => onPick!(items[i]),
            ),
        ],
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({
    super.key,
    required this.term,
    required this.gutter,
    this.onTap,
  });

  final String term;
  final double gutter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: gutter, end: gutter),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: FlareIcon(
                    'clock',
                    size: FlareSizes.iconSizeSm,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Text(
                    term,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSizeLg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
