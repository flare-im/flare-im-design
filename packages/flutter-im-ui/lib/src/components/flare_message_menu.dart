import 'package:flutter/material.dart';

import '../models/message_data.dart';
import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import 'flare_action_menu.dart';
import 'flare_message_action_sheet.dart';

/// What [FlareMessageList] builds a message's menus from: the long-press
/// sheet and, on a pointer device, the secondary-click menu — one entry list
/// ([messageMenuEntries]) drawn in two places, so the host never assembles a
/// second list for the pointer menu. Spec: MessageList `menu`
/// (`FlareMessageMenuSource`).
///
/// - [availability] reads the host's snapshot of the core's action
///   availability for a message, synchronously; null while the host has none.
///   The host refreshes its snapshots asynchronously and rebuilds the list.
/// - [prefetch] is called with the ids ([FlareMessageData.id]) of rows coming
///   on screen, of a row whose menu was asked for without a snapshot, and of
///   the message an open pointer menu is showing when the host drops its
///   snapshot: the host reads their availability ahead of a menu. Asking again
///   for the open menu is the list's job; the host drops a snapshot that no
///   longer holds and answers prefetch, nothing more.
/// - [hiddenActions] is that of [FlareMessageActionSheet]; [extraActions]
///   gives the host's own entries for a message (the sheet's `actions`), so an
///   entry can depend on the message — "report" only on someone else's. Both
///   menus draw the same result.
/// - [perform] receives the chosen entry from either menu.
///
/// Without a snapshot the pointer menu shows one disabled entry,
/// messageMenuLoading, and prefetches the row, once each time it is left
/// without one (when it opens, or when the host drops the snapshot while it is
/// open); the long-press sheet opens once the host's snapshot arrives (the
/// host reads, then the sheet opens).
@immutable
class FlareMessageMenuSource {
  const FlareMessageMenuSource({
    required this.availability,
    this.prefetch,
    this.hiddenActions = const {},
    this.extraActions,
    required this.perform,
  });

  final FlareMessageActionAvailability? Function(FlareMessageData message)
  availability;
  final void Function(List<String> messageIds)? prefetch;
  final Set<String> hiddenActions;
  final List<FlareMessageMenuEntry> Function(FlareMessageData message)?
  extraActions;

  /// The host's entries for [message]; none without [extraActions].
  List<FlareMessageMenuEntry> extraActionsFor(FlareMessageData message) =>
      extraActions?.call(message) ?? const [];
  final void Function(FlareMessageData message, String actionId) perform;

  /// The id of the pointer menu's placeholder entry while the snapshot is
  /// being read; it is disabled and never reaches [perform].
  static const String loadingEntryId = 'flare.messageMenu.loading';

  /// Whether a message's menu is mainly a pointer menu here (a fine pointer:
  /// desktop and web): the secondary click opens it where it landed.
  static bool pointerIdiom(BuildContext context) =>
      flareCapabilitiesOf(context).contextMenu;

  /// The entries [message]'s menus offer, or null while the host has no
  /// snapshot for it.
  List<FlareMessageMenuEntry>? entriesFor(
    FlareMessageData message,
    FlareStrings strings,
  ) {
    final snapshot = availability(message);
    if (snapshot == null) return null;
    return messageMenuEntries(
      snapshot,
      strings,
      hidden: hiddenActions,
      extra: extraActionsFor(message),
      content: message.content,
    );
  }
}

/// The pointer menu's items for [entries] (from [FlareMessageMenuSource.entriesFor]):
/// one item per entry, in order, its group kept and the destructive group in
/// the danger tone; null [entries] (no snapshot yet) give the one disabled
/// messageMenuLoading item.
List<FlareActionItem> flareMessagePointerMenuItems(
  List<FlareMessageMenuEntry>? entries,
  FlareStrings strings,
) {
  if (entries == null) {
    return [
      FlareActionItem(
        id: FlareMessageMenuSource.loadingEntryId,
        label: strings.messageMenuLoading,
        enabled: false,
      ),
    ];
  }
  return [
    for (final entry in entries)
      FlareActionItem(
        id: entry.id,
        label: entry.label,
        icon: entry.icon,
        group: entry.group.name,
        enabled: entry.enabled,
        danger: entry.group == FlareMessageMenuGroup.destructive,
      ),
  ];
}
