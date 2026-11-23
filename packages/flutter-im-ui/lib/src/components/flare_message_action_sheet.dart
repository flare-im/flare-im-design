import 'package:flutter/material.dart';

import '../models/message_content.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'flare_bottom_sheet.dart';
import 'flare_overlay.dart';

enum FlareMessageMenuGroup { primary, organize, destructive }

@immutable
class FlareMessageMenuEntry {
  const FlareMessageMenuEntry({
    required this.id,
    required this.label,
    required this.icon,
    this.group = FlareMessageMenuGroup.organize,
    this.enabled = true,
  });

  final String id;
  final String label;

  /// A semantic icon name from `flareIconNames`.
  final String icon;
  final FlareMessageMenuGroup group;
  final bool enabled;
}

/// What can be done with one message right now: the `can*` flags of the core's
/// action availability (`domain::message_actions`), under the core's names. The
/// host asks the core and hands the answer to [FlareMessageActionSheet], which
/// turns it into the standard actions.
@immutable
class FlareMessageActionAvailability {
  const FlareMessageActionAvailability({
    this.canReply = false,
    this.canForward = false,
    this.canCopy = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canRecall = false,
    this.canPin = false,
    this.canUnpin = false,
    this.canReact = false,
    this.canMultiSelect = false,
    this.canSave = false,
    this.canResend = false,
  });

  /// The core's answer as the SDK returns it (camelCase JSON); a flag that is
  /// not `true` is off.
  factory FlareMessageActionAvailability.fromJson(Map<String, Object?> json) =>
      FlareMessageActionAvailability(
        canReply: json['canReply'] == true,
        canForward: json['canForward'] == true,
        canCopy: json['canCopy'] == true,
        canEdit: json['canEdit'] == true,
        canDelete: json['canDelete'] == true,
        canRecall: json['canRecall'] == true,
        canPin: json['canPin'] == true,
        canUnpin: json['canUnpin'] == true,
        canReact: json['canReact'] == true,
        canMultiSelect: json['canMultiSelect'] == true,
        canSave: json['canSave'] == true,
        canResend: json['canResend'] == true,
      );

  final bool canReply;
  final bool canForward;
  final bool canCopy;
  final bool canEdit;
  final bool canDelete;
  final bool canRecall;
  final bool canPin;
  final bool canUnpin;
  final bool canReact;
  final bool canMultiSelect;
  final bool canSave;
  final bool canResend;
}

/// Quick reactions the sheet offers when the host passes none; the same set on
/// every platform.
const flareQuickReactions = <String>['👍', '❤️', '😂', '😮', '😢', '🎉'];

/// The text a message puts on the clipboard, or null when it has none.
///
/// Only real body text counts: an image, video, voice or file message has
/// nothing to copy, whatever the core's `canCopy` says. (The core reads
/// `text_for_storage()`, which returns a preview token such as `[图片]` for
/// media, so its availability alone would offer a Copy that copies nothing.)
/// Cards and announcements copy their title, the same fallback the Vue kit
/// uses (`messageActionAvailability`).
String? flareCopyableText(FlareMessageContent? content) {
  final text = switch (content) {
    FlareTextContent(:final text) => text,
    FlareRichTextContent(:final plainText) => plainText,
    FlareCardContent(:final title) => title,
    FlareLinkCardContent(:final title) => title,
    FlareAnnouncementContent(:final title) => title,
    _ => null,
  };
  return (text == null || text.trim().isEmpty) ? null : text;
}

