import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/media_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

// FR-078: without a host media handler, a received image opens in the kit
// preview, a video in the kit player and a voice message plays in its bubble,
// one at a time. A host handler takes every media tap instead.

const _strings = FlareStrings();

/// A player that loads instantly (or fails) and never touches a platform.
class _FakePlayer extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  _FakePlayer(this.source, {this.fail = false})
    : super(const VideoPlayerValue(duration: Duration.zero));

  final Uri source;
  final bool fail;
  int plays = 0;
  int pauses = 0;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    if (fail) throw Exception('cannot load $source');
    value = value.copyWith(
      isInitialized: true,
      duration: const Duration(seconds: 7),
      size: const Size(160, 90),
    );
  }

  @override
  Future<void> play() async {
    plays++;
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    pauses++;
    if (!disposed) value = value.copyWith(isPlaying: false);
  }

  /// The platform reports progress.
  void advance(Duration position) => value = value.copyWith(position: position);

  /// The platform reports the end of the media.
  void complete() => value = value.copyWith(
    isPlaying: false,
    isCompleted: true,
    position: value.duration,
  );

  @override
  Future<void> dispose() async {
    disposed = true;
    super.dispose();
  }

  @override
  int get playerId => VideoPlayerController.kUninitializedPlayerId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FlareMessageData _message(String id, FlareMessageContent content) =>
    FlareMessageData(
      id: id,
      senderId: 'bob',
      senderName: 'Bob',
      content: content,
      sentAtMs: DateTime(2024, 5, 1, 10).millisecondsSinceEpoch,
    );

Widget _chat(
  List<FlareMessageData> messages, {
  void Function(FlareMessageData, FlareMessageContent)? onMediaAction,
  FlareMediaController? mediaController,
}) => MaterialApp(
  home: Scaffold(
    body: FlareMessageList(
      messages: messages,
      currentUserId: 'me',
      locale: 'zh-CN',
      onMediaAction: onMediaAction,
      mediaController: mediaController,
    ),
  ),
);

const _voiceA = FlareAudioContent(
  url: 'https://media.example/a.m4a',
  durationSec: 7,
);
const _voiceB = FlareAudioContent(
  url: 'https://media.example/b.m4a',
  durationSec: 12,
);

/// Rows as the reader sees them, top to bottom. The timeline grows upwards
/// from the newest message (a reversed viewport), so element order is not
/// reading order: sort the widgets by where they are drawn.
List<T> _topToBottom<T extends Widget>(WidgetTester tester) {
  final widgets = tester.widgetList<T>(find.byType(T)).toList();
  widgets.sort(
    (a, b) => tester
        .getTopLeft(find.byWidget(a))
        .dy
        .compareTo(tester.getTopLeft(find.byWidget(b)).dy),
  );
  return widgets;
}

List<FlareVoiceMessage> _voices(WidgetTester tester) =>
    _topToBottom<FlareVoiceMessage>(tester);

/// The voice bubble of the message at [index], counting from the oldest.
Finder _voiceAt(WidgetTester tester, int index) =>
    find.byWidget(_voices(tester)[index]);

