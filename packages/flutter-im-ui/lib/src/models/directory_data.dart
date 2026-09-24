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
    this.flareId,
    this.remark,
    this.region,
    this.phone,
    this.tags = const [],
  });

  /// The account id: identifies the contact to the host, never shown.
  final String id;
  final String name;
  final String? avatarUrl;
  final String? signature;
  final FlarePresence? presence;

  /// Explicit A-Z index letter; derived from [name] when null.
  final String? indexKey;

  /// The person's public Flare ID (the handle they chose), shown by
  /// ContactDetail and ProfileCard only when set. Never pass the account [id]
  /// here.
  final String? flareId;

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

/// Who sent a friend request: [incoming] ones wait for the current user,
/// [outgoing] ones wait for the other person.
enum FlareFriendRequestDirection { incoming, outgoing }

class FlareFriendRequest {
  const FlareFriendRequest({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.message,
    this.direction = FlareFriendRequestDirection.incoming,
  });
  final String id;
  final String name;
  final String? avatarUrl;
  final String? message;
  final FlareFriendRequestDirection direction;
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

/// Who may join a group, in display order: anyone ([open]), after an admin
/// approves ([approval]), or only when invited ([invite]). The kit knows no
/// backend numbers: hosts map their own values onto this and back.
enum FlareGroupJoinPolicy { open, approval, invite }

/// The full data model for [FlareGroupDetail] — a group's settings/management
/// page. Presentational: the host maps its own group state onto this and
/// performs data updates when the component raises an intent.
class FlareGroupDetailModel {
  const FlareGroupDetailModel({
    required this.groupId,
    required this.name,
    this.avatarUrl,
    required this.memberCount,
    this.announcement,
    this.members = const [],
    required this.ownerId,
    this.adminIds = const [],
    this.mutedIds = const [],
    this.canManage = false,
    this.isOwner = false,
    this.myNickname,
    this.myMuted,
    this.myPinned,
    this.discoverable = false,
    this.joinPolicy,
    this.muteAll = false,
    this.onlyAdminCanAtAll = false,
    this.onlyAdminCanPin = false,
    this.shareCardPermission = true,
  });

  final String groupId;
  final String name;
  final String? avatarUrl;
  final int memberCount;
  final String? announcement;
  final List<FlareContact> members;
  final String ownerId;
  final List<String> adminIds;

  /// Muted member ids — drives the per-member mute action label.
  final List<String> mutedIds;

  /// Viewer owns or administers the group (gates the management sections).
  final bool canManage;
  final bool isOwner;

  /// Viewer's own nickname in this group.
  final String? myNickname;

  /// Viewer's per-group notification / pin preference; null when the host
  /// could not read it, so the row claims no state (the same rule as
  /// [joinPolicy]: the kit never guesses).
  final bool? myMuted;
  final bool? myPinned;

  /// Whether this group may appear in public group search.
  final bool discoverable;

  /// Who may join; null when the host does not know. The kit never guesses:
  /// the join-mode row then shows the not-set copy and its picker opens with
  /// nothing selected.
  final FlareGroupJoinPolicy? joinPolicy;
  final bool muteAll;
  final bool onlyAdminCanAtAll;
  final bool onlyAdminCanPin;
  final bool shareCardPermission;
}

/// A pending group join request, resolved for display.
class FlareGroupJoinRequestView {
  const FlareGroupJoinRequestView({
    required this.requestId,
    required this.applicantId,
    required this.applicantName,
    this.avatarUrl,
    this.message,
  });
  final String requestId;
  final String applicantId;
  final String applicantName;
  final String? avatarUrl;
  final String? message;
}

/// Visual weight of a [FlareButton].
/// 中性的低强度动作:配在主按钮旁边的那个「出口」。和 text 的唯一区别是不用品牌色 —— 两个都用紫色就分不出主次;和 ghost 的区别是没有那圈 40% 品牌色描边。内距走尺寸类而不是像 text 那样压成固定值,这样它和配对的主按钮同字数时同宽。
enum FlareButtonVariant { primary, secondary, ghost, danger, text, quiet }

/// Height/size step shared by form + button controls (sm 32 / md 40 / lg 48).
enum FlareControlSize { sm, md, lg }

/// One choice in a [FlareSelect] / [FlareRadioGroup].
class FlareSelectOption {
  final String value;
  final String label;
  final bool disabled;
  const FlareSelectOption({
    required this.value,
    required this.label,
    this.disabled = false,
  });
}

/// What a settings row is, which decides whether it is a control at all.
///
/// [navigation] opens a page or a picker: a button with a chevron and an
/// optional current value. [toggle] is a switch. [action] runs in place (clear
/// history, mark unread, sign out): a button with no chevron, `danger` for a
/// destructive one. [value] is read-only information: not a button, no chevron,
/// no pressed state, and it ignores taps — assistive technology reads "label,
/// detail" as one thing. [select] is a pick-one row showing a trailing check
/// when [FlareSettingsItem.value].
enum FlareSettingKind { navigation, toggle, action, value, select }

class FlareSettingsItem {
  const FlareSettingsItem({
    required this.key,
    required this.label,
    this.icon,
    this.kind = FlareSettingKind.navigation,
    this.value = false,
    this.detail,
    this.disabled = false,
    this.danger = false,
  });
  final String key;
  final String label;