/// The standard actions [availability] allows, in the order every platform shows
/// them: reply, forward, recall and resend as quick actions; multi-select, mark,
/// pin, pin for me, unpin, copy, preview, save and edit as the list; delete last.
/// Mark and delete share `canDelete`, pin and pin-for-me share `canPin`,
/// multi-select and preview share `canMultiSelect`. Ids in [hidden] (actions the
/// host does not implement) are left out.
///
/// Copy needs [content] as well: it is offered only for a message with
/// [flareCopyableText], so media never gets a Copy that does nothing. A host
/// that passes no content gets no Copy.
List<FlareMessageMenuEntry> messageMenuActions(
  FlareMessageActionAvailability availability,
  FlareStrings strings, {
  Set<String> hidden = const {},
  FlareMessageContent? content,
}) {
  final a = availability;
  const primary = FlareMessageMenuGroup.primary;
  const organize = FlareMessageMenuGroup.organize;
  // Icons are registry names.
  final candidates = <(bool, String, String, String, FlareMessageMenuGroup)>[
    (a.canReply, 'reply', strings.messageActionReply, 'reply', primary),
    (a.canForward, 'forward', strings.messageActionForward, 'forward', primary),
    (a.canRecall, 'recall', strings.messageActionRecall, 'recall', primary),
    (a.canResend, 'resend', strings.messageActionResend, 'refresh', primary),
    (
      a.canMultiSelect,
      'multiSelect',
      strings.messageActionMultiSelect,
      'multi-select',
      organize,
    ),
    (a.canDelete, 'mark', strings.messageActionMark, 'mark', organize),
    (a.canPin, 'pin', strings.messageActionPin, 'pin', organize),
    (
      a.canPin,
      'pinSelf',
      strings.messageActionPinSelf,
      // A pin for this reader only: its own name, so it never shares the pin's glyph in one sheet.
      'pin-self',
      organize,
    ),
    (a.canUnpin, 'unpin', strings.messageActionUnpin, 'unpin', organize),
    (
      a.canCopy && flareCopyableText(content) != null,
      'copy',
      strings.messageActionCopy,
      'copy',
      organize,
    ),
    (
      a.canMultiSelect,
      'preview',
      strings.messageActionPreview,
      'eye',
      organize,
    ),
    (a.canSave, 'save', strings.messageActionSave, 'download', organize),
    (a.canEdit, 'edit', strings.messageActionEdit, 'edit', organize),
    (
      a.canDelete,
      'delete',
      strings.messageActionDelete,
      'delete',
      FlareMessageMenuGroup.destructive,
    ),
  ];
  return [
    for (final (allowed, id, label, icon, group) in candidates)
      if (allowed && !hidden.contains(id))
        FlareMessageMenuEntry(id: id, label: label, icon: icon, group: group),
  ];
}

/// Every entry a message's menu offers: the standard actions
/// ([messageMenuActions], less [hidden]) then the host's [extra] entries. The
/// one entry list behind the long-press sheet and the pointer menu, so the two
/// never differ.
List<FlareMessageMenuEntry> messageMenuEntries(
  FlareMessageActionAvailability availability,
  FlareStrings strings, {
  Set<String> hidden = const {},
  List<FlareMessageMenuEntry> extra = const [],
  FlareMessageContent? content,
}) => [
  ...messageMenuActions(
    availability,
    strings,
    hidden: hidden,
    content: content,
  ),
  ...extra,
];

@immutable
class FlareMessageMenuSelection {
  const FlareMessageMenuSelection.action(this.actionId) : reaction = null;
  const FlareMessageMenuSelection.reaction(this.reaction) : actionId = null;

  final String? actionId;
  final String? reaction;
}

/// The message long-press action sheet — a reaction strip plus grouped actions
/// (primary / organize / destructive). Spec: Message/MessageActionSheet
/// (`FlareMessageActionSheet`). The host passes the core's [availability] and
/// gets the standard actions (see [messageMenuActions]), leaves out the ones it
/// does not implement with [hiddenActions], and appends its own [actions] to
/// their groups. [reactions] defaults to [flareQuickReactions] when the message
/// can take one. The host dispatches the returned intent; the kit owns visual
/// semantics. Labels default to [FlareStrings].
///
/// [content] is the message's content: Copy appears only for a message that
/// has text to copy (see [flareCopyableText]).
class FlareMessageActionSheet extends StatelessWidget {
  const FlareMessageActionSheet({
    super.key,
    this.availability = const FlareMessageActionAvailability(),
    this.content,
    this.hiddenActions = const {},
    this.actions = const [],
    this.reactions,
    this.label,
    this.emptyText,
    this.onAction,
    this.onReact,
  });

