import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// A message's media upload: a thin bar and its percent. The bubble draws it
/// while [FlareMessageData.uploadProgress] is set — under the body inside a
/// framed bubble, or as a dark pill over bare media ([overlay]). Same shape as
/// the Vue kit's `.message-upload-progress`.
class FlareUploadProgress extends StatelessWidget {
  const FlareUploadProgress({
    super.key,
    required this.percent,
    this.overlay = false,
    this.color,
  });

  /// 0–100; values outside are clamped.
  final int percent;

  /// Drawn over an image or video instead of under a body.
  final bool overlay;

  /// Colour of the bar and the percent when inline; the bubble passes its own
  /// text colour so the bar reads on both message surfaces.
  final Color? color;

  static const double _barWidth = 96;
  static const double _barHeight = 4;

  @override
  Widget build(BuildContext context) {
    final value = percent.clamp(0, 100);
    final base = overlay
        ? Colors.white
        : color ?? FlareColors.of(context).textSecondary;
    final foreground = base.withValues(alpha: overlay ? 1 : 0.72);
    final row = Row(
      mainAxisSize: overlay ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _bar(foreground, value, expand: overlay),
        const SizedBox(width: 7),
        SizedBox(
          width: 30,
          child: Text(
            '$value%',
            textAlign: TextAlign.right,
            maxLines: 1,
            style: TextStyle(
              color: foreground,
              fontSize: FlareSizes.fontSizeXs,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ],
    );
    return Semantics(
      label: 'upload $value%',
      excludeSemantics: true,
      child: overlay
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x9E0F172A),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                child: row,
              ),
            )
          : row,
    );
  }

  Widget _bar(Color foreground, int value, {required bool expand}) {
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
      child: SizedBox(
        height: _barHeight,
        width: expand ? null : _barWidth,
        child: LinearProgressIndicator(
          // A sliver shows even at 0 so the bar reads as a bar, not a gap.
          value: (value < 4 ? 4 : value) / 100,
          minHeight: _barHeight,
          backgroundColor: foreground.withValues(alpha: 0.16),
          valueColor: AlwaysStoppedAnimation(foreground),
        ),
      ),
    );
    return expand ? Expanded(child: bar) : bar;
  }
}
