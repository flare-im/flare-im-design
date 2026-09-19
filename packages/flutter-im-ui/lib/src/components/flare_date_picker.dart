import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';
import 'icon_control.dart';

/// A token-styled date picker — a pill trigger (bgSecondary, borderPrimary) with
/// a calendar leading icon and a `YYYY-MM-DD` value, styled identically to
/// [FlareTimePicker] / [FlareSelect]. Because a native app is always mobile,
/// tapping the trigger opens a **modal bottom sheet** (the app form of the Vue
/// component's H5 sheet branch) containing a month calendar: a ‹ month-label ›
/// nav header, a weekday row, a 7-column day grid (selected day = brand-gradient
/// bg + white bold, today = primary ring, out-of-range days disabled), and a
/// 取消 / 今天 footer. Custom-built from Flare tokens.
/// Spec: Form/DatePicker.
class FlareDatePicker extends StatefulWidget {
  const FlareDatePicker({
    super.key,
    this.value = '',
    this.placeholder,
    this.title,
    this.size = FlareControlSize.md,
    this.min,
    this.max,
    this.disabled = false,
    this.cancelLabel,
    this.todayLabel,
    this.onChanged,
  });

  /// Current date as `"YYYY-MM-DD"` (empty shows the placeholder).
  final String value;
  final String? placeholder;

  /// Sheet header title (defaults to [placeholder]). Matches the Vue `title`
  /// prop.
  final String? title;
  final FlareControlSize size;

  /// Earliest selectable date `"YYYY-MM-DD"`. Matches the Vue `min` prop.
  final String? min;

  /// Latest selectable date `"YYYY-MM-DD"`. Matches the Vue `max` prop.
  final String? max;
  final bool disabled;

  /// Footer button labels; override to localize (default Chinese 取消 / 今天).
  final String? cancelLabel;
  final String? todayLabel;

  /// Flutter idiom replacing the Vue v-model; emits the chosen `"YYYY-MM-DD"`.
  final void Function(String)? onChanged;

  @override
  State<FlareDatePicker> createState() => _FlareDatePickerState();
}

class _FlareDatePickerState extends State<FlareDatePicker> {
  String get _cancelLabel =>
      widget.cancelLabel ?? FlareStrings.of(context).cancel;
  String get _todayLabel => widget.todayLabel ?? FlareStrings.of(context).today;
  bool _open = false;

  double get _height => switch (widget.size) {
    FlareControlSize.sm => 32,
    FlareControlSize.md => 40,
    FlareControlSize.lg => 48,
  };

  double get _hPad => switch (widget.size) {
    FlareControlSize.sm => 10,
    FlareControlSize.md => 12,
    FlareControlSize.lg => 14,
  };

  double get _fontSize => switch (widget.size) {
    FlareControlSize.sm => 13,
    FlareControlSize.md => 14,
    FlareControlSize.lg => 15,
  };

