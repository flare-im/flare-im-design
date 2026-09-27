import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/media_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

// The media key: a download until the media is saved on this device, progress
// while it downloads, then a folder that shows the file in its folder. The
// timeline's file card, image preview and video player all follow the host's
// per-message state, the viewers live while they are open. Every message's
// time sits on the trailing edge.

const _strings = FlareStrings();

const _downloading = FlareMediaDownloadState(
  status: FlareMediaDownloadStatus.downloading,
  progressPct: 40,
);
const _saved = FlareMediaDownloadState(status: FlareMediaDownloadStatus.done);

/// A player that loads instantly and never touches a platform.
class _FakePlayer extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  _FakePlayer() : super(const VideoPlayerValue(duration: Duration.zero));

  @override
  Future<void> initialize() async {
    value = value.copyWith(
      isInitialized: true,
      duration: const Duration(seconds: 7),
      size: const Size(160, 90),
    );
  }

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);

  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);

  @override
  Future<void> dispose() async => super.dispose();

  @override
  int get playerId => VideoPlayerController.kUninitializedPlayerId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

FlareMessageData _incoming(
  String id,
  FlareMessageContent content, {
  String sender = 'bob',
}) => FlareMessageData(
  id: id,
  senderId: sender,
  senderName: 'Bob',
  content: content,
  timeLabel: '09:41',
  sentAtMs: DateTime(2026, 9, 28, 9, 41).millisecondsSinceEpoch,
);

/// A chat that keeps the per-message download state the way an app does: the
/// key starts a download, and the test says how it goes.
class _Chat extends StatefulWidget {
  const _Chat(this.messages);

  final List<FlareMessageData> messages;

  @override
  State<_Chat> createState() => _ChatState();
}

class _ChatState extends State<_Chat> {
  Map<String, FlareMediaDownloadState> states = const {};
  final downloads = <String>[];
  final reveals = <String>[];
  final opened = <String>[];

  void set(String id, FlareMediaDownloadState state) =>
      setState(() => states = {...states, id: state});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: FlareMessageList(
        messages: widget.messages,
        currentUserId: 'me',
        locale: 'zh-CN',
        mediaDownloadStates: states,
        onOpenFile: (message, _) => opened.add(message.id),
        onMediaDownload: (message, _) {
          downloads.add(message.id);
          set(
            message.id,
            const FlareMediaDownloadState(
              status: FlareMediaDownloadStatus.downloading,
            ),
          );
        },
        onMediaReveal: (message, _) => reveals.add(message.id),
      ),
    ),
  );
}

Finder _viewerKey(String icon) => find.byWidgetPredicate(
  (widget) => widget is FlareIconButton && widget.icon == icon,
);

Finder _cardGlyph(String icon) => find.descendant(
  of: find.byType(FlareFileMessage),
  matching: find.byWidgetPredicate(
    (widget) => widget is FlareIcon && widget.name == icon,
  ),
);

