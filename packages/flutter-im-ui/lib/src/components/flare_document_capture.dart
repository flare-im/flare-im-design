import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/capability_ui.dart';
import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'call_stage.dart' show CallFocusRing, callStagePalette;
import 'flare_button.dart';
import 'flare_icon.dart';
import 'flare_modal.dart';
import 'flare_overlay.dart' show flareOverlayScopes;
import 'flare_status_banner.dart';

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

  /// The cancel key and Esc (neither while a photo is processed); null: no
  /// cancel key.
  final VoidCallback? onCancel;

  /// Presents what [builder] returns, named with the side (§6.4): full screen
  /// on a phone; a centred dialog [FlareSizes.componentCapturePreviewWidth]
  /// wide in a PC window (≥ [FlareSizes.appShellCompactMinWidth]).
  static Future<T?> show<T>(
    BuildContext context, {
    required FlareDocumentSide side,
    required WidgetBuilder builder,
  }) {
    final label = flareDocumentSideLabel(FlareStrings.of(context), side);
    if (_isPc(context)) {
      // The capture draws its own dark surface: no header, no card.
      return FlareModal.show<T>(
        context,
        builder: (inner) => FlareModal(
          title: label,
          titleHidden: true,
          showClose: false,
          edgeToEdge: true,
          scrollable: false,
          width: FlareSizes.componentCapturePreviewWidth,
          child: builder(inner),
        ),
      );
    }
    final scopes = flareOverlayScopes(context);
    return Navigator.of(context, rootNavigator: true).push<T>(
      MaterialPageRoute<T>(
        fullscreenDialog: true,
        builder: (inner) => scopes(
          Semantics(
            key: const ValueKey('flare-doc-fullscreen'),
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: label,
            child: Material(
              type: MaterialType.transparency,
              child: Builder(builder: builder),
            ),
          ),
        ),
      ),
    );
  }

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

/// A PC window (≥ breakpoints.md): a dialog, and "Choose file" for the album.
bool _isPc(BuildContext context) =>
    (MediaQuery.maybeSizeOf(context)?.width ?? 0) >=
    FlareSizes.appShellCompactMinWidth;

enum _Phase { viewfinder, processing, review, error }

class _FlareDocumentCaptureState extends State<FlareDocumentCapture> {
  _Phase _phase = _Phase.viewfinder;
  int _generation = 0;
  FlareCapturedDocument? _file;
  FlareDocumentProcessError? _error;
  final FocusNode _focus = FocusNode(debugLabel: 'flare-doc-capture');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _use() {
    final file = _file;
    _reset();
    if (file != null) widget.onDone?.call(file);
  }

  void _cancel() {
    if (_phase != _Phase.processing) widget.onCancel?.call();
  }

  bool get _camera => widget.capture != null && !widget.cameraUnavailable;

