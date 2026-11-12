import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/capability_ui.dart';
import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';

/// Takes a still from the host's camera, or lets the viewer choose a photo:
/// the original bytes, or null when none was taken.
typedef FlareDocumentPhotoSource = Future<Uint8List?> Function();

/// The document capture a host shows for the engine's captureDocument request
/// (design 7.2 and 7.5; spec Message/DocumentCapture).
///
/// The camera is the host's: it passes its live [preview] and a [capture]
/// that takes a still, so the kit never asks for camera permission. The kit
/// draws the viewfinder frame for the [side], the hint, review with use and
/// retake, and processes the photo: the orientation is baked into the
/// pixels, the metadata dropped and the picture re-encoded as a JPEG that
/// fits [maxBytes] ([flareProcessDocumentPhoto]). [onDone] hands over the
/// file the host answers the engine with (`{file}`).
class FlareDocumentCapture extends StatefulWidget {
  const FlareDocumentCapture({
    super.key,
    required this.side,
    required this.maxBytes,
    this.accept = const [],
    this.preview,
    this.capture,
    this.pickPhoto,
    this.cameraUnavailable = false,
    this.onDone,
    this.onCancel,
  });

  final FlareDocumentSide side;

  /// The input's size limit (`captureDocument.maxBytes`).
  final int maxBytes;

  /// The input's accept list (`captureDocument.accept`).
  final List<String> accept;

  /// The host's live camera preview, drawn under the frame.
  final Widget? preview;
  final FlareDocumentPhotoSource? capture;
  final FlareDocumentPhotoSource? pickPhoto;

  /// The host could not open the camera: the viewfinder says so and offers
  /// the album.
  final bool cameraUnavailable;
  final ValueChanged<FlareCapturedDocument>? onDone;
  final VoidCallback? onCancel;

  /// Presents what [builder] returns on the kit sheet, filling its height,
  /// titled with the side.
  static Future<T?> show<T>(
    BuildContext context, {
    required FlareDocumentSide side,
    required WidgetBuilder builder,
  }) => FlareBottomSheet.show<T>(
    context,
    titleBuilder: (inner) =>
        flareDocumentSideLabel(FlareStrings.of(inner), side),
    fill: true,
    builder: builder,
  );

  @override
  State<FlareDocumentCapture> createState() => _FlareDocumentCaptureState();
}

/// The side's name, as the document input names it.
String flareDocumentSideLabel(FlareStrings strings, FlareDocumentSide side) =>
    switch (side) {
      FlareDocumentSide.front => strings.pluginFormDocumentFront,
      FlareDocumentSide.back => strings.pluginFormDocumentBack,
      FlareDocumentSide.holding => strings.pluginFormDocumentHolding,
    };

enum _Phase { viewfinder, processing, review, error }

class _FlareDocumentCaptureState extends State<FlareDocumentCapture> {
  _Phase _phase = _Phase.viewfinder;
  FlareCapturedDocument? _file;
  FlareDocumentProcessError? _error;

  @override
  void didUpdateWidget(FlareDocumentCapture old) {
    super.didUpdateWidget(old);
    if (old.side != widget.side) _reset();
  }

  void _reset() => setState(() {
    _phase = _Phase.viewfinder;
    _file = null;
    _error = null;
  });

