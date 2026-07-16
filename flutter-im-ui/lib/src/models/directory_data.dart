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
    this.remark,
    this.region,
    this.phone,
    this.tags = const [],
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? signature;
  final FlarePresence? presence;

  /// Explicit A-Z index letter; derived from [name] when null.
  final String? indexKey;

  /// Optional profile detail — surfaced by ContactDetail / ProfileCard.
  final String? remark;
  final String? region;
  final String? phone;
  final List<String> tags;
}

/// One participant in a group (multi-party) call.
class FlareCallParticipant {
  const FlareCallParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.muted = false,
    this.cameraOff = false,
    this.speaking = false,
    this.isSelf = false,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final bool muted;
  final bool cameraOff;
  final bool speaking;
  final bool isSelf;
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

/// A grouped emoji reaction on a message.
class FlareReactionGroup {
  final String emoji;
  final int count;
  final bool reactedBySelf;
  final List<String> users;
  const FlareReactionGroup({
    required this.emoji,
    required this.count,
    this.reactedBySelf = false,
    this.users = const [],
  });
}

/// A chat/contact target in the forward-message picker.
class FlareForwardTarget {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? subtitle;
  const FlareForwardTarget({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.subtitle,
  });
}

/// A candidate surfaced by the @-mention picker.
class FlareMentionCandidate {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? detail;
  final bool isEveryone;
  const FlareMentionCandidate({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.detail,
    this.isEveryone = false,
  });
}

/// A single reusable quick-reply phrase.
class FlareQuickPhrase {
  final String id;
  final String text;
  const FlareQuickPhrase({required this.id, required this.text});
}

/// A titled group of quick phrases.
class FlareQuickPhraseGroup {
  final String key;
  final String title;
  final List<FlareQuickPhrase> phrases;
  const FlareQuickPhraseGroup({
    required this.key,
    required this.title,
    this.phrases = const [],
  });
}

/// A slash-command suggestion surfaced by the composer's command menu.
class FlareSlashCommand {
  final String command;
  final String? description;
  final String? hint;
  const FlareSlashCommand({required this.command, this.description, this.hint});
}

enum FlareSearchResultKind { contact, group, message }

/// One row in the global search results.
class FlareSearchResultItem {
  final String id;
  final FlareSearchResultKind kind;
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final String? meta;
  const FlareSearchResultItem({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.meta,
  });
}

/// A kind-grouped section of search results.
class FlareSearchResultGroup {
  final FlareSearchResultKind kind;
  final String label;
  final List<FlareSearchResultItem> items;
  final int? total;
  const FlareSearchResultGroup({
    required this.kind,
    required this.label,
    this.items = const [],
    this.total,
  });
}

/// A single image tile in an image grid / gallery.
class FlareGridImage {
  final String? url;
  final String? alt;
  const FlareGridImage({this.url, this.alt});
}

/// A selectable chat-wallpaper option — either a solid [color] (hex string like
/// "#7C3AED") or an [imageUrl].
class FlareWallpaperOption {
  final String id;
  final String? color;
  final String? imageUrl;
  final String? label;
  const FlareWallpaperOption({
    required this.id,
    this.color,
    this.imageUrl,
    this.label,
  });
}

/// Author of a moment / social-feed post or comment.
class FlareMomentAuthor {
  final String id;
  final String name;
  final String? avatarUrl;
  const FlareMomentAuthor({required this.id, required this.name, this.avatarUrl});
}

/// A single "like" on a moment.
class FlareMomentLike {
  final String id;
  final String name;
  const FlareMomentLike({required this.id, required this.name});
}

/// A comment on a moment. When [replyToName] is set the line renders
/// "A replying to B".
class FlareMomentComment {
  final String id;
  final FlareMomentAuthor author;
  final String text;
  final String? replyToName;
  final String? time;
  const FlareMomentComment({
    required this.id,
    required this.author,
    required this.text,
    this.replyToName,
    this.time,
  });
}

/// A social-feed (Moments / 圈子) post.
class FlareMoment {
  final String id;
  final FlareMomentAuthor author;
  final String? text;
  final List<FlareGridImage> images;
  final String? location;
  final String? time;
  final List<FlareMomentLike> likes;
  final List<FlareMomentComment> comments;
  final bool likedBySelf;
  const FlareMoment({
    required this.id,
    required this.author,
    this.text,
    this.images = const [],
    this.location,
    this.time,
    this.likes = const [],
    this.comments = const [],
    this.likedBySelf = false,
  });
}

/// A category of emojis in the emoji picker.
class FlareEmojiCategory {
  final String key;
  final String label;
  final String? symbol;
  final List<String> emojis;
  const FlareEmojiCategory({
    required this.key,
    required this.label,
    this.symbol,
    this.emojis = const [],
  });
}

/// A single sticker in a sticker pack.
class FlareStickerItem {
  final String id;
  final String? url;
  final String? placeholder;
  const FlareStickerItem({required this.id, this.url, this.placeholder});
}

/// A pack of stickers surfaced by the sticker panel.
class FlareStickerPack {
  final String key;
  final String label;
  final String? coverUrl;
  final String? coverEmoji;
  final List<FlareStickerItem> stickers;
  const FlareStickerPack({
    required this.key,
    required this.label,
    this.coverUrl,
    this.coverEmoji,
    this.stickers = const [],
  });
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
