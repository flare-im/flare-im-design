import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// A custom select — a token-styled trigger (bgSecondary, borderPrimary, pill)
/// that, because a native app is always mobile, presents its [options] as a
/// **modal bottom sheet**. The selected row shows the brand primary + a check;
/// disabled rows are non-tappable. Custom-built from Flare tokens.
/// Spec: Form/Select.
class FlareSelect extends StatefulWidget {
  const FlareSelect({
    super.key,
    required this.options,
    required this.value,
    this.placeholder,
    this.title,
    this.size = FlareControlSize.md,
    this.disabled = false,
    this.onChanged,
  });

  final List<FlareSelectOption> options;
  final String value;
  final String? placeholder;

  /// Sheet header title (defaults to [placeholder]). Matches the Vue `title`
  /// prop.
  final String? title;
  final FlareControlSize size;
  final bool disabled;
  final void Function(String)? onChanged;

  @override
  State<FlareSelect> createState() => _FlareSelectState();
}

class _FlareSelectState extends State<FlareSelect> {
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
    final brightness = Theme.of(context).brightness;
    final colors = FlareColors.of(brightness);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF151220).withValues(alpha: 0.44),
      isScrollControlled: true,
      builder: (ctx) => _OptionsSheet(
        options: widget.options,
        value: widget.value,
        title: widget.title ?? widget.placeholder,
        colors: colors,
      ),
    );
    if (mounted) setState(() => _open = false);
    if (picked != null) widget.onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    FlareSelectOption? current;
    for (final o in widget.options) {
      if (o.value == widget.value) {
        current = o;
        break;
      }
    }

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
            constraints: const BoxConstraints(minWidth: 160),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              border: Border.all(
                color: _open ? colors.primary : colors.borderPrimary,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    current?.label ?? widget.placeholder ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _fontSize,
                      color: current != null
                          ? colors.textPrimary
                          : colors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 150),
                  turns: _open ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: colors.textTertiary,
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
/// centered title, and a scrollable option list (min 52px rows). Selected row =
/// [FlareColors.primary] + [Icons.check]; disabled rows are non-tappable at
/// 0.45 opacity.
class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet({
    required this.options,
    required this.value,
    required this.title,
    required this.colors,
  });

  final List<FlareSelectOption> options;
  final String value;
  final String? title;
  final FlareColors colors;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.72;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
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
          if (title != null && title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Text(
                title!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textTertiary,
                ),
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    options.map((o) => _option(context, o)).toList(growable: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, FlareSelectOption o) {
    final selected = o.value == value;
    return Opacity(
      opacity: o.disabled ? 0.45 : 1,
      child: MouseRegion(
        cursor: o.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: o.disabled ? null : () => Navigator.of(context).pop(o.value),
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    o.label,
                    style: TextStyle(
                      fontSize: 16,
                      color: selected ? colors.primary : colors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check, size: 19, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
