import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'action_icon.dart';
import 'flare_media_controller.dart';
import 'flare_message_bodies.dart';
import 'flare_image_group_message.dart';
import 'flare_rich_text_message.dart';
import '../models/location.dart';
import '../platform/flare_platform.dart';
import '../models/message_content.dart';
import 'flare_media_image.dart';
import '../models/url_safety.dart';
import '../tokens/flare_tokens.dart';
import 'flare_unknown_message.dart';

/// Context passed to every content renderer.
class FlareContentContext {
  const FlareContentContext({
    required this.self,
    this.previewMode = false,
    this.senderName,
    this.messageId,
    this.conversationId,
    this.mediaState,
    this.onMediaAction,
    this.onOpenLink,
    this.onLocate,
  });

  final bool self;
  final bool previewMode;
  final String? senderName;

  /// The message being drawn: its server id when it has one (what the SDK and
  /// plugins key by), else its client id. Null outside a message row.
  final String? messageId;

  /// The conversation the message is in, when the host or list knows it.
  final String? conversationId;
  final FlareMediaDownloadState? mediaState;

  /// Host handles every media tap (image, video, voice, file…). Without it the
  /// kit opens images and videos in its own viewer and plays voice messages in
  /// place; files go to `FlareMessageContentView.onOpenFile`, links to
  /// `onOpenLink`, and locations to `onLocationOpen` (else their map link to
  /// `onOpenLink`).
  final void Function(FlareMessageContent content)? onMediaAction;

  /// Host opens a link tapped in a text body or on a link card. The kit never
  /// leaves the app itself, and only hands over an address that passed
  /// `safeExternalUrl`, so a `javascript:` link never reaches the host.
  final ValueChanged<String>? onOpenLink;

  /// Host focuses/locates this message (e.g. from a link card).
  final VoidCallback? onLocate;
}

/// A builder products register for a custom content [type].
typedef FlareContentBuilder =
    Widget Function(
      BuildContext context,
      FlareMessageContent content,
      FlareContentContext ctx,
    );

/// Extension callback ownership follows the widget tree and its session.
///
/// A type in [bareTypes] is drawn without a bubble — no bubble surface and no
/// bubble padding, the way a lone picture is — while its row keeps the avatar,
/// name, time, selection and menu. Use it for content that brings its own
/// surface (a red packet card).
class FlareContentScope extends InheritedWidget {
  const FlareContentScope({
    super.key,
    required this.builders,
    this.bareTypes = const <String>{},
    required super.child,
  });
  final Map<String, FlareContentBuilder> builders;
  final Set<String> bareTypes;
  static FlareContentBuilder? lookup(BuildContext context, String type) =>
      context
          .dependOnInheritedWidgetOfExactType<FlareContentScope>()
          ?.builders[type];

  /// Whether the builder that draws [type] — from the nearest scope, else the
  /// global [FlareContentRegistry] — asked to be drawn without a bubble.
  static bool isBare(BuildContext context, String type) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FlareContentScope>();
    if (scope != null && scope.builders.containsKey(type)) {
      return scope.bareTypes.contains(type);
    }
    return FlareContentRegistry.isBare(type);
  }

  @override
  bool updateShouldNotify(FlareContentScope oldWidget) =>
      builders != oldWidget.builders ||
      !setEquals(bareTypes, oldWidget.bareTypes);
}

/// Registry for product content types (`vote`, `task`, …). Built-in types are
/// rendered directly by [FlareMessageContentView]; register a builder to add or
/// override a type, with [bare] to draw it without a bubble.
abstract final class FlareContentRegistry {
  static final Map<String, FlareContentBuilder> _builders = {};
  static final Set<String> _bare = {};

  static void register(
    String type,
    FlareContentBuilder builder, {
    bool bare = false,
  }) {
    _builders[type] = builder;
    if (bare) {
      _bare.add(type);
    } else {
      _bare.remove(type);
    }
  }

  static void unregister(String type) {
    _builders.remove(type);
    _bare.remove(type);
  }

  static FlareContentBuilder? lookup(String type) => _builders[type];

