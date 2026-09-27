import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/message_content.dart';
import 'flare_media_image.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon_button.dart';

/// Full-screen image viewer — zoom/pan, download with progress. Spec:
/// Media/ImagePreviewModal (`FlareImagePreview`). Renders nothing when [show]
/// is false, so it can sit in a `Stack`; or use [present] for a route.
///
/// Pinch zooms between [zoomMin] and [zoomMax]; a tap or, at normal size, a
/// swipe down closes it, and so does the platform back gesture when it is a
/// route. The key at the top right is a download ([onDownload]) until the
/// picture is [saved], then a folder that shows it in its folder ([onReveal]);
/// while [downloading] it shows [progressPct] instead. A key with nothing to
/// call is not drawn.
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
    this.saved = false,
    this.zoomMin = 1.0,
    this.zoomMax = 4.0,
    this.onClose,
    this.onDownload,
    this.onReveal,
    this.imageBuilder,
    this.galleryIndex,
    this.galleryCount,
    this.onPrevious,
    this.onNext,
    this.allowLocalFile = false,
  });

  final bool show;
  final String imageSrc;

  /// [imageSrc] may be a file on this device: the copy the host resolved
  /// through the SDK cache (`FlareImageContent.localPath`).
  final bool allowLocalFile;
  final bool loading;
  final String? alt;
  final bool downloading;
  final int progressPct;

  /// The picture is saved on this device: the key shows it in its folder.
  final bool saved;
  final double zoomMin;
  final double zoomMax;
  final VoidCallback? onClose;
  final VoidCallback? onDownload;

  /// Shows the saved picture in its folder (the key while [saved]).
  final VoidCallback? onReveal;

  /// Optional host image loader for local files, authenticated media, or a
  /// product cache. The kit continues to own viewer chrome and gestures.
  final Widget Function(BuildContext context, String imageSrc)? imageBuilder;

  /// This image's place in a gallery (0-based) and the gallery's size; the
  /// paging chrome shows only when both are given and there is more than one.
  final int? galleryIndex;
  final int? galleryCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// Present as a full-screen dialog route. With [downloadState] the key
  /// follows the picture's download while the preview is open: pressing
  /// download turns it into progress and then the folder without closing.
  static Future<void> present(
    BuildContext context, {
    required String imageSrc,
    String? alt,
    VoidCallback? onDownload,
    VoidCallback? onReveal,
    ValueListenable<FlareMediaDownloadState?>? downloadState,
    Widget Function(BuildContext context, String imageSrc)? imageBuilder,
    bool allowLocalFile = false,
  }) {
    Widget preview(BuildContext ctx, FlareMediaDownloadState? state) =>
        FlareImagePreview(
          show: true,
          imageSrc: imageSrc,
          allowLocalFile: allowLocalFile,
          alt: alt,
          downloading: state?.isDownloading ?? false,
          progressPct: state?.progressPct ?? 0,
          saved: state?.isSaved ?? false,
          onClose: () => Navigator.of(ctx).maybePop(),
          onDownload: onDownload,
          onReveal: onReveal,
          imageBuilder: imageBuilder,
        );
    return showGeneralDialog(
      context: context,
      // The viewer paints its own black, which fades while the image is
      // pulled down to close, showing the screen underneath.
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, __) => downloadState == null
          ? preview(ctx, null)
          : ValueListenableBuilder<FlareMediaDownloadState?>(
              valueListenable: downloadState,
              builder: (ctx, state, _) => preview(ctx, state),
            ),
    );
  }

  /// Present [images] as a gallery — one at a time, starting at [initialIndex],
  /// paging to the neighbours with the side keys or a sideways swipe — in a
  /// full-screen dialog route. [onDownload] and [onReveal], when given, are
  /// told the index of the image on screen; [downloadStateAt] gives that
  /// image's live download state, which its key follows.
  static Future<void> presentGallery(
    BuildContext context, {
    required List<FlareImageContent> images,
    int initialIndex = 0,
    ValueChanged<int>? onDownload,
    ValueChanged<int>? onReveal,
    ValueListenable<FlareMediaDownloadState?>? Function(int index)?
    downloadStateAt,
  }) {
    return showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, _, __) => _FlareImageGallery(
        images: images,
        initialIndex: initialIndex,
        onClose: () => Navigator.of(ctx).maybePop(),
        onDownload: onDownload,
        onReveal: onReveal,
        downloadStateAt: downloadStateAt,
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
                              Image(
                                image:
                                    flareMediaImageProvider(
                                      widget.imageSrc,
                                      allowLocalFile: widget.allowLocalFile,
                                    ) ??
                                    NetworkImage(widget.imageSrc),
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
          if (_mediaKey(strings) case final key?)
            Positioned(
              top: MediaQuery.of(context).padding.top + FlareSizes.spacingSm,
              right: FlareSizes.spacingSm,
              child: key,
            ),
        ],
      ),
    );
  }

  /// The key at the top right: progress while downloading, the folder once
  /// saved, else the download — or nothing when there is nothing to call.
  Widget? _mediaKey(FlareStrings strings) {
    final download = widget.onDownload;
    final reveal = widget.onReveal;
    if (widget.downloading) {
      return download == null && reveal == null
          ? null
          : _progress(widget.progressPct.clamp(0, 100));
    }
    if (widget.saved) {
      return reveal == null
          ? null
          : _circleButton('folder', strings.showInFolder, reveal);
    }
    return download == null
        ? null
        : _circleButton('download', strings.download, download);
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

  /// Progress in the key's place: not a control, but named for a screen
  /// reader.
  Widget _progress(int pct) {
    final strings = FlareStrings.of(context);
    return Semantics(
      label: '${strings.downloading} $pct%',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: FlareSizes.touchTarget,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                value: pct > 0 ? pct / 100 : null,
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            Text(
              '$pct',
              style: const TextStyle(
                color: Colors.white,
                fontSize: FlareSizes.fontSize2xs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A conversation's image gallery: the kit preview of one of [images] at a
/// time, starting at [initialIndex], paging to its neighbours with the side
/// keys or a sideways swipe, and saying where it is. Each image opens fresh at
/// normal size. The download key appears only with [onDownload] and the folder
/// key only with [onReveal], each told the index of the image on screen; the
/// key follows that image's live state from [downloadStateAt].
class _FlareImageGallery extends StatefulWidget {
  const _FlareImageGallery({
    required this.images,
    this.initialIndex = 0,
    this.onClose,
    this.onDownload,
    this.onReveal,
    this.downloadStateAt,
  });

  final List<FlareImageContent> images;
  final int initialIndex;
  final VoidCallback? onClose;
  final ValueChanged<int>? onDownload;
  final ValueChanged<int>? onReveal;
  final ValueListenable<FlareMediaDownloadState?>? Function(int index)?
  downloadStateAt;

  @override
  State<_FlareImageGallery> createState() => _FlareImageGalleryState();
}

class _FlareImageGalleryState extends State<_FlareImageGallery> {
  late int _index = widget.initialIndex.clamp(0, widget.images.length - 1);

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    final state = widget.downloadStateAt?.call(_index);
    if (state == null) return _page(null);
    return ValueListenableBuilder<FlareMediaDownloadState?>(
      valueListenable: state,
      builder: (_, value, __) => _page(value),
    );
  }

  Widget _page(FlareMediaDownloadState? state) {
    final index = _index;
    final image = widget.images[index];
    final picture = flarePictureSource(image, preferThumbnail: false);
    final download = widget.onDownload;
    final reveal = widget.onReveal;
    return FlareImagePreview(
      // A new image starts at normal size.
      key: ValueKey(index),
      show: true,
      imageSrc: picture.src,
      allowLocalFile: picture.local,
      alt: image.alt,
      galleryIndex: index,
      galleryCount: widget.images.length,
      downloading: state?.isDownloading ?? false,
      progressPct: state?.progressPct ?? 0,
      saved: state?.isSaved ?? false,
      onClose: widget.onClose,
      onDownload: download == null ? null : () => download(index),
      onReveal: reveal == null ? null : () => reveal(index),
      onPrevious: index > 0 ? () => setState(() => _index -= 1) : null,
      onNext: index < widget.images.length - 1
          ? () => setState(() => _index += 1)
          : null,
    );
  }
}
