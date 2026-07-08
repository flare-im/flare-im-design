import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Full-screen image viewer — zoom/pan, download with progress. Spec:
/// Media/ImagePreviewModal (`FlareImagePreview`). Renders nothing when [show]
/// is false, so it can sit in a `Stack`; or use [present] for a route.
class FlareImagePreview extends StatelessWidget {
  const FlareImagePreview({
    super.key,
    required this.show,
    required this.imageSrc,
    this.loading = false,
    this.alt,
    this.downloading = false,
    this.progressPct = 0,
    this.zoomMin = 1.0,
    this.zoomMax = 4.0,
    this.onClose,
    this.onDownload,
  });

  final bool show;
  final String imageSrc;
  final bool loading;
  final String? alt;
  final bool downloading;
  final int progressPct;
  final double zoomMin;
  final double zoomMax;
  final VoidCallback? onClose;
  final VoidCallback? onDownload;

  /// Present as a full-screen dialog route.
  static Future<void> present(
    BuildContext context, {
    required String imageSrc,
    String? alt,
    VoidCallback? onDownload,
  }) {
    return showGeneralDialog(
      context: context,
      barrierColor: Colors.black,
      pageBuilder: (ctx, _, __) => FlareImagePreview(
        show: true,
        imageSrc: imageSrc,
        alt: alt,
        onClose: () => Navigator.of(ctx).maybePop(),
        onDownload: onDownload,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: Center(
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : InteractiveViewer(
                        minScale: zoomMin,
                        maxScale: zoomMax,
                        child: Image.network(
                          imageSrc,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 64,
                            semanticLabel: alt,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + FlareSizes.spacingSm,
            left: FlareSizes.spacingSm,
            child: _circleButton(Icons.close_rounded, onClose),
          ),
          if (onDownload != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + FlareSizes.spacingSm,
              right: FlareSizes.spacingSm,
              child: downloading
                  ? _progress(progressPct)
                  : _circleButton(Icons.download_rounded, onDownload),
            ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.white24,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _progress(int pct) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct / 100,
            color: Colors.white,
            strokeWidth: 2,
          ),
          Text('$pct',
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}
