import 'package:flutter/material.dart';
import '../tokens/flare_tokens.dart';

/// The decorative red arch under the header of red packet pages (composer,
/// review, detail). Spec: RedPacket/RedPacketArch (`FlareRedPacketArch`).
/// It spans its container's width — never put it inside a card that clips
/// it — and is hidden from screen readers.
class FlareRedPacketArch extends StatelessWidget {
  const FlareRedPacketArch({super.key, this.compact = false});

  /// [FlareSizes.componentRedPacketArchCompactHeight] (composer, review)
  /// instead of
  /// [FlareSizes.componentRedPacketDetailHeaderHeight] (detail).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final height = compact
        ? FlareSizes.componentRedPacketArchCompactHeight
        : FlareSizes.componentRedPacketDetailHeaderHeight;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) => Container(
          height: height,
          decoration: BoxDecoration(
            color: colors.redPacketEnd,
            // A full-width band: straight sides 60% high, the bottom bowed
            // across the whole width by the other 40% (spec RedPacketArch).
            borderRadius: BorderRadius.vertical(
              bottom: Radius.elliptical(constraints.maxWidth / 2, height * 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
