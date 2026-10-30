import 'package:flutter/material.dart';

import '../models/plugin_view.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_empty_state.dart';
import 'flare_icon.dart';
import 'flare_icon_button.dart';
import 'flare_plugin_view.dart';

/// Explicit presentation of resolved account fields/rows; no money calculations.
enum FlarePluginPageAppearance { document, account }

@immutable
class FlareAccountEntry {
  const FlareAccountEntry(this.id, this.block, this.row);
  final String id;
  final FlarePluginRowsBlock block;
  final FlarePluginRow row;
  String get amount => row.cells.isEmpty ? '' : row.cells.first.text;
  String get title =>
      row.badge?.text ??
      (row.cells.length > 1
          ? row.cells[1].text
          : block.columns.firstOrNull?.label ?? '');
  String get subtitle => [
    for (var i = row.badge == null ? 2 : 1; i < row.cells.length && i < 3; i++)
      if (block.columns.elementAtOrNull(i)?.format !=
          FlarePluginColumnFormat.time)
        row.cells[i].text,
  ].where((s) => s.isNotEmpty).join(' · ');
  int? get timeMs {
    for (var i = 0; i < row.cells.length; i++) {
      if (block.columns.elementAtOrNull(i)?.format ==
          FlarePluginColumnFormat.time) {
        return row.cells[i].timeMs;
      }
    }
    return null;
  }
}

List<FlareAccountEntry> flareAccountEntries(FlarePluginViewModel view) => [
  for (final (i, block) in view.blocks.indexed)
    if (block is FlarePluginRowsBlock)
      for (final row in flarePluginRowsOnce(block.rows))
        FlareAccountEntry('$i/${row.key}', block, row),
];

/// The first field is the headline. All amounts remain server-formatted text.
/// Existing PluginView owns confirmations/forms and emits the bound row unchanged.
class FlareAccountView extends StatefulWidget {
  const FlareAccountView({
    super.key,
    required this.view,
    this.busyActionId,
    this.error,
    this.formErrors = const [],
    this.members = const [],
    this.settleToken = 0,
    this.onAction,
  });
  final FlarePluginViewModel view;
  final String? busyActionId;
  final String? error;
  final List<FlarePluginFormError> formErrors;
  final List<FlarePluginMember> members;
  final int settleToken;
  final FlarePluginActionCallback? onAction;
  @override
  State<FlareAccountView> createState() => _FlareAccountViewState();
}

class _FlareAccountViewState extends State<FlareAccountView> {
  bool _hidden = false;
  bool _information = false;
  final _revision = ValueNotifier(0);
  final _locked = ValueNotifier(false);
  Map get _presentation {
    final props = widget.view.presentation?["props"];
    return props is Map ? props : const {};
  }

  @override
  void didUpdateWidget(covariant FlareAccountView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _locked.value = widget.busyActionId != null;
    _revision.value++;
  }

  @override
  void dispose() {
    _revision.dispose();
    _locked.dispose();
    super.dispose();
  }

  FlarePluginViewModel _projection({
    List<FlarePluginAction> actions = const [],
    List<FlarePluginBlock> blocks = const [],
  }) => FlarePluginViewModel(
    available: widget.view.available,
    title: widget.view.title,
    inputs: widget.view.inputs,
    actions: actions,
    blocks: blocks,
    unavailableReason: widget.view.unavailableReason,
  );
  Widget _actions(FlarePluginViewModel view, {FlareAccountEntry? entry}) =>
      FlarePluginView(
        view: view,
        embedded: true,
        busyActionId: widget.busyActionId,
        error: widget.error,
        formErrors: widget.formErrors,
        members: widget.members,
        settleToken: widget.settleToken,
        onAction: widget.onAction == null
            ? null
            : (id, payload) {
                final binding = entry?.row.actions
                    .where((a) => a.id == id)
                    .firstOrNull;
                widget.onAction!(
                  id,
                  FlarePluginActionPayload(
                    selection: payload.selection,
                    formValues: payload.formValues,
                    row: entry == null
                        ? payload.row
                        : (key: entry.row.key, input: binding?.input),
                  ),
                );
              },
      );

