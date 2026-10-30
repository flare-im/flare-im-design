import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;

import '../components/flare_message_status.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'message_content.dart';
import 'message_data.dart';

/// The surface a timeline row draws its content on
/// (`spec/message-surface-vectors.json`, docs/design/message-surface-and-meta.md
/// C1). [bubble] is the coloured bubble; [bareMedia] has no background (the
/// media is the surface); [card] is the content component's own shell
/// (plugin cards, red packets, locations, contact cards …) with nothing drawn
/// around it; [centered] is one centred notice line.
enum FlareMessageSurface { bubble, bareMedia, card, centered }

/// The facts [flareMessageSurface] reads, in the spec vocabulary.
@immutable
class FlareMessageSurfaceInput {
  const FlareMessageSurfaceInput({
    required this.contentType,
    this.subtype,
    this.loneEmoji = false,
    this.hasQuote = false,
    this.hasCaption = false,
    this.recalled = false,
    this.deleted = false,
    this.registered,
  });

  /// The spec content type (`components.json` contentTypes plus system,
  /// forward, thread, quote and custom).
  final String contentType;

  /// The custom content's subtype (`custom:<subtype>`), when there is one.
  final String? subtype;

  /// A text that is one emoji (pack token or Unicode), with no mentions.
  final bool loneEmoji;

  /// The message replies to another one.
  final bool hasQuote;

  /// A video with a description that is not blank.
  final bool hasCaption;
  final bool recalled;
  final bool deleted;

  /// The surface the host registered for the content's key.
  final FlareMessageSurface? registered;
}

/// The default surface of each spec content type
/// (`spec/message-surface-vectors.json` → defaults).
const Map<FlareMessageSurface, Set<String>> flareMessageSurfaceDefaults = {
  FlareMessageSurface.bubble: {
    'text',
    'richText',
    'audio',
    'file',
    'imageGroup',
    'quote',
    'placeholder',
  },
  FlareMessageSurface.bareMedia: {'image', 'sticker', 'emoji'},
  FlareMessageSurface.card: {
    'location',
    'card',
    'linkCard',
    'vote',
    'task',
    'schedule',
    'announcement',
    'miniProgram',
    'forward',
    'thread',
    'custom',
  },
  FlareMessageSurface.centered: {'system', 'notification'},
};

FlareMessageSurface? _defaultSurface(String contentType) {
  for (final entry in flareMessageSurfaceDefaults.entries) {
    if (entry.value.contains(contentType)) return entry.key;
  }
  return null;
}

/// The surface of one message (rules.order of the surface vectors): a recall
/// or delete notice and system lines are centered; then the host's
/// registration (bareMedia with a quote becomes bubble); a quote keeps a card
/// a card and puts everything else in a bubble; a video without a caption and
/// a lone emoji are bare media; then the defaults table. A type the kit does
/// not know draws its unknown-message body in a bubble.
FlareMessageSurface flareMessageSurface(FlareMessageSurfaceInput input) {
  if (input.recalled || input.deleted) return FlareMessageSurface.centered;
  final type = input.contentType;
  if (type == 'system' || type == 'notification') {
    return FlareMessageSurface.centered;
  }
  final registered = input.registered;
  if (registered != null) {
    return registered == FlareMessageSurface.bareMedia && input.hasQuote
        ? FlareMessageSurface.bubble
        : registered;
  }
  final fallback = _defaultSurface(type);
  if (input.hasQuote) {
    return fallback == FlareMessageSurface.card
        ? FlareMessageSurface.card
        : FlareMessageSurface.bubble;
  }
  if (type == 'video') {
    return input.hasCaption
        ? FlareMessageSurface.bubble
        : FlareMessageSurface.bareMedia;
  }
  if (type == 'text') {
    return input.loneEmoji
        ? FlareMessageSurface.bareMedia
        : FlareMessageSurface.bubble;
  }
  return fallback ?? FlareMessageSurface.bubble;
}

