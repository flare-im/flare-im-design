import 'package:flutter/foundation.dart';

import '../tokens/flare_strings.dart';

/// What a notification shows: the sender and the message, the sender only, or
/// neither.
enum FlareNotificationPreview { full, senderOnly, hidden }

/// How the phone alerts while the person is using another device.
enum FlareMultiDeviceAlert { delay, immediate, badgeOnly }

/// When new messages arrive silently, in device local time. The protocol's
/// shape: minutes after midnight, weekdays as bits (bit 0 Monday … bit 6
/// Sunday, 0 every day).
@immutable
class FlareQuietHours {
  const FlareQuietHours({
    this.enabled = false,
    this.startMinute = 22 * 60,
    this.endMinute = 8 * 60,
    this.weekdays = 0,
    this.allowMentions = true,
  });

  /// Whether quiet hours apply; the times are kept while they are off.
  final bool enabled;

  /// Minutes after midnight, 0 to 1439.
  final int startMinute;

  /// Minutes after midnight; not after the start means the next day (equal is
  /// the whole day).
  final int endMinute;

  /// Bits, bit 0 Monday … bit 6 Sunday; 0 is every day.
  final int weekdays;

  /// Messages that mention the person still alert.
  final bool allowMentions;

  FlareQuietHours copyWith({
    bool? enabled,
    int? startMinute,
    int? endMinute,
    int? weekdays,
    bool? allowMentions,
  }) => FlareQuietHours(
    enabled: enabled ?? this.enabled,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    weekdays: weekdays ?? this.weekdays,
    allowMentions: allowMentions ?? this.allowMentions,
  );

  @override
  bool operator ==(Object other) =>
      other is FlareQuietHours &&
      other.enabled == enabled &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute &&
      other.weekdays == weekdays &&
      other.allowMentions == allowMentions;

  @override
  int get hashCode =>
      Object.hash(enabled, startMinute, endMinute, weekdays, allowMentions);
}

/// A person's notification preferences as [FlareNotificationAlertSettings]
/// edits them. The default is what a person who never chose has: quiet hours
/// off (22:00 to 08:00 every day, mentions allowed), full preview, delay.
@immutable
class FlareNotificationAlertPreferences {
  const FlareNotificationAlertPreferences({
    this.quietHours = const FlareQuietHours(),
    this.preview = FlareNotificationPreview.full,
    this.multiDevice = FlareMultiDeviceAlert.delay,
  });

  final FlareQuietHours quietHours;
  final FlareNotificationPreview preview;
  final FlareMultiDeviceAlert multiDevice;

  FlareNotificationAlertPreferences copyWith({
    FlareQuietHours? quietHours,
    FlareNotificationPreview? preview,
    FlareMultiDeviceAlert? multiDevice,
  }) => FlareNotificationAlertPreferences(
    quietHours: quietHours ?? this.quietHours,
    preview: preview ?? this.preview,
    multiDevice: multiDevice ?? this.multiDevice,
  );

  @override
  bool operator ==(Object other) =>
      other is FlareNotificationAlertPreferences &&
      other.quietHours == quietHours &&
      other.preview == preview &&
      other.multiDevice == multiDevice;

  @override
  int get hashCode => Object.hash(quietHours, preview, multiDevice);
}

/// Every day, as bits. 0 means the same.
const int allWeekdays = 0x7f;

/// The minute step of the start and end pickers.
const int quietHoursMinuteStep = 5;

const int _minutesPerDay = 24 * 60;

/// A minute of the day as HH:mm, 24-hour; minutes are taken modulo a day.
String formatMinuteOfDay(int minute) {
  final m = ((minute % _minutesPerDay) + _minutesPerDay) % _minutesPerDay;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(m ~/ 60)}:${two(m % 60)}';
}

/// HH:mm as a minute of the day; anything else reads as midnight.
int parseMinuteOfDay(String text) {
  final parts = text.split(':');
  final h = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  final m = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (h == null || m == null) return 0;
  return h.clamp(0, 23) * 60 + m.clamp(0, 59);
}

/// Whether the end is on the next day: it is not after the start.
bool quietHoursEndsNextDay(FlareQuietHours quietHours) =>
    quietHours.endMinute <= quietHours.startMinute;

