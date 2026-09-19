import 'package:flutter/material.dart';

import '../models/message_content.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';

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
    return showModalBottomSheet<FlareMessageMenuSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    final entries = [
      ...messageMenuActions(
        availability,
        strings,
        hidden: hiddenActions,
        content: content,
      ),
      ...actions,
    ];
    // A host list is gated by canReact too: no strip on a message that cannot take one.
    final strip = availability.canReact
        ? (reactions ?? flareQuickReactions)
        : const <String>[];
    final grouped = FlareMessageMenuGroup.values
        .map(
          (group) => MapEntry(
            group,
            entries.where((entry) => entry.group == group).toList(),
          ),
        )
        .where((entry) => entry.value.isNotEmpty)
        .toList();

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
          padding: const EdgeInsets.fromLTRB(
            FlareSizes.spacingMd,
            FlareSizes.spacingLg,
            FlareSizes.spacingMd,
            FlareSizes.spacingMd,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (strip.isNotEmpty) ...[
                  Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    runSpacing: FlareSizes.spacingSm,
                    children: strip
                        .map((reaction) => _reaction(reaction))
                        .toList(growable: false),
                  ),
                  const SizedBox(height: FlareSizes.spacingMd),
                ],
                if (grouped.isEmpty && strip.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(FlareSizes.spacingLg),
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                for (var index = 0; index < grouped.length; index++) ...[
                  if (index > 0) const SizedBox(height: FlareSizes.spacingSm),
                  _actionGroup(grouped[index].value, colors),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reaction(String reaction) {
    return Semantics(
      button: true,
      label: reaction,
      child: InkResponse(
        onTap: onReact == null ? null : () => onReact!(reaction),
        radius: FlareSizes.touchTarget / 2,
        child: SizedBox.square(
          dimension: FlareSizes.touchTarget,
          child: Center(
            child: Text(
              reaction,
              style: const TextStyle(fontSize: FlareSizes.iconSizeLg),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionGroup(List<FlareMessageMenuEntry> entries, FlareColors colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        border: Border.all(color: colors.borderPrimary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0) Divider(height: 1, color: colors.borderSecondary),
            _action(entries[index], colors),
          ],
        ],
      ),
    );
  }

  Widget _action(FlareMessageMenuEntry entry, FlareColors colors) {
    final destructive = entry.group == FlareMessageMenuGroup.destructive;
    final foreground = !entry.enabled
        ? colors.textDisabled
        : destructive
        ? colors.error
        : colors.textPrimary;
    return Semantics(
      button: true,
      enabled: entry.enabled,
      label: entry.label,
      child: InkWell(
        onTap: entry.enabled && onAction != null
            ? () => onAction!(entry.id)
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingMd,
              vertical: FlareSizes.spacingSm,
            ),
            child: Row(
              children: [
                Icon(
                  flareIconGlyph(entry.icon),
                  color: foreground,
                  size: FlareSizes.iconSizeMd,
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Text(
                    entry.label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: FlareSizes.fontSizeXl,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
