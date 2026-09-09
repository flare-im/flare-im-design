import 'package:flutter/material.dart';
import '../models/directory_data.dart';
import 'flare_search_bar.dart';
import 'flare_search_results.dart';
import 'flare_status_banner.dart';

@immutable
class FlareSearchCriteria {
  const FlareSearchCriteria({required this.query, required this.filterId, this.fromTime, this.toTime});
  final String query;
  final String filterId;
  final int? fromTime, toTime;
  @override
  bool operator ==(Object other) =>
      other is FlareSearchCriteria &&
      other.query == query &&
      other.filterId == filterId && other.fromTime == fromTime && other.toTime == toTime;
  @override
  int get hashCode => Object.hash(query, filterId, fromTime, toTime);
}

class FlareSearchRangeOption {
  const FlareSearchRangeOption({required this.id, required this.label, this.fromTime, this.toTime});
  final String id, label;
  final int? fromTime, toTime;
  bool get isValid => (fromTime == null || fromTime! >= 0 && fromTime! <= 9007199254740991)
    && (toTime == null || toTime! >= 0 && toTime! <= 9007199254740991)
    && (fromTime == null || toTime == null || fromTime! <= toTime!);
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

class FlareSearchPanel extends StatefulWidget {
  const FlareSearchPanel({
    super.key,
    required this.snapshot,
    required this.filters,
    required this.onSearch,
    this.onOpen,
    this.onViewAll,
    this.timeRanges = const [],
    this.timeRangeText = '时间范围',
    this.searchText = '搜索',
    this.idleText = '输入关键词或选择类型',
  });
  final FlareSearchSnapshot snapshot;
  final Map<String, String> filters;
  final ValueChanged<FlareSearchCriteria> onSearch;
  final ValueChanged<FlareSearchResultItem>? onOpen;
  final ValueChanged<FlareSearchResultKind>? onViewAll;
  final String searchText, idleText, timeRangeText;
  final List<FlareSearchRangeOption> timeRanges;
  @override
  State<FlareSearchPanel> createState() => _FlareSearchPanelState();
}

class _FlareSearchPanelState extends State<FlareSearchPanel> {
  late final TextEditingController _text = TextEditingController(
    text: widget.snapshot.criteria.query,
  );
  late int? _fromTime = widget.snapshot.criteria.fromTime;
  late int? _toTime = widget.snapshot.criteria.toTime;
  late String _filter = widget.snapshot.criteria.filterId;
  late FlareSearchCriteria _submitted = widget.snapshot.criteria;
  void _submit() {
    setState(
      () => _submitted = FlareSearchCriteria(
        query: _text.text.trim(),
        filterId: _filter,
        fromTime: _fromTime, toTime: _toTime,
      ),
    );
    widget.onSearch(_submitted);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final waiting =
        snapshot.criteria != _submitted ||
        snapshot.state == FlareSearchState.loading;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlareSearchBar(
          controller: _text,
          placeholder: widget.searchText,
          onSubmitted: (_) => _submit(),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: _submit,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(widget.searchText),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in widget.filters.entries)
              Semantics(
                selected: _filter == f.key,
                child: OutlinedButton(
                  onPressed: () {
                    _filter = f.key;
                    _submit();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: _filter == f.key
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : null,
                  ),
                  child: Text(f.value),
                ),
              ),
          ],
        ),
        if (widget.timeRanges.isNotEmpty)
          Semantics(label: widget.timeRangeText, container: true, child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final range in widget.timeRanges)
              Semantics(selected: range.fromTime == _fromTime && range.toTime == _toTime,
                child: OutlinedButton(
                  onPressed: range.isValid ? () { _fromTime = range.fromTime; _toTime = range.toTime; _submit(); } : null,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48),
                    backgroundColor: range.fromTime == _fromTime && range.toTime == _toTime ? Theme.of(context).colorScheme.secondaryContainer : null),
                  child: Text(range.label))),
          ])),
        const SizedBox(height: 12),
        if (waiting)
          const Center(child: CircularProgressIndicator())
        else if (snapshot.state == FlareSearchState.failure)
          FlareStatusBanner(
            text: snapshot.error ?? widget.idleText,
            tone: FlareStatusTone.danger,
            actionText: widget.searchText,
            onAction: () => widget.onSearch(_submitted),
          )
        else if (snapshot.state == FlareSearchState.success)
          FlareSearchResults(
            groups: snapshot.groups,
            query: _submitted.query,
            onOpen: widget.onOpen,
            onViewAll: widget.onViewAll,
          )
        else
          Text(widget.idleText),
      ],
    );
  }
}