/// Kit wire names that differ from the spec vocabulary.
const Map<String, String> _specTypeOf = {
  'link_card': 'linkCard',
  'mini_program': 'miniProgram',
  'rich_text': 'richText',
  'image_group': 'imageGroup',
  'merged_forward': 'forward',
  'mergedForward': 'forward',
};

/// [content]'s key in the spec vocabulary: a kit type name (`link_card`,
/// `mini_program` …) maps onto the spec's, and `custom:<subtype>` splits into
/// the type and its subtype.
({String contentType, String? subtype}) flareMessageContentKey(
  FlareMessageContent content,
) {
  final type = content.type;
  final colon = type.indexOf(':');
  final head = colon < 0 ? type : type.substring(0, colon);
  final subtype = colon < 0 ? null : type.substring(colon + 1);
  return (
    contentType: _specTypeOf[head] ?? head,
    subtype: subtype == null || subtype.isEmpty ? null : subtype,
  );
}

/// Whether [content] is a lone emoji (the surface vectors' `loneEmoji`): a
/// text with no mentions that is one emoji, or a rich text with no title
/// whose whole text is one — older Core records carry a picked pack emoji
/// that way (`[smile]`), and it is the same one emoji, not formatted text.
bool flareIsLoneEmojiContent(FlareMessageContent content) => switch (content) {
  FlareTextContent c =>
    c.mentions.isEmpty && flareIsStandaloneEmojiMessage(c.text),
  FlareRichTextContent c =>
    c.title.trim().isEmpty && flareIsStandaloneEmojiMessage(c.plainText),
  _ => false,
};

/// The surface input of [message]; [registered] is what the host registered
/// for its content key (`FlareContentScope` / `FlareContentRegistry`).
FlareMessageSurfaceInput flareMessageSurfaceInputOf(
  FlareMessageData message, {
  FlareMessageSurface? registered,
}) {
  final key = flareMessageContentKey(message.content);
  final loneEmoji = flareIsLoneEmojiContent(message.content);
  return FlareMessageSurfaceInput(
    // A rich text that is one emoji reads as that emoji's text.
    contentType: loneEmoji ? 'text' : key.contentType,
    subtype: key.subtype,
    loneEmoji: loneEmoji,
    hasQuote: message.replyTo != null,
    recalled: message.isRecalled,
    deleted: message.isDeleted,
    registered: registered,
  );
}

// ── meta placement (spec/message-meta-placement-vectors.json) ──────────────

/// Where a message's time and receipt sit (C2): [inline] after a text's last
/// line, [bubbleFooter] in its own row inside other bubbles, [below] under bare
/// media and cards at the trailing edge, [none] on centered rows.
enum FlareMessageMetaPlacement { inline, bubbleFooter, below, none }

/// The palette of the meta: [onOutgoing] inside an outgoing bubble that has
/// not failed, [standard] (the spec's `default`) everywhere else.
enum FlareMessageMetaTone { standard, onOutgoing }

/// How a failed outgoing message offers its retry: the failed [glyph] inside a
/// bubble, or the [text] key "Failed to send. Retry" under a card or media.
enum FlareMessageRetryKind { glyph, text }

/// [flareMessageMetaPlacement]'s answer.
@immutable
class FlareMessageMetaLayout {
  const FlareMessageMetaLayout({
    required this.placement,
    required this.tone,
    this.retry,
  });
  final FlareMessageMetaPlacement placement;
  final FlareMessageMetaTone tone;

  /// Null unless the viewer's own message failed.
  final FlareMessageRetryKind? retry;
}

