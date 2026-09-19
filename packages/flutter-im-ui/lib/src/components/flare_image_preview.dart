import 'package:flutter/material.dart';

import '../models/message_content.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon_button.dart';

/// Full-screen image viewer — zoom/pan, download with progress. Spec:
/// Media/ImagePreviewModal (`FlareImagePreview`). Renders nothing when [show]
/// is false, so it can sit in a `Stack`; or use [present] for a route.
///
/// Pinch zooms between [zoomMin] and [zoomMax]; a tap or, at normal size, a
/// swipe down closes it, and so does the platform back gesture when it is a
/// route. The download key appears only with [onDownload].
///
/// In a gallery ([presentGallery]) the preview shows where it is
/// ([galleryIndex] of [galleryCount]) and pages with [onPrevious] and [onNext]:
/// their keys at the sides, or a sideways swipe at normal size. A key with no
/// callback (the first or the last image) is disabled.
class FlareImagePreview extends StatefulWidget {
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
    this.imageBuilder,
    this.galleryIndex,
    this.galleryCount,
    this.onPrevious,
    this.onNext,
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

  /// Optional host image loader for local files, authenticated media, or a
  /// product cache. The kit continues to own viewer chrome and gestures.
  final Widget Function(BuildContext context, String imageSrc)? imageBuilder;

  /// This image's place in a gallery (0-based) and the gallery's size; the
  /// paging chrome shows only when both are given and there is more than one.
  final int? galleryIndex;
  final int? galleryCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// Present as a full-screen dialog route.
  static Future<void> present(
    BuildContext context, {
    required String imageSrc,
    String? alt,
    VoidCallback? onDownload,
    Widget Function(BuildContext context, String imageSrc)? imageBuilder,
  }) {
    return showGeneralDialog(
      context: context,
      // The viewer paints its own black, which fades while the image is
      // pulled down to close, showing the screen underneath.
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, __) => FlareImagePreview(
        show: true,
        imageSrc: imageSrc,
        alt: alt,
        onClose: () => Navigator.of(ctx).maybePop(),
        onDownload: onDownload,
        imageBuilder: imageBuilder,
      ),
    );
  }

  /// Present [images] as a gallery — one at a time, starting at [initialIndex],
  /// paging to the neighbours with the side keys or a sideways swipe — in a
  /// full-screen dialog route. [onDownload], when given, is told the index of
  /// the image on screen.
  static Future<void> presentGallery(
    BuildContext context, {
    required List<FlareImageContent> images,
    int initialIndex = 0,
    ValueChanged<int>? onDownload,
  }) {
    return showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, __) => _FlareImageGallery(
        images: images,
        initialIndex: initialIndex,
        onClose: () => Navigator.of(ctx).maybePop(),
        onDownload: onDownload,
      ),
    );
  }

  @override
  State<FlareImagePreview> createState() => _FlareImagePreviewState();
}

class _FlareImagePreviewState extends State<FlareImagePreview> {
  final _transform = TransformationController();

  /// How far a one-finger swipe at normal size has pulled the image down, and
  /// how far it has moved sideways (a sideways swipe pages a gallery).
  double _drag = 0;
  double _sideways = 0;
  bool _dragging = false;

  bool get _pages => (widget.galleryCount ?? 0) > 1;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  bool get _atNormalSize => _transform.value.getMaxScaleOnAxis() <= 1.01;

  void _onStart(ScaleStartDetails details) {
    _dragging = details.pointerCount == 1 && _atNormalSize;
    _sideways = 0;
  }

  void _onUpdate(ScaleUpdateDetails details) {
    if (!_dragging || details.pointerCount != 1) return;
    _sideways += details.focalPointDelta.dx;
    final next = (_drag + details.focalPointDelta.dy).clamp(
      0.0,
      double.infinity,
    );
    if (next != _drag) setState(() => _drag = next);
  }

