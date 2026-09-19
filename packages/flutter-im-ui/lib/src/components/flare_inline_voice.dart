import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';

/// Local capture only. The host owns sending and retains the file on success
/// until the host has copied or uploaded it. No message is sent on keyboard exit.
class FlareInlineVoice extends StatefulWidget {
  const FlareInlineVoice({
    super.key,
    required this.onKeyboard,
    required this.onSend,
    this.disabled = false,
  });
  final VoidCallback onKeyboard;
  final Future<bool> Function(String path, int durationMs) onSend;
  final bool disabled;
  @override
  State<FlareInlineVoice> createState() => _FlareInlineVoiceState();
}

class _FlareInlineVoiceState extends State<FlareInlineVoice>
    with WidgetsBindingObserver {
  final _recorder = AudioRecorder();
  final _pcm = BytesBuilder(copy: false);
  StreamSubscription<Uint8List>? _stream;
  VideoPlayerController? _player;
  Timer? _timer;
  bool _recording = false, _paused = false, _busy = false, _sending = false;
  int _generation = 0, _bytes = 0;
  String? _error, _path;
  int get _duration => (_bytes * 1000 ~/ 32000).clamp(0, 65000);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(FlareInlineVoice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disabled && !oldWidget.disabled) unawaited(_clear());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _recording) unawaited(_pause());
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_stream?.cancel());
    unawaited(_recorder.dispose());
    unawaited(_player?.dispose());
    final path = _path;
    if (path != null && !_sending)
      unawaited(File(path).delete().catchError((_) => File(path)));
    super.dispose();
  }

  Future<void> _start() async {
    if (_busy || widget.disabled) return;
    final strings = FlareStrings.of(context);
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (kIsWeb || !await _recorder.hasPermission())
        throw _VoiceError(strings.inlineVoiceMicrophoneUnavailable);
      if (!mounted || generation != _generation) return;
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      if (!mounted || generation != _generation) {
        await _recorder.stop();
        return;
      }
      _stream = stream.listen(
        (data) {
          final remaining = 2080000 - _bytes;
          if (remaining <= 0) return;
          final chunk = data.length > remaining
              ? data.sublist(0, remaining)
              : data;
          _pcm.add(chunk);
          _bytes += chunk.length;
          if (_bytes >= 2080000 && _recording) unawaited(_pause());
        },
        onError: (Object e) {
          if (mounted) {
            unawaited(_clear());
            setState(() => _error = e.toString());
          }
        },
      );
      setState(() {
        _recording = true;
        _paused = false;
      });
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      if (mounted && generation == _generation)
        setState(() => _error = e.toString());
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _pause() async {
    if (!_recording) return;
    final generation = _generation;
    setState(() {
      _recording = false;
      _busy = true;
    });
    try {
      await _recorder.pause();
      if (!mounted || generation != _generation) return;
      _timer?.cancel();
      final pcm = _pcm.toBytes();
      final header = ByteData(44);
      void ascii(int offset, String text) {
        for (var i = 0; i < text.length; i++) {
          header.setUint8(offset + i, text.codeUnitAt(i));
        }
      }

      ascii(0, 'RIFF');
      header.setUint32(4, pcm.length + 36, Endian.little);
      ascii(8, 'WAVE');
      ascii(12, 'fmt ');
      header.setUint32(16, 16, Endian.little);
      header.setUint16(20, 1, Endian.little);
      header.setUint16(22, 1, Endian.little);
      header.setUint32(24, 16000, Endian.little);
      header.setUint32(28, 32000, Endian.little);
      header.setUint16(32, 2, Endian.little);
      header.setUint16(34, 16, Endian.little);
      ascii(36, 'data');
      header.setUint32(40, pcm.length, Endian.little);
      final directory = await getTemporaryDirectory();
      if (!mounted || generation != _generation) return;
      _path ??=
          '${directory.path}/flare-voice-${DateTime.now().microsecondsSinceEpoch}.wav';
      await _player?.dispose();
      _player = null;
      if (!mounted || generation != _generation) return;
      final file = File(_path!);
      await file.writeAsBytes([
        ...header.buffer.asUint8List(),
        ...pcm,
      ], flush: true);
      if (!mounted || generation != _generation) {
        if (await file.exists()) await file.delete();
        return;
      }
      setState(() => _paused = true);
    } catch (e) {
      if (mounted && generation == _generation)
        setState(() => _error = e.toString());
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _resume() async {
    if (_busy || widget.disabled || _duration >= 65000) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _player?.pause();
      if (!mounted || generation != _generation) return;
      await _recorder.resume();
      if (!mounted || generation != _generation) return;
      setState(() {
        _paused = false;
        _recording = true;
      });
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (mounted) setState(() {});
      });
    } catch (e) {
      if (mounted && generation == _generation)
        setState(() => _error = e.toString());
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _preview() async {
    try {
      if (_path == null) return;
      if (_player == null) {
        _player = VideoPlayerController.file(File(_path!));
        await _player!.initialize();
        _player!.addListener(() {
          if (mounted) setState(() {});
        });
      }
      if (_player!.value.isPlaying) {
        await _player!.pause();
      } else {
        if (_player!.value.position >= _player!.value.duration)
          await _player!.seekTo(Duration.zero);
        await _player!.play();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _clear() async {
    _generation++;
    _timer?.cancel();
    await _stream?.cancel();
    _stream = null;
    try {
      await _recorder.stop();
    } catch (_) {
      /* Capture may still be requesting permission. */
    }
    await _player?.dispose();
    _player = null;
    final path = _path;
    _path = null;
    if (path != null && await File(path).exists()) await File(path).delete();
    _pcm.clear();
    _bytes = 0;
    if (mounted)
      setState(() {
        _recording = false;
        _paused = false;
        _busy = false;
      });
  }

  Future<void> _send() async {
    if (_busy || _path == null || _duration < 250 || widget.disabled) return;
    final strings = FlareStrings.of(context);
    setState(() {
      _busy = true;
      _sending = true;
      _error = null;
    });
    try {
      await _player?.pause();
      if (!await widget.onSend(_path!, _duration))
        throw _VoiceError(strings.inlineVoiceSendFailed);
      // The host owns an accepted source file; do not delete it during asynchronous upload.
      _path = null;
      await _clear();
      if (mounted) widget.onKeyboard();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      _sending = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _button(
    IconData icon,
    String label,
    VoidCallback? action, {
    bool accent = false,
  }) => IconButton(
    tooltip: label,
    onPressed: action,
    iconSize: 20,
    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: accent ? FlareColors.of(context).primary : null,
    ),
    icon: Icon(icon),
  );
  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final seconds = _duration ~/ 1000;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          decoration: BoxDecoration(
            color: colors.bgPrimary,
            border: Border.all(color: colors.borderPrimary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _button(
                flareIconGlyph('keyboard'),
                strings.inlineVoiceKeyboard,
                _sending
                    ? null
                    : () {
                        unawaited(_clear());
                        widget.onKeyboard();
                      },
              ),
              if (!_paused)
                _button(
                  flareIconGlyph(_recording ? 'pause' : 'mic'),
                  _recording
                      ? strings.inlineVoicePause
                      : strings.inlineVoiceStart,
                  _busy || widget.disabled
                      ? null
                      : () => _recording ? _pause() : _start(),
                  accent: true,
                )
              else
                _button(
                  flareIconGlyph(
                    _player?.value.isPlaying == true ? 'pause' : 'play',
                  ),
                  strings.inlineVoicePreview,
                  _busy ? null : _preview,
                ),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: CustomPaint(
                    painter: _VoiceWave(
                      colors: colors,
                      active: _recording || _paused,
                    ),
                  ),
                ),
              ),
              Text(
                '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (_paused) ...[
                _button(
                  flareIconGlyph('mic'),
                  strings.inlineVoiceResume,
                  _busy || _duration >= 65000 ? null : _resume,
                  accent: true,
                ),
                _button(
                  flareIconGlyph('delete'),
                  strings.inlineVoiceDiscard,
                  _busy ? null : _clear,
                ),
                _button(
                  flareIconGlyph('send'),
                  strings.send,
                  _busy || widget.disabled ? null : _send,
                  accent: true,
                ),
              ],
            ],
          ),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: colors.errorText, fontSize: 12),
          ),
      ],
    );
  }
}

/// A failure the bar explains in its own words (the strings table), shown
/// without an exception type in front of it.
class _VoiceError implements Exception {
  const _VoiceError(this.message);
  final String message;

  @override
  String toString() => message;
}

class _VoiceWave extends CustomPainter {
  _VoiceWave({required this.colors, required this.active});
  final FlareColors colors;
  final bool active;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (active
          ? colors.primary.withValues(alpha: .45)
          : colors.borderPrimary)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (double x = 3; x < size.width; x += 6) {
      final h = 4 + (x.toInt() * 17 % 20);
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceWave old) =>
      active != old.active || colors != old.colors;
}