/// The meta layout for a message on [surface] whose spec content type is
/// [contentType] (rules of the meta placement vectors).
FlareMessageMetaLayout flareMessageMetaPlacement({
  required FlareMessageSurface surface,
  required String contentType,
  required bool self,
  required FlareMessageDeliveryStatus status,
}) {
  final placement = switch (surface) {
    FlareMessageSurface.bubble =>
      contentType == 'text'
          ? FlareMessageMetaPlacement.inline
          : FlareMessageMetaPlacement.bubbleFooter,
    FlareMessageSurface.bareMedia ||
    FlareMessageSurface.card => FlareMessageMetaPlacement.below,
    FlareMessageSurface.centered => FlareMessageMetaPlacement.none,
  };
  final failed = self && status == FlareMessageDeliveryStatus.failed;
  final inBubble =
      placement == FlareMessageMetaPlacement.inline ||
      placement == FlareMessageMetaPlacement.bubbleFooter;
  return FlareMessageMetaLayout(
    placement: placement,
    tone: inBubble && self && !failed
        ? FlareMessageMetaTone.onOutgoing
        : FlareMessageMetaTone.standard,
    retry: !failed
        ? null
        : inBubble
        ? FlareMessageRetryKind.glyph
        : placement == FlareMessageMetaPlacement.below
        ? FlareMessageRetryKind.text
        : null,
  );
}

// ── bubble palette (spec/message-surface-vectors.json `palette`) ─────────────

/// How a bubble surface is painted: the [incoming] or [outgoing] palette by
/// side, and the [failed] surface for a failed outgoing message.
enum FlareMessageBubbleTone { incoming, outgoing, failed }

/// The tone of a bubble: [FlareMessageBubbleTone.failed] only for the viewer's
/// own message that failed; a failed status on someone else's message keeps
/// the incoming palette.
FlareMessageBubbleTone flareMessageBubbleTone({
  required bool self,
  required FlareMessageDeliveryStatus? status,
}) {
  if (!self) return FlareMessageBubbleTone.incoming;
  return status == FlareMessageDeliveryStatus.failed
      ? FlareMessageBubbleTone.failed
      : FlareMessageBubbleTone.outgoing;
}

/// A bubble's fill, the foreground of its body, and its edge, which only the
/// failure surface has.
@immutable
class FlareMessageBubblePalette {
  const FlareMessageBubblePalette({
    required this.background,
    required this.foreground,
    this.edge,
  });
  final Color background;
  final Color foreground;
  final Color? edge;
}

/// [tone] in [colors]: the message.incoming, message.outgoing or
/// message.failed tokens.
FlareMessageBubblePalette flareMessageBubblePalette(
  FlareMessageBubbleTone tone,
  FlareColors colors,
) => switch (tone) {
  FlareMessageBubbleTone.incoming => FlareMessageBubblePalette(
    background: colors.messageIncomingBackground,
    foreground: colors.messageIncomingForeground,
  ),
  FlareMessageBubbleTone.outgoing => FlareMessageBubblePalette(
    background: colors.messageOutgoingBackground,
    foreground: colors.messageOutgoingForeground,
  ),
  FlareMessageBubbleTone.failed => FlareMessageBubblePalette(
    background: colors.messageFailedBackground,
    foreground: colors.messageFailedForeground,
    edge: colors.messageFailedBorder,
  ),
};

// ── receipt (spec/message-receipt-vectors.json) ────────────────────────────

/// The core SDK's group read summary of the viewer's own message
/// (MessageReceiptView.readSummary). Empty for big groups and before the data
/// exists: the kit never makes a number up.
@immutable
class FlareMessageReadSummary {
  const FlareMessageReadSummary({
    required this.readCount,
    required this.unreadCount,
    required this.total,
  });
  final int readCount;
  final int unreadCount;
  final int total;

  @override
  bool operator ==(Object other) =>
      other is FlareMessageReadSummary &&
      other.readCount == readCount &&
      other.unreadCount == unreadCount &&
      other.total == total;

  @override
  int get hashCode => Object.hash(readCount, unreadCount, total);
}

/// The receipt glyphs: pending clock, sending spinner, sent single check,
/// read double check (never the same shape as sent), failed alert.
enum FlareMessageReceiptGlyph { clock, spinner, check, doubleCheck, alert }

/// The read summary line: "N 人未读" while [count] members have not read it,
/// else "全部已读" ([allRead]).
@immutable
class FlareMessageReadSummaryText {
  const FlareMessageReadSummaryText.unread(int this.count) : allRead = false;
  const FlareMessageReadSummaryText.allRead() : count = null, allRead = true;
  final int? count;
  final bool allRead;

