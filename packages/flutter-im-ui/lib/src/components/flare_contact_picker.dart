import 'package:flutter/material.dart';

import '../models/contact_picker.dart';
import '../models/directory_data.dart' show FlareControlSize;
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_empty_state.dart';
import 'flare_filter_tabs.dart';
import 'flare_icon.dart';
import 'flare_search_bar.dart';

/// Choose the person a contact card names: tabs for the groups the host
/// passes (friends, group members — one group shows no tabs), a search over
/// names and subtitles, and a lazily built list, so a long address book only
/// builds the rows on screen. One tap answers in single mode; [multiple] mode
/// toggles rows and answers from the confirm key. The signed-in user stays
/// selectable and reads "(me)". Present it with
/// `FlareBottomSheet.show(fill: true, ...)`: it brings its own header
/// ([FlareSheetOwnHeader]), so the sheet draws no second title.
/// Spec: Composer/ContactPicker.
class FlareContactPicker extends StatefulWidget implements FlareSheetOwnHeader {
  const FlareContactPicker({
    super.key,
    required this.groups,
    this.searchable = true,
    this.multiple = false,
    this.title,
    this.onSelect,
    this.onCancel,
  });

  final List<FlareContactPickerGroup> groups;
  final bool searchable;
  final bool multiple;

  /// Header title; the kit's "Choose a contact" when null.
  final String? title;

  /// The chosen people: one on a tap in single mode, the toggled ones from the
  /// confirm key in [multiple] mode.
  final ValueChanged<List<FlareContactPickerEntry>>? onSelect;
  final VoidCallback? onCancel;

  @override
  State<FlareContactPicker> createState() => _FlareContactPickerState();
}

class _FlareContactPickerState extends State<FlareContactPicker> {
  final TextEditingController _query = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late String _groupId = widget.groups.isEmpty ? '' : widget.groups.first.id;
  final List<String> _chosen = <String>[];

  @override
  void didUpdateWidget(FlareContactPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.groups.any((group) => group.id == _groupId)) {
      _groupId = widget.groups.isEmpty ? '' : widget.groups.first.id;
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _label(FlareContactPickerGroup group, FlareStrings strings) =>
      group.label ??
      switch (group.id) {
        flareContactPickerFriends => strings.contactPickerFriends,
        flareContactPickerGroupMembers => strings.contactPickerGroupMembers,
        _ => group.id,
      };

  FlareContactPickerGroup? get _group {
    for (final group in widget.groups) {
      if (group.id == _groupId) return group;
    }
    return widget.groups.isEmpty ? null : widget.groups.first;
  }

  List<FlareContactPickerEntry> get _filtered {
    final entries = _group?.entries ?? const <FlareContactPickerEntry>[];
    final query = _query.text;
    if (!widget.searchable || query.trim().isEmpty) return entries;
    return entries.where((entry) => entry.matches(query)).toList(growable: false);
  }

  void _resetScroll() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _tap(FlareContactPickerEntry entry) {
    if (!widget.multiple) {
      widget.onSelect?.call([entry]);
      return;
    }
    setState(() {
      if (!_chosen.remove(entry.userId)) _chosen.add(entry.userId);
    });
  }

  void _confirm() {
    final everyone = [for (final group in widget.groups) ...group.entries];
    final picked = <FlareContactPickerEntry>[];
    for (final id in _chosen) {
      for (final entry in everyone) {
        if (entry.userId == id) {
          picked.add(entry);
          break;
        }
      }
    }
    if (picked.isNotEmpty) widget.onSelect?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final title = widget.title ?? strings.contactPickerTitle;
    final entries = _filtered;
    final group = _group;
    return Semantics(
      container: true,
      label: title,
      child: ColoredBox(
        color: colors.bgPrimary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: FlareSizes.controlHeightLg,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingMd),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: widget.onCancel,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.textSecondary,
                            minimumSize: const Size(FlareSizes.touchTargetMin, FlareSizes.touchTargetMin),
                            textStyle: const TextStyle(fontSize: FlareSizes.fontSizeXl),
                          ),
                          child: Text(strings.cancel),
                        ),
                      ),
                    ),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: FlareSizes.fontSize2xl,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: widget.multiple
                            ? FlareButton(
                                key: const ValueKey('flare-contact-picker-confirm'),
                                size: FlareControlSize.sm,
                                label: _chosen.isEmpty
                                    ? strings.confirm
                                    : '${strings.confirm} (${_chosen.length})',
                                disabled: _chosen.isEmpty,
                                onPressed: _chosen.isEmpty ? null : _confirm,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingMd,
                  vertical: FlareSizes.spacingXs,
                ),
                child: FlareSearchBar(
                  controller: _query,
                  placeholder: strings.contactPickerSearch,
                  onChanged: (_) {
                    setState(() {});
                    _resetScroll();
                  },
                ),
              ),
            if (widget.groups.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingMd),
                child: FlareFilterTabs(
                  appearance: FlareFilterTabsAppearance.quiet,
                  options: [
                    for (final group in widget.groups)
                      FlareFilterTabOption(value: group.id, label: _label(group, strings)),
                  ],
                  selected: group?.id ?? '',
                  onSelect: (id) {
                    setState(() => _groupId = id);
                    _resetScroll();
                  },
                ),
              ),
            Expanded(
              child: Semantics(
                container: true,
                label: group == null ? null : _label(group, strings),
                child: entries.isEmpty
                    ? FlareEmptyState(
                        title: strings.contactPickerEmpty,
                        icon: _query.text.trim().isEmpty ? 'people' : 'search',
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: EdgeInsets.zero,
                        itemCount: entries.length,
                        itemExtent: _ContactRow.height,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _ContactRow(
                            entry: entry,
                            multiple: widget.multiple,
                            chosen: _chosen.contains(entry.userId),
                            selfSuffix: strings.contactPickerSelfSuffix,
                            onTap: () => _tap(entry),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.entry,
    required this.multiple,
    required this.chosen,
    required this.selfSuffix,
    required this.onTap,
  });

  static const double height = 60;

  final FlareContactPickerEntry entry;
  final bool multiple;
  final bool chosen;
  final String selfSuffix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final subtitle = entry.subtitle?.trim() ?? '';
    return Semantics(
      key: ValueKey('flare-contact-picker-${entry.userId}'),
      button: !multiple,
      checked: multiple ? chosen : null,
      child: Material(
        color: multiple && chosen ? colors.bgSelected : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingLg),
            child: Row(
              children: [
                if (multiple) ...[
                  _Check(on: chosen),
                  const SizedBox(width: FlareSizes.spacingMd),
                ],
                FlareAvatar(
                  userId: entry.userId,
                  displayName: entry.name,
                  avatarUrl: entry.avatarUrl,
                  size: FlareSizes.controlHeightMd,
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: entry.name,
                          children: [
                            if (entry.isSelf)
                              TextSpan(
                                text: selfSuffix,
                                style: TextStyle(color: colors.textTertiary),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: FlareSizes.fontSizeXl,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: FlareSizes.fontSizeSm,
                            color: colors.textTertiary,
                          ),
                        ),
                    ],
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

class _Check extends StatelessWidget {
  const _Check({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Container(
      width: FlareSizes.iconSizeMd,
      height: FlareSizes.iconSizeMd,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? colors.primary : Colors.transparent,
        border: Border.all(color: on ? colors.primary : colors.borderHover, width: 1.5),
      ),
      alignment: Alignment.center,
      child: on ? FlareIcon('check', size: 12, color: colors.bgPrimary) : null,
    );
  }
}
