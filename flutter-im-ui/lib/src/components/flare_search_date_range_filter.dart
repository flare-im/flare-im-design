import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_date_picker.dart';
import 'flare_search_panel.dart';

/// Inclusive UTC epoch milliseconds; absent bounds mean unrestricted.
@immutable
class FlareSearchTimeRange {
  const FlareSearchTimeRange({this.fromTime, this.toTime});
  final int? fromTime, toTime;

  @override
  bool operator ==(Object other) =>
      other is FlareSearchTimeRange &&
      other.fromTime == fromTime &&
      other.toTime == toTime;

  @override
  int get hashCode => Object.hash(fromTime, toTime);
}

/// The two local date strings a pair of DatePickers is bound to; '' means unset.
@immutable
class FlareSearchDateDraft {
  const FlareSearchDateDraft({required this.from, required this.to});
  final String from, to;

  @override
  bool operator ==(Object other) =>
      other is FlareSearchDateDraft && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

bool sameSearchTimeRange(FlareSearchTimeRange a, FlareSearchTimeRange b) =>
    a.fromTime == b.fromTime && a.toTime == b.toTime;

const int _maxSafeInteger = 9007199254740991;
final RegExp _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

List<int>? _dateParts(String date) {
  final match = _datePattern.firstMatch(date.trim());
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final probe = DateTime.utc(year, month, day);
  if (probe.year != year || probe.month != month || probe.day != day) return null;
  return [year, month, day];
}

int? _atLocalTime(String date, int hour, int minute, int second, int millis,
    int? tzOffsetMinutes) {
  final parts = _dateParts(date);
  if (parts == null) return null;
  final [year, month, day] = parts;
  if (tzOffsetMinutes == null) {
    return DateTime(year, month, day, hour, minute, second, millis)
        .millisecondsSinceEpoch;
  }
  return DateTime.utc(year, month, day, hour, minute, second, millis)
          .millisecondsSinceEpoch -
      tzOffsetMinutes * 60000;
}

/// Inclusive lower bound: 00:00:00.000 of [date]. `null` when the string is not
/// a real date. [tzOffsetMinutes] is minutes **east of UTC** (UTC+8 → 480);
/// omitted, the device zone for that calendar date is used.
int? dayStartMs(String date, [int? tzOffsetMinutes]) =>
    _atLocalTime(date, 0, 0, 0, 0, tzOffsetMinutes);

/// Inclusive upper bound: 23:59:59.999 of [date]. `null` for a non-date.
int? dayEndMs(String date, [int? tzOffsetMinutes]) =>
    _atLocalTime(date, 23, 59, 59, 999, tzOffsetMinutes);

bool _usableTime(int? time) =>
    time != null && time >= 0 && time <= _maxSafeInteger;

/// Build the range two DatePickers describe. Both blank is *unrestricted*
/// (an empty range), not an error. `null` means the host must not submit: an
/// unparsable date, an instant before the epoch, or `from` after `to`.
FlareSearchTimeRange? rangeFromDates(String from, String to,
    [int? tzOffsetMinutes]) {
  int? fromTime, toTime;
  if (from.trim().isNotEmpty) {
    final parsed = dayStartMs(from, tzOffsetMinutes);
    if (!_usableTime(parsed)) return null;
    fromTime = parsed;
  }
  if (to.trim().isNotEmpty) {
    final parsed = dayEndMs(to, tzOffsetMinutes);
    if (!_usableTime(parsed)) return null;
    toTime = parsed;
  }
  if (fromTime != null && toTime != null && fromTime > toTime) return null;
  return FlareSearchTimeRange(fromTime: fromTime, toTime: toTime);
}

String _pad(int value, [int width = 2]) =>
    value.toString().padLeft(width, '0');

String _dateStringOf(int? time, int? tzOffsetMinutes) {
  if (time == null || time < 0) return '';
  final moment = tzOffsetMinutes == null
      ? DateTime.fromMillisecondsSinceEpoch(time)
      : DateTime.fromMillisecondsSinceEpoch(
          time + tzOffsetMinutes * 60000,
          isUtc: true,
        );
  return '${_pad(moment.year, 4)}-${_pad(moment.month)}-${_pad(moment.day)}';
}

/// Fill the DatePickers back from a range; an absent bound stays ''.
FlareSearchDateDraft datesFromRange(FlareSearchTimeRange range,
        [int? tzOffsetMinutes]) =>
    FlareSearchDateDraft(
      from: _dateStringOf(range.fromTime, tzOffsetMinutes),
      to: _dateStringOf(range.toTime, tzOffsetMinutes),
    );

/// Neither bound set — the "no time limit" state.
bool unrestrictedRange(FlareSearchTimeRange range) =>
    range.fromTime == null && range.toTime == null;

/// Which preset chip is selected. Matching is by value, not by id, because a
/// host may rebuild its option objects on every build.
String? matchedOptionId(
    FlareSearchTimeRange value, List<FlareSearchRangeOption> options) {
  for (final option in options) {
    if (value.fromTime == option.fromTime && value.toTime == option.toTime) {
      return option.id;
    }
  }
  return null;
}

/// Whether the custom start/end area is expanded: never without [allowCustom],
/// always when the host forces it, otherwise whenever the current value is a
/// real range no preset covers.
bool shouldOpenCustomRange(
  FlareSearchTimeRange value,
  List<FlareSearchRangeOption> options,
  bool allowCustom, [
  bool customActive = false,
]) {
  if (!allowCustom) return false;
  if (customActive) return true;
  return !unrestrictedRange(value) && matchedOptionId(value, options) == null;
}

/// Time-range filter for search. Host-supplied presets are chips; "custom"
/// expands a start/end pair built from [FlareDatePicker]. The component owns no
/// clock — it never computes "today" itself — and emits one
/// [FlareSearchTimeRange] in inclusive UTC epoch milliseconds that the host
/// folds into its search criteria.
/// Spec: General/SearchDateRangeFilter (`FlareSearchDateRangeFilter`).
class FlareSearchDateRangeFilter extends StatefulWidget {
  const FlareSearchDateRangeFilter({
    super.key,
    required this.value,
    required this.onChange,
    this.options = const [],
    this.allowCustom = true,
    this.customActive = false,
    this.minDate,
    this.maxDate,
    this.tzOffsetMinutes,
    this.disabled = false,
    this.onClear,
    this.title = '时间范围',
    this.customText = '自定义',
    this.fromLabel = '起始日期',
    this.toLabel = '结束日期',
    this.clearText = '清除',
    this.unlimitedText = '不限时间',
    this.invalidText = '起始日期不能晚于结束日期',
  });