  String text(FlareStrings strings) => allRead
      ? strings.messageReadSummaryAllRead
      : strings.messageReadSummaryUnread.replaceAll('{count}', '$count');
}

/// What a message's receipt shows: a [glyph], or the read [summary] in its
/// place, or nothing (incoming messages).
@immutable
class FlareMessageReceiptPresentation {
  const FlareMessageReceiptPresentation({this.glyph, this.summary});
  final FlareMessageReceiptGlyph? glyph;
  final FlareMessageReadSummaryText? summary;
}

FlareMessageReceiptGlyph flareMessageReceiptGlyph(
  FlareMessageDeliveryStatus status,
) => switch (status) {
  FlareMessageDeliveryStatus.pending => FlareMessageReceiptGlyph.clock,
  FlareMessageDeliveryStatus.sending => FlareMessageReceiptGlyph.spinner,
  FlareMessageDeliveryStatus.sent => FlareMessageReceiptGlyph.check,
  FlareMessageDeliveryStatus.read => FlareMessageReceiptGlyph.doubleCheck,
  FlareMessageDeliveryStatus.failed => FlareMessageReceiptGlyph.alert,
};

/// The receipt of a message (rules of the receipt vectors): incoming messages
/// show none; the viewer's own messages in a [group] with a [readSummary] and
/// status sent or read show the summary in place of the check; everything else
/// shows the status glyph.
FlareMessageReceiptPresentation flareMessageReceiptPresentation({
  required bool self,
  required FlareMessageDeliveryStatus status,
  bool group = false,
  FlareMessageReadSummary? readSummary,
}) {
  if (!self) return const FlareMessageReceiptPresentation();
  final summary = readSummary;
  if (group &&
      summary != null &&
      (status == FlareMessageDeliveryStatus.sent ||
          status == FlareMessageDeliveryStatus.read)) {
    return FlareMessageReceiptPresentation(
      summary: summary.unreadCount > 0
          ? FlareMessageReadSummaryText.unread(summary.unreadCount)
          : const FlareMessageReadSummaryText.allRead(),
    );
  }
  return FlareMessageReceiptPresentation(
    glyph: flareMessageReceiptGlyph(status),
  );
}

/// The accessible name of a status glyph.
String flareMessageStatusLabel(
  FlareMessageDeliveryStatus status,
  FlareStrings strings,
) => switch (status) {
  FlareMessageDeliveryStatus.pending => strings.messagePending,
  FlareMessageDeliveryStatus.sending => strings.messageSending,
  FlareMessageDeliveryStatus.sent => strings.messageSent,
  FlareMessageDeliveryStatus.read => strings.messageRead,
  FlareMessageDeliveryStatus.failed => strings.messageFailed,
};

/// The list separator of [locale]: "，" for Chinese, ", " elsewhere.
String flareListSeparator(String? locale) =>
    (locale ?? '').toLowerCase().startsWith('zh') ? '，' : ', ';

/// One reading unit for a message row (receipt vectors → accessibility):
/// sender, content summary, time, then for the viewer's own messages the
/// status text (or "发送失败，重试" when failed) or the read summary that
/// replaces the glyph. Empty parts are skipped; parts are joined with the
/// locale's list separator.
String flareMessageAccessibilityLabel({
  required String sender,
  required String preview,
  required String time,
  required bool self,
  required FlareMessageDeliveryStatus status,
  required FlareStrings strings,
  String? locale,
  bool group = false,
  FlareMessageReadSummary? readSummary,
}) {
  final receipt = flareMessageReceiptPresentation(
    self: self,
    status: status,
    group: group,
    readSummary: readSummary,
  );
  final String state;
  if (!self) {
    state = '';
  } else if (receipt.summary != null) {
    state = receipt.summary!.text(strings);
  } else if (status == FlareMessageDeliveryStatus.failed) {
    state = strings.messageSendFailedRetry;
  } else {
    state = flareMessageStatusLabel(status, strings);
  }
  return [
    sender,
    preview,
    time,
    state,
  ].where((part) => part.trim().isNotEmpty).join(flareListSeparator(locale));
}
