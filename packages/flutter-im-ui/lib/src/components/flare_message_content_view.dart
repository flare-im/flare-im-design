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
import 'flare_message_card_shell.dart';
import '../models/message_data.dart';
import '../models/message_surface.dart';
import '../models/url_safety.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';
import 'flare_unknown_message.dart';
import 'flare_forward_message.dart';
import '../models/forward_record.dart';

/// Context passed to every content renderer.
class FlareContentContext {
  const FlareContentContext({
    required this.self,
    this.previewMode = false,
    this.senderId,
    this.senderName,
    this.messageId,
    this.conversationId,
    this.mediaState,
    this.onMediaAction,
    this.onOpenLink,
    this.onLocate,
    this.selectionMode = false,
    this.surface,
  });

  final bool self;
  final bool previewMode;

  /// The row is in multi-select: every control in the content is inert and a
  /// tap goes to the row (spec MessageContentView `selectionMode`). The kit
  /// already ignores pointers then; a builder uses it to draw its controls
  /// disabled.
  final bool selectionMode;

  /// The surface the row draws the content on; a card builder's shell is the
  /// card surface itself (nothing is drawn around it).
  final FlareMessageSurface? surface;

  /// The message's sender id. Null outside a message row.
  final String? senderId;

  /// The display name the host gave the message's sender, trimmed; null when
  /// empty. Never the id or a placeholder word: a builder chooses its own
  /// wording when there is no name.
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
/// [surfaces] registers the surface of a content key the kit does not know
/// (`spec/message-surface-vectors.json` rules.registration): `card` or
/// `bareMedia`. Every custom and plugin content (`custom`, `custom:<subtype>`)
/// is already a card by default — red packets and all plugin cards — so a host
/// registers only a new kind of content, such as a bare animated picture. A
/// key is the content type with its subtype (`custom:acme.gif`) or the type
/// alone (`custom`); the longer key wins.
class FlareContentScope extends InheritedWidget {
  const FlareContentScope({
    super.key,
    required this.builders,
    this.surfaces = const <String, FlareMessageSurface>{},
    required super.child,
  });
  final Map<String, FlareContentBuilder> builders;
  final Map<String, FlareMessageSurface> surfaces;
  static FlareContentBuilder? lookup(BuildContext context, String type) =>
      context
          .dependOnInheritedWidgetOfExactType<FlareContentScope>()
          ?.builders[type];

  /// The builder that draws [type]: its full key first (`custom:acme.poll`),
  /// then the content type before `:` (`custom`); for each key the nearest
  /// scope, then the global [FlareContentRegistry].
  static FlareContentBuilder? builderFor(BuildContext context, String type) {
    final colon = type.indexOf(':');
    for (final key in [type, if (colon > 0) type.substring(0, colon)]) {
      final builder = lookup(context, key) ?? FlareContentRegistry.lookup(key);
      if (builder != null) return builder;
    }
    return null;
  }

  /// The surface registered for [type]: its full key first, then the content
  /// type before `:`; for each key the nearest scope that knows it decides,
  /// then the global [FlareContentRegistry].
  static FlareMessageSurface? surfaceFor(BuildContext context, String type) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FlareContentScope>();
    final colon = type.indexOf(':');
    for (final key in [type, if (colon > 0) type.substring(0, colon)]) {
      if (scope != null &&
          (scope.surfaces.containsKey(key) ||
              scope.builders.containsKey(key))) {
        return scope.surfaces[key];
      }
      if (FlareContentRegistry._knows(key)) {
        return FlareContentRegistry.surfaceOf(key);
      }
    }
    return null;
  }

  /// The surface [message] is drawn on (`flareMessageSurface` with the
  /// registration for its content).
  static FlareMessageSurface surfaceOf(
    BuildContext context,
    FlareMessageData message,
  ) => flareMessageSurface(
    flareMessageSurfaceInputOf(
      message,
      registered: surfaceFor(context, message.content.type),
    ),
  );

  @override
  bool updateShouldNotify(FlareContentScope oldWidget) =>
      builders != oldWidget.builders ||
      !mapEquals(surfaces, oldWidget.surfaces);
}