  Future<void> _openSheet() async {
    if (widget.disabled) return;
    setState(() => _open = true);
    final colors = FlareColors.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF151220).withValues(alpha: 0.44),
      isScrollControlled: true,
      builder: (ctx) => _DateSheet(
        value: widget.value,
        title: widget.title ?? widget.placeholder,
        min: widget.min,
        max: widget.max,
        cancelLabel: _cancelLabel,
        todayLabel: _todayLabel,
        previousMonthLabel: FlareStrings.of(context).previousMonth,
        nextMonthLabel: FlareStrings.of(context).nextMonth,
        colors: colors,
      ),
    );
    if (mounted) setState(() => _open = false);
    if (picked != null) widget.onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final hasValue = widget.value.isNotEmpty;

    return Opacity(
      opacity: widget.disabled ? 0.55 : 1,
      child: MouseRegion(
        cursor: widget.disabled
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _openSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: _height,
            padding: EdgeInsets.symmetric(horizontal: _hPad),
            constraints: const BoxConstraints(minWidth: 150),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              border: Border.all(
                color: _open ? colors.primary : colors.borderPrimary,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colors.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasValue ? widget.value : (widget.placeholder ?? ''),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: hasValue
                          ? colors.textPrimary
                          : colors.textTertiary,
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

/// The modal bottom sheet content: rounded top corners, a drag grip, an optional
/// centered title, a month calendar (‹ month-label › nav header, weekday row,
/// 7-column day grid), and a [cancelLabel] / [todayLabel] footer. Manages its
/// own view month + temporary selection, initialised from [value]. Tapping a day
/// pops the chosen `"YYYY-MM-DD"`; [todayLabel] jumps to and selects today then
/// pops; [cancelLabel] pops null.
class _DateSheet extends StatefulWidget {
  const _DateSheet({
    required this.value,
    required this.title,
    required this.min,
    required this.max,
    required this.cancelLabel,
    required this.todayLabel,
    required this.previousMonthLabel,
    required this.nextMonthLabel,
    required this.colors,
  });

  final String value;
  final String? title;
  final String? min;
  final String? max;
  final String cancelLabel;
  final String todayLabel;

  /// Accessible names of the month navigation controls, resolved where the
  /// picker sits (a sheet route may be outside the host's strings scope).
  final String previousMonthLabel;
  final String nextMonthLabel;
  final FlareColors colors;

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  late int _viewYear;
  late int _viewMonth; // 0-11
  late final DateTime _now;
  late final String _todayStr;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _todayStr = _dstr(_now.year, _now.month, _now.day);

    final parsed = _tryParse(widget.value);
    final anchor = parsed ?? _now;
    _viewYear = anchor.year;
    _viewMonth = anchor.month - 1;
  }

  static DateTime? _tryParse(String s) {
    final parts = s.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// `"YYYY-MM-DD"` from a 1-based month.
  static String _dstr(int year, int month, int day) =>
      '$year-${_pad(month)}-${_pad(day)}';

  String _cell(int day) => _dstr(_viewYear, _viewMonth + 1, day);

  bool _isDisabled(int day) {
    final s = _cell(day);
    final min = widget.min;
    final max = widget.max;
    return (min != null && min.isNotEmpty && s.compareTo(min) < 0) ||
        (max != null && max.isNotEmpty && s.compareTo(max) > 0);
  }

  void _nav(int delta) {
    final m = _viewMonth + delta;
    setState(() {
      _viewYear += (m / 12).floor();
      _viewMonth = ((m % 12) + 12) % 12;
    });
  }

  void _goToday() {
    Navigator.of(context).pop(_todayStr);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final title = widget.title;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(FlareSizes.radius2xl),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF151220).withValues(alpha: 0.22),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(12, 8, 12, 10 + bottomInset),
      // Scrolls when large text makes the month taller than the screen (a
      // phone in landscape, a short window) instead of overflowing.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag grip.
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.fromLTRB(
                0,
                FlareSizes.spacing2xs,
                0,
                FlareSizes.spacingXs,
              ),
              decoration: BoxDecoration(
                color: colors.borderPrimary,
                borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
              ),
            ),
            if (title != null && title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            // The month header is a touch target tall; its lower half is the gap
            // above the weekday row.
            _monthHeader(colors),
            _weekdayRow(colors),
            const SizedBox(height: 4),
            _dayGrid(colors),
            // Footer: 取消 / 今天.
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 2),
              child: Row(
                children: [
                  Expanded(
                    child: _footerButton(
                      label: widget.cancelLabel,
                      primary: false,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _footerButton(
                      label: widget.todayLabel,
                      primary: true,
                      onTap: _goToday,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthHeader(FlareColors colors) {
    // 年月标题取自框架的区域数据，随宿主 locale 自动切换。
    final label = MaterialLocalizations.of(
      context,
    ).formatMonthYear(DateTime(_viewYear, _viewMonth + 1));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navButton(
          'chevron-left',
          widget.previousMonthLabel,
          () => _nav(-1),
          colors,
        ),
        // The label gives way at large text sizes; the month keys keep their
        // full touch targets.
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: colors.textPrimary,
            ),
          ),
        ),
        _navButton(
          'chevron-right',
          widget.nextMonthLabel,
          () => _nav(1),
          colors,
        ),
      ],
    );
  }

  Widget _navButton(
    String icon,
    String label,
    VoidCallback onTap,
    FlareColors colors,
  ) {
    return FlareIconControl(
      label: label,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
        ),
        child: FlareIcon(
          icon,
          size: FlareSizes.iconSizeMd,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _weekdayRow(FlareColors colors) {
    return Row(
      children: [
        // 星期名取自框架的区域数据（周日起，与下方日期网格排布一致），
        // 随宿主 locale 自动切换，无需组件自备中文常量。
        for (final w in MaterialLocalizations.of(context).narrowWeekdays)
          Expanded(
            child: Center(
              child: Text(
                w,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dayGrid(FlareColors colors) {
    // Leading blanks for the first weekday (Sun=0), then the month's days.
    final startDow = DateTime(_viewYear, _viewMonth + 1, 1).weekday % 7;
    final daysIn = DateTime(_viewYear, _viewMonth + 2, 0).day;
    final cells = <int?>[
      for (var i = 0; i < startDow; i++) null,
      for (var d = 1; d <= daysIn; d++) d,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 7,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: [for (final d in cells) _dayCell(d, colors)],
    );
  }

  Widget _dayCell(int? day, FlareColors colors) {
    if (day == null) return const SizedBox.shrink();

    final s = _cell(day);
    final isSelected = widget.value.isNotEmpty && s == widget.value;
    final isToday = s == _todayStr;
    final disabled = _isDisabled(day);

    Color textColor;
    FontWeight weight = FontWeight.w400;
    BoxDecoration? decoration;

    if (isSelected) {
      textColor = Colors.white;
      weight = FontWeight.w600;
      decoration = BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
      );
    } else if (isToday) {
      textColor = colors.primary;
      weight = FontWeight.w600;
      decoration = BoxDecoration(
        border: Border.all(color: colors.primary),
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
      );
    } else {
      textColor = colors.textPrimary;
    }

    final cell = AspectRatio(
      aspectRatio: 1,
      child: Container(
        alignment: Alignment.center,
        decoration: decoration,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 14,
            fontWeight: weight,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: textColor,
          ),
        ),
      ),
    );

    if (disabled) {
      return Opacity(opacity: 0.32, child: cell);
    }
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(s),
      behavior: HitTestBehavior.opaque,
      child: cell,
    );
  }

  Widget _footerButton({
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    final colors = widget.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? colors.primary : colors.bgSecondary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primary ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