/// Whether [day] (0 Monday … 6 Sunday) is in [mask]; 0 is every day.
bool weekdayIsOn(int mask, int day) {
  final days = mask & allWeekdays;
  return days == 0 || days & (1 << day) != 0;
}

/// [mask] with [day] turned on or off. 0 starts from all seven; all seven is
/// written 0; a pick that leaves no day changes nothing.
int weekdayToggle(int mask, int day, bool on) {
  final days = (mask & allWeekdays) == 0 ? allWeekdays : mask & allWeekdays;
  final next = on ? days | (1 << day) : days & ~(1 << day);
  if (next == 0) return mask;
  return next == allWeekdays ? 0 : next;
}

/// How a weekday mask reads.
enum FlareWeekdaySummaryKind { everyDay, weekdays, weekends, days }

/// How a weekday mask reads: every day, Monday to Friday, the weekend, or the
/// [days] in week order.
@immutable
class FlareWeekdaySummary {
  const FlareWeekdaySummary(this.kind, [this.days = const []]);
  final FlareWeekdaySummaryKind kind;
  final List<int> days;
}

FlareWeekdaySummary weekdaySummary(int mask) {
  final days = mask & allWeekdays;
  if (days == 0 || days == allWeekdays) {
    return const FlareWeekdaySummary(FlareWeekdaySummaryKind.everyDay);
  }
  if (days == 0x1f) {
    return const FlareWeekdaySummary(FlareWeekdaySummaryKind.weekdays);
  }
  if (days == 0x60) {
    return const FlareWeekdaySummary(FlareWeekdaySummaryKind.weekends);
  }
  return FlareWeekdaySummary(FlareWeekdaySummaryKind.days, [
    for (var day = 0; day < 7; day++)
      if (days & (1 << day) != 0) day,
  ]);
}

/// The name of [day] (0 Monday … 6 Sunday) in [strings].
String weekdayName(int day, {FlareStrings strings = const FlareStrings()}) =>
    switch (day) {
      0 => strings.weekdayMonday,
      1 => strings.weekdayTuesday,
      2 => strings.weekdayWednesday,
      3 => strings.weekdayThursday,
      4 => strings.weekdayFriday,
      5 => strings.weekdaySaturday,
      _ => strings.weekdaySunday,
    };

/// The words of the Repeat row for [mask].
String weekdaySummaryText(
  int mask, {
  FlareStrings strings = const FlareStrings(),
}) {
  final summary = weekdaySummary(mask);
  return switch (summary.kind) {
    FlareWeekdaySummaryKind.everyDay => strings.weekdayEveryDay,
    FlareWeekdaySummaryKind.weekdays => strings.weekdayWeekdays,
    FlareWeekdaySummaryKind.weekends => strings.weekdayWeekends,
    FlareWeekdaySummaryKind.days => summary.days
        .map((day) => weekdayName(day, strings: strings))
        .join(strings.displayNameSeparator),
  };
}

/// The words of the Ends row: the time, on the next day when it is not after
/// the start.
String quietHoursEndText(
  FlareQuietHours quietHours, {
  FlareStrings strings = const FlareStrings(),
}) {
  final time = formatMinuteOfDay(quietHours.endMinute);
  return quietHoursEndsNextDay(quietHours)
      ? strings.quietHoursNextDay(time)
      : time;
}

/// The words of [preview] in a settings row.
String notificationPreviewText(
  FlareNotificationPreview preview, {
  FlareStrings strings = const FlareStrings(),
}) => switch (preview) {
  FlareNotificationPreview.full => strings.notificationPreviewFull,
  FlareNotificationPreview.senderOnly => strings.notificationPreviewSenderOnly,
  FlareNotificationPreview.hidden => strings.notificationPreviewHidden,
};

/// The words of [policy] in a settings row.
String multiDeviceAlertText(
  FlareMultiDeviceAlert policy, {
  FlareStrings strings = const FlareStrings(),
}) => switch (policy) {
  FlareMultiDeviceAlert.delay => strings.multiDeviceDelay,
  FlareMultiDeviceAlert.immediate => strings.multiDeviceImmediate,
  FlareMultiDeviceAlert.badgeOnly => strings.multiDeviceBadgeOnly,
};
