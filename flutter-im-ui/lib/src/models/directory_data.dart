import 'package:flutter/widgets.dart';

import '../components/flare_avatar.dart' show FlarePresence;

/// A directory contact.
class FlareContact {
  const FlareContact({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.signature,
    this.presence,
    this.indexKey,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? signature;
  final FlarePresence? presence;

  /// Explicit A-Z index letter; derived from [name] when null.
  final String? indexKey;
}

class FlareFriendRequest {
  const FlareFriendRequest({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.message,
  });
  final String id;
  final String name;
  final String? avatarUrl;
  final String? message;
}

class FlareGroupSummary {
  const FlareGroupSummary({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.memberCount = 0,
  });
  final String id;
  final String name;
  final String? avatarUrl;
  final int memberCount;
}

class FlareUserProfile {
  const FlareUserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.signature,
    this.flareId,
  });
  final String id;
  final String name;
  final String? avatarUrl;
  final String? signature;
  final String? flareId;
}

enum FlareSettingKind { navigation, toggle, value }

class FlareSettingsItem {
  const FlareSettingsItem({
    required this.key,
    required this.label,
    this.icon,
    this.kind = FlareSettingKind.navigation,
    this.value = false,
    this.detail,
  });
  final String key;
  final String label;
  final IconData? icon;
  final FlareSettingKind kind;
  final bool value;
  final String? detail;
}

class FlareSettingsSection {
  const FlareSettingsSection({this.title, required this.items});
  final String? title;
  final List<FlareSettingsItem> items;
}

/// A destination in [FlareAppShell]'s adaptive navigation.
class FlareNavItem {
  const FlareNavItem({
    required this.key,
    required this.label,
    required this.icon,
    this.badge = 0,
  });
  final String key;
  final String label;
  final IconData icon;
  final int badge;
}