  /// Whether a builder is registered for [type] with `bare: true`.
  static bool isBare(String type) =>
      _builders.containsKey(type) && _bare.contains(type);
}

/// Content-type dispatcher — renders a message body by type. Spec:
/// Message/MessageContentView (`FlareMessageContentView`).
///
/// With [onMediaAction] the host takes every media tap. Without it, an image
/// opens in [FlareImagePreview] (full size, else the thumbnail), a video in
/// [FlareVideoPlayer], and a voice message plays in place through the nearest
/// [FlareMediaController] — the one `FlareMessageList` provides, so one voice
/// message plays at a time. A file tap then goes to [onOpenFile] and a link
/// (in a text body or on a link card) to [onOpenLink]. A location goes to
/// [onLocationOpen]; without it the kit hands the platform's default map link
/// (Apple Maps on iOS and macOS, a `geo:` URI on Android, the provider's web
/// map elsewhere — `spec/location-vectors.json`) to [onOpenLink]. A person's
/// card reports its user id to [onCardOpen]. The kit never leaves the app
/// itself.
///
/// A poll's options and a task's checkbox are controls only with [onVote] and
/// [onTaskToggle]; without them the bodies are read-only.
class FlareMessageContentView extends StatelessWidget {
  const FlareMessageContentView({
    super.key,
    required this.content,
    this.self = false,
    this.previewMode = false,
    this.senderName,
    this.messageId,
    this.rendererMessageId,
    this.conversationId,
    this.mediaState,
    this.onMediaAction,
    this.onOpenFile,
    this.onOpenLink,
    this.onLocate,
    this.onVote,
    this.onTaskToggle,
    this.onCardOpen,
    this.onLocationOpen,
    this.onMediaDownload,
    this.onMediaReveal,
    this.uploading = false,
  });

  final FlareMessageContent content;

  /// This device's own message whose media is still uploading
  /// (`FlareMessageData.uploadProgress`). Its pictures may then come from the
  /// file on this device, and nothing opens or plays until the upload is done:
  /// the addresses the players need do not exist yet.
  final bool uploading;
  final bool self;
  final bool previewMode;
  final String? senderName;

  /// The message [content] belongs to; keeps a voice message's playback
  /// state across list refreshes.
  final String? messageId;

  /// The id custom builders receive as `FlareContentContext.messageId`: the
  /// server id when the row has one. Defaults to [messageId].
  final String? rendererMessageId;

  /// The conversation the message is in, for custom builders.
  final String? conversationId;
  final FlareMediaDownloadState? mediaState;
  final void Function(FlareMessageContent content)? onMediaAction;

  /// A file tap when there is no [onMediaAction]: the host opens the file
  /// (after `safeExternalUrl` for a remote one) while images, videos and voice
  /// keep the kit defaults. Without either, a file does nothing.
  final ValueChanged<FlareFileContent>? onOpenFile;

  /// A link tapped in a text body or on a link card. The kit checks the
  /// address with `safeExternalUrl` first: only `http` and `https` reach the
  /// host, which opens it (the kit never leaves the app itself). A location
  /// card without [onLocationOpen] hands over the map link the kit built from
  /// its coordinate, which on Android is a `geo:` URI.
  final ValueChanged<String>? onOpenLink;
  final VoidCallback? onLocate;

  /// A tapped poll option, by its index.
  final ValueChanged<int>? onVote;

  /// A tapped task checkbox, with the done state the user asks for.
  final ValueChanged<bool>? onTaskToggle;

  /// A tapped person's card, with its user id: the host opens the profile.
  /// A card without a user id, or without this, only displays.
  final ValueChanged<String>? onCardOpen;

  /// A tapped location card. Without it the default map link of the platform
  /// goes to [onOpenLink]; without either the card only displays.
  final ValueChanged<FlareLocationContent>? onLocationOpen;

  /// The download key of a file card, of the kit's image preview (with the
  /// picture on screen) and of its video player; without it none of them has
  /// a download key. Inside a [FlareMessageList] a picture opens the
  /// conversation's gallery, whose key saves each picture through the list's
  /// handler instead.
  final ValueChanged<FlareMessageContent>? onMediaDownload;

