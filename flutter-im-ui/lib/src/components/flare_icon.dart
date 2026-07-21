import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// The 52 semantic icon names exposed by [FlareIcon], in canonical order.
///
/// Kept in lock-step with the cross-platform icon-library contract so every
/// platform ships the same fixed vocabulary of glyphs.
const List<String> flareIconNames = <String>[
  'search',
  'send',
  'more',
  'back',
  'close',
  'check',
  'add',
  'remove',
  'edit',
  'delete',
  'heart',
  'heart-filled',
  'comment',
  'share',
  'camera',
  'image',
  'location',
  'mic',
  'phone',
  'video',
  'settings',
  'person',
  'people',
  'person-add',
  'star',
  'bookmark',
  'download',
  'link',
  'emoji',
  'file',
  'folder',
  'notification',
  'mute',
  'copy',
  'forward',
  'reply',
  'refresh',
  'chevron-down',
  'chevron-right',
  'arrow-down',
  'warning',
  'info',
  'success',
  'error',
  'calendar',
  'clock',
  'eye',
  'eye-off',
  'lock',
  'qr',
  'chats',
  'moments',
];

/// Maps each semantic name in [flareIconNames] to the closest Material glyph.
///
/// Outlined variants are preferred where a good one exists, matching the
/// kit's light, considered visual language; otherwise a filled glyph is used.
const Map<String, IconData> flareIconMap = <String, IconData>{
  'search': Icons.search,
  'send': Icons.send,
  'more': Icons.more_horiz,
  'back': Icons.arrow_back,
  'close': Icons.close,
  'check': Icons.check,
  'add': Icons.add,
  'remove': Icons.remove,
  'edit': Icons.edit_outlined,
  'delete': Icons.delete_outline,
  'heart': Icons.favorite_border,
  'heart-filled': Icons.favorite,
  'comment': Icons.chat_bubble_outline,
  'share': Icons.share_outlined,
  'camera': Icons.photo_camera_outlined,
  'image': Icons.image_outlined,
  'location': Icons.location_on_outlined,
  'mic': Icons.mic_none_outlined,
  'phone': Icons.phone_outlined,
  'video': Icons.videocam_outlined,
  'settings': Icons.settings_outlined,
  'person': Icons.person_outline,
  'people': Icons.people_outline,
  'person-add': Icons.person_add_alt_1_outlined,
  'star': Icons.star_border,
  'bookmark': Icons.bookmark_border,
  'download': Icons.download_outlined,
  'link': Icons.link,
  'emoji': Icons.emoji_emotions_outlined,
  'file': Icons.insert_drive_file_outlined,
  'folder': Icons.folder_outlined,
  'notification': Icons.notifications_outlined,
  'mute': Icons.notifications_off_outlined,
  'copy': Icons.copy_outlined,
  'forward': Icons.forward,
  'reply': Icons.reply,
  'refresh': Icons.refresh,
  'chevron-down': Icons.keyboard_arrow_down,
  'chevron-right': Icons.chevron_right,
  'arrow-down': Icons.arrow_downward,
  'warning': Icons.warning_amber_outlined,
  'info': Icons.info_outline,
  'success': Icons.check_circle_outline,
  'error': Icons.cancel_outlined,
  'calendar': Icons.calendar_today_outlined,
  'clock': Icons.access_time,
  'eye': Icons.visibility_outlined,
  'eye-off': Icons.visibility_off_outlined,
  'lock': Icons.lock_outline,
  'qr': Icons.qr_code,
  'chats': Icons.forum_outlined,
  'moments': Icons.explore_outlined,
};

/// A cross-platform icon rendered from a fixed semantic [name].
///
/// Unknown names fall back to [Icons.help_outline] so a missing mapping is
/// visible rather than silently blank. When [color] is omitted the icon uses
/// the kit's secondary text colour for the current brightness.
class FlareIcon extends StatelessWidget {
  const FlareIcon(this.name, {super.key, this.size = 20, this.color});

  /// One of the semantic names in [flareIconNames].
  final String name;

  /// Rendered glyph size in logical pixels.
  final double size;

  /// Optional override colour; defaults to the token secondary text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      flareIconMap[name] ?? Icons.help_outline,
      size: size,
      color: color ?? FlareColors.of(Theme.of(context).brightness).textSecondary,
    );
  }
}
