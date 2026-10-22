import 'package:flutter/foundation.dart';

import 'message_data.dart';
import 'message_surface.dart';

/// Grouping, row presentation and date pills of a timeline
/// (`spec/message-grouping-vectors.json`, docs/design/message-surface-and-meta.md
/// C4). Pure: the list and the shared vectors run the same functions.

enum FlareMessageGroupPosition { single, first, middle, last }

enum FlareAvatarPlacement { leading, trailing }

class FlareMessageRowPresentation {
  const FlareMessageRowPresentation({
    this.showAvatar = false,
    this.reserveAvatarSpace = false,
    this.showSenderName = false,
    this.avatarPlacement = FlareAvatarPlacement.leading,
    this.tail = false,
  });

  final bool showAvatar;
  final bool reserveAvatarSpace;
  final bool showSenderName;
  final FlareAvatarPlacement avatarPlacement;

  /// Draw the bubble tail: a bubble surface that ends its run.
  final bool tail;
}

/// The facts grouping reads about one message.
@immutable
class FlareTimelineItem {
  const FlareTimelineItem({
    required this.id,
    required this.senderId,
    required this.atMs,
    this.surface = FlareMessageSurface.bubble,
  });

  /// [message] on [surface].
  FlareTimelineItem.of(FlareMessageData message, FlareMessageSurface surface)
    : this(
        id: message.id,
        senderId: message.senderId,
        atMs: message.sentAtMs,
        surface: surface,
      );

  final String id;
  final String senderId;

  /// The send time (epoch ms); 0 when unknown (starts no day, breaks no run).
  final int atMs;
  final FlareMessageSurface surface;
}

/// The default gap that still continues a sender's run.
const int flareMessageGroupGapMs = 300000;

/// Whether two neighbouring messages share a run (rules.shareGroup): the same
/// non-empty sender within [timeGapMs], neither centered, and both cards or
/// neither (bubble and bare media mix; a switch to or from a card breaks the
/// run). Separators are the caller's ([flareMessageGroupPosition]).
bool flareMessagesShareGroup(
  FlareTimelineItem? previous,
  FlareTimelineItem? current, {
  int timeGapMs = flareMessageGroupGapMs,
}) {
  if (previous == null || current == null) return false;
  if (previous.surface == FlareMessageSurface.centered ||
      current.surface == FlareMessageSurface.centered) {
    return false;
  }
  if (previous.senderId.isEmpty || previous.senderId != current.senderId) {
    return false;
  }
  if ((previous.surface == FlareMessageSurface.card) !=
      (current.surface == FlareMessageSurface.card)) {
    return false;
  }
  if (previous.atMs <= 0 || current.atMs <= 0) return true;
  return (current.atMs - previous.atMs).abs() <= timeGapMs;
}

/// The position of [items][index] in its run (rules.position). A separator
/// (a date pill or the unread divider) drawn right above a row is listed in
/// [breaksBefore] by row index: the row above it closes its run and the row
/// below it opens a new one. Centered rows are always single.
FlareMessageGroupPosition flareMessageGroupPosition(
  List<FlareTimelineItem> items,
  int index, {
  Set<int> breaksBefore = const {},
  int timeGapMs = flareMessageGroupGapMs,
}) {
  final current = items[index];
  if (current.surface == FlareMessageSurface.centered) {
    return FlareMessageGroupPosition.single;
  }
  final joinsPrevious =
      index > 0 &&
      !breaksBefore.contains(index) &&
      flareMessagesShareGroup(
        items[index - 1],
        current,
        timeGapMs: timeGapMs,
      );
  final joinsNext =
      index + 1 < items.length &&
      !breaksBefore.contains(index + 1) &&
      flareMessagesShareGroup(current, items[index + 1], timeGapMs: timeGapMs);
  if (!joinsPrevious && !joinsNext) return FlareMessageGroupPosition.single;
  if (!joinsPrevious) return FlareMessageGroupPosition.first;
  if (!joinsNext) return FlareMessageGroupPosition.last;
  return FlareMessageGroupPosition.middle;
}