  /// A semantic icon name from `flareIconNames`; null draws no icon.
  final String? icon;
  final FlareSettingKind kind;
  final bool value;
  final String? detail;
  final bool disabled;
  final bool danger;
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

/// A kind-grouped section of search results. [total] is the match count when
/// the list is truncated and the host knows it; [hasMore] says the list is
/// truncated when it does not (a search that takes a limit and returns no
/// count: ask for one more than is shown). [total] wins; a count is never made up.
class FlareSearchResultGroup {
  final FlareSearchResultKind kind;
  final String label;
  final List<FlareSearchResultItem> items;
  final int? total;
  final bool hasMore;
  const FlareSearchResultGroup({
    required this.kind,
    required this.label,
    this.items = const [],
    this.total,
    this.hasMore = false,
  });

  /// Whether [total] says more than is shown.
  bool get counted => total != null && total! > items.length;
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
  const FlareMomentAuthor({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
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

/// A minimal contact reference — enough to render a row (avatar + name).
///
/// Deliberately smaller than [FlareContact]: visibility lists and match results
/// come from endpoints that return only identity, not the full profile.
class FlareContactBrief {
  const FlareContactBrief({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
}

/// One hit from a contact-book match.
class FlareMatchedContact extends FlareContactBrief {
  const FlareMatchedContact({
    required super.userId,
    required super.displayName,
    super.avatarUrl,
    required this.matchedBy,
    this.alreadyFriend = false,
  });

  /// The phone/email that matched. Echoed on the row because the display name
  /// may be a nickname the user does not recognise from their address book.
  final String matchedBy;

  /// Already a friend → offer 发消息 instead of 添加.
  final bool alreadyFriend;
}

/// Which direction a Moments visibility rule points.
///
/// The two are opposites and setting the wrong one has privacy consequences,
/// so components must never share wording between them.
enum FlareMomentsVisibilityRuleKind {
  /// Hide my moments from this person.
  hideFrom,

  /// Do not show me this person's moments.
  mute,
}

/// 谁能看到这条动态（FR-100）。套件只认名字，宿主把自己的编号映射一次；
/// `spec/moments-privacy.json` 记着参考 app 原来的编号。
enum FlareMomentVisibility { friends, public, private }

/// 在可见人群之上做加减：谁都不单独指定 / 只给这些人 / 除了这些人。
enum FlareMomentAudienceMode { everyone, include, exclude }

/// 陌生人能往回看多久的动态。
enum FlareMomentHistoryRange { all, threeDays, oneMonth, sixMonths }

/// 私密动态没有名单可言：没人看得到，加减谁都不改变结果。
bool flareMomentAudienceApplies(FlareMomentVisibility visibility) =>
    visibility != FlareMomentVisibility.private;

/// 宿主自己的操作（举报、分享名片、后台工具），画在详情页里套件自带的按钮旁边（FR-046）。
/// [danger] 用危险色；套件只把 [id] 报回去，别的什么都不知道。
class FlareDetailExtraAction {
  const FlareDetailExtraAction({
    required this.id,
    required this.label,
    this.danger = false,
  });
  final String id;
  final String label;
  final bool danger;
}