  /// Current range, controlled by the host.
  final FlareSearchTimeRange value;

  /// Preset chips. The host computes them (today / last 7 days / …) so time
  /// zones stay its business.
  final List<FlareSearchRangeOption> options;
  final bool allowCustom;

  /// Force the custom area open (e.g. restoring a saved filter).
  final bool customActive;

  /// Earliest / latest selectable day, `"YYYY-MM-DD"`, passed to the picker.
  final String? minDate, maxDate;

  /// Minutes east of UTC (UTC+8 → 480). Null uses the device zone.
  final int? tzOffsetMinutes;
  final bool disabled;

  final void Function(FlareSearchTimeRange) onChange;

  /// Absent hides the clear button.
  final VoidCallback? onClear;

  final String title,
      customText,
      fromLabel,
      toLabel,
      clearText,
      unlimitedText,
      invalidText;

  @override
  State<FlareSearchDateRangeFilter> createState() =>
      _FlareSearchDateRangeFilterState();
}

class _FlareSearchDateRangeFilterState
    extends State<FlareSearchDateRangeFilter> {
  late FlareSearchDateDraft _draft =
      datesFromRange(widget.value, widget.tzOffsetMinutes);
  late bool _customOpen = _forcedOpen;

  bool get _forcedOpen => shouldOpenCustomRange(
      widget.value, widget.options, widget.allowCustom, widget.customActive);

  @override
  void didUpdateWidget(FlareSearchDateRangeFilter old) {
    super.didUpdateWidget(old);
    // Re-seed the pickers only when the host pushes a range the current draft
    // does not already describe — an illegal draft must survive until fixed.
    final current = rangeFromDates(_draft.from, _draft.to, widget.tzOffsetMinutes);
    if (current == null || !sameSearchTimeRange(current, widget.value)) {
      _draft = datesFromRange(widget.value, widget.tzOffsetMinutes);
    }
    if (_forcedOpen) _customOpen = true;
  }

  void _chooseOption(FlareSearchRangeOption option) {
    if (widget.disabled || !option.isValid) return;
    final next =
        FlareSearchTimeRange(fromTime: option.fromTime, toTime: option.toTime);
    if (sameSearchTimeRange(next, widget.value)) return;
    widget.onChange(next);
  }

  void _commit() {
    final range = rangeFromDates(_draft.from, _draft.to, widget.tzOffsetMinutes);
    if (range == null) return; // illegal draft: keep it visible, emit nothing
    if (sameSearchTimeRange(range, widget.value)) return;
    widget.onChange(range);
  }

  void _pick({String? from, String? to}) {
    if (widget.disabled) return;
    setState(() => _draft = FlareSearchDateDraft(
          from: from ?? _draft.from,
          to: to ?? _draft.to,
        ));
    _commit();
  }

  String _summary() {
    if (unrestrictedRange(widget.value)) return widget.unlimitedText;
    final id = matchedOptionId(widget.value, widget.options);
    for (final option in widget.options) {
      if (option.id == id) return option.label;
    }
    final dates = datesFromRange(widget.value, widget.tzOffsetMinutes);
    final parts = <String>[
      if (dates.from.isNotEmpty) '${widget.fromLabel} ${dates.from}',
      if (dates.to.isNotEmpty) '${widget.toLabel} ${dates.to}',
    ];
    return parts.isEmpty ? widget.unlimitedText : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final selectedId = matchedOptionId(widget.value, widget.options);
    final showCustom = widget.allowCustom && _customOpen;
    final invalid = widget.allowCustom &&
        rangeFromDates(_draft.from, _draft.to, widget.tzOffsetMinutes) == null;
    final unrestricted = unrestrictedRange(widget.value);

    return Semantics(
      container: true,
      label: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: FlareSizes.fontSizeXl,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: FlareSizes.spacingMd),
          Wrap(
            spacing: FlareSizes.spacingSm,
            runSpacing: FlareSizes.spacingSm,
            children: [
              for (final option in widget.options)
                _Chip(
                  label: option.label,
                  selected: selectedId == option.id,
                  disabled: widget.disabled || !option.isValid,
                  colors: colors,
                  onTap: () => _chooseOption(option),
                ),
              if (widget.allowCustom)
                _Chip(
                  label: widget.customText,
                  icon: Icons.calendar_today_outlined,
                  selected: showCustom,
                  expanded: showCustom,
                  disabled: widget.disabled,
                  colors: colors,
                  onTap: () => setState(() => _customOpen = !_customOpen),
                ),
            ],
          ),
          if (showCustom) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            Container(
              padding: const EdgeInsets.all(FlareSizes.spacingMd),
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(
                    colors: colors,
                    label: widget.fromLabel,
                    value: _draft.from,
                    onChanged: (date) => _pick(from: date),
                  ),
                  const SizedBox(height: FlareSizes.spacingMd),
                  _field(
                    colors: colors,
                    label: widget.toLabel,
                    value: _draft.to,
                    onChanged: (date) => _pick(to: date),
                  ),
                ],
              ),
            ),
          ],
          if (invalid) ...[
            const SizedBox(height: FlareSizes.spacingSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_outlined,
                    size: 16, color: colors.warning),
                const SizedBox(width: FlareSizes.spacingXs),
                Expanded(
                  child: Text(
                    widget.invalidText,
                    style: TextStyle(
                      color: colors.warning,
                      fontSize: FlareSizes.fontSizeMd,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: FlareSizes.spacingSm),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _summary(),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: FlareSizes.fontSizeMd,
                    ),
                  ),
                ),
              ),
              if (widget.onClear != null && !unrestricted)
                OutlinedButton(
                  onPressed: widget.disabled ? null : widget.onClear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.borderPrimary),
                    minimumSize: const Size(
                        FlareSizes.touchTarget, FlareSizes.touchTarget),
                  ),
                  child: Text(widget.clearText),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field({
    required FlareColors colors,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: FlareSizes.fontSizeMd,
          ),
        ),
        const SizedBox(height: FlareSizes.spacingXs),
        Row(
          children: [
            Expanded(
              child: FlareDatePicker(
                value: value,
                placeholder: label,
                title: label,
                size: FlareControlSize.lg,
                min: widget.minDate,
                max: widget.maxDate,
                disabled: widget.disabled,
                onChanged: onChanged,
              ),
            ),
            if (value.isNotEmpty)
              IconButton(
                onPressed: widget.disabled ? null : () => onChanged(''),
                tooltip: '${widget.clearText} $label',
                iconSize: 16,
                color: colors.textSecondary,
                constraints: const BoxConstraints(
                  minWidth: FlareSizes.touchTarget,
                  minHeight: FlareSizes.touchTarget,
                ),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.colors,
    required this.onTap,
    this.icon,
    this.expanded,
  });

  final String label;
  final bool selected, disabled;
  final FlareColors colors;
  final VoidCallback onTap;
  final IconData? icon;
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final foreground = disabled
        ? colors.textDisabled
        : (selected ? colors.primary : colors.textPrimary);
    return Semantics(
      button: true,
      selected: selected,
      expanded: expanded,
      enabled: !disabled,
      label: label,
      child: Material(
        color: disabled
            ? colors.bgDisabled
            : (selected ? colors.bgSelected : colors.bgPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
          side: BorderSide(
            color: selected && !disabled ? colors.primary : colors.borderPrimary,
          ),
        ),
        child: InkWell(
          onTap: disabled ? null : onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: FlareSizes.touchTarget,
              minHeight: FlareSizes.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingMd,
                vertical: FlareSizes.spacingSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: foreground),
                    const SizedBox(width: FlareSizes.spacingXs),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontSize: FlareSizes.fontSizeLg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