  /// §6.4 keys: Esc cancels; Space shoots and Enter uses the photo unless a
  /// control inside has focus (then the key is that control's).
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && widget.onCancel != null) {
      _cancel();
      return KeyEventResult.handled;
    }
    if (!node.hasPrimaryFocus) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.space &&
        _camera &&
        (_phase == _Phase.viewfinder || _phase == _Phase.error)) {
      _take(widget.capture);
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        _phase == _Phase.review) {
      _use();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(FlareDocumentCapture old) {
    super.didUpdateWidget(old);
    if (old.side != widget.side) _reset();
  }

  void _reset() => setState(() {
    _generation++;
    _phase = _Phase.viewfinder;
    _file = null;
    _error = null;
  });

  Future<void> _take(FlareDocumentPhotoSource? source) async {
    if (source == null || _phase == _Phase.processing) return;
    final generation = ++_generation;
    setState(() => _phase = _Phase.processing);
    try {
      final photo = await source();
      if (!mounted || generation != _generation) return;
      if (photo == null) {
        _reset();
        return;
      }
      final file = await flareProcessDocumentPhoto(
        photo,
        widget.side,
        maxBytes: widget.maxBytes,
        accept: widget.accept,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _file = file;
        _phase = _Phase.review;
      });
    } on FlareDocumentProcessException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e.error;
        _phase = _Phase.error;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = FlareDocumentProcessError.failed;
        _phase = _Phase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) => FlareTheme(
    // The stage is dark in both themes: the kit keys on it take the dark look.
    colors: callStagePalette(context),
    child: Builder(builder: _build),
  );

  Widget _build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final pc = _isPc(context);
    final light = colors.mediaOnStage;
    final busy = _phase == _Phase.processing;
    final file = _phase == _Phase.review ? _file : null;
    final hint = switch (widget.side) {
      FlareDocumentSide.front => strings.documentCaptureHintFront,
      FlareDocumentSide.back => strings.documentCaptureHintBack,
      FlareDocumentSide.holding => strings.documentCaptureHintHolding,
    };
    final caption = TextStyle(color: light, fontSize: FlareSizes.fontSizeMd);
    // In the frame: the spinner while processing, else camera-off.
    final Widget? inside = busy
        ? Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: FlareSizes.iconSizeXl,
                  child: CircularProgressIndicator(
                    strokeWidth: _markWidth,
                    color: light,
                  ),
                ),
                const SizedBox(height: FlareSizes.spacingSm),
                Text(strings.documentCaptureProcessing, style: caption),
              ],
            ),
          )
        : widget.cameraUnavailable
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlareIcon(
                'camera-off',
                size: FlareSizes.iconSizeXl,
                color: light,
              ),
              const SizedBox(height: FlareSizes.spacingSm),
              Text(
                strings.documentCaptureCameraUnavailable,
                textAlign: TextAlign.center,
                style: caption,
              ),
            ],
          )
        : null;
    final Widget stage = ClipRect(
      child: file != null
          ? Image.memory(
              file.bytes,
              key: const ValueKey('flare-doc-review'),
              fit: BoxFit.contain,
              semanticLabel: flareDocumentSideLabel(strings, widget.side),
            )
          : LayoutBuilder(
              builder: (context, box) => Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.preview != null) widget.preview!,
                  // §6.4: the frame is the stage less spacing.2xl each side,
                  // the hint for the side and the glare line under it.
                  Padding(
                    padding: const EdgeInsets.all(FlareSizes.spacing2xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: AspectRatio(
                            key: const ValueKey('flare-doc-frame'),
                            aspectRatio: flareDocumentFrameAspect(widget.side),
                            child: CustomPaint(
                              painter: _FramePainter(
                                holding:
                                    widget.side == FlareDocumentSide.holding,
                                color: light,
                                shade: colors.mediaStageShade,
                                reach: box.biggest,
                              ),
                              child: inside == null
                                  ? null
                                  : Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                          FlareSizes.spacingMd,
                                        ),
                                        child: inside,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        if (!busy) ...[
                          const SizedBox(height: FlareSizes.spacingMd),
                          Text(
                            hint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: light,
                              fontSize: FlareSizes.fontSizeXl,
                            ),
                          ),
                          const SizedBox(height: FlareSizes.spacingXs),
                          Text(
                            strings.documentCaptureHintGlare,
                            textAlign: TextAlign.center,
                            style: caption.copyWith(
                              color: light.withValues(
                                alpha: light.a * FlareOpacity.muted,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
    final Widget bar = file != null
        // §6.4 review: retake | use, equal widths.
        ? Row(
            children: [
              Expanded(
                child: FlareButton(
                  key: const ValueKey('flare-doc-retake'),
                  block: true,
                  maintainTouchTarget: true,
                  variant: FlareButtonVariant.secondary,
                  label: strings.documentCaptureRetake,
                  onPressed: _reset,
                ),
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: FlareButton(
                  key: const ValueKey('flare-doc-use'),
                  block: true,
                  maintainTouchTarget: true,
                  label: strings.documentCaptureUse,
                  onPressed: _use,
                ),
              ),
            ],
          )
        // §6.4: album | shutter | cancel; no camera, no shutter.
        : ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FlareSizes.componentCaptureShutterSize,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: widget.pickPhoto == null
                        ? null
                        : FlareButton(
                            key: const ValueKey('flare-doc-album'),
                            variant: FlareButtonVariant.quiet,
                            icon: 'image',
                            maintainTouchTarget: true,
                            label: pc
                                ? strings.pluginFileChoose
                                : strings.documentCaptureFromAlbum,
                            disabled: busy,
                            onPressed: () => _take(widget.pickPhoto),
                          ),
                  ),
                ),
                if (_camera)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FlareSizes.spacingMd,
                    ),
                    child: _shutter(light, strings.documentCaptureShoot, busy),
                  ),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: widget.onCancel == null
                        ? null
                        : FlareButton(
                            key: const ValueKey('flare-doc-cancel'),
                            variant: FlareButtonVariant.quiet,
                            maintainTouchTarget: true,
                            label: strings.cancel,
                            disabled: busy,
                            onPressed: _cancel,
                          ),
                  ),
                ),
              ],
            ),
          );
    return PopScope(
      canPop: !busy,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: ColoredBox(
          color: colors.mediaStage,
          child: SafeArea(
            child: Column(
              mainAxisSize: pc ? MainAxisSize.min : MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // §6.4: errors in a danger banner above the stage.
                if (_phase == _Phase.error)
                  Padding(
                    padding: const EdgeInsets.all(FlareSizes.spacingLg),
                    child: Semantics(
                      liveRegion: true,
                      child: FlareStatusBanner(
                        key: const ValueKey('flare-doc-error'),
                        tone: FlareStatusTone.danger,
                        text: switch (_error) {
                          FlareDocumentProcessError.tooLarge =>
                            strings.documentCaptureTooLarge,
                          FlareDocumentProcessError.notAccepted =>
                            strings.documentCaptureNotAccepted,
                          _ => strings.documentCaptureFailed,
                        },
                      ),
                    ),
                  ),
                // §6.4: the PC dialog's camera picture is 16:10.
                if (pc)
                  Flexible(
                    child: AspectRatio(
                      aspectRatio: FlareSizes.componentCapturePreviewRatio,
                      child: stage,
                    ),
                  )
                else
                  Expanded(child: stage),
                Padding(
                  padding: const EdgeInsets.all(FlareSizes.spacingLg),
                  child: bar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// §6.4: a white disc in a white ring 4 wide,
  /// [FlareSizes.componentCaptureShutterSize] across, read "Take photo".
  Widget _shutter(Color light, String label, bool busy) {
    final onTap = busy ? null : () => _take(widget.capture);
    return Semantics(
      key: const ValueKey('flare-doc-shoot'),
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: CallFocusRing(
        diameter: FlareSizes.componentCaptureShutterSize,
        child: Opacity(
          opacity: busy ? FlareOpacity.disabled : 1,
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Container(
                width: FlareSizes.componentCaptureShutterSize,
                height: FlareSizes.componentCaptureShutterSize,
                // The ring, a gap as wide, then the disc.
                padding: const EdgeInsets.all(FlareSizes.spacingXs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: light, width: FlareSizes.spacingXs),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: light,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The corner marks' stroke (§6.4).
const double _markWidth = FlareSizes.componentCaptureFrameStroke;

/// The viewfinder guide: the stage shaded outside the frame; 3-wide corner
/// marks spacing.2xl long; holding adds a face oval (half the width) above an
/// ID-1 card frame (60%, lower end).
class _FramePainter extends CustomPainter {
  const _FramePainter({
    required this.holding,
    required this.color,
    required this.shade,
    required this.reach,
  });
  final bool holding;
  final Color color;
  final Color shade;

  /// The stage's size: wherever the frame sits in it, a rect this far each
  /// way from the frame's origin covers it (the stage clips the rest).
  final Size reach;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(
          Rect.fromLTRB(-reach.width, -reach.height, reach.width, reach.height),
        )
        ..addRRect(
          RRect.fromRectAndRadius(
            Offset.zero & size,
            const Radius.circular(FlareSizes.radiusMd),
          ),
        ),
      Paint()..color = shade,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _markWidth
      ..strokeCap = StrokeCap.round;
    const mark = FlareSizes.spacing2xl;
    for (final (x, y, dx, dy) in [
      (0.0, 0.0, 1.0, 1.0),
      (w, 0.0, -1.0, 1.0),
      (0.0, h, 1.0, -1.0),
      (w, h, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(Offset(x, y), Offset(x + dx * mark, y), paint)
        ..drawLine(Offset(x, y), Offset(x, y + dy * mark), paint);
    }
    if (!holding) return;
    final guide = Paint()
      ..color = color.withValues(alpha: color.a * FlareOpacity.muted)
      ..style = PaintingStyle.stroke
      ..strokeWidth = FlareSizes.spacing3xs;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .5, h * .3),
        width: w * .5,
        height: h * .34,
      ),
      guide,
    );
    final cardWidth = w * .6;
    final cardHeight = cardWidth / FlareSizes.componentDocumentFrameRatio;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .34, h * .62, cardWidth, cardHeight),
        const Radius.circular(FlareSizes.radiusMd),
      ),
      guide,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.holding != holding ||
      old.color != color ||
      old.shade != shade ||
      old.reach != reach;
}
