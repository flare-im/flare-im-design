import 'package:flutter/foundation.dart';

import '../tokens/flare_strings.dart';

/// How strongly a new message asks for attention: the engine's notification
/// channel.
enum FlareInAppNotificationChannel { messages, quiet, mentions, urgent }

/// A message that arrived while the app is open on another screen, as the host
/// maps it from the engine's `notification.present` (surface `inApp`).
/// Spec: InAppNotificationBanner / InAppNotificationHost.
@immutable
class FlareInAppNotification {
  const FlareInAppNotification({
    required this.collapseId,
    required this.conversationId,
    this.messageId,
    required this.title,
    required this.body,
    this.count = 1,
    this.channel = FlareInAppNotificationChannel.messages,
    this.avatarUrl,
  });

  /// One banner per collapse id: a newer item with the same id replaces the
  /// shown or waiting one in place.
  final String collapseId;

  /// The conversation the banner opens; also seeds the avatar colour.
  final String conversationId;

  /// The newest message the banner stands for, handed back on open.
  final String? messageId;

  /// Conversation or sender name; its initials stand in for a missing avatar.
  final String title;

  /// The preview, drawn on one line and ellipsised.
  final String body;

  /// Unread messages the banner stands for; above 1 the kit's "[3条]" goes
  /// before the body.
  final int count;

  /// messages and quiet look the same; mentions and urgent carry a tag and an
  /// accent.
  final FlareInAppNotificationChannel channel;

  /// Conversation avatar the host resolved; the initials of [title] without it.
  final String? avatarUrl;

  /// Whether the count goes before the body: only above one message.
  bool get showsCount => count > 1;

  /// The tag before the body in [strings], or null for the plain channels.
  String? tag(FlareStrings strings) => switch (channel) {
    FlareInAppNotificationChannel.mentions => strings.inAppNotificationMention,
    FlareInAppNotificationChannel.urgent => strings.inAppNotificationUrgent,
    _ => null,
  };

  /// What a reader hears: New message, the title, the tag, the count and the
  /// body.
  String spoken(FlareStrings strings) => [
    strings.inAppNotificationLabel,
    title,
    if (tag(strings) case final String label) label,
    if (showsCount) strings.inAppNotificationCount(count),
    body,
  ].where((part) => part.isNotEmpty).join(', ');
}

/// How long a banner stays after it shows or is replaced, and again after a
/// touch or focus on it ends.
const Duration inAppNotificationDuration = Duration(milliseconds: 4000);

/// Banners waiting behind the visible one; beyond this the oldest waiting one
/// is dropped, so the newest win.
const int inAppNotificationPendingLimit = 3;

/// How far up a swipe has to travel before it dismisses the banner.
const double inAppNotificationSwipeDismissDistance = 24;

/// The presenter of the in-app new-message banner: the app feeds it and
/// [FlareInAppNotificationHost] draws it.
///
/// The app forwards the engine's `notification.present` events whose surface
/// is `inApp` to [present] and its `notification.clear` events to [clear] /
/// [clearAll]. What shows and what waits follows
/// spec/in-app-notification-vectors.json; the host owns the time on screen and
/// starts it over whenever [revision] moves.
class FlareInAppNotifications extends ChangeNotifier {
  FlareInAppNotification? _current;
  List<FlareInAppNotification> _pending = const [];
  int _revision = 0;

  /// The visible banner.
  FlareInAppNotification? get current => _current;

  /// Banners waiting, oldest first, at most [inAppNotificationPendingLimit].
  List<FlareInAppNotification> get pending => List.unmodifiable(_pending);

  /// Moves whenever a banner shows or the visible one is replaced.
  int get revision => _revision;

  /// Shows, replaces or queues [notification].
  void present(FlareInAppNotification notification) {
    final current = _current;
    if (current == null || current.collapseId == notification.collapseId) {
      _current = notification;
      _revision += 1;
      notifyListeners();
      return;
    }
    final waiting = _pending.indexWhere(
      (entry) => entry.collapseId == notification.collapseId,
    );
    final pending = [..._pending];
    if (waiting >= 0) {
      pending[waiting] = notification;
    } else {
      pending.add(notification);
      while (pending.length > inAppNotificationPendingLimit) {
        pending.removeAt(0);
      }
    }
    _pending = pending;
    notifyListeners();
  }

  /// The visible banner goes and the first waiting one shows.
  void dismiss() {
    if (_current == null && _pending.isEmpty) return;
    _advance();
    notifyListeners();
  }

  /// Takes away the banners of [collapseIds]; the visible one goes as
  /// [dismiss] says.
  void clear(Iterable<String> collapseIds) {
    final ids = collapseIds.toSet();
    if (ids.isEmpty) return;
    _pending = [
      for (final entry in _pending)
        if (!ids.contains(entry.collapseId)) entry,
    ];
    if (_current != null && ids.contains(_current!.collapseId)) _advance();
    notifyListeners();
  }

  /// Takes every banner away.
  void clearAll() {
    if (_current == null && _pending.isEmpty) return;
    _current = null;
    _pending = const [];
    notifyListeners();
  }

  void _advance() {
    if (_pending.isEmpty) {
      _current = null;
      return;
    }
    _current = _pending.first;
    _pending = _pending.sublist(1);
    _revision += 1;
  }
}