  final FlareMessageActionAvailability availability;

  /// The content of the message the sheet acts on; decides whether Copy is
  /// offered. Null (unknown content) shows no Copy.
  final FlareMessageContent? content;
  final Set<String> hiddenActions;
  final List<FlareMessageMenuEntry> actions;
  final List<String>? reactions;
  final String? label;
  final String? emptyText;
  final ValueChanged<String>? onAction;
  final ValueChanged<String>? onReact;

  static Future<FlareMessageMenuSelection?> show(
    BuildContext context, {
    FlareMessageActionAvailability availability =
        const FlareMessageActionAvailability(),
    FlareMessageContent? content,
    Set<String> hiddenActions = const {},
    List<FlareMessageMenuEntry> actions = const [],
    List<String>? reactions,
    String? label,
    String? emptyText,
  }) {
    // The kit's short-task surface: a bottom sheet on the phone form factor, a
    // centered Modal on wide layouts. The list of actions is the whole panel,
    // so its name is spoken but not drawn.
    return FlareBottomSheet.show<FlareMessageMenuSelection>(
      context,
      title: label ?? FlareStrings.of(context).messageActionSheetLabel,
      titleHidden: true,
      builder: (sheetContext) => FlareMessageActionSheet(
        availability: availability,
        content: content,
        hiddenActions: hiddenActions,
        actions: actions,
        reactions: reactions,
        label: label,
        emptyText: emptyText,
        onAction: (id) => Navigator.of(
          sheetContext,
        ).pop(FlareMessageMenuSelection.action(id)),
        onReact: (reaction) => Navigator.of(
          sheetContext,
        ).pop(FlareMessageMenuSelection.reaction(reaction)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final label = this.label ?? strings.messageActionSheetLabel;
    final emptyText = this.emptyText ?? strings.messageActionSheetEmpty;
    final entries = messageMenuEntries(
      availability,
      strings,
      hidden: hiddenActions,
      extra: actions,
      content: content,
    );
    // A host list is gated by canReact too: no strip on a message that cannot take one.
    final strip = availability.canReact
        ? (reactions ?? flareQuickReactions)
        : const <String>[];
    // Vue `buildMessageContextSheetModel`: the primary group is the quick grid,
    // the rest one list with delete last.
    final ordered = [
      for (final group in FlareMessageMenuGroup.values)
        ...entries.where((entry) => entry.group == group),
    ];
    final quick = ordered
        .where((entry) => entry.group == FlareMessageMenuGroup.primary)
        .toList();
    final list = ordered
        .where((entry) => entry.group != FlareMessageMenuGroup.primary)
        .toList();

    // On a kit overlay the surface is the frame, the safe area and the name;
    // standing alone the sheet draws its own grouped backdrop.
    final onSurface = FlareOverlaySurface.maybeOf(context) != null;
    final body = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        FlareSizes.spacingMd,
        onSurface ? FlareSizes.spacingXs : FlareSizes.spacingLg,
        FlareSizes.spacingMd,
        FlareSizes.spacingMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (strip.isNotEmpty) _reactionStrip(strip, colors),
          if (ordered.isEmpty && strip.isEmpty)
            Padding(
              padding: const EdgeInsets.all(FlareSizes.spacingLg),
              child: Text(
                emptyText,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          if (quick.isNotEmpty) ...[
            if (strip.isNotEmpty) const SizedBox(height: FlareSizes.spacing2sm),
            _quickGrid(quick, colors),
          ],
          if (list.isNotEmpty) ...[
            if (strip.isNotEmpty || quick.isNotEmpty)
              const SizedBox(height: FlareSizes.spacing2sm),
            _listBlock(list, colors),
          ],
        ],
      ),
    );
    if (onSurface) return body;
    return Semantics(
      container: true,
      label: label,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(FlareSizes.radiusXl),
            ),
          ),
          child: body,
        ),
      ),
    );
  }

  /// One of the sheet's white blocks (Vue `.msg-ctx-sheet__block`).
  Widget _block(FlareColors colors, Widget child) => DecoratedBox(
    decoration: BoxDecoration(
      color: colors.bgPrimary,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A111318),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: child,
  );

  /// Emoji on 48pt tiles, scrolling sideways when they do not fit (Vue `__reactions`).
  Widget _reactionStrip(List<String> strip, FlareColors colors) => _block(
    colors,
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: FlareSizes.spacingMd,
        vertical: FlareSizes.spacing2sm,
      ),
      child: Row(
        children: [
          for (var index = 0; index < strip.length; index++) ...[
            if (index > 0) const SizedBox(width: FlareSizes.spacingSm),
            _reaction(strip[index], colors),
          ],
        ],
      ),
    ),
  );

  Widget _reaction(String reaction, FlareColors colors) {
    return Semantics(
      button: true,
      label: reaction,
      child: Material(
        color: colors.bgTertiary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onReact == null ? null : () => onReact!(reaction),
          borderRadius: BorderRadius.circular(14),
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: Text(
                reaction,
                style: const TextStyle(fontSize: 28, height: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Reply, forward, recall, resend: tinted 52pt tiles with their names under
  /// them, sharing the row (Vue `__quick`).
  Widget _quickGrid(List<FlareMessageMenuEntry> entries, FlareColors colors) =>
      _block(
        colors,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FlareSizes.spacingSm,
            FlareSizes.spacing2md,
            FlareSizes.spacingSm,
            FlareSizes.spacingMd,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in entries)
                Expanded(child: _quickAction(entry, colors)),
            ],
          ),
        ),
      );

  Widget _quickAction(FlareMessageMenuEntry entry, FlareColors colors) {
    // Vue marks recall as the danger quick action.
    final danger = entry.id == 'recall';
    return Semantics(
      button: true,
      enabled: entry.enabled,
      label: entry.label,
      child: Opacity(
        opacity: entry.enabled ? 1 : 0.45,
        child: InkWell(
          onTap: entry.enabled && onAction != null
              ? () => onAction!(entry.id)
              : null,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: FlareSizes.spacingXs,
              horizontal: FlareSizes.spacing2xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (danger ? colors.error : colors.primary).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    flareIconGlyph(entry.icon),
                    color: danger ? colors.errorText : colors.primaryText,
                    size: FlareSizes.iconSizeLg,
                  ),
                ),
                const SizedBox(height: FlareSizes.spacingSm),
                Text(
                  entry.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: danger ? colors.errorText : colors.textPrimary,
                    fontSize: FlareSizes.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The other actions as rows with a 44pt tinted icon disc and a hairline
  /// between them (Vue `__list`).
  Widget _listBlock(List<FlareMessageMenuEntry> entries, FlareColors colors) =>
      _block(
        colors,
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: FlareSizes.spacing2xs,
            horizontal: FlareSizes.spacingSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < entries.length; index++) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    color: colors.borderPrimary.withValues(alpha: 0.55),
                  ),
                _action(entries[index], colors),
              ],
            ],
          ),
        ),
      );

  Widget _action(FlareMessageMenuEntry entry, FlareColors colors) {
    final destructive = entry.group == FlareMessageMenuGroup.destructive;
    final foreground = !entry.enabled
        ? colors.textTertiary
        : destructive
        ? colors.errorText
        : colors.textPrimary;
    return Semantics(
      button: true,
      enabled: entry.enabled,
      label: entry.label,
      child: InkWell(
        onTap: entry.enabled && onAction != null
            ? () => onAction!(entry.id)
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacing2sm,
            vertical: FlareSizes.spacingMd,
          ),
          child: Row(
            children: [
              Container(
                width: FlareSizes.touchTargetMin,
                height: FlareSizes.touchTargetMin,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: destructive
                      ? colors.error.withValues(alpha: 0.12)
                      : colors.bgSelected,
                ),
                child: Icon(
                  flareIconGlyph(entry.icon),
                  color: destructive ? colors.errorText : colors.primaryText,
                  size: FlareSizes.iconSizeMd,
                ),
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: Text(
                  entry.label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: FlareSizes.fontSize2xl,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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
