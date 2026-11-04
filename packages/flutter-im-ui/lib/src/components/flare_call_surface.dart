import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../tokens/flare_tokens.dart';
import 'flare_call_controls.dart';
import 'flare_modal.dart';

/// A focused call modal. Only video conferences with more than two people
/// need the expanded workspace; voice and one-to-one calls keep chat visible.
class FlareCallSurface extends StatelessWidget {
  const FlareCallSurface({
    super.key,
    required this.mode,
    required this.child,
    this.expanded = false,
    this.label,
    this.onMinimize,
  });
  final FlareCallMode mode;
  final bool expanded;
  final String? label;
  final VoidCallback? onMinimize;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final video = mode == FlareCallMode.video;
    final width = expanded
        ? size.width - FlareSizes.spacingXl * 2
        : FlareSizes.componentSheetDialogWidth * (video ? 1.5 : 1);
    final height = expanded
        ? size.height * .9
        : math.min(
            size.height * .8,
            FlareSizes.componentSheetDialogWidth * (video ? 1.25 : 1),
          );
    return Stack(
      children: [
        Positioned.fill(
          child: ModalBarrier(
            color: FlareColors.of(context).scrim,
            dismissible: onMinimize != null,
            onDismiss: onMinimize,
          ),
        ),
        FlareModal(
          edgeToEdge: true,
          label: label,
          width: width,
          maxHeight: height,
          fill: true,
          scrollable: false,
          showClose: false,
          onClose: onMinimize,
          child: child,
        ),
      ],
    );
  }
}
