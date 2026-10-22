import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Freezes any [ImageProvider] at frame zero. This is the only renderer used
/// by composer inputs, inline emoji and picker cards; an animated provider can
/// therefore never start playing on an editing surface.
class FlareStaticImage extends StatefulWidget {
  const FlareStaticImage({
    super.key,
    required this.image,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.error,
  });

  final ImageProvider<Object> image;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? error;

  @override
  State<FlareStaticImage> createState() => _FlareStaticImageState();
}

class _FlareStaticImageState extends State<FlareStaticImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant FlareStaticImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _resolve();
  }

  void _resolve() {
    _detach();
    _image?.dispose();
    _image = null;
    _failed = false;
    // Ask providers to decode a bounded preview. The first delivered frame is
    // cloned below and the listener is detached before an animation can tick.
    final previewProvider = ResizeImage.resizeIfNeeded(256, 256, widget.image);
    final stream = previewProvider.resolve(
      createLocalImageConfiguration(context),
    );
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronousCall) {
        final frozen = info.image.clone();
        stream.removeListener(listener);
        if (!mounted) {
          frozen.dispose();
          return;
        }
        setState(() {
          _image?.dispose();
          _image = frozen;
        });
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (mounted) setState(() => _failed = true);
      },
    );
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _detach() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) stream.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detach();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.error ?? const SizedBox.shrink();
    final image = _image;
    if (image == null)
      return SizedBox(width: widget.width, height: widget.height);
    return RawImage(
      image: image,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      filterQuality: FilterQuality.medium,
    );
  }
}