  String _day(FlareAccountEntry entry, FlareStrings strings) {
    final ms = entry.timeMs;
    if (ms == null) return strings.accountOtherEntries;
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return strings.accountToday;
    if (day == today.subtract(const Duration(days: 1)))
      return strings.accountYesterday;
    return flarePluginRenderPattern(
      date.year == now.year
          ? strings.accountDayFormat
          : strings.accountDayYearFormat,
      date,
    );
  }

  String _time(FlareAccountEntry entry) {
    final ms = entry.timeMs;
    if (ms == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _open(String id) async {
    final strings = FlareStrings.of(context);
    _locked.value = widget.busyActionId != null;
    await FlareBottomSheet.show<void>(
      context,
      title:
          (_presentation["detailTitle"] as String? ??
          _presentation["sectionTitle"] as String? ??
          strings.accountEntryDetails),
      titleHidden: true,
      busy: _locked,
      listenable: _revision,
      builder: (inner) {
        final entry = flareAccountEntries(
          widget.view,
        ).where((e) => e.id == id).firstOrNull;
        final colors = FlareColors.of(inner);
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (_presentation["detailTitle"] as String? ??
                            _presentation["sectionTitle"] as String? ??
                            strings.accountEntryDetails),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FlareIconButton(
                      icon: 'close',
                      semanticLabel: strings.close,
                      disabled: widget.busyActionId != null,
                      onPressed: () => Navigator.of(inner).pop(),
                    ),
                  ],
                ),
                if (entry == null)
                  Text(
                    strings.accountEmpty,
                    style: TextStyle(color: colors.textSecondary),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: FlareSizes.spacingLg,
                    ),
                    child: Text(
                      entry.amount,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: FlareSizes.fontSize5xl,
                        fontWeight: FontWeight.w600,
                        color: entry.amount.startsWith('+')
                            ? colors.successText
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  if (entry.row.badge != null)
                    _detailLine(
                      strings.accountType,
                      entry.row.badge!.text,
                      colors,
                    ),
                  for (var i = 1; i < entry.row.cells.length; i++)
                    _detailLine(
                      entry.block.columns.elementAtOrNull(i)?.label ?? '',
                      entry.block.columns.elementAtOrNull(i)?.format ==
                                  FlarePluginColumnFormat.time &&
                              entry.row.cells[i].timeMs != null
                          ? flarePluginDateTime(
                              entry.row.cells[i].timeMs!,
                              DateTime.now().millisecondsSinceEpoch,
                              strings,
                            )
                          : entry.row.cells[i].text,
                      colors,
                    ),
                  _detailLine(
                    _presentation["rowKeyLabel"] as String? ??
                        strings.accountEntryId,
                    entry.row.key,
                    colors,
                  ),
                  _actions(
                    _projection(
                      actions: entry.block.actions
                          .where(
                            (a) => entry.row.actions.any((r) => r.id == a.id),
                          )
                          .toList(),
                    ),
                    entry: entry,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailLine(String label, String value, FlareColors colors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: colors.textSecondary)),
        ),
        const SizedBox(width: FlareSizes.spacingMd),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.view.available) return _actions(widget.view);
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final entries = flareAccountEntries(widget.view);
    final presentation = widget.view.presentation?['props'] is Map
        ? widget.view.presentation!['props'] as Map
        : const {};
    final urgent = widget.view.blocks
        .where(
          (b) =>
              b is FlarePluginNoteBlock &&
              (b.tone == FlarePluginTone.warning ||
                  b.tone == FlarePluginTone.danger),
        )
        .toList();
    final information = widget.view.blocks
        .where((b) => b is! FlarePluginRowsBlock && !urgent.contains(b))
        .toList();
    final groups = <({String label, List<FlareAccountEntry> entries})>[];
    for (final entry in entries) {
      final label = _day(entry, strings);
      if (groups.isEmpty || groups.last.label != label)
        groups.add((label: label, entries: []));
      groups.last.entries.add(entry);
    }
    final fields = widget.view.fields;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fields.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(FlareSizes.spacingLg),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fields.first.label,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    FlareIconButton(
                      icon: _hidden ? 'eye-off' : 'eye',
                      semanticLabel: _hidden
                          ? strings.accountShowBalance
                          : strings.accountHideBalance,
                      onPressed: () => setState(() => _hidden = !_hidden),
                    ),
                  ],
                ),
                Semantics(
                  label: _hidden
                      ? strings.accountBalanceHidden
                      : fields.first.value,
                  excludeSemantics: true,
                  child: Text(
                    _hidden ? '••••' : fields.first.value,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.componentRedPacketAmountFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (fields.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: FlareSizes.spacingLg),
                    child: Wrap(
                      spacing: FlareSizes.spacingXl,
                      runSpacing: FlareSizes.spacingMd,
                      children: [
                        for (final field in fields.skip(1))
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                field.label,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: FlareSizes.fontSizeSm,
                                ),
                              ),
                              Text(
                                _hidden ? '••••' : field.value,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (urgent.isNotEmpty) _actions(_projection(blocks: urgent)),
        _actions(
          _projection(
            actions: [...widget.view.actions, ...widget.view.menuActions],
          ),
        ),
        if (fields.isNotEmpty || presentation['sectionTitle'] is String)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingMd),
            child: Text(
              (widget.view.presentation?['props'] is Map &&
                      (widget.view.presentation!['props']
                              as Map)['sectionTitle']
                          is String)
                  ? (widget.view.presentation!['props'] as Map)['sectionTitle']
                        as String
                  : strings.accountTransactions,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: FlareSizes.fontSize3xl,
              ),
            ),
          ),
        if (entries.isEmpty)
          FlareEmptyState(
            title: presentation['emptyTitle'] is String
                ? presentation['emptyTitle'] as String
                : strings.accountEmpty,
            description: presentation['emptyDescription'] is String
                ? presentation['emptyDescription'] as String
                : strings.accountEmptyDescription,
            icon: 'wallet',
          ),
        for (final group in groups) ...[
          if (presentation['groupByDate'] != false)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: FlareSizes.spacingSm,
              ),
              child: Text(
                group.label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FlareSizes.fontSizeSm,
                ),
              ),
            ),
          for (final entry in group.entries)
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('account-entry:${entry.id}'),
                onTap: widget.busyActionId == null
                    ? () => _open(entry.id)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: FlareSizes.spacingMd,
                  ),
                  child: LayoutBuilder(
                    builder: (context, bounds) => Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(FlareSizes.spacingSm),
                          decoration: BoxDecoration(
                            color: colors.bgSecondary,
                            borderRadius: BorderRadius.circular(
                              FlareSizes.radiusMd,
                            ),
                          ),
                          child: FlareIcon(
                            'wallet',
                            color: entry.amount.startsWith('+')
                                ? colors.successText
                                : colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: FlareSizes.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (entry.subtitle.isNotEmpty)
                                Text(
                                  entry.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: FlareSizes.fontSizeSm,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: FlareSizes.spacingSm),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: bounds.maxWidth * 0.42,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _hidden &&
                                        presentation['maskRowAmounts'] == true
                                    ? '••••'
                                    : entry.amount,
                                style: TextStyle(
                                  color: entry.amount.startsWith('+')
                                      ? colors.successText
                                      : colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _time(entry),
                                style: TextStyle(
                                  color: colors.textTertiary,
                                  fontSize: FlareSizes.fontSizeSm,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: FlareSizes.spacingSm),
                        FlareIcon(
                          'chevron-right',
                          size: FlareSizes.iconSizeSm,
                          color: colors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
        if (information.isNotEmpty) ...[
          InkWell(
            onTap: () => setState(() => _information = !_information),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: FlareSizes.spacingMd,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.accountInformation,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                  FlareIcon(
                    _information ? 'chevron-up' : 'chevron-down',
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_information) _actions(_projection(blocks: information)),
        ],
      ],
    );
  }
}
