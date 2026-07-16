import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// A custom select — a token-styled trigger (bgSecondary, borderPrimary, pill)
/// that opens an overlay list of [options]. The selected row shows the brand
/// primary + a check; disabled rows are non-tappable. Custom-built from Flare
/// tokens. Spec: Form/Select.
class FlareSelect extends StatefulWidget {
  const FlareSelect({
    super.key,
    required this.options,
    required this.value,
    this.placeholder,
    this.size = FlareControlSize.md,
    this.disabled = false,
    this.onChanged,
  });

  final List<FlareSelectOption> options;
  final String value;
  final String? placeholder;
  final FlareControlSize size;
  final bool disabled;
  final void Function(String)? onChanged;

  @override
  State<FlareSelect> createState() => _FlareSelectState();
}

class _FlareSelectState extends State<FlareSelect> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();
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

  void _toggle() {
    if (widget.disabled) return;
    setState(() => _open = !_open);
    if (_open) {
      _controller.show();
    } else {
      _controller.hide();
    }
  }

  void _close() {
    setState(() => _open = false);
    _controller.hide();
  }

  void _pick(FlareSelectOption o) {
    if (o.disabled) return;
    widget.onChanged?.call(o.value);
    _close();
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

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) => _buildOverlay(context, colors),
        child: Opacity(
          opacity: widget.disabled ? 0.55 : 1,
          child: MouseRegion(
            cursor: widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _toggle,
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
                          color: current != null ? colors.textPrimary : colors.textTertiary,
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
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, FlareColors colors) {
    return Stack(
      children: [
        // Full-screen barrier to dismiss on outside tap.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(minWidth: 160, maxHeight: 240),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.bgPrimary,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                  border: Border.all(color: colors.borderPrimary),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF151220).withValues(alpha: 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.options.map((o) => _option(colors, o)).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _option(FlareColors colors, FlareSelectOption o) {
    final selected = o.value == widget.value;
    return Opacity(
      opacity: o.disabled ? 0.45 : 1,
      child: MouseRegion(
        cursor: o.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: o.disabled ? null : () => _pick(o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    o.label,
                    style: TextStyle(
                      fontSize: 14,
                      color: selected ? colors.primary : colors.textPrimary,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected) Icon(Icons.check, size: 15, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