void main() {
  group('file card key', () {
    testWidgets('idle and failed offer the download on the right', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final taps = <String>[];
      for (final state in [
        null,
        const FlareMediaDownloadState(status: FlareMediaDownloadStatus.failed),
      ]) {
        taps.clear();
        await tester.pumpWidget(
          _host(
            FlareFileMessage(
              name: 'spec.pdf',
              size: '2.4 MB',
              ext: 'PDF',
              downloadState: state,
              onOpen: () => taps.add('open'),
              onDownload: () => taps.add('download'),
              onReveal: () => taps.add('reveal'),
            ),
          ),
        );
        expect(_cardGlyph('download'), findsOneWidget);
        expect(_cardGlyph('folder'), findsNothing);
        expect(find.text('2.4 MB · PDF'), findsOneWidget);
        // The key is the card's trailing element, a full touch target.
        final card = tester.getRect(find.byType(FlareFileMessage));
        final key = tester.getRect(find.bySemanticsLabel(_strings.download));
        expect(key.right, card.right);
        expect(key.width, greaterThanOrEqualTo(FlareSizes.touchTarget));
        expect(key.height, greaterThanOrEqualTo(FlareSizes.touchTarget));
        await tester.tap(find.bySemanticsLabel(_strings.download));
        expect(taps, ['download']);
        await tester.tap(find.text('spec.pdf'));
        expect(taps, ['download', 'open']);
      }
      handle.dispose();
    });

    testWidgets('downloading shows progress that cannot be pressed', (
      tester,
    ) async {
      final taps = <String>[];
      await tester.pumpWidget(
        _host(
          FlareFileMessage(
            name: 'spec.pdf',
            size: '2.4 MB',
            ext: 'PDF',
            downloadState: _downloading,
            onDownload: () => taps.add('download'),
            onReveal: () => taps.add('reveal'),
          ),
        ),
      );
      expect(_cardGlyph('download'), findsNothing);
      expect(_cardGlyph('folder'), findsNothing);
      final ring = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(ring.value, 0.4);
      expect(
        find.text('2.4 MB · PDF · ${_strings.downloading} 40%'),
        findsOneWidget,
      );
      await tester.tap(find.byType(CircularProgressIndicator));
      expect(taps, isEmpty);
    });

    testWidgets('saved shows the folder, which reveals the file', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final taps = <String>[];
      await tester.pumpWidget(
        _host(
          FlareFileMessage(
            name: 'spec.pdf',
            size: '2.4 MB',
            ext: 'PDF',
            downloadState: _saved,
            onDownload: () => taps.add('download'),
            onReveal: () => taps.add('reveal'),
          ),
        ),
      );
      expect(_cardGlyph('folder'), findsOneWidget);
      expect(_cardGlyph('download'), findsNothing);
      expect(
        find.text('2.4 MB · PDF · ${_strings.downloaded}'),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel(_strings.showInFolder));
      expect(taps, ['reveal']);
      handle.dispose();
    });

    testWidgets('a saved file with nothing to reveal it has no spent key', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareFileMessage(
            name: 'spec.pdf',
            downloadState: _saved,
            onDownload: () {},
          ),
        ),
      );
      expect(find.byType(FlareIcon), findsNothing);
    });

    testWidgets('in the timeline the key follows the host state, and the '
        'folder reports the message', (tester) async {
      final file = _incoming(
        'doc',
        const FlareFileContent(
          name: '连调测试.txt',
          url: 'https://media.example/a.txt',
          sizeBytes: 8704,
        ),
      );
      await tester.pumpWidget(_Chat([file]));
      final chat = tester.state<_ChatState>(find.byType(_Chat));
      expect(find.text('8.5 KB · TXT'), findsOneWidget);

      await tester.tap(_cardGlyph('download'));
      await tester.pump();
      expect(chat.downloads, ['doc']);
      // No second download while one runs, and no bar under the card: the
      // key is the progress.
      expect(_cardGlyph('download'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.tap(find.byType(CircularProgressIndicator));
      expect(chat.downloads, ['doc']);

      chat.set('doc', _saved);
      await tester.pump();
      expect(
        find.text('8.5 KB · TXT · ${_strings.downloaded}'),
        findsOneWidget,
      );
      await tester.tap(_cardGlyph('folder'));
      expect(chat.reveals, ['doc']);
      expect(chat.opened, isEmpty);

      // The file was gone: the host puts the download back.
      chat.set('doc', const FlareMediaDownloadState());
      await tester.pump();
      expect(_cardGlyph('download'), findsOneWidget);
      expect(_cardGlyph('folder'), findsNothing);

      // The card itself still opens the file.
      await tester.tap(find.text('连调测试.txt'));
      expect(chat.opened, ['doc']);
    });
  });

  group('viewer key follows the live state', () {
    setUp(() => flareMediaPlayerFactory = (_) => _FakePlayer());
    tearDown(() => flareMediaPlayerFactory = VideoPlayerController.networkUrl);

    testWidgets('image preview: download, progress, folder, without closing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Chat([
          _incoming(
            'img',
            const FlareImageContent(url: 'https://media.example/full.jpg'),
          ),
        ]),
      );
      final chat = tester.state<_ChatState>(find.byType(_Chat));
      await tester.tap(find.byType(FlareImageMessage));
      await tester.pumpAndSettle();
      FlareImagePreview preview() =>
          tester.widget<FlareImagePreview>(find.byType(FlareImagePreview));
      expect(_viewerKey('download'), findsOneWidget);

      await tester.tap(_viewerKey('download'));
      await tester.pump();
      await tester.pump();
      expect(chat.downloads, ['img']);
      expect(preview().downloading, isTrue);
      expect(_viewerKey('download'), findsNothing);

      chat.set('img', _saved);
      await tester.pump();
      await tester.pump();
      expect(preview().saved, isTrue);
      expect(_viewerKey('folder'), findsOneWidget);
      await tester.tap(_viewerKey('folder'));
      expect(chat.reveals, ['img']);

      // The saved copy was deleted: the key offers the download again.
      chat.set('img', const FlareMediaDownloadState());
      await tester.pump();
      await tester.pump();
      expect(_viewerKey('folder'), findsNothing);
      expect(_viewerKey('download'), findsOneWidget);
      expect(find.byType(FlareImagePreview), findsOneWidget);
    });

    testWidgets('video player: download, progress, folder, without closing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Chat([
          _incoming(
            'vid',
            const FlareVideoContent(url: 'https://media.example/clip.mp4'),
          ),
        ]),
      );
      final chat = tester.state<_ChatState>(find.byType(_Chat));
      await tester.tap(find.byType(FlareVideoMessage));
      await tester.pumpAndSettle();
      FlareVideoPlayer player() =>
          tester.widget<FlareVideoPlayer>(find.byType(FlareVideoPlayer));
      expect(_viewerKey('download'), findsOneWidget);

      await tester.tap(_viewerKey('download'));
      await tester.pump();
      await tester.pump();
      expect(chat.downloads, ['vid']);
      expect(player().downloading, isTrue);

      chat.set('vid', _saved);
      await tester.pump();
      await tester.pump();
      expect(player().saved, isTrue);
      await tester.tap(_viewerKey('folder'));
      expect(chat.reveals, ['vid']);
      expect(find.byType(FlareVideoPlayer), findsOneWidget);
    });
  });

  group('the time sits on the trailing edge', () {
    Future<({Rect bubble, Rect meta})> layout(
      WidgetTester tester,
      FlareMessageData message,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMessageBubble(message: message, currentUserId: 'me'),
          ),
        ),
      );
      final meta = find.byType(FlareMessageMeta);
      final surface = find
          .ancestor(of: meta, matching: find.byType(DecoratedBox))
          .first;
      return (bubble: tester.getRect(surface), meta: tester.getRect(meta));
    }

    testWidgets('an incoming bubble wider than its time', (tester) async {
      final r = await layout(
        tester,
        _incoming('t', const FlareTextContent('a longer line than the time')),
      );
      expect(
        r.meta.right,
        moreOrLessEquals(r.bubble.right - FlareSizes.componentBubblePaddingX),
      );
      expect(
        tester.getRect(find.text('a longer line than the time')).left,
        moreOrLessEquals(r.bubble.left + FlareSizes.componentBubblePaddingX),
      );
    });

    testWidgets('an incoming bubble narrower than its time keeps its body '
        'at the start', (tester) async {
      final r = await layout(
        tester,
        _incoming('t', const FlareTextContent('ok')),
      );
      expect(
        r.meta.right,
        moreOrLessEquals(r.bubble.right - FlareSizes.componentBubblePaddingX),
      );
      final body = tester.getRect(find.text('ok'));
      expect(
        body.left,
        moreOrLessEquals(r.bubble.left + FlareSizes.componentBubblePaddingX),
      );
      expect(body.right, lessThan(r.meta.right));
    });

    testWidgets('an incoming file card has its time at the bottom right', (
      tester,
    ) async {
      final r = await layout(
        tester,
        _incoming(
          'f',
          const FlareFileContent(name: '连调测试.txt', url: '', sizeBytes: 8704),
        ),
      );
      expect(
        r.meta.right,
        moreOrLessEquals(r.bubble.right - FlareSizes.componentBubblePaddingX),
      );
      expect(r.meta.bottom, lessThan(r.bubble.bottom));
      expect(
        r.meta.top,
        greaterThanOrEqualTo(
          tester.getRect(find.byType(FlareFileMessage)).bottom,
        ),
      );
    });

    testWidgets('an own bubble keeps its time on the right', (tester) async {
      final r = await layout(
        tester,
        _incoming('t', const FlareTextContent('mine'), sender: 'me'),
      );
      expect(
        r.meta.right,
        moreOrLessEquals(r.bubble.right - FlareSizes.componentBubblePaddingX),
      );
    });

    testWidgets('under incoming media, the time ends at the media\'s right '
        'edge', (tester) async {
      for (final content in <FlareMessageContent>[
        const FlareImageContent(url: 'https://media.example/a.jpg'),
        const FlareVideoContent(url: 'https://media.example/a.mp4'),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlareMessageBubble(
                message: _incoming('m', content),
                currentUserId: 'me',
              ),
            ),
          ),
        );
        final media = tester.getRect(
          find.byType(
            content is FlareImageContent
                ? FlareImageMessage
                : FlareVideoMessage,
          ),
        );
        final meta = tester.getRect(find.byType(FlareMessageMeta));
        expect(meta.right, moreOrLessEquals(media.right));
        expect(meta.top, greaterThanOrEqualTo(media.bottom));
        // The media itself stays on the sender's side.
        expect(media.left, lessThan(400));
      }
    });
  });

  group('video thumbnail', () {
    testWidgets('an unknown length draws no badge instead of 00:00', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FlareMessageContentView(
            content: FlareVideoContent(url: 'https://media.example/a.mp4'),
          ),
        ),
      );
      expect(find.text('00:00'), findsNothing);
      expect(find.byType(Text), findsNothing);
      // The image width at 16:9, with the play disc in the middle.
      expect(tester.getSize(find.byType(FlareVideoMessage)).width, 240);
      final play = find.byWidgetPredicate(
        (widget) => widget is FlareIcon && widget.name == 'play',
      );
      expect(
        tester.getCenter(play),
        tester.getCenter(find.byType(FlareVideoMessage)),
      );

      await tester.pumpWidget(
        _host(
          const FlareMessageContentView(
            content: FlareVideoContent(
              url: 'https://media.example/a.mp4',
              durationSec: 65,
            ),
          ),
        ),
      );
      expect(find.text('01:05'), findsOneWidget);
    });
  });
}
