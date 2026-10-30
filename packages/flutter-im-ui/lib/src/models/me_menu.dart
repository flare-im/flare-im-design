import 'package:flutter/foundation.dart';

import '../components/flare_icon.dart';
import '../tokens/flare_strings.dart';
import 'directory_data.dart';

/// What a 我 page menu item is: a built-in destination or a plugin page entry.
enum FlareMeMenuItemKind { builtin, plugin }

/// One item of the social SDK's `features.meMenu`, as the kit reads it.
@immutable
class FlareMeMenuItem {
  const FlareMeMenuItem({
    required this.kind,
    required this.id,
    this.icon,
    this.title,
    this.order = 0,
  });

  /// Reads one SDK item; null for a kind the kit does not know.
  static FlareMeMenuItem? fromJson(Map<String, Object?> json) {
    final kind = switch (json['kind']) {
      'builtin' => FlareMeMenuItemKind.builtin,
      'plugin' => FlareMeMenuItemKind.plugin,
      _ => null,
    };
    final id = json['id'];
    if (kind == null || id is! String) return null;
    final order = json['order'];
    return FlareMeMenuItem(
      kind: kind,
      id: id,
      icon: json['icon'] is String ? json['icon']! as String : null,
      title: json['title'] is String ? json['title']! as String : null,
      order: order is num ? order.toInt() : 0,
    );
  }

  final FlareMeMenuItemKind kind;

  /// `moments` / `reports` / `invite` / `settings` for a built-in item;
  /// `plugin:<contributionId>` for a plugin item.
  final String id;

  /// A kit icon name; another name draws the plugin glyph.
  final String? icon;

  /// A plugin item's title.
  final String? title;

  /// The SDK's sort key. The kit keeps the given order and never re-sorts.
  final int order;
}

/// The social SDK's `features.meMenu` result: the items in the SDK's order,
/// and whether everything was read ([complete] false: the switches or the
/// plugin catalog were not, and the host reads again later).
@immutable
class FlareMeMenu {
  const FlareMeMenu({this.items = const [], this.complete = true});

  /// Reads the SDK's JSON `{items, complete}`; items of an unknown kind are
  /// dropped.
  factory FlareMeMenu.fromJson(Map<String, Object?> json) {
    final raw = json['items'];
    return FlareMeMenu(
      items: [
        if (raw is List)
          for (final item in raw)
            if (item is Map)
              ?FlareMeMenuItem.fromJson(item.cast<String, Object?>()),
      ],
      complete: json['complete'] != false,
    );
  }

  final List<FlareMeMenuItem> items;
  final bool complete;
}

/// The 我 page's settings sections from the SDK's [menu]
/// (`spec/me-menu-vectors.json`):
///
/// - section one holds every item but `settings`, in the SDK's order (the kit
///   never re-sorts); `settings` alone is section two, last; an empty section
///   is left out;
/// - a built-in item's label is [labels]`[id]`, else the kit copy
///   (meMenuMoments / Reports / Invite / Settings); a built-in id the kit does
///   not know is dropped;
/// - a plugin item's label is its title trimmed, else meMenuPluginFallback;
/// - an item's detail is [summaries]`[id]` trimmed when not empty: a plugin
///   item's meMenuSummary text, or the host's subtitle for a built-in page
///   (what 我的邀请 holds);
/// - the icon is [flareIconNameOrFallback] of the item's icon, `plugin` when
///   it has none;
/// - of two items with one id the first is kept.
///
/// Every row is a navigation row keyed by the item id: the host routes a
/// built-in id itself and opens a plugin item's page.
List<FlareSettingsSection> flareMeMenuSections(
  FlareMeMenu menu, {
  Map<String, String> labels = const {},
  Map<String, String> summaries = const {},
  FlareStrings strings = const FlareStrings(),
}) {
  final seen = <String>{};
  final main = <FlareSettingsItem>[];
  FlareSettingsItem? settings;
  for (final item in menu.items) {
    if (!seen.add(item.id)) continue;
    final icon = flareIconNameOrFallback(item.icon) ?? 'plugin';
    final summary = summaries[item.id]?.trim() ?? '';
    final detail = summary.isEmpty ? null : summary;
    switch (item.kind) {
      case FlareMeMenuItemKind.builtin:
        final copy = switch (item.id) {
          'moments' => strings.meMenuMoments,
          'reports' => strings.meMenuReports,
          'invite' => strings.meMenuInvite,
          'settings' => strings.meMenuSettings,
          _ => null,
        };
        if (copy == null) continue;
        final row = FlareSettingsItem(
          key: item.id,
          label: labels[item.id] ?? copy,
          icon: icon,
          detail: detail,
        );
        if (item.id == 'settings') {
          settings = row;
        } else {
          main.add(row);
        }
      case FlareMeMenuItemKind.plugin:
        final title = item.title?.trim() ?? '';
        main.add(
          FlareSettingsItem(
            key: item.id,
            label: title.isEmpty ? strings.meMenuPluginFallback : title,
            icon: icon,
            detail: detail,
          ),
        );
    }
  }
  return [
    if (main.isNotEmpty) FlareSettingsSection(items: main),
    if (settings != null) FlareSettingsSection(items: [settings]),
  ];
}
