import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/plugin_view.dart' show FlarePluginDocumentSide;
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';

/// What a [FlareDocumentSlot] shows.
enum FlareDocumentSlotState { empty, captured, uploading, failed }

/// Document slot — one capture tile for an ID photo (spec
/// Account/DocumentSlot; §6.3 of docs/plugin-experience.md): an empty 16:10
/// frame with the side's outline, the camera, the label and "点击拍摄"; a
/// captured photo with a success badge and "重拍"; upload progress; an
/// upload failure that retries on tap. The tile is one button.
class FlareDocumentSlot extends StatelessWidget {
  const FlareDocumentSlot({
    super.key,
    required this.label,
    required this.side,
    this.state = FlareDocumentSlotState.empty,
    this.imageUrl,
    this.image,
    this.progress,
    this.disabled = false,
    this.onCapture,
    this.onRetry,
  });

  final String label;
  final FlarePluginDocumentSide side;
  final FlareDocumentSlotState state;

  /// The captured photo (https or data:image), drawn cover.
  final String? imageUrl;

  /// The captured photo as the host holds it (in memory); wins over
  /// [imageUrl].
  final ImageProvider? image;

  /// Upload progress 0–100 while uploading.
  final double? progress;
  final bool disabled;
  final VoidCallback? onCapture;
  final VoidCallback? onRetry;

  ImageProvider? get _image {
    if (image case final image?) return image;
    final url = imageUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image/')) {
      final data = Uri.tryParse(url)?.data;
      return data == null ? null : MemoryImage(data.contentAsBytes());
    }
    return url.startsWith('https://') ? NetworkImage(url) : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final failed = state == FlareDocumentSlotState.failed;
    final tap = disabled ? null : (failed ? onRetry : onCapture);
    final percent = (progress ?? 0).clamp(0, 100).round();
    final spoken = switch (state) {
      FlareDocumentSlotState.empty => strings.documentSlotTapToCapture,
      FlareDocumentSlotState.captured =>
        '${strings.documentSlotCaptured}，${strings.documentCaptureRetake}',
      FlareDocumentSlotState.uploading =>
        strings.documentSlotUploading.replaceAll('{percent}', '$percent'),
      FlareDocumentSlotState.failed => strings.documentSlotUploadFailed,
    };
    final image = _image;
    final caption = TextStyle(
      fontSize: FlareTextRoles.caption.fontSize,
      color: colors.textSecondary,
    );
    final Widget content = switch (state) {
      FlareDocumentSlotState.empty => Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _OutlinePainter(side, colors.borderPrimary)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlareIcon('camera', size: 24, color: colors.textSecondary),
              const SizedBox(height: FlareSizes.spacingXs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeLg,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              Text(strings.documentSlotTapToCapture, style: caption),
            ],
          ),
        ],
      ),
      FlareDocumentSlotState.failed => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FlareIcon('error', size: 24, color: colors.errorText),
          const SizedBox(height: FlareSizes.spacingXs),
          Text(
            label,
            style: TextStyle(
              fontSize: FlareSizes.fontSizeLg,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          Text(
            strings.documentSlotUploadFailed,
            textAlign: TextAlign.center,
            style: caption.copyWith(color: colors.errorText),
          ),
        ],
      ),
      _ => Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Image(image: image, fit: BoxFit.cover)
          else
            ColoredBox(
              color: colors.bgTertiary,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: FlareSizes.fontSizeLg,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
          if (state == FlareDocumentSlotState.uploading)
            ColoredBox(
              color: colors.mediaStageShade,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 32,
                      child: CircularProgressIndicator(
                        value: progress == null ? null : percent / 100,
                        strokeWidth: 3,
                        color: colors.mediaOnStage,
                      ),
                    ),
                    const SizedBox(height: FlareSizes.spacingXs),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: FlareTextRoles.caption.fontSize,
                        color: colors.mediaOnStage,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            PositionedDirectional(
              top: FlareSizes.spacingSm,
              end: FlareSizes.spacingSm,
              child: FlareIcon('success', size: 20, color: colors.successText),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, colors.mediaStageShade],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(FlareSizes.spacingXs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlareIcon(
                        'refresh',
                        size: FlareSizes.iconSizeSm,
                        color: colors.mediaOnStage,
                      ),
                      const SizedBox(width: FlareSizes.spacing2xs),
                      Text(
                        strings.documentCaptureRetake,
                        style: TextStyle(
                          fontSize: FlareTextRoles.caption.fontSize,
                          color: colors.mediaOnStage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    };
    return Semantics(
      button: true,
      enabled: tap != null,
      label: '$label，$spoken',
      excludeSemantics: true,
      onTap: tap,
      child: Opacity(
        opacity: disabled ? FlareOpacity.disabled : 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : FlareSizes.componentDocumentSlotHeight * 1.6;
            final height = math.max(
              width * 10 / 16,
              FlareSizes.componentDocumentSlotHeight,
            );
            return Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: const ValueKey('flare-document-slot-tap'),
                onTap: tap,
                borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
                child: CustomPaint(
                  foregroundPainter: _BorderPainter(
                    color: failed ? colors.error : colors.borderPrimary,
                    dashed: state == FlareDocumentSlotState.empty,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
                    child: Container(
                      width: width,
                      height: height,
                      color: colors.bgSecondary,
                      child: content,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The slot's 1.5 border: dashed while empty, solid otherwise.
class _BorderPainter extends CustomPainter {
  const _BorderPainter({required this.color, required this.dashed});
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(FlareSizes.radiusCard),
        ).deflate(0.75),
      );
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += 10) {
        canvas.drawPath(metric.extractPath(at, at + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BorderPainter old) =>
      old.color != color || old.dashed != dashed;
}

/// A faint sketch of the side: a portrait box on the right of the front, an
/// emblem on the left of the back, a face over a card for holding.
class _OutlinePainter extends CustomPainter {
  const _OutlinePainter(this.side, this.color);
  final FlarePluginDocumentSide side;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final w = size.width, h = size.height;
    switch (side) {
      case FlarePluginDocumentSide.front:
        canvas.drawRRect(
          RRect.fromLTRBR(
            w * .68,
            h * .2,
            w * .88,
            h * .62,
            const Radius.circular(4),
          ),
          paint,
        );
      case FlarePluginDocumentSide.back:
        canvas.drawCircle(Offset(w * .2, h * .32), h * .14, paint);
      case FlarePluginDocumentSide.holding:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * .3, h * .36),
            width: w * .16,
            height: h * .34,
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(
            w * .5,
            h * .5,
            w * .86,
            h * .82,
            const Radius.circular(4),
          ),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_OutlinePainter old) =>
      old.side != side || old.color != color;
}
