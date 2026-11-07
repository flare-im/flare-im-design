import 'package:flutter/material.dart';

import '../models/update_prompt.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_overlay.dart' show flareReduceMotion;

/// A linear progress bar: a value from 0 to 1, or a sliding fill while the
/// length of the work is not known. Spec: Feedback/ProgressBar
/// (`FlareProgressBar`).
///
/// A value that is missing or not finite reads as indeterminate
/// (`spec/update-prompt-vectors.json`, the same in every kit). Screen readers
/// get [label] and the number. Under reduced motion the indeterminate fill
/// stands still and muted.
class FlareProgressBar extends StatefulWidget {
  const FlareProgressBar({
    super.key,
    this.value,
    this.indeterminate = false,
    this.tone = FlareProgressBarTone.primary,
    this.label,
  });

  /// How far along, 0 to 1.
  final double? value;

  /// The length of the work is not known: the fill slides instead.
  final bool indeterminate;

  /// What the colour says.
  final FlareProgressBarTone tone;

  /// What is progressing, for a screen reader.
  final String? label;

  @override
  State<FlareProgressBar> createState() => _FlareProgressBarState();
}

class _FlareProgressBarState extends State<FlareProgressBar>
    with SingleTickerProviderStateMixin {
  /// The sliding fill's share of the track.
  static const _slideShare = 0.4;

  /// One pass of the sliding fill, the kit's looping pace.
  static const _slideDuration = Duration(milliseconds: 1400);

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: _slideDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow();
  }

  @override
  void didUpdateWidget(FlareProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _follow();
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  /// The fill slides only with nothing to measure and motion allowed.
  void _follow() {
    final shown = flareProgressBarValue(
      widget.value,
      indeterminate: widget.indeterminate,
    );
    final sliding = shown.value == null && !flareReduceMotion(context);
    if (sliding && !_slide.isAnimating) {
      _slide.repeat();
    } else if (!sliding && _slide.isAnimating) {
      _slide.stop();
    }
  }

  Color _fill(FlareColors colors) => switch (widget.tone) {
    FlareProgressBarTone.primary => colors.primaryText,
    FlareProgressBarTone.success => colors.successText,
    FlareProgressBarTone.warning => colors.warningText,
    FlareProgressBarTone.danger => colors.errorText,
    FlareProgressBarTone.neutral => colors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final shown = flareProgressBarValue(
      widget.value,
      indeterminate: widget.indeterminate,
    );
    final value = shown.value;
    final still = flareReduceMotion(context);
    final fill = _fill(colors);

    Widget bar(double start, double share, {double opacity = 1}) =>
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                PositionedDirectional(
                  start: start * width,
                  top: 0,
                  bottom: 0,
                  width: share * width,
                  child: Opacity(
                    opacity: opacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(
                          FlareSizes.radiusFull,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );

    final Widget track = value != null
        ? bar(0, value)
        : still
        ? bar(0, 1, opacity: FlareOpacity.muted)
        : AnimatedBuilder(
            animation: _slide,
            builder: (context, _) => bar(
              -_slideShare + (1 + _slideShare) * _slide.value,
              _slideShare,
            ),
          );

    return Semantics(
      container: true,
      label: widget.label ?? strings.progressBarLabel,
      value: shown.percent == null
          ? strings.progressBarLoading
          : '${shown.percent}%',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
          child: SizedBox(
            height: FlareSizes.spacingXs,
            width: double.infinity,
            child: ColoredBox(color: colors.bgTertiary, child: track),
          ),
        ),
      ),
    );
  }
}
