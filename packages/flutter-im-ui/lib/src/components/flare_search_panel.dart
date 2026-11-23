import 'dart:async';

import 'package:flutter/material.dart';
import '../models/directory_data.dart';
import 'flare_action_menu.dart';
import 'flare_filter_tabs.dart';
import 'flare_icon.dart';
import 'flare_search_bar.dart';
import 'flare_search_results.dart';
import 'flare_status_banner.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';

@immutable
class FlareSearchCriteria {
  const FlareSearchCriteria({
    required this.query,
    required this.filterId,
    this.fromTime,
    this.toTime,
  });
  final String query;
  final String filterId;
  final int? fromTime, toTime;
  @override
  bool operator ==(Object other) =>
      other is FlareSearchCriteria &&
      other.query == query &&
      other.filterId == filterId &&
      other.fromTime == fromTime &&
      other.toTime == toTime;
  @override
  int get hashCode => Object.hash(query, filterId, fromTime, toTime);
}

class FlareSearchRangeOption {
  const FlareSearchRangeOption({
    required this.id,
    required this.label,
    this.fromTime,
    this.toTime,
  });
  final String id, label;
  final int? fromTime, toTime;
  bool get isValid =>
      (fromTime == null || fromTime! >= 0 && fromTime! <= 9007199254740991) &&
      (toTime == null || toTime! >= 0 && toTime! <= 9007199254740991) &&
      (fromTime == null || toTime == null || fromTime! <= toTime!);
}

enum FlareSearchState { idle, loading, success, failure }

class FlareSearchSnapshot {
  const FlareSearchSnapshot({
    required this.criteria,
    required this.state,
    this.groups = const [],
    this.error,
  });
  final FlareSearchCriteria criteria;
  final FlareSearchState state;
  final List<FlareSearchResultGroup> groups;
  final String? error;
}

/// How a [FlareSearchPanel] sits in its host (spec SearchPanel `layout`).
enum FlareSearchPanelLayout {
  /// Inside a padded surface, scrolling with its host.
  inline,

  /// The panel is the whole page, drawer or modal body: the field and the
  /// type row stay put and only the results under their hairline scroll (a
  /// new query's results start at the top). The panel owns the page gutter
  /// and the bottom safe area; result rows run edge to edge. It needs a
  /// bounded height from its host.
  page,
}

class FlareSearchPanel extends StatefulWidget {
  const FlareSearchPanel({
    super.key,
    required this.snapshot,
    required this.filters,
    required this.onSearch,
    this.onOpen,
    this.onViewAll,
    this.timeRanges = const [],
    this.timeRangeText,
    this.searchText,
    this.idleText,
    this.autofocus = false,
    this.layout = FlareSearchPanelLayout.inline,
  });
  final FlareSearchSnapshot snapshot;
  final Map<String, String> filters;
  final ValueChanged<FlareSearchCriteria> onSearch;
  final ValueChanged<FlareSearchResultItem>? onOpen;
  final ValueChanged<FlareSearchResultKind>? onViewAll;
  final String? searchText, idleText, timeRangeText;
  final List<FlareSearchRangeOption> timeRanges;

  /// Put the caret in the search field when the panel opens.
  final bool autofocus;
  final FlareSearchPanelLayout layout;
  @override
  State<FlareSearchPanel> createState() => _FlareSearchPanelState();
}

class _FlareSearchPanelState extends State<FlareSearchPanel> {
  // Vue FlareSearchPanel: typing searches after a short pause (never while an
  // IME is composing); Return, a type or a time range searches at once.
  static const _searchDelay = Duration(milliseconds: 300);

  String get _timeRangeText =>
      widget.timeRangeText ?? FlareStrings.of(context).timeRange;
  String get _searchText =>
      widget.searchText ?? FlareStrings.of(context).search;
  String get _idleText =>
      widget.idleText ?? FlareStrings.of(context).searchIdleHint;
  late final TextEditingController _text = TextEditingController(
    text: widget.snapshot.criteria.query,
  );
  late int? _fromTime = widget.snapshot.criteria.fromTime;
  late int? _toTime = widget.snapshot.criteria.toTime;
  late String _filter = widget.snapshot.criteria.filterId;
  late FlareSearchCriteria _submitted = widget.snapshot.criteria;
  final FocusNode _field = FocusNode();
  Timer? _timer;

  /// The last results stay on screen while the next query runs, so typing
  /// does not blank the list.
  FlareSearchSnapshot? _shown;

  String get _defaultFilter =>
      widget.filters.isEmpty ? '' : widget.filters.keys.first;
  List<FlareSearchRangeOption> get _ranges =>
      widget.timeRanges.where((range) => range.isValid).toList();

  bool _isIdle(FlareSearchCriteria c) =>
      c.query.trim().isEmpty &&
      (c.filterId.isEmpty || c.filterId == _defaultFilter) &&
      c.fromTime == null &&
      c.toTime == null;

  @override
  void initState() {
    super.initState();
    if (widget.snapshot.state == FlareSearchState.success) {
      _shown = widget.snapshot;
    }
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _field.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(FlareSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapshot.state == FlareSearchState.success) {
      _shown = widget.snapshot;
    }
  }

  void _submit() {
    _timer?.cancel();
    final criteria = FlareSearchCriteria(
      query: _text.text.trim(),
      filterId: _filter,
      fromTime: _fromTime,
      toTime: _toTime,
    );
    if (criteria == _submitted &&
        !_isIdle(criteria) &&
        widget.snapshot.state != FlareSearchState.failure) {
      return;
    }
    setState(() {
      _submitted = criteria;
      if (_isIdle(criteria)) _shown = null;
    });
    if (!_isIdle(criteria)) widget.onSearch(criteria);
  }

