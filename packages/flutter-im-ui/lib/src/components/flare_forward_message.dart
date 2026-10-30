import 'package:flutter/material.dart';

import '../models/forward_record.dart';
import '../models/message_content.dart';
import '../models/message_surface.dart';
import '../models/plural.dart';
import '../models/time_format.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_drawer.dart';
import 'flare_message_card_shell.dart';
import 'flare_message_content_view.dart';

/// A merged-forward record in the timeline (content type `forward`, card
/// surface), drawn the way every kit draws it
/// (`spec/message-forward-vectors.json`):
///
/// - no items: one line, forwardRecordEmpty;
/// - one item of a record that is not merged: that item's content inline (its
///   plain text as a text body when it has no content);
/// - otherwise the record card: the title (forwardRecordTitle when blank), "N
///   messages in total" past one message, the first three "sender: text"
///   lines, "N more messages…" past three and the hint forwardRecordViewDetails.
///   The whole card is one button named "title, subtitle"; a tap opens the kit
///   drawer titled "title (N)" with every message: the sender's initial, the
///   sender, the time, the summary line and, for content other than text, the
///   content drawn under it. In [selectionMode] the card does not respond.
///
/// Spec: Message/MessageContentView (`FlareForwardMessage`, drawn by
/// `FlareMessageContentView` for a [FlareForwardContent]).
class FlareForwardMessage extends StatelessWidget {
  const FlareForwardMessage({
    super.key,
    required this.record,
    this.self = false,
    this.selectionMode = false,
    this.locale,
  });

  final FlareForwardContent record;

  /// The viewer sent the forward; an inline single item draws as theirs.
  final bool self;

  /// The row is in multi-select: the card is inert.
  final bool selectionMode;

  /// Language tag of the counts and times; defaults to the app's locale.
  final String? locale;

  /// Keys for tests and hosts.
  static const Key cardKey = ValueKey('flare-forward-card');
  static const Key emptyKey = ValueKey('flare-forward-empty');
  static const Key drawerListKey = ValueKey('flare-forward-drawer-list');
  static Key itemKey(int index) => ValueKey('flare-forward-item-$index');

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final tag = flareCopyLocaleOf(context, locale);
    final view = flareForwardRecordView(record, strings, locale: tag);
    switch (view.layout) {
      case FlareForwardLayout.empty:
        return FlareMessageCardShell(
          child: Text(
            strings.forwardRecordEmpty,
            key: emptyKey,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: FlareSizes.fontSizeMd,
            ),
          ),
        );
      case FlareForwardLayout.single:
        final content = flareForwardItemContent(record.items.first);
        final key = flareMessageContentKey(content);
        final natural = flareMessageSurface(
          FlareMessageSurfaceInput(
            contentType: key.contentType,
            subtype: key.subtype,
            loneEmoji: flareIsLoneEmojiContent(content),
          ),
        );
        // The row is a card: what a bubble would carry sits on the card
        // shell instead, so it keeps the neutral palette.
        return FlareMessageContentView(
          content: content,
          self: self,
          selectionMode: selectionMode,
          surface: natural == FlareMessageSurface.bubble
              ? FlareMessageSurface.card
              : natural,
        );
      case FlareForwardLayout.card:
        return FlareMessageCardShell(child: _card(context, colors, view, tag));
    }
  }

  Widget _card(
    BuildContext context,
    FlareColors colors,
    FlareForwardRecordView view,
    String locale,
  ) {
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: FlareSizes.fontSizeLg * 1.4,
          margin: const EdgeInsetsDirectional.only(end: FlareSizes.spacingSm),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                view.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeLg,
                  fontWeight: FontWeight.w700,
                  height: FlareSizes.lineHeightSnug,
                ),
              ),
              if (view.subtitle case final subtitle?) ...[
                const SizedBox(height: FlareSizes.spacing3xs),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareSizes.fontSizeSm,
                  ),
                ),
              ],
              const SizedBox(height: FlareSizes.spacingXs),
              for (final line in view.previews)
                Padding(
                  padding: const EdgeInsets.only(bottom: FlareSizes.spacing3xs),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${line.sender}: ',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: _oneLine(line.text)),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: FlareSizes.fontSizeMd,
                      height: FlareSizes.lineHeightNormal,
                    ),
                  ),
                ),
              if (view.more case final more?)
                Text(
                  more,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: FlareSizes.fontSizeSm,
                  ),
                ),
              const SizedBox(height: FlareSizes.spacingXs),
              Text(
                view.hint,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: FlareSizes.fontSizeXs,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final open = selectionMode
        ? null
        : () => FlareDrawer.show<void>(
            context,
            title: view.drawerTitle,
            navigable: false,
            builder: (_) => _FlareForwardRecordList(
              key: drawerListKey,
              record: record,
              locale: locale,
            ),
          );
    return Semantics(
      button: true,
      enabled: !selectionMode,
      label: view.label,
      excludeSemantics: true,
      onTap: open,
      child: GestureDetector(
        key: cardKey,
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: body,
      ),
    );
  }

  static String _oneLine(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// The full list of a merged-forward record, in the kit drawer.
class _FlareForwardRecordList extends StatelessWidget {
  const _FlareForwardRecordList({
    super.key,
    required this.record,
    required this.locale,
  });

  final FlareForwardContent record;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        0,
        FlareSizes.spacingLg,
        FlareSizes.spacingLg,
      ),
      itemCount: record.items.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: colors.borderPrimary),
      itemBuilder: (context, index) {
        final item = record.items[index];
        final sender = flareForwardSender(item, strings);
        final initial = flareForwardSenderInitial(item);
        final time = item.sentAtMs > 0
            ? FlareTimeFormat.dateTime(
                DateTime.fromMillisecondsSinceEpoch(item.sentAtMs),
                locale: locale,
              )
            : '';
        final content = item.content;
        final embed = content != null && content is! FlareTextContent;
        return Padding(
          key: FlareForwardMessage.itemKey(index),
          padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.avatarTintBlueBg,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: colors.avatarTintBlueFg,
                          fontSize: FlareSizes.fontSizeMd,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: FlareSizes.spacingSm),
                  Expanded(
                    child: Text(
                      sender,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSizeMd,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(width: FlareSizes.spacingSm),
                    Text(
                      time,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: FlareSizes.fontSizeXs,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 36 + FlareSizes.spacingSm,
                  top: FlareSizes.spacingSm,
                ),
                child: Text(
                  flareForwardPreviewLine(item, strings, locale: locale),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSizeMd,
                    height: FlareSizes.lineHeightNormal,
                  ),
                ),
              ),
              if (embed)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 36 + FlareSizes.spacingSm,
                    top: FlareSizes.spacingSm,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FlareMessageContentView(content: content),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