/// What a row draws (rules.presentation and rules.tail): incoming rows show
/// the avatar and, in groups, the name on the first of a run; the viewer's
/// own rows show neither unless [showSelfAvatar]; centered rows draw no
/// avatar, name, gutter or tail; only a bubble draws a tail, on the last of
/// its run.
FlareMessageRowPresentation flareMessageRowPresentation({
  required FlareTimelineItem item,
  required FlareMessageGroupPosition position,
  required String currentUserId,
  required bool groupConversation,
  bool showIncomingAvatar = true,
  bool showSelfAvatar = false,
  bool showGroupSenderName = true,
}) {
  final self = item.senderId == currentUserId;
  final placement = self
      ? FlareAvatarPlacement.trailing
      : FlareAvatarPlacement.leading;
  if (item.surface == FlareMessageSurface.centered) {
    return FlareMessageRowPresentation(avatarPlacement: placement);
  }
  final edge =
      position == FlareMessageGroupPosition.single ||
      position == FlareMessageGroupPosition.first;
  final end =
      position == FlareMessageGroupPosition.single ||
      position == FlareMessageGroupPosition.last;
  return FlareMessageRowPresentation(
    showAvatar: (self ? showSelfAvatar : showIncomingAvatar) && edge,
    reserveAvatarSpace: self ? showSelfAvatar : showIncomingAvatar,
    showSenderName: !self && groupConversation && showGroupSenderName && edge,
    avatarPlacement: placement,
    tail: item.surface == FlareMessageSurface.bubble && end,
  );
}

/// The tier of a date pill's label (rules.datePill): the kit's today and
/// yesterday words, month and day this year, or the full date.
enum FlareTimelineDateLabel { today, yesterday, monthDay, yearMonthDay }

/// One row of a timeline: a date pill, the unread divider or a message.
sealed class FlareTimelineRow {
  const FlareTimelineRow();
}

final class FlareTimelineDateRow extends FlareTimelineRow {
  const FlareTimelineDateRow({required this.label, required this.atMs});
  final FlareTimelineDateLabel label;

  /// The first message of the day, which the label is formatted from.
  final int atMs;
}

final class FlareTimelineUnreadRow extends FlareTimelineRow {
  const FlareTimelineUnreadRow({required this.count});

  /// Messages from the divider to the end not sent by the viewer.
  final int count;
}

final class FlareTimelineMessageRow extends FlareTimelineRow {
  const FlareTimelineMessageRow({
    required this.index,
    required this.id,
    required this.position,
    required this.presentation,
  });
  final int index;
  final String id;
  final FlareMessageGroupPosition position;
  final FlareMessageRowPresentation presentation;
}

/// A local calendar day as one number (yyyymmdd): the device zone, or a fixed
/// offset ([utcOffsetMinutes], tests).
int flareLocalDayKey(int atMs, {int? utcOffsetMinutes}) {
  final at = utcOffsetMinutes == null
      ? DateTime.fromMillisecondsSinceEpoch(atMs)
      : DateTime.fromMillisecondsSinceEpoch(
          atMs + utcOffsetMinutes * 60000,
          isUtc: true,
        );
  return at.year * 10000 + at.month * 100 + at.day;
}