void main() {
  late List<_FakePlayer> players;
  late Set<String> failing;

  setUp(() {
    players = [];
    failing = {};
    flareMediaPlayerFactory = (source) {
      final player = _FakePlayer(
        source,
        fail: failing.contains(source.toString()),
      );
      players.add(player);
      return player;
    };
  });
  tearDown(() => flareMediaPlayerFactory = VideoPlayerController.networkUrl);

  group('image', () {
    testWidgets('a tap opens the preview on the full-size address; closing '
        'and back both leave it', (tester) async {
      await tester.pumpWidget(
        _chat([
          _message(
            'img',
            const FlareImageContent(
              url: 'https://media.example/full.jpg',
              thumbnailUrl: 'https://media.example/thumb.jpg',
            ),
          ),
        ]),
      );
      await tester.tap(find.byType(FlareImageMessage));
      await tester.pumpAndSettle();
      final preview = tester.widget<FlareImagePreview>(
        find.byType(FlareImagePreview),
      );
      expect(preview.imageSrc, 'https://media.example/full.jpg');
      // No download key unless a host supplies one.
      expect(find.bySemanticsLabel(_strings.download), findsNothing);

      await tester.tap(find.bySemanticsLabel(_strings.closePreview));
      await tester.pumpAndSettle();
      expect(find.byType(FlareImagePreview), findsNothing);

      await tester.tap(find.byType(FlareImageMessage));
      await tester.pumpAndSettle();
      expect(find.byType(FlareImagePreview), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(FlareImagePreview), findsNothing);
    });

    testWidgets('without a full-size address the thumbnail opens', (
      tester,
    ) async {
      await tester.pumpWidget(
        _chat([
          _message(
            'img',
            const FlareImageContent(
              url: '',
              thumbnailUrl: 'https://media.example/thumb.jpg',
            ),
          ),
        ]),
      );
      await tester.tap(find.byType(FlareImageMessage));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FlareImagePreview>(find.byType(FlareImagePreview))
            .imageSrc,
        'https://media.example/thumb.jpg',
      );
    });

    testWidgets('a swipe down at normal size closes the preview', (
      tester,
    ) async {
      var closed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: FlareImagePreview(
            show: true,
            imageSrc: 'https://media.example/full.jpg',
            imageBuilder: (_, _) => const SizedBox.square(dimension: 200),
            onClose: () => closed++,
          ),
        ),
      );
      // A short pull settles back.
      await tester.timedDrag(
        find.byType(InteractiveViewer),
        const Offset(0, 40),
        const Duration(milliseconds: 400),
      );
      await tester.pumpAndSettle();
      expect(closed, 0);
      await tester.fling(
        find.byType(InteractiveViewer),
        const Offset(0, 300),
        1500,
      );
      await tester.pumpAndSettle();
      expect(closed, 1);
    });
  });

  group('video', () {
    testWidgets('a tap opens the player, which plays; pause, play and close '
        'are named', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _chat([
          _message(
            'vid',
            const FlareVideoContent(
              url: 'https://media.example/clip.mp4',
              durationSec: 7,
            ),
          ),
        ]),
      );
      await tester.tap(find.byType(FlareVideoMessage));
      // The route fades in; its controls join the semantics tree once shown.
      await tester.pumpAndSettle();
      expect(find.byType(FlareVideoPlayer), findsOneWidget);
      expect(
        players.single.source.toString(),
        'https://media.example/clip.mp4',
      );
      expect(players.single.plays, 1);

      await tester.tap(find.bySemanticsLabel(_strings.pause));
      await tester.pump();
      expect(players.single.value.isPlaying, isFalse);
      expect(find.bySemanticsLabel(_strings.play), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(_strings.close));
      await tester.pumpAndSettle();
      expect(find.byType(FlareVideoPlayer), findsNothing);
      expect(players.single.disposed, isTrue);

      // The platform back gesture closes it too.
      await tester.tap(find.byType(FlareVideoMessage));
      await tester.pumpAndSettle();
      expect(find.byType(FlareVideoPlayer), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(FlareVideoPlayer), findsNothing);
      expect(players.last.disposed, isTrue);
      handle.dispose();
    });

    testWidgets('an address that fails shows 重试 and 关闭, never a blank '
        'screen', (tester) async {
      failing.add('https://media.example/broken.mp4');
      var closed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: FlareVideoPlayer(
            show: true,
            videoSrc: 'https://media.example/broken.mp4',
            onClose: () => closed++,
          ),
        ),
      );
      await tester.pump();
      expect(find.text(_strings.videoLoadFailed), findsOneWidget);
      await tester.tap(find.text(_strings.retry));
      await tester.pump();
      expect(players, hasLength(2));
      expect(find.text(_strings.videoLoadFailed), findsOneWidget);

      failing.clear();
      await tester.tap(find.text(_strings.retry));
      await tester.pump();
      await tester.pump();
      expect(find.text(_strings.videoLoadFailed), findsNothing);
      expect(players.last.plays, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: FlareVideoPlayer(
            show: true,
            // Not an address the kit plays: it never reaches a player.
            videoSrc: 'file:///private/clip.mp4',
            onClose: () => closed++,
          ),
        ),
      );
      await tester.pump();
      expect(find.text(_strings.videoLoadFailed), findsOneWidget);
      expect(players, hasLength(3));
      await tester.tap(find.text(_strings.close));
      expect(closed, 1);
    });
  });

  group('voice', () {
    testWidgets('a tap plays in the bubble; a second message stops the first', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _chat([_message('a', _voiceA), _message('b', _voiceB)]),
      );
      expect(_voices(tester).map((v) => v.playing), [false, false]);

      await tester.tap(_voiceAt(tester, 0));
      await tester.pump();
      await tester.pump();
      expect(_voices(tester).map((v) => v.playing), [true, false]);
      expect(find.bySemanticsLabel(_strings.pause), findsOneWidget);

      // Elapsed time shows while playing.
      players.single.advance(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text('0:03 / 0:07'), findsOneWidget);

      await tester.tap(_voiceAt(tester, 1));
      await tester.pump();
      await tester.pump();
      expect(players, hasLength(2));
      expect(players.first.disposed, isTrue);
      expect(_voices(tester).map((v) => v.playing), [false, true]);

      // Tapping the playing one pauses it; tapping again resumes.
      await tester.tap(_voiceAt(tester, 1));
      await tester.pump();
      expect(_voices(tester).map((v) => v.playing), [false, false]);
      await tester.tap(_voiceAt(tester, 1));
      await tester.pump();
      expect(_voices(tester).map((v) => v.playing), [false, true]);
      expect(players, hasLength(2));

      // At the end it rests again, ready to play from the start.
      players.last.complete();
      await tester.pump();
      await tester.pump();
      expect(_voices(tester).map((v) => v.playing), [false, false]);
      expect(players.last.disposed, isTrue);
      handle.dispose();
    });

    testWidgets('a failure shows a failed state that retries', (tester) async {
      final handle = tester.ensureSemantics();
      failing.add(_voiceA.url);
      await tester.pumpWidget(_chat([_message('a', _voiceA)]));
      await tester.tap(find.byType(FlareVoiceMessage));
      await tester.pump();
      await tester.pump();
      expect(_voices(tester).single.failed, isTrue);
      expect(find.text(_strings.voicePlaybackFailed), findsOneWidget);
      expect(find.bySemanticsLabel(_strings.retry), findsOneWidget);

      failing.clear();
      await tester.tap(find.bySemanticsLabel(_strings.retry));
      await tester.pump();
      await tester.pump();
      expect(players, hasLength(2));
      expect(_voices(tester).single.playing, isTrue);
      handle.dispose();
    });

    testWidgets('while selecting, a tap selects instead of playing', (
      tester,
    ) async {
      final toggled = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMessageList(
              messages: [
                _message('a', _voiceA),
                _message(
                  'img',
                  const FlareImageContent(url: 'https://media.example/i.jpg'),
                ),
              ],
              currentUserId: 'me',
              multiSelectMode: true,
              onToggleSelect: (message) => toggled.add(message.id),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FlareVoiceMessage));
      await tester.tap(find.byType(FlareImageMessage));
      await tester.pumpAndSettle();
      expect(toggled, ['a', 'img']);
      expect(players, isEmpty);
      expect(find.byType(FlareImagePreview), findsNothing);
    });

    testWidgets('playback survives a list refresh with new message objects', (
      tester,
    ) async {
      await tester.pumpWidget(_chat([_message('a', _voiceA)]));
      await tester.tap(find.byType(FlareVoiceMessage));
      await tester.pump();
      await tester.pump();
      // The host rereads the thread (a receipt arrived): same id, new objects.
      await tester.pumpWidget(
        _chat([_message('a', _voiceA), _message('c', _voiceB)]),
      );
      await tester.pump();
      expect(_voices(tester).first.playing, isTrue);
      expect(players.single.disposed, isFalse);
    });

    testWidgets('playback stops when the list goes away', (tester) async {
      await tester.pumpWidget(_chat([_message('a', _voiceA)]));
      await tester.tap(find.byType(FlareVoiceMessage));
      await tester.pump();
      await tester.pump();
      expect(players.single.value.isPlaying, isTrue);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
      expect(players.single.disposed, isTrue);
    });

    testWidgets('playback stops when another screen covers the chat', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: Scaffold(
            body: FlareMessageList(
              messages: [_message('a', _voiceA)],
              currentUserId: 'me',
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FlareVoiceMessage));
      await tester.pump();
      await tester.pump();
      expect(players.single.disposed, isFalse);
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pumpAndSettle();
      expect(players.single.disposed, isTrue);
    });
  });

  group('host handler', () {
    testWidgets('takes precedence over every default', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(
        _chat([
          _message(
            'img',
            const FlareImageContent(url: 'https://media.example/full.jpg'),
          ),
          _message(
            'vid',
            const FlareVideoContent(url: 'https://media.example/clip.mp4'),
          ),
          _message('voice', _voiceA),
        ], onMediaAction: (message, content) => taps.add(message.id)),
      );
      await tester.tap(find.byType(FlareImageMessage));
      await tester.tap(find.byType(FlareVideoMessage));
      await tester.tap(find.byType(FlareVoiceMessage));
      await tester.pumpAndSettle();
      expect(taps, ['img', 'vid', 'voice']);
      expect(find.byType(FlareImagePreview), findsNothing);
      expect(find.byType(FlareVideoPlayer), findsNothing);
      expect(players, isEmpty);
    });

    testWidgets('a file tap goes to onOpenFile; image, video and voice keep '
        'the kit defaults', (tester) async {
      final files = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMessageList(
              messages: [
                _message(
                  'file',
                  const FlareFileContent(
                    name: 'spec.pdf',
                    url: 'https://media.example/spec.pdf',
                  ),
                ),
                _message('voice', _voiceA),
                _message(
                  'img',
                  const FlareImageContent(
                    url: 'https://media.example/full.jpg',
                  ),
                ),
              ],
              currentUserId: 'me',
              onOpenFile: (message, file) =>
                  files.add('${message.id}:${file.name}'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FlareFileMessage));
      expect(files, ['file:spec.pdf']);
      // No download key without a download handler.
      expect(
        find.descendant(
          of: find.byType(FlareFileMessage),
          matching: find.byType(FlareIcon),
        ),
        findsNothing,
      );

      await tester.tap(find.byType(FlareVoiceMessage));
      await tester.pump();
      await tester.pump();
      expect(_voices(tester).single.playing, isTrue);

      await tester.tap(find.byType(FlareImageMessage));
      await tester.pumpAndSettle();
      expect(find.byType(FlareImagePreview), findsOneWidget);
      expect(files, hasLength(1));
    });

    testWidgets('onMediaAction still takes the file tap over onOpenFile', (
      tester,
    ) async {
      final taps = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMessageList(
              messages: [
                _message(
                  'file',
                  const FlareFileContent(
                    name: 'spec.pdf',
                    url: 'https://media.example/spec.pdf',
                  ),
                ),
              ],
              currentUserId: 'me',
              onMediaAction: (message, content) => taps.add('media'),
              onOpenFile: (message, file) => taps.add('file'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FlareFileMessage));
      expect(taps, ['media']);
    });
  });
}
