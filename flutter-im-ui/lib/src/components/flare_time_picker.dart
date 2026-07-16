import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// A token-styled time picker — a pill trigger (bgSecondary, borderPrimary) with
/// a clock leading icon and an `HH:mm` value, styled identically to [FlareSelect].
/// Because a native app is always mobile, tapping the trigger opens a **modal
/// bottom sheet** (the app form of the Vue component's H5 sheet branch) with two
/// scrollable columns — hours 00–23 and minutes 00, [minuteStep], … — plus a
/// 取消 / 确定 footer. Custom-built from Flare tokens.
/// Spec: Form/TimePicker.
class FlareTimePicker extends StatefulWidget {
  const FlareTimePicker({
    super.key,
    this.value = '',
    this.placeholder,
    this.title,
    this.size = FlareControlSize.md,
    this.minuteStep = 5,
    this.disabled = false,
    this.onChanged,
  });

  /// Current time as `"HH:mm"` (empty shows the placeholder).
  final String value;
  final String? placeholder;

  /// Sheet header title (defaults to [placeholder]). Matches the Vue `title`
  /// prop.
  final String? title;
  final FlareControlSize size;

  /// Minute granularity. Clamped to 1–30. Matches the Vue `minuteStep` prop.
  final int minuteStep;
  final bool disabled;

  /// Flutter idiom replacing the Vue v-model; emits the chosen `"HH:mm"`.
  final void Function(String)? onChanged;

  @override
  State<FlareTimePicker> createState() => _FlareTimePickerState();
}

class _FlareTimePickerState extends State<FlareTimePicker> {
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
    final colors = FlareColors.of(Theme.of(context).brightness);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF151220).withValues(alpha: 0.44),
      isScrollControlled: true,
      builder: (ctx) => _TimeSheet(
        value: widget.value,
        title: widget.title ?? widget.placeholder,
        minuteStep: widget.minuteStep,
        colors: colors,
      ),
    );
    if (mounted) setState(() => _open = false);
    if (picked != null) widget.onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
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
            constraints: const BoxConstraints(minWidth: 130),
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
                  Icons.schedule,
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
                      color:
                          hasValue ? colors.textPrimary : colors.textTertiary,
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
/// centered title, two scrollable columns (hours / minutes) separated by a `:`,
/// and a 取消 / 确定 footer. Selected cell = [FlareColors.bgSelected] bg +
/// [FlareColors.primary] bold text. Manages its own temporary selection,
/// initialised from [value]; 确定 pops the chosen `"HH:mm"`, 取消 pops null.
class _TimeSheet extends StatefulWidget {
  const _TimeSheet({
    required this.value,
    required this.title,
    required this.minuteStep,
    required this.colors,
  });

  final String value;
  final String? title;
  final int minuteStep;
  final FlareColors colors;

  @override
  State<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<_TimeSheet> {
  static const double _rowExtent = 44;

  late int _hour;
  late int _minute;
  late final List<int> _hours;
  late final List<int> _minutes;
  late final ScrollController _hourCtrl;
  late final ScrollController _minCtrl;

  @override
  void initState() {
    super.initState();
    final step = widget.minuteStep.clamp(1, 30);
    _hours = List<int>.generate(24, (i) => i);
    _minutes = List<int>.generate((60 / step).ceil(), (i) => i * step);

    final parts = widget.value.split(':');
    _hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    _minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

    // Snap the initial minute to the nearest available step so the column has a
    // real selection to highlight and centre.
    if (!_minutes.contains(_minute)) {
      _minute = _minutes.reduce(
        (a, b) => (a - _minute).abs() <= (b - _minute).abs() ? a : b,
      );
    }

    _hourCtrl = ScrollController(
      initialScrollOffset: _centerOffset(_hours.indexOf(_hour)),
    );
    _minCtrl = ScrollController(
      initialScrollOffset: _centerOffset(_minutes.indexOf(_minute)),
    );
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  /// Roughly centres [index] within a ~240px viewport of [_rowExtent] rows.
  double _centerOffset(int index) {
    if (index <= 0) return 0;
    return (index * _rowExtent - (240 - _rowExtent) / 2).clamp(0, double.infinity);
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

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
      padding: EdgeInsets.fromLTRB(8, 8, 8, 10 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag grip.
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.fromLTRB(0, 6, 0, 8),
            decoration: BoxDecoration(
              color: colors.borderPrimary,
              borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
            ),
          ),
          if (title != null && title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
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
          // Two scrollable columns separated by a colon.
          SizedBox(
            height: 240,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _column(
                  controller: _hourCtrl,
                  items: _hours,
                  selected: _hour,
                  onTap: (v) => setState(() => _hour = v),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Center(
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                ),
                _column(
                  controller: _minCtrl,
                  items: _minutes,
                  selected: _minute,
                  onTap: (v) => setState(() => _minute = v),
                ),
              ],
            ),
          ),
          // Footer: 取消 / 确定.
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
            child: Row(
              children: [
                Expanded(
                  child: _footerButton(
                    label: '取消',
                    primary: false,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _footerButton(
                    label: '确定',
                    primary: true,
                    onTap: () => Navigator.of(context)
                        .pop('${_pad(_hour)}:${_pad(_minute)}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _column({
    required ScrollController controller,
    required List<int> items,
    required int selected,
    required void Function(int) onTap,
  }) {
    final colors = widget.colors;
    return SizedBox(
      width: 96,
      child: ListView.builder(
        controller: controller,
        padding: EdgeInsets.zero,
        itemExtent: _rowExtent,
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final v = items[i];
          final isSel = v == selected;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: GestureDetector(
              onTap: () => onTap(v),
              behavior: HitTestBehavior.opaque,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSel ? colors.bgSelected : Colors.transparent,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
                ),
                child: Text(
                  _pad(v),
                  style: TextStyle(
                    fontSize: 17,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                    color: isSel ? colors.primary : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
