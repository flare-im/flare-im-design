import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_contact_item.dart';
import 'flare_empty_state.dart';

/// Directory — contacts grouped A-Z with group headers and a side index bar for
/// quick jump. Spec: Contacts/ContactList (`FlareContactList`).
class FlareContactList extends StatefulWidget {
  const FlareContactList({
    super.key,
    required this.items,
    this.indexed = true,
    this.loading = false,
    this.onSelect,
  });

  final List<FlareContact> items;
  final bool indexed;
  final bool loading;
  final ValueChanged<FlareContact>? onSelect;

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
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  void _jump(String letter) {
    final ctx = _keys[letter]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 250), alignment: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    if (widget.items.isEmpty) {
      return widget.loading
          ? const Center(child: CircularProgressIndicator())
          : const Center(child: FlareEmptyState(title: 'No contacts yet'));
    }
    final groups = _groups;

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final g in groups) ...[
                Container(
                  key: _keys.putIfAbsent(g.key, () => GlobalKey()),
                  color: colors.bgSecondary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: FlareSizes.spacingMd, vertical: 4),
                  child: Text(g.key,
                      style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: FlareSizes.fontSizeSm,
                          fontWeight: FontWeight.w600)),
                ),
                for (final c in g.value)
                  FlareContactItem(
                    item: c,
                    onSelect: widget.onSelect == null
                        ? null
                        : () => widget.onSelect!(c),
                  ),
              ],
            ],
          ),
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
                        child: Text(g.key,
                            style: TextStyle(
                                color: colors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
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