/// Registry for product content types (`vote`, `task`, …). Built-in types are
/// rendered directly by [FlareMessageContentView]; register a builder to add or
/// override a type, with [surface] for a new kind of content that is not a
/// card (see [FlareContentScope.surfaces]).
abstract final class FlareContentRegistry {
  static final Map<String, FlareContentBuilder> _builders = {};
  static final Map<String, FlareMessageSurface> _surfaces = {};

  static void register(
    String type,
    FlareContentBuilder builder, {
    FlareMessageSurface? surface,
  }) {
    _builders[type] = builder;
    if (surface != null) {
      _surfaces[type] = surface;
    } else {
      _surfaces.remove(type);
    }
  }

  static void unregister(String type) {
    _builders.remove(type);
    _surfaces.remove(type);
  }

  static FlareContentBuilder? lookup(String type) => _builders[type];

  /// The surface registered with the builder for [type].
  static FlareMessageSurface? surfaceOf(String type) => _surfaces[type];

  static bool _knows(String type) =>
      _builders.containsKey(type) || _surfaces.containsKey(type);
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
    this.senderId,
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
    this.surface,
    this.failed = false,
    this.selectionMode = false,
  });

  final FlareMessageContent content;

  /// The surface the content is drawn on (`spec/message-surface-vectors.json`).
  /// Only a [FlareMessageSurface.bubble] takes the bubble's text colours; a
  /// built-in card body gets the kit card shell ([FlareMessageCardShell]) as
  /// its surface. Null derives it from the content alone.
  final FlareMessageSurface? surface;

  /// The viewer's own message failed: on a bubble the text takes the failed
  /// colours (`message.failed.*`).
  final bool failed;

  /// The row is in multi-select: the content is inert and a tap goes to the
  /// row, which toggles its selection.
  final bool selectionMode;

  /// This device's own message whose media is still uploading
  /// (`FlareMessageData.uploadProgress`). Its pictures may then come from the
  /// file on this device, and nothing opens or plays until the upload is done:
  /// the addresses the players need do not exist yet.
  final bool uploading;
  final bool self;
  final bool previewMode;

  /// The sender's id, handed to a custom builder as
  /// `FlareContentContext.senderId`.
  final String? senderId;

  /// The sender's display name; a custom builder gets it trimmed, and null
  /// when empty (`FlareContentContext.senderName`).
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

  /// The surface when none is given: the content alone, as if unquoted.
  FlareMessageSurface _surface(BuildContext context) {
    final given = surface;
    if (given != null) return given;
    final key = flareMessageContentKey(content);
    final loneEmoji = flareIsLoneEmojiContent(content);
    return flareMessageSurface(
      FlareMessageSurfaceInput(
        contentType: loneEmoji ? 'text' : key.contentType,
        subtype: key.subtype,
        loneEmoji: loneEmoji,
        registered: FlareContentScope.surfaceFor(context, content.type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = _surface(context);
    final name = senderName?.trim() ?? '';
    final ctx = FlareContentContext(
      self: self,
      previewMode: previewMode,
      senderId: senderId,
      senderName: name.isEmpty ? null : name,
      messageId: rendererMessageId ?? messageId,
      conversationId: conversationId,
      mediaState: mediaState,
      onMediaAction: onMediaAction,
      onOpenLink: onOpenLink,
      onLocate: onLocate,
      selectionMode: selectionMode,
      surface: surface,
    );

    final custom = FlareContentScope.builderFor(context, content.type);
    if (custom != null) {
      return IgnorePointer(
        ignoring: selectionMode,
        child: custom(context, content, ctx),
      );
    }

    final colors = FlareColors.of(context);
    Widget body = _body(context, surface);
    if (surface == FlareMessageSurface.bubble) {
      // The same content bodies serve standalone previews and runtime
      // bubbles. Only a bubble scopes its foreground here; on a card or bare
      // media the body keeps the neutral palette of its own surface. Text and
      // rich text read their side's foreground, so inside the bubble both
      // sides are the bubble's: a failed message's failure surface reaches
      // them too.
      final foreground = failed
          ? colors.messageFailedForeground
          : self
          ? colors.messageOutgoingForeground
          : colors.messageIncomingForeground;
      body = FlareTheme(
        colors: colors.copyWith(
          textPrimary: foreground,
          textSecondary: foreground,
          textTertiary: foreground.withValues(alpha: 0.8),
          messageOutgoingForeground: foreground,
          messageIncomingForeground: foreground,
          primary: self && !failed ? foreground : colors.primaryText,
        ),
        child: IconTheme(
          data: IconThemeData(color: foreground, size: FlareSizes.iconSizeMd),
          child: body,
        ),
      );
    } else if (surface == FlareMessageSurface.card && _needsCardShell) {
      body = FlareMessageCardShell(child: body);
    }
    return IgnorePointer(ignoring: selectionMode, child: body);
  }

  /// Built-in card bodies that have no shell of their own: the kit card shell
  /// is their surface. A location card and a red packet bring their own.
  bool get _needsCardShell => switch (content) {
    FlareLocationContent() => false,
    // A forward record draws its own: the card, or the one item inline.
    FlareForwardContent() => false,
    FlareImageContent() ||
    FlareVideoContent() ||
    FlareStickerContent() ||
    FlareEmojiContent() => false,
    _ => true,
  };

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

  Widget _body(BuildContext context, FlareMessageSurface surface) {
    // A lone emoji is bare media; quoted it is a line of text in a bubble.
    final bare = surface != FlareMessageSurface.bubble;
    VoidCallback? action(FlareMessageContent value) =>
        onMediaAction == null ? null : () => onMediaAction!(value);
    if (uploading) {
      final pending = _uploadingBody();
      if (pending != null) return pending;
    }
    final media = FlareMediaScope.maybeOf(context);
    final body = switch (content) {
      FlareTextContent c
          when bare &&
              c.mentions.isEmpty &&
              flareIsStandaloneEmojiMessage(c.text) =>
        FlareEmojiMessage(emoji: c.text.trim()),
      FlareTextContent c => FlareTextMessage(
        text: c.text,
        self: self,
        mentions: c.mentions,
        onLinkTap: _openLink,
      ),
      FlareRichTextContent c
          when bare &&
              c.title.trim().isEmpty &&
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
        // No address yet (the media is still being resolved): nothing plays.
        onPlay: c.url.trim().isEmpty
            ? action(c)
            : action(c) ??
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
      FlareForwardContent c => FlareForwardMessage(
        record: c,
        self: self,
        selectionMode: selectionMode,
      ),
      // A picture, a video or a voice message whose address is missing is
      // still that kind of message: it says it cannot be loaded right now,
      // never "unsupported" (the same in all four kits).
      FlareGenericContent c
          when _mediaUnavailableLine(c.contentType, FlareStrings.of(context)) !=
              null =>
        _MediaUnavailable(
          line: _mediaUnavailableLine(c.contentType, FlareStrings.of(context))!,
        ),
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
/// The words for a picture, a video or a voice message the host has no
/// address for, and the icon it is drawn with: still that kind of message,
/// never "unsupported". Null for any other wire type.
({String icon, String text})? _mediaUnavailableLine(
  String wireType,
  FlareStrings strings,
) => switch (wireType) {
  'image' => (icon: 'image', text: strings.mediaUnavailableImage),
  'video' => (icon: 'video', text: strings.mediaUnavailableVideo),
  'audio' || 'voice' => (icon: 'mic', text: strings.mediaUnavailableAudio),
  _ => null,
};

/// A picture, a video or a voice message with no address to load (the host
/// passes it as [FlareGenericContent] under its wire type): its icon and the
/// kit's words for why it is not there, on the media's tertiary ground.
/// Nothing to tap — there is nothing to retry from here — and a screen reader
/// hears the same line.
class _MediaUnavailable extends StatelessWidget {
  const _MediaUnavailable({required this.line});

  final ({String icon, String text}) line;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Semantics(
      container: true,
      label: line.text,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgTertiary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingMd,
            vertical: FlareSizes.spacingSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlareIcon(
                line.icon,
                size: FlareSizes.iconSizeSm,
                color: colors.textTertiary,
              ),
              const SizedBox(width: FlareSizes.spacingXs),
              Flexible(
                child: Text(
                  line.text,
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: FlareSizes.fontSizeSm,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FixedDownloadState implements ValueListenable<FlareMediaDownloadState?> {
  const _FixedDownloadState(this.value);

  @override
  final FlareMediaDownloadState? value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
