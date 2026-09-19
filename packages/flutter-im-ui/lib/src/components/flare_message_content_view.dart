import 'dart:async';

import 'package:flutter/material.dart';

import 'action_icon.dart';
import 'flare_media_controller.dart';
import 'flare_message_bodies.dart';
import 'flare_image_group_message.dart';
import 'flare_rich_text_message.dart';
import '../models/message_content.dart';
import '../models/url_safety.dart';
import '../tokens/flare_tokens.dart';
import 'flare_unknown_message.dart';

/// Context passed to every content renderer.
class FlareContentContext {
  const FlareContentContext({
    required this.self,
    this.previewMode = false,
    this.senderName,
    this.mediaState,
    this.onMediaAction,
    this.onOpenLink,
    this.onLocate,
  });

  final bool self;
  final bool previewMode;
  final String? senderName;
  final FlareMediaDownloadState? mediaState;

  /// Host handles every media tap (image, video, voice, file…). Without it the
  /// kit opens images and videos in its own viewer and plays voice messages in
  /// place; files go to `FlareMessageContentView.onOpenFile`, links to
  /// `onOpenLink`, and locations do nothing.
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

/// Registry for product content types (`vote`, `task`, …). Built-in types are
/// rendered directly by [FlareMessageContentView]; register a builder to add or
/// override a type.
abstract final class FlareContentRegistry {
  static final Map<String, FlareContentBuilder> _builders = {};

  static void register(String type, FlareContentBuilder builder) =>
      _builders[type] = builder;

  static void unregister(String type) => _builders.remove(type);

  static FlareContentBuilder? lookup(String type) => _builders[type];
}

/// Content-type dispatcher — renders a message body by type. Spec:
/// Message/MessageContentView (`FlareMessageContentView`).
///
/// With [onMediaAction] the host takes every media tap. Without it, an image
/// opens in [FlareImagePreview] (full size, else the thumbnail), a video in
/// [FlareVideoPlayer], and a voice message plays in place through the nearest
/// [FlareMediaController] — the one `FlareMessageList` provides, so one voice
/// message plays at a time. A file tap then goes to [onOpenFile] and a link
/// (in a text body or on a link card) to [onOpenLink]; locations stay host
/// actions. The kit never leaves the app itself.
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
    this.mediaState,
    this.onMediaAction,
    this.onOpenFile,
    this.onOpenLink,
    this.onLocate,
    this.onVote,
    this.onTaskToggle,
    this.onMediaDownload,
  });

  final FlareMessageContent content;
  final bool self;
  final bool previewMode;
  final String? senderName;

  /// The message [content] belongs to; keeps a voice message's playback
  /// state across list refreshes.
  final String? messageId;
  final FlareMediaDownloadState? mediaState;
  final void Function(FlareMessageContent content)? onMediaAction;

  /// A file tap when there is no [onMediaAction]: the host opens the file
  /// (after `safeExternalUrl` for a remote one) while images, videos and voice
  /// keep the kit defaults. Without either, a file does nothing.
  final ValueChanged<FlareFileContent>? onOpenFile;

  /// A link tapped in a text body or on a link card. The kit checks the
  /// address with `safeExternalUrl` first: only `http` and `https` reach the
  /// host, which opens it (the kit never leaves the app itself).
  final ValueChanged<String>? onOpenLink;
  final VoidCallback? onLocate;

  /// A tapped poll option, by its index.
  final ValueChanged<int>? onVote;

  /// A tapped task checkbox, with the done state the user asks for.
  final ValueChanged<bool>? onTaskToggle;

  /// Offered as the download key of the kit's image preview, with the picture
  /// on screen; without it the preview has no download key. Inside a
  /// [FlareMessageList] a picture opens the conversation's gallery, whose key
  /// saves each picture through the list's handler instead.
  final ValueChanged<FlareMessageContent>? onMediaDownload;

  @override
  Widget build(BuildContext context) {
    final ctx = FlareContentContext(
      self: self,
      previewMode: previewMode,
      senderName: senderName,
      mediaState: mediaState,
      onMediaAction: onMediaAction,
      onOpenLink: onOpenLink,
      onLocate: onLocate,
    );

    final custom = FlareContentRegistry.lookup(content.type);
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
        primary: self ? foreground : colors.primary,
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

  Widget _body(BuildContext context) {
    VoidCallback? action(FlareMessageContent value) =>
        onMediaAction == null ? null : () => onMediaAction!(value);
    final media = FlareMediaScope.maybeOf(context);
    final body = switch (content) {
      FlareTextContent c => FlareTextMessage(
        text: c.text,
        self: self,
        mentions: c.mentions,
        onLinkTap: _openLink,
      ),
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
        src: c.thumbnailUrl ?? c.url,
        alt: c.alt,
        width: 240,
        height: c.width != null && c.height != null && c.width! > 0
            ? (240 * c.height! / c.width!).clamp(48, 240)
            : 180,
        onTap:
            action(c) ??
            (c.url.trim().isEmpty && (c.thumbnailUrl ?? '').trim().isEmpty
                ? null
                : () => flareOpenImage(
                    context,
                    c,
                    messageId: messageId,
                    onDownload: onMediaDownload == null
                        ? null
                        : () => onMediaDownload!(c),
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
              flarePresentVideo(context, c);
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
        onOpen: action(c) ?? (onOpenFile == null ? null : () => onOpenFile!(c)),
      ),
      FlareLocationContent c => FlareLocationMessage(
        title: c.name,
        address: c.address,
        onOpen: action(c),
      ),
      FlareCardContent c => FlareContactMessage(
        name: c.title,
        subtitle: c.subtitle,
        avatarUrl: c.imageUrl,
        onOpen: action(c),
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
    if (mediaState?.isDownloading != true) return body;
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

  static String _duration(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  static String _bytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
