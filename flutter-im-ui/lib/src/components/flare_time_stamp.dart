import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Muted, small-caps timestamp label. Spec: General/TimeStamp (`FlareTimeStamp`).
///
/// Pure display — the caller formats [label] (relative "刚刚", clock time, or a
/// date) upstream; the component only styles it with the design tokens.
class FlareTimeStamp extends StatelessWidget {
  const FlareTimeStamp({super.key, required this.label});

  /// Pre-formatted timestamp text.
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Text(
      label,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: FlareSizes.fontSizeXs,
        height: FlareSizes.lineHeightNormal,
      ),
    );
  }
}
