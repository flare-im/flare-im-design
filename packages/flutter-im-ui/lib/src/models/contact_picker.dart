import 'package:flutter/foundation.dart';

/// Contact picker contracts (spec ContactPicker): the people a contact card
/// can name, grouped the way the host knows them. The kit filters and draws;
/// who may be shared is the host's and the server's rule.

/// One person [FlareContactPicker] can return.
@immutable
class FlareContactPickerEntry {
  const FlareContactPickerEntry({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.subtitle,
    this.isSelf = false,
  });
  final String userId;
  final String name;
  final String? avatarUrl;

  /// A secondary line (department, handle); searched with the name.
  final String? subtitle;

  /// The signed-in user: drawn with the "(me)" suffix and still selectable.
  final bool isSelf;

  /// Case-insensitive match against the name and the subtitle; a blank query
  /// matches everyone.
  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return name.toLowerCase().contains(needle) ||
        (subtitle?.toLowerCase().contains(needle) ?? false);
  }

  @override
  bool operator ==(Object other) =>
      other is FlareContactPickerEntry &&
      other.userId == userId &&
      other.name == name &&
      other.avatarUrl == avatarUrl &&
      other.subtitle == subtitle &&
      other.isSelf == isSelf;

  @override
  int get hashCode => Object.hash(userId, name, avatarUrl, subtitle, isSelf);
}

/// The group id the kit labels "Friends".
const String flareContactPickerFriends = 'friends';

/// The group id the kit labels "Group members".
const String flareContactPickerGroupMembers = 'groupMembers';

/// One tab of the picker. A picker with a single group shows no tabs.
@immutable
class FlareContactPickerGroup {
  const FlareContactPickerGroup({
    required this.id,
    this.label,
    required this.entries,
  });

  /// [flareContactPickerFriends], [flareContactPickerGroupMembers] or the
  /// host's own id (which then needs a [label]).
  final String id;

  /// Tab label; defaults to the kit's words for the two known ids.
  final String? label;
  final List<FlareContactPickerEntry> entries;
}
