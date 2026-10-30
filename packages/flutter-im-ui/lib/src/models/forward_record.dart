import 'package:flutter/foundation.dart';

import '../tokens/flare_strings.dart';
import 'message_content.dart';
import 'message_preview.dart';
import 'plural.dart';

/// How a forward was made (the core's ForwardMode: 0 unspecified, 1 single,
/// 2 merged).
enum FlareForwardMode {
  unspecified,
  single,
  merged;

  /// The core's wire value; an unknown value reads as [unspecified].
  static FlareForwardMode fromWire(int? value) => switch (value) {
    1 => single,
    2 => merged,
    _ => unspecified,
  };
}

/// One message of a merged-forward record. A host maps the core's
/// `sourceSenderName`, `sourceMessageTimeMs`, `plainText` and `content` (the
/// content through its usual content mapping).
@immutable
class FlareForwardItem {
  const FlareForwardItem({
    this.senderName = '',
    this.sentAtMs = 0,
    this.plainText = '',
    this.content,
  });

  /// The original sender's name; blank reads as forwardRecordUnknownSender.
  final String senderName;

  /// When the original was sent, in epoch milliseconds; 0 when unknown.
  final int sentAtMs;

  /// The original's plain text: the summary line when present.
  final String plainText;

  /// The original content, drawn under the summary in the record's drawer.
  final FlareMessageContent? content;
}

/// A merged-forward record (content type `forward`, card surface), drawn as
/// the other kits draw it (`spec/message-forward-vectors.json`): an empty
/// notice, one message inline, or the record card that opens the full list in
/// the kit drawer. A host maps the core's `forward` (or `merged_forward`)
/// content: `title`, `mode` ([FlareForwardMode.fromWire]) and `items`.
class FlareForwardContent extends FlareMessageContent {
  const FlareForwardContent({
    this.title = '',
    this.mode = FlareForwardMode.unspecified,
    this.items = const [],
  });

  /// The record's own title; blank reads as forwardRecordTitle.
  final String title;
  final FlareForwardMode mode;
  final List<FlareForwardItem> items;

  @override
  String get type => 'forward';
}

/// What a forward record draws.
enum FlareForwardLayout {
  /// No items: one line, forwardRecordEmpty.
  empty,

  /// One item of a record that is not merged: that item's content inline.
  single,

  /// The record card.
  card,
}

/// How many preview lines the record card shows.
const int flareForwardPreviewLimit = 3;

/// One preview line of the record card: "sender: text".
typedef FlareForwardPreview = ({String sender, String text});

/// What the record card and its drawer show for a record.
@immutable
class FlareForwardRecordView {
  const FlareForwardRecordView({
    required this.layout,
    required this.title,
    required this.subtitle,
    required this.previews,
    required this.more,
    required this.hint,
    required this.label,
    required this.drawerTitle,
  });

  final FlareForwardLayout layout;

  /// The record's title trimmed, else forwardRecordTitle.
  final String title;

  /// forwardRecordTotal(count) when the record holds more than one message.
  final String? subtitle;

  /// The first [flareForwardPreviewLimit] messages.
  final List<FlareForwardPreview> previews;

  /// forwardRecordMore(count − 3) past the first three.
  final String? more;

  /// forwardRecordViewDetails.
  final String hint;

  /// The card's accessible name: "title, subtitle", or the title alone.
  final String label;

  /// "{title}{forwardRecordCountSuffix(count)}".
  final String drawerTitle;
}

/// A forwarded message's sender label: its name trimmed, else
/// forwardRecordUnknownSender — never an account id.
String flareForwardSender(FlareForwardItem item, FlareStrings strings) {
  final name = item.senderName.trim();
  return name.isEmpty ? strings.forwardRecordUnknownSender : name;
}

/// The drawer avatar's initial for a forwarded message: the first character of
/// the sender's name (trimmed), upper-cased; "?" without a name — never the
/// first character of forwardRecordUnknownSender.
String flareForwardSenderInitial(FlareForwardItem item) {
  final name = item.senderName.trim();
  return name.isEmpty
      ? '?'
      : String.fromCharCodes(name.runes.take(1)).toUpperCase();
}

/// A forwarded message's one-line summary: its plain text read as a text
/// body's summary is (trimmed, Markdown to plain text, emoji-pack keys in the
/// reader's language), else its content's one-line summary
/// ([flareMessagePreviewText]), else previewForward.
String flareForwardPreviewLine(
  FlareForwardItem item,
  FlareStrings strings, {
  String? locale,
}) {
  final plain = flareMessagePreviewText(
    FlareTextContent(item.plainText),
    strings,
    locale: locale,
  ).trim();
  if (plain.isNotEmpty) return plain;
  final summary = flareMessagePreviewText(
    item.content,
    strings,
    locale: locale,
  ).trim();
  return summary.isEmpty ? strings.previewForward : summary;
}

/// What a forwarded message draws as content: its own, else its plain text
/// as a text body.
FlareMessageContent flareForwardItemContent(FlareForwardItem item) =>
    item.content ?? FlareTextContent(item.plainText.trim());

/// The record's layout and copy (`spec/message-forward-vectors.json`):
/// empty without items; single for one item of a record that is not merged;
/// else the card — title, subtitle (more than one message), the first three
/// "sender: text" lines, "N more" past three, the hint, the card's accessible
/// name and the drawer's title. Counts take their plural form in [locale].
FlareForwardRecordView flareForwardRecordView(
  FlareForwardContent record,
  FlareStrings strings, {
  String? locale,
}) {
  final count = record.items.length;
  final layout = count == 0
      ? FlareForwardLayout.empty
      : count == 1 && record.mode != FlareForwardMode.merged
      ? FlareForwardLayout.single
      : FlareForwardLayout.card;
  final trimmed = record.title.trim();
  final title = trimmed.isEmpty ? strings.forwardRecordTitle : trimmed;
  final subtitle = count > 1
      ? strings.forwardRecordTotalCount(count, locale)
      : null;
  return FlareForwardRecordView(
    layout: layout,
    title: title,
    subtitle: subtitle,
    previews: [
      for (final item in record.items.take(flareForwardPreviewLimit))
        (
          sender: flareForwardSender(item, strings),
          text: flareForwardPreviewLine(item, strings, locale: locale),
        ),
    ],
    more: count > flareForwardPreviewLimit
        ? strings.forwardRecordMoreCount(
            count - flareForwardPreviewLimit,
            locale,
          )
        : null,
    hint: strings.forwardRecordViewDetails,
    label: subtitle == null
        ? title
        : strings.forwardRecordCardLabel
              .replaceAll('{title}', title)
              .replaceAll('{subtitle}', subtitle),
    drawerTitle:
        '$title${strings.forwardRecordCountSuffix.replaceAll('{count}', '$count')}',
  );
}
