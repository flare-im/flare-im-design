import 'package:flutter/material.dart';

import 'flare_icon.dart';

/// The registry glyph for a semantic icon [name] — how a kit component that
/// builds or hands on an [IconData] (an icon table, an `IconButton`, a menu
/// entry) draws a name from [flareIconNames] instead of naming a Material glyph.
/// An unknown name draws the same visible fallback as [FlareIcon] and, in a
/// debug build, says so once on the console: a typo is a developer mistake, not
/// something a reader should see as an error. Internal: not exported from the
/// package.
IconData flareIconGlyph(String name) {
  final glyph = flareIconMap[name];
  if (glyph != null) return glyph;
  assert(() {
    if (_warned.add(name)) {
      debugPrint(
        'FlareIcon: "$name" is not one of the ${flareIconNames.length} '
        'semantic icon names; drawing the fallback glyph.',
      );
    }
    return true;
  }());
  return Icons.help_outline;
}

/// Names already warned about, so a name in a rebuilt list warns once.
final Set<String> _warned = <String>{};

/// The glyph for an action's semantic icon name — the one map behind the
/// conversation header's buttons and every `FlareActionMenu` row, so a name
/// draws the same glyph wherever an action appears. The header's own names
/// (including the call and details ids it resolves when an action has no
/// icon: `audioCall` → phone, `videoCall` → video, `addMember` → person-add,
/// `details` → info) come first, then the kit vocabulary in [flareIconMap].
/// Null when the name is unknown. Internal: not exported from the package.
IconData? flareActionIcon(String? name) => switch (name) {
  null => null,
  'search' => Icons.search_rounded,
  'phone' || 'audioCall' => Icons.call_outlined,
  'video' || 'videoCall' => Icons.videocam_outlined,
  'person-add' || 'addMember' => Icons.person_add_alt_1_outlined,
  'share' => Icons.share_outlined,
  'info' || 'details' => Icons.info_outline_rounded,
  'devices' => Icons.devices_outlined,
  _ => flareIconMap[name],
};