  void _scheduleSubmit(String _) {
    _timer?.cancel();
    if (_text.value.composing.isValid) return;
    if (_text.text.trim() == _submitted.query &&
        _filter == _submitted.filterId &&
        _fromTime == _submitted.fromTime &&
        _toTime == _submitted.toTime) {
      return;
    }
    _timer = Timer(_searchDelay, _submit);
  }

  void _chooseRange(String id) {
    final range = _ranges.where((r) => r.id == id).firstOrNull;
    if (range == null) return;
    _fromTime = range.fromTime;
    _toTime = range.toTime;
    _submit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _field.dispose();
    _text.dispose();
    super.dispose();
  }

  /// The trailing time-range capsule: the chosen range's name, or the
  /// category's while nothing narrows it (Vue `__range`).
  Widget _rangeChip(FlareColors colors, List<FlareSearchRangeOption> ranges) {
    final active = ranges
        .where((r) => r.fromTime == _fromTime && r.toTime == _toTime)
        .firstOrNull;
    final narrowed = active != null && active.id != ranges.first.id;
    return FlareActionMenu(
      label: _timeRangeText,
      items: [
        for (final range in ranges)
          FlareActionItem(id: range.id, label: range.label),
      ],
      onSelected: _chooseRange,
      builder: (context, open) => Semantics(
        button: true,
        label: _timeRangeText,
        child: GestureDetector(
          onTap: open,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FlareSizes.touchTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: narrowed
                      ? colors.primary.withValues(alpha: 0.12)
                      : colors.bgSecondary,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                  border: Border.all(
                    color: narrowed
                        ? colors.primary.withValues(alpha: 0.26)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      narrowed ? active.label : _timeRangeText,
                      style: TextStyle(
                        color: narrowed
                            ? colors.primaryText
                            : colors.textSecondary,
                        fontSize: FlareSizes.fontSizeSm,
                        fontWeight: narrowed
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: FlareSizes.spacingXs),
                    FlareIcon(
                      'chevron-down',
                      size: FlareSizes.iconSizeSm,
                      color: narrowed
                          ? colors.primaryText
                          : colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final snapshot = widget.snapshot;
    final idle = _isIdle(_submitted);
    final current = snapshot.criteria == _submitted;
    final waiting =
        !idle && (!current || snapshot.state == FlareSearchState.loading);
    final ranges = _ranges;
    final controls = <Widget>[
      FlareSearchBar(
        controller: _text,
        focusNode: _field,
        placeholder: _searchText,
        loading: waiting,
        onChanged: _scheduleSubmit,
        onSubmitted: (_) => _submit(),
      ),
      // One row: the types scroll sideways, the time range trails them and
      // opens a menu (Vue `__filters`).
      if (widget.filters.length > 1 || ranges.isNotEmpty)
        Row(
          children: [
            if (widget.filters.length > 1)
              Expanded(
                child: FlareFilterTabs(
                  size: FlareControlSize.sm,
                  padding: EdgeInsets.zero,
                  options: [
                    for (final f in widget.filters.entries)
                      FlareFilterTabOption(value: f.key, label: f.value),
                  ],
                  selected: _filter,
                  onSelect: (id) {
                    _filter = id;
                    _submit();
                  },
                ),
              )
            else
              const Spacer(),
            if (ranges.isNotEmpty) ...[
              const SizedBox(width: FlareSizes.spacingSm),
              _rangeChip(colors, ranges),
            ],
          ],
        ),
    ];
    Widget status(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingLg),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.textTertiary,
          fontSize: FlareSizes.fontSizeMd,
        ),
      ),
    );
    final shown = _shown;
    final Widget outcome;
    if (idle) {
      outcome = status(_idleText);
    } else if (current && snapshot.state == FlareSearchState.failure) {
      outcome = FlareStatusBanner(
        text: snapshot.error ?? _idleText,
        tone: FlareStatusTone.danger,
        actionText: strings.retry,
        onAction: () => widget.onSearch(_submitted),
      );
    } else if (shown != null) {
      outcome = Opacity(
        opacity: waiting ? 0.6 : 1,
        child: FlareSearchResults(
          groups: shown.groups,
          query: shown.criteria.query,
          onOpen: widget.onOpen,
          onViewAll: widget.onViewAll,
        ),
      );
    } else {
      outcome = status(strings.searchPanelSearching);
    }
    if (widget.layout == FlareSearchPanelLayout.inline) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < controls.length; i++) ...[
            if (i > 0) const SizedBox(height: FlareSizes.spacingMd),
            controls[i],
          ],
          const SizedBox(height: FlareSizes.spacingMd),
          outcome,
        ],
      );
    }
    final bottom = MediaQuery.paddingOf(context).bottom;
    final results = shown != null && !idle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FlareSizes.spacingLg,
            FlareSizes.spacingSm,
            FlareSizes.spacingLg,
            FlareSizes.spacingSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < controls.length; i++) ...[
                if (i > 0) const SizedBox(height: FlareSizes.spacingSm),
                controls[i],
              ],
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: colors.borderSecondary),
        Expanded(
          child: SingleChildScrollView(
            // A new query's results start at the top.
            key: ValueKey(shown?.criteria),
            padding: EdgeInsets.fromLTRB(
              results ? 0 : FlareSizes.spacingLg,
              FlareSizes.spacingSm,
              results ? 0 : FlareSizes.spacingLg,
              FlareSizes.spacingSm + bottom,
            ),
            child: outcome,
          ),
        ),
      ],
    );
  }
}
