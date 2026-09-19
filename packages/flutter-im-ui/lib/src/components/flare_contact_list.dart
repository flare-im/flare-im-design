import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_contact_item.dart';
import 'flare_empty_state.dart';

/// Directory — contacts grouped A-Z with group headers and a side index bar for
/// quick jump. Spec: Contacts/ContactList (`FlareContactList`).
///
/// Letters come from [flareContactLetter]: a contact's `indexKey` when the host
/// passes one, otherwise its name — a Latin letter by that letter, a Chinese
/// name by the pinyin initial of its first character (GB2312 level 1). The
/// rest goes under "#", listed last. Within a letter, names follow
/// [flareCompareContactNames] (Chinese names in pinyin order).
///
/// [selectable] makes every row a checkbox for pickers: [selectedIds] are
/// checked and a tap calls [onToggleSelect] (never [onSelect]).
/// [trailingBuilder] adds content at the end of each row, such as an action.
/// [empty] replaces the kit's own empty state, for a directory that is empty for
/// a reason only the host knows (a filter, a permission, an invitation to add someone).
class FlareContactList extends StatefulWidget {
  const FlareContactList({
    super.key,
    required this.items,
    this.indexed = true,
    this.loading = false,
    this.onSelect,
    this.selectable = false,
    this.selectedIds = const {},
    this.onToggleSelect,
    this.trailingBuilder,
    this.empty,
  });

  final List<FlareContact> items;
  final bool indexed;
  final bool loading;
  final ValueChanged<FlareContact>? onSelect;
  final bool selectable;
  final Set<String> selectedIds;
  final ValueChanged<FlareContact>? onToggleSelect;
  final Widget Function(BuildContext context, FlareContact contact)?
  trailingBuilder;
  final Widget? empty;

  @override
  State<FlareContactList> createState() => _FlareContactListState();
}

class _FlareContactListState extends State<FlareContactList> {
  final Map<String, GlobalKey> _keys = {};

  List<MapEntry<String, List<FlareContact>>> get _groups {
    final map = <String, List<FlareContact>>{};
    for (final c in widget.items) {
      map.putIfAbsent(flareContactLetter(c), () => []).add(c);
    }
    // A to Z, then "#"; inside a letter, by name.
    final entries = map.entries.toList()
      ..sort((a, b) => flareCompareContactLetters(a.key, b.key));
    return [
      for (final entry in entries) MapEntry(entry.key, _byName(entry.value)),
    ];
  }

  /// [contacts] ordered by name; the same names keep the host's order, so
  /// rows do not swap places between builds.
  static List<FlareContact> _byName(List<FlareContact> contacts) {
    final indexed = [
      for (var i = 0; i < contacts.length; i++) (i, contacts[i]),
    ];
    indexed.sort((a, b) {
      final order = flareCompareContactNames(a.$2.name, b.$2.name);
      return order != 0 ? order : a.$1.compareTo(b.$1);
    });
    return [for (final (_, contact) in indexed) contact];
  }

  void _jump(String letter) {
    final ctx = _keys[letter]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        alignment: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    if (widget.items.isEmpty) {
      if (widget.loading)
        return const Center(child: CircularProgressIndicator());
      // Scrollable even with nothing in it, so a pull to refresh above still reaches the host:
      // an empty directory is exactly when someone pulls.
      return LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child:
                  widget.empty ??
                  Center(
                    child: FlareEmptyState(
                      title: FlareStrings.of(context).noContacts,
                    ),
                  ),
            ),
          ],
        ),
      );
    }
    final groups = _groups;

    return Stack(
      children: [
        // Letter headers stay pinned while their group scrolls under them —
        // same as iOS (pinnedViews) / Android (stickyHeader).
        CustomScrollView(
          slivers: [
            for (final g in groups)
              SliverMainAxisGroup(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _LetterHeaderDelegate(
                      child: Container(
                        key: _keys.putIfAbsent(g.key, () => GlobalKey()),
                        color: colors.bgSecondary,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: FlareSizes.spacingMd,
                          vertical: 4,
                        ),
                        child: Text(
                          g.key,
                          style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: FlareSizes.fontSizeSm,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverList.list(
                    children: [
                      for (final c in g.value)
                        FlareContactItem(
                          item: c,
                          onSelect: widget.onSelect == null
                              ? null
                              : () => widget.onSelect!(c),
                          selectable: widget.selectable,
                          selected: widget.selectedIds.contains(c.id),
                          onToggleSelect: widget.onToggleSelect == null
                              ? null
                              : () => widget.onToggleSelect!(c),
                          trailing: widget.trailingBuilder?.call(context, c),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
        if (widget.indexed && groups.length > 1)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final g in groups)
                    GestureDetector(
                      onTap: () => _jump(g.key),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          g.key,
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Fixed-height pinned letter header (12px text + 4px vertical inset).
class _LetterHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _LetterHeaderDelegate({required this.child});

  final Widget child;

  static const double _height = 24;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(height: _height, child: child);

  @override
  bool shouldRebuild(_LetterHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}