  void _onEnd(ScaleEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    final velocity = details.velocity.pixelsPerSecond;
    if (_pages &&
        _drag < FlareSizes.touchTarget &&
        (_sideways.abs() > FlareSizes.touchTarget * 1.5 ||
            velocity.dx.abs() > 700) &&
        (_sideways.abs() > _drag || velocity.dx.abs() > velocity.dy.abs())) {
      // Sideways, not down: a swipe to the left shows the next image.
      final page = (_sideways < 0 || velocity.dx < -700)
          ? widget.onNext
          : widget.onPrevious;
      if (_drag != 0) setState(() => _drag = 0);
      page?.call();
      return;
    }
    final height = MediaQuery.sizeOf(context).height;
    final flung = details.velocity.pixelsPerSecond.dy > 700;
    final close = widget.onClose;
    if (close != null && (_drag > height * 0.12 || (flung && _drag > 0))) {
      // The image leaves from where it was let go.
      close();
      return;
    }
    // Not far enough: it settles back.
    if (_drag != 0) setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();
    final strings = FlareStrings.of(context);
    final height = MediaQuery.sizeOf(context).height;
    // The backdrop fades as the image is pulled down.
    final fade = height <= 0 ? 0.0 : (_drag / height).clamp(0.0, 0.6);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Material(
      color: Colors.black.withValues(alpha: 1 - fade),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: AnimatedContainer(
                duration: _dragging || reduceMotion
                    ? Duration.zero
                    : FlareMotion.fast,
                curve: FlareMotion.fastCurve,
                transform: Matrix4.translationValues(0, _drag, 0),
                child: Center(
                  child: widget.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : InteractiveViewer(
                          transformationController: _transform,
                          minScale: widget.zoomMin,
                          maxScale: widget.zoomMax,
                          onInteractionStart: _onStart,
                          onInteractionUpdate: _onUpdate,
                          onInteractionEnd: _onEnd,
                          child:
                              widget.imageBuilder?.call(
                                context,
                                widget.imageSrc,
                              ) ??
                              Image.network(
                                widget.imageSrc,
                                fit: BoxFit.contain,
                                // A picture that cannot load says so, instead
                                // of leaving a dark screen with a glyph.
                                errorBuilder: (_, __, ___) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.white54,
                                      size: 64,
                                      semanticLabel: widget.alt,
                                    ),
                                    const SizedBox(
                                      height: FlareSizes.spacingSm,
                                    ),
                                    Text(
                                      strings.imageLoadFailed,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: FlareSizes.fontSizeLg,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + FlareSizes.spacingSm,
            left: FlareSizes.spacingSm,
            child: _circleButton('close', strings.closePreview, widget.onClose),
          ),
          if (_pages) ...[
            Positioned(
              top: MediaQuery.of(context).padding.top + FlareSizes.spacingMd,
              left: 0,
              right: 0,
              child: Center(
                child: Semantics(
                  label: strings.imagePreviewPosition(
                    widget.galleryIndex! + 1,
                    widget.galleryCount!,
                  ),
                  excludeSemantics: true,
                  child: Text(
                    '${widget.galleryIndex! + 1} / ${widget.galleryCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: FlareSizes.fontSizeLg,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: FlareSizes.spacingSm,
              top: 0,
              bottom: 0,
              child: Center(
                child: _circleButton(
                  'chevron-left',
                  strings.imagePreviewPrevious,
                  widget.onPrevious,
                ),
              ),
            ),
            Positioned(
              right: FlareSizes.spacingSm,
              top: 0,
              bottom: 0,
              child: Center(
                child: _circleButton(
                  'chevron-right',
                  strings.imagePreviewNext,
                  widget.onNext,
                ),
              ),
            ),
          ],
          if (widget.onDownload != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + FlareSizes.spacingSm,
              right: FlareSizes.spacingSm,
              child: widget.downloading
                  ? _progress(widget.progressPct)
                  : _circleButton(
                      'download',
                      strings.download,
                      widget.onDownload,
                    ),
            ),
        ],
      ),
    );
  }

  /// The same labelled control as the video player's close: a full touch
  /// target on the dark viewer.
  Widget _circleButton(String icon, String label, VoidCallback? onTap) {
    return FlareIconButton(
      icon: icon,
      semanticLabel: label,
      onPressed: onTap,
      tintColor: Colors.white,
      backgroundColor: Colors.white24,
      customSize: FlareSizes.touchTarget,
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
          Text(
            '$pct',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// A conversation's image gallery: the kit preview of one of [images] at a
/// time, starting at [initialIndex], paging to its neighbours with the side
/// keys or a sideways swipe, and saying where it is. Each image opens fresh at
/// normal size. The download key appears only with [onDownload], which is told
/// the index of the image on screen.
class _FlareImageGallery extends StatefulWidget {
  const _FlareImageGallery({
    required this.images,
    this.initialIndex = 0,
    this.onClose,
    this.onDownload,
  });

  final List<FlareImageContent> images;
  final int initialIndex;
  final VoidCallback? onClose;
  final ValueChanged<int>? onDownload;

  @override
  State<_FlareImageGallery> createState() => _FlareImageGalleryState();
}

class _FlareImageGalleryState extends State<_FlareImageGallery> {
  late int _index = widget.initialIndex.clamp(0, widget.images.length - 1);

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    final image = widget.images[_index];
    final source = image.url.trim().isNotEmpty
        ? image.url
        : (image.thumbnailUrl ?? '');
    final download = widget.onDownload;
    return FlareImagePreview(
      // A new image starts at normal size.
      key: ValueKey(_index),
      show: true,
      imageSrc: source,
      alt: image.alt,
      galleryIndex: _index,
      galleryCount: widget.images.length,
      onClose: widget.onClose,
      onDownload: download == null ? null : () => download(_index),
      onPrevious: _index > 0 ? () => setState(() => _index -= 1) : null,
      onNext: _index < widget.images.length - 1
          ? () => setState(() => _index += 1)
          : null,
    );
  }
}
