import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Decodes only the **first frame** of a (possibly animated) webp — used in
/// picker grids so many animated stickers don't all loop at once.
class FlareStaticAssetImage extends StatefulWidget {
  const FlareStaticAssetImage({
    super.key,
    required this.assetPath,
    this.package,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.decodeSize = 112,
    this.error,
  });

  /// Asset path (e.g. `assets/emoji-sticker/emoji/red_heart.webp`).
  final String assetPath;

  /// Owning package for a package asset (e.g. `flare_im_ui`).
  final String? package;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Decode edge length (caps memory/CPU).
  final int decodeSize;
  final Widget? error;

  static final Map<String, MemoryImage> _cache = <String, MemoryImage>{};

  @override
  State<FlareStaticAssetImage> createState() => _FlareStaticAssetImageState();
}

class _FlareStaticAssetImageState extends State<FlareStaticAssetImage> {
  MemoryImage? _provider;
  bool _failed = false;
  int _request = 0;

  String get _bundleKey => widget.package == null
      ? widget.assetPath
      : 'packages/${widget.package}/${widget.assetPath}';

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant FlareStaticAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.package != widget.package ||
        oldWidget.decodeSize != widget.decodeSize) {
      _failed = false;
      _provider = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final request = ++_request;
    final bundleKey = _bundleKey;
    final edge = widget.decodeSize.clamp(1, 256);
    final key = '$bundleKey@$edge';
    final cached = FlareStaticAssetImage._cache[key];
    if (cached != null) {
      if (mounted) setState(() => _provider = cached);
      return;
    }
    try {
      final data = await rootBundle.load(bundleKey);
      if (data.lengthInBytes > 8 * 1024 * 1024) {
        throw StateError('Sticker exceeds the encoded image budget');
      }
      ui.Codec? codec;
      ui.Image? img;
      ByteData? bytes;
      try {
        codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          targetWidth: edge,
          targetHeight: edge,
        );
        img = (await codec.getNextFrame()).image;
        bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        img?.dispose();
        codec?.dispose();
      }
      if (bytes == null) {
        if (mounted && request == _request) setState(() => _failed = true);
        return;
      }
      final mem = MemoryImage(bytes.buffer.asUint8List());
      FlareStaticAssetImage._cache[key] = mem;
      if (FlareStaticAssetImage._cache.length > 180) {
        FlareStaticAssetImage._cache.remove(
          FlareStaticAssetImage._cache.keys.first,
        );
      }
      if (mounted && request == _request) setState(() => _provider = mem);
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.error ??
          Icon(
            Icons.broken_image_outlined,
            size: 22,
            color: Theme.of(context).colorScheme.outline,
          );
    }
    final provider = _provider;
    if (provider == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Image(
      image: provider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}