/// The label tier of a pill for a message sent at [atMs], seen at [nowMs].
FlareTimelineDateLabel flareTimelineDateLabel(
  int atMs,
  int nowMs, {
  int? utcOffsetMinutes,
}) {
  DateTime wall(int ms) => utcOffsetMinutes == null
      ? DateTime.fromMillisecondsSinceEpoch(ms)
      : DateTime.fromMillisecondsSinceEpoch(
          ms + utcOffsetMinutes * 60000,
          isUtc: true,
        );
  final at = wall(atMs);
  final now = wall(nowMs);
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  if (sameDay(at, now)) return FlareTimelineDateLabel.today;
  final yesterday = utcOffsetMinutes == null
      ? DateTime(now.year, now.month, now.day - 1)
      : DateTime.utc(now.year, now.month, now.day - 1);
  if (sameDay(at, yesterday)) return FlareTimelineDateLabel.yesterday;
  return at.year == now.year
      ? FlareTimelineDateLabel.monthDay
      : FlareTimelineDateLabel.yearMonthDay;
}

/// The rows of a timeline (rules of the grouping vectors): a date pill before
/// the first message and wherever the local day changes, the unread divider
/// right before [unreadFromId] (after that day's pill), and every message
/// with its run position and presentation. Both separators end a run.
List<FlareTimelineRow> flareTimelineRows(
  List<FlareTimelineItem> items, {
  required String currentUserId,
  required bool groupConversation,
  String? unreadFromId,
  bool showIncomingAvatar = true,
  bool showSelfAvatar = false,
  bool showGroupSenderName = true,
  int? nowMs,
  int? utcOffsetMinutes,
  int timeGapMs = flareMessageGroupGapMs,
}) {
  final layout = flareTimelineLayout(
    items,
    currentUserId: currentUserId,
    unreadFromId: unreadFromId,
    utcOffsetMinutes: utcOffsetMinutes,
  );
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  final rows = <FlareTimelineRow>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (layout.dayStarts.contains(i)) {
      rows.add(
        FlareTimelineDateRow(
          label: flareTimelineDateLabel(
            item.atMs,
            now,
            utcOffsetMinutes: utcOffsetMinutes,
          ),
          atMs: item.atMs,
        ),
      );
    }
    if (i == layout.unreadIndex) {
      rows.add(FlareTimelineUnreadRow(count: layout.unreadCount));
    }
    final position = flareMessageGroupPosition(
      items,
      i,
      breaksBefore: layout.breaksBefore,
      timeGapMs: timeGapMs,
    );
    rows.add(
      FlareTimelineMessageRow(
        index: i,
        id: item.id,
        position: position,
        presentation: flareMessageRowPresentation(
          item: item,
          position: position,
          currentUserId: currentUserId,
          groupConversation: groupConversation,
          showIncomingAvatar: showIncomingAvatar,
          showSelfAvatar: showSelfAvatar,
          showGroupSenderName: showGroupSenderName,
        ),
      ),
    );
  }
  return rows;
}

/// Where the separators of a timeline fall: the rows that open a local day,
/// the unread row and its count, and the rows a separator is drawn above
/// (the first row's pill has no run above it).
({Set<int> dayStarts, int unreadIndex, int unreadCount, Set<int> breaksBefore})
flareTimelineLayout(
  List<FlareTimelineItem> items, {
  required String currentUserId,
  String? unreadFromId,
  int? utcOffsetMinutes,
}) {
  final starts = <int>{};
  var previousDay = 0;
  for (var i = 0; i < items.length; i++) {
    final at = items[i].atMs;
    if (at <= 0) continue;
    final day = flareLocalDayKey(at, utcOffsetMinutes: utcOffsetMinutes);
    if (day != previousDay) starts.add(i);
    previousDay = day;
  }
  var unreadIndex = -1;
  if (unreadFromId != null) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].id == unreadFromId) {
        unreadIndex = i;
        break;
      }
    }
  }
  var count = 0;
  if (unreadIndex >= 0) {
    for (var i = unreadIndex; i < items.length; i++) {
      if (items[i].senderId != currentUserId) count++;
    }
  }
  return (
    dayStarts: starts,
    unreadIndex: unreadIndex,
    unreadCount: count,
    breaksBefore: {
      for (final start in starts)
        if (start > 0) start,
      if (unreadIndex > 0) unreadIndex,
    },
  );
}
