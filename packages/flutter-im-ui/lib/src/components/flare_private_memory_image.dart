import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';

/// Bounded, uncached rendering for private bytes owned by the host.
///
/// The kit never reads a URL, writes a file or enters Flutter's global image
/// cache. A decoded frame belongs only to this widget and is disposed when the
/// bytes change or the widget leaves the tree. Hosts still own authorization,
/// lease expiry and disposal of the source bytes.
class FlarePrivateMemoryImage extends StatefulWidget {
  const FlarePrivateMemoryImage({
    super.key,
    required this.bytes,
    this.maxPixelSize = 1024,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.errorBuilder,
  }) : assert(maxPixelSize > 0);

  final Uint8List bytes;
  final int maxPixelSize;
  final BoxFit fit;
  final String? semanticLabel;
  final WidgetBuilder? errorBuilder;

  @override
  State<FlarePrivateMemoryImage> createState() =>
      _FlarePrivateMemoryImageState();
}

class _FlarePrivateMemoryImageState extends State<FlarePrivateMemoryImage> {
  ui.Image? _image;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_decode());
  }

  @override
  void didUpdateWidget(FlarePrivateMemoryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes) ||
        oldWidget.maxPixelSize != widget.maxPixelSize) {
      unawaited(_decode());
    }
  }

  Future<void> _decode() async {
    final generation = ++_generation;
    final bytes = widget.bytes;
    final maxPixelSize = widget.maxPixelSize;
    _image?.dispose();
    _image = null;
    _failed = false;
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final ratio = math.min(
        1.0,
        maxPixelSize / math.max(descriptor.width, descriptor.height),
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * ratio).round()),
        targetHeight: math.max(1, (descriptor.height * ratio).round()),
      );
      final frame = await codec.getNextFrame();
      if (!mounted || generation != _generation) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _failed = true);
      }
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  @override
  void dispose() {
    _generation++;
    _image?.dispose();
    _image = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.errorBuilder?.call(context) ??
          Center(
            child: FlareIcon(
              'image',
              size: FlareSizes.iconSizeXl,
              color: FlareColors.of(context).textTertiary,
            ),
          );
    }
    if (_image == null) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          semanticsLabel: FlareStrings.of(context).loading,
        ),
      );
    }
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: RawImage(image: _image, fit: widget.fit),
    );
  }
}
