import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// A range slider — a brand-gradient active track, a white thumb ringed in the
/// brand primary, and an optional value bubble ([showValue]) shown above the
/// thumb while dragging. Built on a custom track so the fill can carry the
/// `--im-brand-gradient` look. Custom-built from Flare tokens. Spec:
/// Form/Slider.
class FlareSlider extends StatefulWidget {
  const FlareSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.showValue = false,
    this.disabled = false,
    this.onChanged,
  });

  final double value;
  final double min;
  final double max;

  /// Step between discrete stops (<= 0 means continuous).
  final double step;

  /// Show a value bubble above the thumb while dragging.
  final bool showValue;
  final bool disabled;
  final void Function(double)? onChanged;

  @override
  State<FlareSlider> createState() => _FlareSliderState();
}

class _FlareSliderState extends State<FlareSlider> {
  bool _dragging = false;

  double get _pct {
    final span = widget.max - widget.min;
    if (span <= 0) return 0;
    return ((widget.value - widget.min) / span).clamp(0.0, 1.0);
  }

  double _snap(double raw) {
    var v = raw.clamp(widget.min, widget.max);
    if (widget.step > 0) {
      final steps = ((v - widget.min) / widget.step).round();
      v = widget.min + steps * widget.step;
      v = v.clamp(widget.min, widget.max);
    }
    return v;
  }

  void _updateFromDx(double dx, double width) {
    if (widget.disabled || width <= 0) return;
    final ratio = (dx / width).clamp(0.0, 1.0);
    final raw = widget.min + ratio * (widget.max - widget.min);
    final next = _snap(raw);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    const thumb = 18.0;

    return Opacity(
      opacity: widget.disabled ? 0.5 : 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 240.0;
          final travel = width - thumb;
          final pct = _pct;
          final thumbLeft = travel * pct;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: widget.disabled
                ? null
                : (d) {
                    setState(() => _dragging = true);
                    _updateFromDx(d.localPosition.dx - thumb / 2, travel);
                  },
            onHorizontalDragUpdate: widget.disabled
                ? null
                : (d) => _updateFromDx(d.localPosition.dx - thumb / 2, travel),
            onHorizontalDragEnd:
                widget.disabled ? null : (_) => setState(() => _dragging = false),
            onTapDown: widget.disabled
                ? null
                : (d) => _updateFromDx(d.localPosition.dx - thumb / 2, travel),
            child: SizedBox(
              width: double.infinity,
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Track.
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.borderHover,
                      borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                    ),
                  ),
                  // Brand-gradient fill.
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.primary, colors.primaryActive],
                        ),
                        borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                      ),
                    ),
                  ),
                  // Thumb.
                  Positioned(
                    left: thumbLeft,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: _dragging ? 1.14 : 1,
                      child: Container(
                        width: thumb,
                        height: thumb,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF151220).withValues(alpha: 0.24),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Value bubble.
                  if (widget.showValue && _dragging)
                    Positioned(
                      left: thumbLeft + thumb / 2,
                      bottom: 22,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
                          ),
                          child: Text(
                            _formatSliderValue(widget.value),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _formatSliderValue(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();