  /// The folder key that replaces the download key once [mediaState] says the
  /// media is saved on this device: the host shows the file in its folder, or
  /// — when the file is gone — sets the state back so the key offers the
  /// download again. Without it a saved media has no key.
  final ValueChanged<FlareMessageContent>? onMediaReveal;

  @override
  Widget build(BuildContext context) {
    final ctx = FlareContentContext(
      self: self,
      previewMode: previewMode,
      senderName: senderName,
      messageId: rendererMessageId ?? messageId,
      conversationId: conversationId,
      mediaState: mediaState,
      onMediaAction: onMediaAction,
      onOpenLink: onOpenLink,
      onLocate: onLocate,
    );

    final custom =
        FlareContentScope.lookup(context, content.type) ??
        FlareContentRegistry.lookup(content.type);
    if (custom != null) return custom(context, content, ctx);

    final colors = FlareColors.of(context);
    // The same content bodies serve standalone previews and runtime bubbles.
    // Outgoing foregrounds are scoped here; bodies never own a second surface.
    final foreground = self
        ? colors.messageOutgoingForeground
        : colors.messageIncomingForeground;
    return FlareTheme(
      colors: colors.copyWith(
        textPrimary: foreground,
        textSecondary: foreground,
        textTertiary: foreground.withValues(alpha: 0.8),
        primary: self ? foreground : colors.primaryText,
      ),
      child: IconTheme(
        data: IconThemeData(color: foreground, size: FlareSizes.iconSizeMd),
        child: _body(context),
      ),
    );
  }

  /// Reports a tapped link to the host, but only an address the chat may open
  /// (`safeExternalUrl`): `javascript:` and friends never leave the kit.
  void _openLink(String raw) {
    final url = safeExternalUrl(raw);
    if (url != null) onOpenLink?.call(url);
  }

  VoidCallback? _openerFor(String raw) {
    if (onOpenLink == null || safeExternalUrl(raw) == null) return null;
    return () => _openLink(raw);
  }

  /// A media body while its upload runs: drawn like the finished one (a
  /// picture from the local file, the video or voice card) but inert.
  Widget? _uploadingBody() => switch (content) {
    FlareImageContent c => FlareImageMessage(
      src: c.thumbnailUrl ?? c.url,
      alt: c.alt,
      width: 240,
      height: c.width != null && c.height != null && c.width! > 0
          ? (240 * c.height! / c.width!).clamp(48, 240)
          : 180,
      allowLocalFile: true,
    ),
    FlareImageGroupContent c => FlareImageGroupMessage(
      images: c.images,
      description: c.description,
      self: self,
      allowLocalFile: true,
    ),
    FlareVideoContent c => FlareVideoMessage(
      poster: c.poster,
      duration: _duration(c.durationSec),
    ),
    FlareFileContent c => FlareFileMessage(
      name: c.name,
      size: _bytes(c.sizeBytes),
      ext: _ext(c.name),
    ),
    _ => null,
  };

  /// The live download state of this message for a viewer opened from it:
  /// the timeline's ([FlareMediaScope.downloadStateOf]) when there is one, so
  /// the viewer's key keeps up with a download started inside it; else a
  /// snapshot of [mediaState].
  ValueListenable<FlareMediaDownloadState?>? _liveState(BuildContext context) {
    final id = messageId;
    final live = id == null
        ? null
        : FlareMediaScope.downloadStateOf(context, id);
    if (live != null) return live;
    final state = mediaState;
    return state == null ? null : _FixedDownloadState(state);
  }

