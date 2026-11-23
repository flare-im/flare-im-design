import 'dart:async';
import 'package:flutter/material.dart';
import '../tokens/flare_strings.dart';
import 'flare_qr_card.dart';

class FlarePluginQr extends StatefulWidget {
  const FlarePluginQr({
    super.key,
    this.token,
    this.ttlMs,
    this.caption,
    this.encodeQr,
  });
  final String? token, caption;
  final int? ttlMs;
  final Future<String> Function(String token)? encodeQr;
  @override
  State<FlarePluginQr> createState() => _FlarePluginQrState();
}

class _FlarePluginQrState extends State<FlarePluginQr> {
  String? _url;
  String _phase = 'loading';
  final _clock = Stopwatch();
  Timer? _expiry;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _clock.start();
    unawaited(_encode());
  }

  @override
  void didUpdateWidget(FlarePluginQr old) {
    super.didUpdateWidget(old);
    if (old.token != widget.token || old.ttlMs != widget.ttlMs) {
      _clock.reset();
      unawaited(_encode());
    } else if (_phase == 'failed' &&
        old.encodeQr == null &&
        widget.encodeQr != null) {
      unawaited(_encode());
    }
  }

  Future<void> _encode() async {
    final current = ++_generation;
    _expiry?.cancel();
    _url = null;
    _phase = 'loading';
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    if (widget.ttlMs != null && widget.ttlMs! <= _clock.elapsedMilliseconds) {
      _phase = 'expired';
      return;
    }
    try {
      final encode = widget.encodeQr;
      if (encode == null) throw StateError('encoderUnavailable');
      final url = await encode(token);
      if (!mounted || current != _generation) return;
      final remaining = widget.ttlMs == null
          ? null
          : widget.ttlMs! - _clock.elapsedMilliseconds;
      if (remaining != null && remaining <= 0) {
        setState(() => _phase = 'expired');
        return;
      }
      setState(() {
        _url = url;
        _phase = 'ready';
      });
      if (remaining != null)
        _expiry = Timer(Duration(milliseconds: remaining), () {
          if (mounted)
            setState(() {
              _url = null;
              _phase = 'expired';
            });
        });
    } catch (_) {
      if (mounted && current == _generation) setState(() => _phase = 'failed');
    }
  }

  @override
  void dispose() {
    _generation++;
    _expiry?.cancel();
    _clock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = FlareStrings.of(context);
    if (widget.token?.isNotEmpty != true) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_url != null)
          FlareQrMatrix(payload: _url, label: widget.caption ?? s.qrCode)
        else if (_phase == 'expired')
          Text(s.scanCodeExpired)
        else if (_phase == 'failed')
          Text(s.qrCardUnavailable)
        else
          Text(s.scanPreparing),
        if (widget.caption != null) Text(widget.caption!),
      ],
    );
  }
}

class FlareScanSurfaceHints {
  const FlareScanSurfaceHints({
    required this.secure,
    required this.maxBrightness,
  });
  final bool secure, maxBrightness;
}