  Future<void> _take(FlareDocumentPhotoSource? source) async {
    if (source == null || _phase == _Phase.processing) return;
    final photo = await source();
    if (photo == null || !mounted) return;
    setState(() => _phase = _Phase.processing);
    try {
      final file = await flareProcessDocumentPhoto(
        photo,
        widget.side,
        maxBytes: widget.maxBytes,
        accept: widget.accept,
      );
      if (!mounted) return;
      setState(() {
        _file = file;
        _phase = _Phase.review;
      });
    } on FlareDocumentProcessException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.error;
        _phase = _Phase.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = FlareDocumentProcessError.failed;
        _phase = _Phase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final aspect = flareDocumentFrameAspect(widget.side);
    final hint = switch (widget.side) {
      FlareDocumentSide.front => strings.documentCaptureHintFront,
      FlareDocumentSide.back => strings.documentCaptureHintBack,
      FlareDocumentSide.holding => strings.documentCaptureHintHolding,
    };
    final message = switch (_phase) {
      _Phase.processing => (strings.documentCaptureProcessing, false),
      _Phase.error => (
        switch (_error) {
          FlareDocumentProcessError.tooLarge => strings.documentCaptureTooLarge,
          FlareDocumentProcessError.notAccepted =>
            strings.documentCaptureNotAccepted,
          _ => strings.documentCaptureFailed,
        },
        true,
      ),
      _Phase.viewfinder => (hint, false),
      _Phase.review => (null, false),
    };
    final camera = widget.capture != null && !widget.cameraUnavailable;
    final busy = _phase == _Phase.processing;
    // A camera stage stays dark in both themes.
    const stage = Color(0xF0000000);
    const light = Color(0xEBFFFFFF);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        FlareSizes.spacingSm,
        FlareSizes.spacingLg,
        FlareSizes.spacingLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
              child: ColoredBox(
                color: stage,
                child: _phase == _Phase.review && _file != null
                    ? Image.memory(
                        _file!.bytes,
                        key: const ValueKey('flare-doc-review'),
                        fit: BoxFit.contain,
                        semanticLabel: flareDocumentSideLabel(
                          strings,
                          widget.side,
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          if (widget.preview != null) widget.preview!,
                          Padding(
                            padding: const EdgeInsets.all(FlareSizes.spacingLg),
                            child: Center(
                              child: AspectRatio(
                                key: const ValueKey('flare-doc-frame'),
                                aspectRatio: aspect,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: light, width: 2),
                                    borderRadius: BorderRadius.circular(
                                      FlareSizes.radiusMd,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (widget.cameraUnavailable)
                            Positioned(
                              left: FlareSizes.spacingLg,
                              right: FlareSizes.spacingLg,
                              bottom: FlareSizes.spacingLg,
                              child: Text(
                                strings.documentCaptureCameraUnavailable,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: light,
                                  fontSize: FlareSizes.fontSizeMd,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          if (message.$1 != null) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            Semantics(
              liveRegion: true,
              child: Text(
                message.$1!,
                key: message.$2 ? const ValueKey('flare-doc-error') : null,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: message.$2 ? colors.errorText : colors.textSecondary,
                  fontSize: FlareSizes.fontSizeMd,
                ),
              ),
            ),
          ],
          const SizedBox(height: FlareSizes.spacingMd),
          if (_phase == _Phase.review) ...[
            FlareButton(
              key: const ValueKey('flare-doc-use'),
              block: true,
              size: FlareControlSize.lg,
              label: strings.documentCaptureUse,
              onPressed: () {
                final file = _file;
                _reset();
                if (file != null) widget.onDone?.call(file);
              },
            ),
            const SizedBox(height: FlareSizes.spacingSm),
            FlareButton(
              key: const ValueKey('flare-doc-retake'),
              block: true,
              size: FlareControlSize.lg,
              variant: FlareButtonVariant.secondary,
              label: strings.documentCaptureRetake,
              onPressed: _reset,
            ),
          ] else ...[
            if (camera) ...[
              FlareButton(
                key: const ValueKey('flare-doc-shoot'),
                block: true,
                size: FlareControlSize.lg,
                label: strings.documentCaptureShoot,
                loading: busy,
                onPressed: busy ? null : () => _take(widget.capture),
              ),
              const SizedBox(height: FlareSizes.spacingSm),
            ],
            if (widget.pickPhoto != null)
              FlareButton(
                key: const ValueKey('flare-doc-album'),
                block: true,
                size: FlareControlSize.lg,
                variant: camera
                    ? FlareButtonVariant.secondary
                    : FlareButtonVariant.primary,
                label: strings.documentCaptureFromAlbum,
                disabled: busy,
                onPressed: () => _take(widget.pickPhoto),
              ),
          ],
        ],
      ),
    );
  }
}