  Widget _body(BuildContext context) {
    VoidCallback? action(FlareMessageContent value) =>
        onMediaAction == null ? null : () => onMediaAction!(value);
    if (uploading) {
      final pending = _uploadingBody();
      if (pending != null) return pending;
    }
    final media = FlareMediaScope.maybeOf(context);
    final body = switch (content) {
      FlareTextContent c
          when c.mentions.isEmpty && flareIsStandaloneEmojiMessage(c.text) =>
        FlareEmojiMessage(emoji: c.text.trim()),
      FlareTextContent c => FlareTextMessage(
        text: c.text,
        self: self,
        mentions: c.mentions,
        onLinkTap: _openLink,
      ),
      FlareRichTextContent c
          when c.title.trim().isEmpty &&
              flareIsStandaloneEmojiMessage(c.plainText) =>
        FlareEmojiMessage(emoji: c.plainText.trim()),
      FlareRichTextContent c => FlareRichTextMessage(
        docJson: c.docJson,
        plainText: c.plainText,
        title: c.title,
        self: self,
        onLinkTap: _openLink,
      ),
      FlareEmojiContent c => FlareEmojiMessage(emoji: c.emoji),
      FlareStickerContent c => FlareStickerMessage(
        src: c.url,
        packageId: c.packageId,
        stickerId: c.stickerId,
        width: c.width,
        height: c.height,
        onTap: action(c),
      ),
      FlareImageContent c => FlareImageMessage(
        src: flarePictureSource(c).src,
        allowLocalFile: flarePictureSource(c).local,
        alt: c.alt,
        width: 240,
        height: c.width != null && c.height != null && c.width! > 0
            ? (240 * c.height! / c.width!).clamp(48, 240)
            : 180,
        onTap:
            action(c) ??
            (flarePictureSource(c).src.isEmpty
                ? null
                : () => flareOpenImage(
                    context,
                    c,
                    messageId: messageId,
                    onDownload: onMediaDownload == null
                        ? null
                        : () => onMediaDownload!(c),
                    onReveal: onMediaReveal == null
                        ? null
                        : () => onMediaReveal!(c),
                    downloadState: _liveState(context),
                  )),
      ),
      FlareImageGroupContent c => FlareImageGroupMessage(
        images: c.images,
        description: c.description,
        self: self,
        onOpen: onMediaAction != null
            ? (_) => onMediaAction!(c)
            : (index) => flareOpenImage(
                context,
                c.images[index],
                messageId: messageId,
                index: index,
                onDownload: onMediaDownload == null
                    ? null
                    : () => onMediaDownload!(c.images[index]),
              ),
      ),
      FlareVideoContent c => FlareVideoMessage(
        poster: c.poster,
        duration: _duration(c.durationSec),
        onPlay:
            action(c) ??
            () {
              // A video and a voice message never talk over each other.
              if (media != null) unawaited(media.stopVoice());
              flarePresentVideo(
                context,
                c,
                onDownload: onMediaDownload == null
                    ? null
                    : () => onMediaDownload!(c),
                onReveal: onMediaReveal == null
                    ? null
                    : () => onMediaReveal!(c),
                downloadState: _liveState(context),
              );
            },
      ),
      FlareAudioContent c => FlareVoicePlaybackMessage(
        content: c,
        messageId: messageId,
        onPlay: action(c),
      ),
      FlareFileContent c => FlareFileMessage(
        name: c.name,
        size: _bytes(c.sizeBytes),
        ext: _ext(c.name),
        downloadState: mediaState,
        onOpen: action(c) ?? (onOpenFile == null ? null : () => onOpenFile!(c)),
        onDownload: onMediaDownload == null ? null : () => onMediaDownload!(c),
        onReveal: onMediaReveal == null ? null : () => onMediaReveal!(c),
      ),
      FlareLocationContent c => FlareLocationMessage(
        title: c.name,
        address: c.address,
        latitude: _coordinate(c).$1,
        longitude: _coordinate(c).$2,
        snapshotUrl: c.snapshotUrl,
        provider: c.provider,
        onOpen: _locationOpener(c, action(c)),
      ),
      FlareCardContent c => FlareContactMessage(
        name: c.title,
        subtitle: c.subtitle,
        avatarUrl: c.imageUrl,
        userId: c.userId ?? '',
        onOpen: (c.userId?.isNotEmpty ?? false) && onCardOpen != null
            ? (id) => onCardOpen!(id)
            : (action(c) == null ? null : (_) => onMediaAction!(c)),
      ),
      FlareLinkCardContent c => FlareLinkCardMessage(
        title: c.title,
        description: c.description,
        thumb: c.imageUrl,
        domain: c.url,
        // A link card is a link: the same intent as a link in a text body.
        onOpen: onLocate ?? action(c) ?? _openerFor(c.url),
      ),
      FlarePollContent c => FlareVoteMessage(
        title: c.title,
        options: c.options.map((text) => FlareVoteOption(text)).toList(),
        onSelect: onVote == null ? null : (_, index) => onVote!(index),
      ),
      FlareTaskContent c => FlareTaskMessage(
        title: c.title,
        meta: c.detail,
        done: c.done,
        onToggle: onTaskToggle == null ? null : () => onTaskToggle!(!c.done),
      ),
      FlareCalendarContent c => FlareLinkCardMessage(
        title: c.title,
        description: c.timeRange,
        onOpen: action(c),
        icon: const Icon(Icons.calendar_month_outlined),
      ),
      FlareMiniAppContent c => FlareLinkCardMessage(
        title: c.title,
        description: c.description,
        thumb: c.thumbnailUrl,
        domain: c.appId,
        onOpen: action(c),
        icon: c.thumbnailUrl == null ? Icon(flareIconGlyph('mini-app')) : null,
      ),
      FlareAnnouncementContent c => FlareLinkCardMessage(
        title: c.title,
        description: c.body,
        descriptionMaxLines: null,
        icon: const Icon(Icons.campaign_outlined),
        onOpen: action(c),
      ),
      FlareNotificationContent c => FlareSystemMessage(text: c.text),
      FlarePlaceholderContent c => FlareSystemMessage(text: c.label),
      FlareGenericContent c => FlareUnknownMessage(
        contentType: c.contentType,
        summary: '[${c.label}]',
        isSelf: self,
      ),
      _ => FlareUnknownMessage(contentType: content.type, isSelf: self),
    };
    // A file card shows its own progress in its key.
    if (mediaState?.isDownloading != true || content is FlareFileContent) {
      return body;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        body,
        LinearProgressIndicator(
          value: mediaState!.progressPct.clamp(0, 100) / 100,
        ),
      ],
    );
  }

  /// The coordinate a location card draws. The wire writes an absent
  /// coordinate as 0, 0: that pair is "no coordinate", not a place to open.
  static (double?, double?) _coordinate(FlareLocationContent c) =>
      c.latitude == 0 && c.longitude == 0 ? (null, null) : (c.latitude, c.longitude);

  /// What a location tap does: the host's [onLocationOpen], then the media
  /// handler, then the platform's default map link through [onOpenLink].
  VoidCallback? _locationOpener(FlareLocationContent c, VoidCallback? media) {
    if (onLocationOpen != null) return () => onLocationOpen!(c);
    if (media != null) return media;
    final (lat, lng) = _coordinate(c);
    final links = flareLocationMapLinks(
      latitude: lat ?? double.nan,
      longitude: lng ?? double.nan,
      title: c.name,
      provider: c.provider,
    );
    final open = onOpenLink;
    if (links == null || open == null) return null;
    return () => open(links.forPlatform(flareTargetPlatform));
  }

  /// A video's length as its badge shows it; null when it is unknown, so the
  /// badge is left out rather than saying `00:00`.
  static String? _duration(int seconds) => seconds <= 0
      ? null
      : '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  /// The type label of a file card: the name's extension (1–5 letters or
  /// digits) in capitals, the rule the other kits use; null without one.
  static String? _ext(String name) {
    final match = RegExp(
      r'\.([a-z0-9]{1,5})$',
      caseSensitive: false,
    ).firstMatch(name);
    return match?.group(1)!.toUpperCase();
  }

  static String _bytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

/// A download state that does not change: a standalone body's snapshot for
/// the viewer it opens.
class _FixedDownloadState implements ValueListenable<FlareMediaDownloadState?> {
  const _FixedDownloadState(this.value);

  @override
  final FlareMediaDownloadState? value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
