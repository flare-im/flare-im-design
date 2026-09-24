import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
